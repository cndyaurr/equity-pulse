import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;

class BeritaDetailPage extends StatelessWidget {
  final Map<String, dynamic> article;

  const BeritaDetailPage({super.key, required this.article});

  // Tema warna EWF
  static const Color background = Color(0xFFFFFBF7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFF58220);
  static const Color primaryDark = Color(0xFFD96812);
  static const Color primaryLight = Color(0xFFFFE5CC);
  static const Color textPrimary = Color(0xFF252525);
  static const Color textSecondary = Color(0xFF555555);
  static const Color muted = Color(0xFF777777);
  static const Color dividerColor = Color(0xFFE2E8F0);

  String _cleanContent(String raw) {
    final formatted = raw
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    final document = html_parser.parse(formatted);

    return (document.body?.text ?? formatted).trim();
  }

  @override
  Widget build(BuildContext context) {
    final title = article['title']?.toString() ?? 'Berita';
    final category = article['category']?.toString() ?? 'Berita';
    final source = article['source']?.toString() ?? 'Equity Pulse';
    final date = article['date']?.toString() ?? '';
    final image = article['image']?.toString() ?? '';
    final content = _cleanContent(article['description']?.toString() ?? '');

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Detail Berita',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar berita
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _imagePlaceholder();
                      },
                    )
                  : _imagePlaceholder(),
            ),

            const SizedBox(height: 20),

            // Label kategori
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.toUpperCase(),
                style: GoogleFonts.roboto(
  color: primaryDark,
  fontSize: 10,
  fontWeight: FontWeight.w700,
),
              ),
            ),

            const SizedBox(height: 14),

            // Judul berita
            Text(
              title,
              style: GoogleFonts.roboto(
  color: const Color(0xFF1F2937),
  fontSize: 16,
  height: 1.35,
  fontWeight: FontWeight.w700,
),
            ),

            const SizedBox(height: 14),

            // Sumber dan tanggal
            Row(
              children: [
                const Icon(Icons.newspaper_outlined, size: 17, color: primary),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    source,
                    style: GoogleFonts.roboto(
  color: const Color(0xFF64748B),
  fontSize: 10,
  fontWeight: FontWeight.w600,
),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: muted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    date,
                    textAlign: TextAlign.end,
                    style: GoogleFonts.roboto(
  color: const Color(0xFF64748B),
  fontSize: 9,
  fontWeight: FontWeight.w500,
),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Divider(color: dividerColor),

            const SizedBox(height: 16),

            // Isi berita
            Text(
              'Isi Berita',
              style: GoogleFonts.roboto(
  color: const Color(0xFF1F2937),
  fontSize: 16,
  fontWeight: FontWeight.w700,
),
            ),

            const SizedBox(height: 12),

            SelectableText(
              content.isNotEmpty ? content : 'Isi berita belum tersedia.',
              style: GoogleFonts.roboto(
  color: const Color(0xFF475569),
  fontSize: 13,
  height: 1.5,
),
            ),

            const SizedBox(height: 28),

            // Tombol kembali
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali ke Daftar Berita'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: const BorderSide(color: primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: primaryLight,
      alignment: Alignment.center,
      child: const Icon(Icons.newspaper_outlined, size: 56, color: primary),
    );
  }
}
