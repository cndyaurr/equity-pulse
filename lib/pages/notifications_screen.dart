
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/gold_price.dart';
import '../models/pivot_point.dart';
import '../services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Warna mengikuti BeritaDetailPage.
  static const Color background = Color(0xFFFFFBF7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFF58220);
  static const Color primaryDark = Color(0xFFD96812);
  static const Color primaryLight = Color(0xFFFFE5CC);
  static const Color surfaceContainer = Color(0xFFFFE5CC);
  static const Color surfaceContainerLow = Color(0xFFFFF3E8);
  static const Color textPrimary = Color(0xFF252525);
  static const Color textSecondary = Color(0xFF555555);

  bool _isLoading = true;
  bool _allRead = false;
  String? _errorMessage;

  List<GoldPrice> _prices = [];
  List<PivotPoint> _pivotPoints = [];
  Map<String, dynamic>? _latestNews;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _yesterday =>
      _today.subtract(const Duration(days: 1));

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatPrice(num? value) {
    if (value == null) return '-';

    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final formattedInteger = integer.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );

    return '$formattedInteger,$decimal';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:-- WIB';

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute WIB';
  }

  DateTime? _parseNewsDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<Map<String, dynamic>?> _getLatestNewsToday() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/news?per_page=50'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);

      if (decoded is! List) return null;

      final todayNews = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) {
            final date = _parseNewsDate(item['published_at']);
            return date != null &&
                _dateKey(date.toLocal()) == _dateKey(_today);
          })
          .toList();

      todayNews.sort((a, b) {
        final dateA = _parseNewsDate(a['published_at']);
        final dateB = _parseNewsDate(b['published_at']);

        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      return todayNews.isEmpty ? null : todayNews.first;
    } catch (_) {
      return null;
    }
  }

  Future<PivotPoint?> _getPivotSafely(String commodity) async {
    try {
      final pivot = await ApiService.getPivotPoint(commodity);

      final pivotDate = DateTime.tryParse(
        pivot.date.substring(0, 10),
      );

      if (pivotDate == null ||
          _dateKey(pivotDate) != _dateKey(_today)) {
        return null;
      }

      return pivot;
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadNotifications() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        ApiService.getGoldPrices(),
        _getLatestNewsToday(),
      ]);

      final prices = results[0] as List<GoldPrice>;
      final news = results[1] as Map<String, dynamic>?;

      final pivotResults = await Future.wait([
        _getPivotSafely('LGD'),
        _getPivotSafely('HSI'),
      ]);

      if (!mounted) return;

      setState(() {
        _prices = prices;
        _latestNews = news;
        _pivotPoints = pivotResults.whereType<PivotPoint>().toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Tidak dapat memuat notifikasi. Periksa koneksi server.';
        _isLoading = false;
      });
    }
  }

  List<GoldPrice> get _todayPrices {
    return _prices.where((price) {
      final date = price.recordedAt;

      return date != null &&
          _dateKey(date.toLocal()) == _dateKey(_today);
    }).toList();
  }

  List<GoldPrice> get _yesterdayPrices {
    return _prices.where((price) {
      final date = price.recordedAt;

      return date != null &&
          _dateKey(date.toLocal()) == _dateKey(_yesterday);
    }).toList();
  }

  List<String> get _commodities {
    final values = _prices.map((price) => price.commodity).toSet();
    return values.toList();
  }

  GoldPrice? _findPrice(
    List<GoldPrice> source,
    String commodity,
  ) {
    final matches = source
        .where((price) => price.commodity == commodity)
        .toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) {
      final dateA = a.recordedAt;
      final dateB = b.recordedAt;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return matches.first;
  }

  List<Map<String, dynamic>> _buildTodayNotifications() {
    final notifications = <Map<String, dynamic>>[];

    // Harga pembukaan hari ini.
    for (final commodity in _commodities) {
      final price = _findPrice(_todayPrices, commodity);

      if (price == null || price.open == null) continue;

      notifications.add({
        'category': 'HARGA PEMBUKAAN',
        'title': 'Harga Pembukaan $commodity Hari Ini',
        'description':
            'Harga pembukaan tercatat sebesar ${_formatPrice(price.open)} ${commodity == 'LGD' ? 'USD / t.oz.' : 'INDEX'}.',
        'time': _formatTime(price.recordedAt),
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF059669),
        'background': const Color(0xFFE1F3E8),
        'highlight': true,
      });
    }

    // Berita terbaru hari ini.
    if (_latestNews != null) {
      final news = _latestNews!;
      final publishedAt = _parseNewsDate(news['published_at']);

      notifications.add({
        'category': 'BERITA TERBARU',
        'title': news['title'] ?? 'Berita Pasar Terbaru',
        'description':
            'Sumber: ${news['source'] ?? 'Equityworld Futures'}',
        'time': _formatTime(publishedAt),
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF1976D2),
        'background': const Color(0xFFE0ECFF),
        'highlight': false,
      });
    }

    // Pivot Point dan NEST hari ini.
    for (final pivot in _pivotPoints) {
      final commodity = pivot.commodity;
      final unit = pivot.unit;

      notifications.add({
        'category': 'PIVOT POINT',
        'title': 'Pivot Point $commodity Hari Ini',
        'description':
            'Pivot: ${_formatPrice(pivot.pivot)} $unit.',
        'time': '07:30 WIB',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFD18A00),
        'background': const Color(0xFFFFEDC7),
        'highlight': true,
      });

      if (pivot.nest != null) {
        notifications.add({
          'category': 'TREND / NEST',
          'title': 'Harga Trend $commodity Hari Ini',
          'description':
              'NEST: ${_formatPrice(pivot.nest)} $unit.',
          'time': '07:30 WIB',
          'icon': Icons.show_chart_rounded,
          'color': const Color(0xFF7C3AED),
          'background': const Color(0xFFEDE2FF),
          'highlight': false,
        });
      }
    }

    return notifications;
  }

  List<Map<String, dynamic>> _buildYesterdayNotifications() {
    final notifications = <Map<String, dynamic>>[];

    for (final commodity in _commodities) {
      final price = _findPrice(_yesterdayPrices, commodity);

      if (price == null || price.close == null) continue;

      notifications.add({
        'category': 'HARGA PENUTUPAN',
        'title': 'Harga Penutupan $commodity Kemarin',
        'description':
            'Harga penutupan tercatat sebesar ${_formatPrice(price.close)} ${commodity == 'LGD' ? 'USD / t.oz.' : 'INDEX'}.',
        'time': _formatTime(price.recordedAt),
        'icon': Icons.trending_down_rounded,
        'color': const Color(0xFFDC2626),
        'background': const Color(0xFFFFDEDE),
        'highlight': false,
      });
    }

    return notifications;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final todayNotifications = _buildTodayNotifications();
    final yesterdayNotifications = _buildYesterdayNotifications();

    final newCount = _allRead ? 0 : todayNotifications.length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: textPrimary,
          ),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$newCount BARU',
                  style: GoogleFonts.roboto(
                    color: white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadNotifications,
        child: _isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 260),
                  Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                ],
              )
            : _errorMessage != null
                ? _buildErrorState()
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    children: [
                      _buildSectionHeader(
                        'HARI INI',
                        showMarkRead: true,
                      ),
                      const SizedBox(height: 14),

                      if (todayNotifications.isEmpty)
                        _buildEmptyMessage(
                          'Belum ada notifikasi hari ini.',
                        )
                      else
                        ...todayNotifications.map(
                          (item) => _NotificationCard(
                            item: item,
                            isRead: _allRead,
                          ),
                        ),

                      const SizedBox(height: 30),

                      _buildSectionHeader(
                        'KEMARIN',
                        showMarkRead: false,
                      ),
                      const SizedBox(height: 14),

                      if (yesterdayNotifications.isEmpty)
                        _buildEmptyMessage(
                          'Belum ada data notifikasi kemarin.',
                        )
                      else
                        ...yesterdayNotifications.map(
                          (item) => _NotificationCard(
                            item: item,
                            isRead: true,
                          ),
                        ),

                      const SizedBox(height: 28),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    required bool showMarkRead,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        if (showMarkRead)
          GestureDetector(
            onTap: () {
              setState(() {
                _allRead = !_allRead;
              });
            },
            child: Text(
              _allRead ? 'Sudah dibaca' : 'Tandai semua dibaca',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryDark,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryLight),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 15,
            color: textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }

    Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 180),
        const Icon(
          Icons.wifi_off_rounded,
          size: 45,
          color: textSecondary,
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            _errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              color: textSecondary,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(
              'Coba Lagi',
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: white,
            ),
          ),
        ),
      ],
    );
  }
} // Penutup class _NotificationsScreenState

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isRead;

  const _NotificationCard({
    required this.item,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = item['color'] as Color;
    final Color iconBackground = item['background'] as Color;
    final bool highlight = item['highlight'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight && !isRead
            ? const Color(0xFFFFE5CC)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight && !isRead
              ? const Color(0xFFFFC58A)
              : const Color(0xFFFFE5CC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              item['icon'] as IconData,
              color: color,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['category'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['time'] as String,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  item['title'] as String,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF252525),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['description'] as String,
                  style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF555555),
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
