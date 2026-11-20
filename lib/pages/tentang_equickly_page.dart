
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TentangEquicklyPage extends StatelessWidget {
  const TentangEquicklyPage({super.key});

  static const Color primary = Color(0xFFF58220);
  static const Color background = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);

  TextStyle style({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: textPrimary),
        title: Text(
          'Tentang EQUICKLY',
          style: style(size: 18, weight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LOGO DAN BRAND
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_perusahaan.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: TextSpan(
                        style: style(size: 26, weight: FontWeight.w800),
                        children: const [
                          TextSpan(
                            text: 'EQU',
                            style: TextStyle(color: textPrimary),
                          ),
                          TextSpan(
                            text: 'ICKLY',
                            style: TextStyle(color: primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'MARKET INTELLIGENCE',
                      style: style(
                        size: 11,
                        weight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // NAMA EQUICKLY
              _sectionTitle('Makna Nama EQUICKLY'),
              const SizedBox(height: 10),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nama EQUICKLY merupakan gabungan dari dua kata:',
                      textAlign: TextAlign.justify,
                      style: style(size: 13),
                    ),
                    const SizedBox(height: 16),

                    _meaningItem(
                      title: 'EQUITY',
                      description:
                          'Merepresentasikan bidang keuangan, investasi, dan perdagangan.',
                      icon: Icons.trending_up_rounded,
                    ),

                    const SizedBox(height: 14),

                    _meaningItem(
                      title: 'QUICKLY',
                      description:
                          'Menggambarkan kecepatan dan kemudahan dalam memperoleh informasi.',
                      icon: Icons.speed_rounded,
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Secara keseluruhan, EQUICKLY memiliki makna sebagai aplikasi yang membantu pengguna mendapatkan informasi pasar dengan lebih cepat, mudah, dan efisien melalui satu platform terintegrasi.',
                        textAlign: TextAlign.justify,
                        style: style(
                          size: 13,
                          weight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // TUJUAN PENGEMBANGAN
              _sectionTitle('Tujuan Pengembangan'),
              const SizedBox(height: 10),

              _card(
                child: Text(
                  'EQUICKLY dikembangkan sebagai solusi digital untuk menjawab kebutuhan PT Equityworld Futures terhadap aplikasi pemantauan pasar emas yang terintegrasi.',
                  textAlign: TextAlign.justify,
                  style: style(size: 13),
                ),
              ),

              const SizedBox(height: 24),

              // FITUR APLIKASI
              _sectionTitle('Fitur dalam Satu Platform'),
              const SizedBox(height: 10),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dengan menggabungkan fitur pemantauan harga trading, histori harga, perhitungan analisis, berita, dan notifikasi dalam satu platform, EQUICKLY diharapkan mampu meningkatkan kemudahan dan efisiensi pengguna dalam memperoleh informasi pasar.',
                      textAlign: TextAlign.justify,
                      style: style(size: 13),
                    ),
                    const SizedBox(height: 18),

                    _featureItem(
                      Icons.show_chart_rounded,
                      'Pemantauan Harga Trading',
                    ),
                    _featureItem(
                      Icons.history_rounded,
                      'Histori Harga',
                    ),
                    _featureItem(
                      Icons.analytics_outlined,
                      'Perhitungan Analisis',
                    ),
                    _featureItem(
                      Icons.newspaper_rounded,
                      'Informasi Berita Pasar',
                    ),
                    _featureItem(
                      Icons.notifications_active_outlined,
                      'Notifikasi',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KEMUDAHAN PENGGUNAAN
              _sectionTitle('Kemudahan Penggunaan'),
              const SizedBox(height: 10),

              _card(
                child: Text(
                  'Selain mengutamakan kelengkapan informasi, aplikasi ini juga memperhatikan kemudahan penggunaan agar dapat diakses oleh pengguna dengan latar belakang usia dan pemahaman teknologi digital yang beragam.',
                  textAlign: TextAlign.justify,
                  style: style(size: 13),
                ),
              ),

              const SizedBox(height: 24),

              // FOOTER
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 30,
                      color: primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EQUICKLY',
                      style: style(size: 16, weight: FontWeight.w800),
                    ),
                    Text(
                      'Market Intelligence',
                      style: style(
                        size: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: style(size: 16, weight: FontWeight.w700),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // MEANING ITEM
  // ============================================================

  Widget _meaningItem({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: style(size: 14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.justify,
                style: style(size: 12, color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE ITEM
  // ============================================================

  Widget _featureItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: style(size: 13, weight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
