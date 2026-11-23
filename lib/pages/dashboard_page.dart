
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'harga_emas_page.dart';
import 'pivot_point_page.dart';
import 'kalkulator_page.dart';
import 'informasi_pt_page.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../widgets/latest_news_section.dart';
import 'konset_page.dart';
import 'tentang_equickly_page.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const DashboardPage({super.key, this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  void _openFeature(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFFF58220);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);

  TextStyle jakarta({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return GoogleFonts.roboto(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo_perusahaan.png',
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: jakarta(
                      size: 18,
                      weight: FontWeight.w700,
                      color: Colors.black,
                    ),
                    children: const [
                      TextSpan(
                        text: 'EQUICKLY',
                        style: TextStyle(color: Color(0xFFFF9800)),
                      ),
                    ],
                  ),
                ),
                Text(
                  'MARKET INTELLIGENCE',
                  style: jakarta(
                    size: 11,
                    weight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none,
              color: textPrimary,
            ),
          ),
        ],
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardBody(),
          KonsetPage(
            onHargaTap: () => _openFeature(const HargaEmasPage()),
            onPivotTap: () => _openFeature(PivotPointPage(user: widget.user)),
            onKalkulatorTap: () => _openFeature(const KalkulatorPage()),
          ),
          ProfileScreen(user: widget.user),
        ],
      ),

      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  Widget _buildDashboardBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcome(),
            const SizedBox(height: 20),

            // BERITA
            const LatestNewsSection(),

            const SizedBox(height: 24),

            // INFORMASI PT
            _buildInfoCard(
              icon: Icons.business_outlined,
              title: 'Informasi PT',
              subtitle:
                  'Informasi perusahaan, legalitas, jaringan cabang, dan layanan customer care.',
              onTap: () => _openFeature(const InformasiPtPage()),
            ),

            const SizedBox(height: 12),

            // TENTANG EQUICKLY
            _buildInfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Tentang EQUICKLY',
              subtitle:
                  'Kenali EQUICKLY, tujuan pengembangan, dan fitur aplikasi.',
              onTap: () => _openFeature(const TentangEquicklyPage()),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CARD INFORMASI
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: jakarta(
                      size: 15,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: jakarta(
                      size: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation(BuildContext context) {
    final items = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Dashboard'),
      (
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Konsep',
      ),
      (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (index) {
            final active = _selectedIndex == index;

            return Expanded(
              child: InkWell(
                onTap: () => _selectTab(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      active ? items[index].activeIcon : items[index].icon,
                      size: 25,
                      color: active ? primary : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[index].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        color: active ? primary : textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: jakarta(size: 22, weight: FontWeight.w700),
        ),
      ],
    );
  }
}
