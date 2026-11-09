import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../pages/berita_detail_page.dart';
import '../pages/berita_page.dart';

class LatestNewsSection extends StatefulWidget {
  const LatestNewsSection({super.key});

  @override
  State<LatestNewsSection> createState() => _LatestNewsSectionState();
}

class _LatestNewsSectionState extends State<LatestNewsSection> {
  static const Color _orange = Color(0xFFF58220);
  static const Color _dark = Color(0xFF1F2937);
  static const Color _muted = Color(0xFF64748B);

  static const String _apiUrl = 'http://10.0.2.2:8000/api/news';

  List<Map<String, dynamic>> _news = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      debugPrint('[LATEST NEWS] Status: ${response.statusCode}');
      debugPrint('[LATEST NEWS] Response: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      dynamic rawData = decoded;

      // Mendukung respons List maupun object dengan key data.
      if (rawData is Map) {
        rawData = rawData['data'] ?? rawData['news'] ?? [];
      }

      // Mendukung pagination Laravel: data.data.
      if (rawData is Map) {
        rawData = rawData['data'] ?? [];
      }

      if (rawData is! List) {
        throw const FormatException(
          'Format respons API berita tidak sesuai.',
        );
      }

      final items = rawData
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) {
            return (item['title'] ?? '').toString().trim().isNotEmpty;
          })
          .toList();

      // Urutkan berita terbaru terlebih dahulu.
      items.sort((a, b) {
        final dateA = DateTime.tryParse(
          (a['published_at'] ?? '').toString(),
        );

        final dateB = DateTime.tryParse(
          (b['published_at'] ?? '').toString(),
        );

        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      final formattedNews = items.take(4).map((item) {
        return {
          'image': item['image']?.toString() ?? '',
          'category': item['category']?.toString() ?? 'Market News',
          'source': item['source']?.toString() ?? 'Equityworld Futures',
          'date': _formatDate(
            (item['published_at'] ?? '').toString(),
          ),
          'title': item['title']?.toString() ?? '',
          'url': item['url']?.toString() ?? '',
          'slug': item['slug']?.toString() ?? '',
          'description': item['content']?.toString() ?? '',
          'content': item['content']?.toString() ?? '',
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _news = formattedNews;
        _loading = false;
      });

      debugPrint('[LATEST NEWS] Berhasil memuat ${_news.length} berita.');
    } catch (e) {
      debugPrint('[LATEST NEWS] ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _formatDate(String raw) {
    final date = DateTime.tryParse(raw);

    if (date == null) return 'Latest update';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final local = date.toLocal();

    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  void _openAllNews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BeritaPage(),
      ),
    );
  }

  void _openArticle(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BeritaDetailPage(article: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latest News',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
            ),
            TextButton(
              onPressed: _openAllNews,
              child: const Text(
                'View All News',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        const Text(
          'Latest updates from the market',
          style: TextStyle(
            fontSize: 12,
            color: _muted,
          ),
        ),

        const SizedBox(height: 12),

        if (_loading)
          const SizedBox(
            height: 190,
            child: Center(
              child: CircularProgressIndicator(color: _orange),
            ),
          )
        else if (_error != null)
          _buildMessage(
            icon: Icons.wifi_off_outlined,
            message: 'News could not be loaded.',
            buttonLabel: 'Retry',
            onPressed: _loadNews,
          )
        else if (_news.isEmpty)
          _buildMessage(
            icon: Icons.newspaper_outlined,
            message: 'No news available yet.',
            buttonLabel: 'Refresh',
            onPressed: _loadNews,
          )
        else
          SizedBox(
            height: 252,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _news.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildNewsCard(_news[index]);
              },
            ),
          ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE5CC)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _muted),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> item) {
    final image = (item['image'] ?? '').toString();

    return SizedBox(
      width: 245,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openArticle(item),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFFFE5CC),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 118,
                  width: double.infinity,
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imagePlaceholder(),
                        )
                      : _imagePlaceholder(),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['category'] ?? 'Market News')
                              .toString()
                              .toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _orange,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Expanded(
                          child: Text(
                            (item['title'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _dark,
                              fontSize: 12,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${item['source']} · ${item['date']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFFFF3E8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.newspaper_outlined,
        size: 36,
        color: _orange,
      ),
    );
  }
}
