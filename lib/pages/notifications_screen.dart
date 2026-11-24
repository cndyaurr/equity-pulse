
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../models/gold_price.dart';
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
  static const Color textPrimary = Color(0xFF252525);
  static const Color textSecondary = Color(0xFF555555);

  bool _isLoading = true;
  bool _allRead = false;
  String? _errorMessage;

  List<GoldPrice> _prices = [];
  Map<String, dynamic>? _latestNews;

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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Waktu tidak tersedia';

    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute WIB';
  }

  DateTime? _parseNewsDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // Mengambil berita terbaru dari backend.
  Future<Map<String, dynamic>?> _getLatestNews() async {
    try {
      final response = await http
          .get(
            Uri.parse('${ApiService.baseUrl}/news?per_page=50'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);

      if (decoded is! List) return null;

      final newsList = decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (newsList.isEmpty) return null;

      newsList.sort((a, b) {
        final dateA = _parseNewsDate(a['published_at']);
        final dateB = _parseNewsDate(b['published_at']);

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      return newsList.first;
    } catch (_) {
      return null;
    }
  }

  // Memuat data harga harian dan berita terbaru.
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
        _getLatestNews(),
      ]);

      if (!mounted) return;

      setState(() {
        _prices = results[0] as List<GoldPrice>;
        _latestNews = results[1] as Map<String, dynamic>?;
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

  // Mengambil satu data harian terbaru untuk setiap komoditas.
  GoldPrice? _findLatestPrice(String commodity) {
    final matches = _prices.where((price) {
      return price.commodity.toUpperCase() == commodity.toUpperCase() &&
          price.recordedAt != null;
    }).toList();

    if (matches.isEmpty) return null;

    matches.sort(
      (a, b) => b.recordedAt!.compareTo(a.recordedAt!),
    );

    return matches.first;
  }

  // Membuat notifikasi harga pembukaan dan penutupan.
  List<Map<String, dynamic>> _buildPriceNotifications() {
    final notifications = <Map<String, dynamic>>[];

    for (final commodity in ['LGD', 'SNI', 'HSI']) {
      final price = _findLatestPrice(commodity);

      if (price == null) continue;

      final unit = commodity == 'LGD' ? 'USD / t.oz.' : 'INDEX';
      final date = _formatDate(price.recordedAt);

      if (price.open != null) {
        notifications.add({
          'category': 'HARGA PEMBUKAAN',
          'title': 'Harga Pembukaan $commodity',
          'description':
              'Harga pembukaan: ${_formatPrice(price.open)} $unit. '
                  'Tanggal data: $date.',
          'time': date,
          'icon': Icons.trending_up_rounded,
          'color': const Color(0xFF059669),
          'background': const Color(0xFFE1F3E8),
          'highlight': true,
        });
      }

      if (price.close != null) {
        notifications.add({
          'category': 'HARGA PENUTUPAN',
          'title': 'Harga Penutupan $commodity',
          'description':
              'Harga penutupan: ${_formatPrice(price.close)} $unit. '
                  'Tanggal data: $date.',
          'time': date,
          'icon': Icons.trending_down_rounded,
          'color': const Color(0xFFDC2626),
          'background': const Color(0xFFFFDEDE),
          'highlight': false,
        });
      }
    }

    return notifications;
  }

  // Membuat notifikasi berita terbaru.
  List<Map<String, dynamic>> _buildNewsNotifications() {
    final notifications = <Map<String, dynamic>>[];

    if (_latestNews != null) {
      final news = _latestNews!;
      final publishedAt = _parseNewsDate(news['published_at']);

      notifications.add({
        'category': 'BERITA TERBARU',
        'title': news['title']?.toString() ??
            'Berita Terbaru Equityworld Futures',
        'description':
            'Sumber: ${news['source'] ?? 'Equityworld Futures'}',
        'time': _formatTime(publishedAt),
        'icon': Icons.newspaper_rounded,
        'color': const Color(0xFF1976D2),
        'background': const Color(0xFFE0ECFF),
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
    final priceNotifications = _buildPriceNotifications();
    final newsNotifications = _buildNewsNotifications();

    final newCount = _allRead
        ? 0
        : priceNotifications.length + newsNotifications.length;

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
                        'HARGA PEMBUKAAN & PENUTUPAN',
                        showMarkRead: true,
                      ),
                      const SizedBox(height: 14),

                      if (priceNotifications.isEmpty)
                        _buildEmptyMessage(
                          'Belum ada data harga dari News Maker.',
                        )
                      else
                        ...priceNotifications.map(
                          (item) => _NotificationCard(
                            item: item,
                            isRead: _allRead,
                          ),
                        ),

                      const SizedBox(height: 30),

                      _buildSectionHeader(
                        'BERITA TERBARU',
                        showMarkRead: false,
                      ),
                      const SizedBox(height: 14),

                      if (newsNotifications.isEmpty)
                        _buildEmptyMessage('Belum ada berita terbaru.')
                      else
                        ...newsNotifications.map(
                          (item) => _NotificationCard(
                            item: item,
                            isRead: _allRead,
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
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
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
}

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
