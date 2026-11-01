import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class InformasiPtPage extends StatefulWidget {
  const InformasiPtPage({super.key});

  @override
  State<InformasiPtPage> createState() => _InformasiPtPageState();
}

class _InformasiPtPageState extends State<InformasiPtPage> {
  int selectedTab = 0;

  final Color primary = const Color(0xFF785600);
  final Color surface = const Color(0xFFF8F9FF);
  final Color surfaceLow = const Color(0xFFEFF4FF);
  final Color textPrimary = const Color(0xFF0B1C30);
  final Color textSecondary = const Color(0xFF4F4535);
  final Color tertiary = const Color(0xFF006947);

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLegalitas(String regulator) {
    String title = '';
    String registration = '';
    String description = '';

    if (regulator == 'BAPPEBTI') {
      title = 'Legalitas BAPPEBTI';
      registration = '988/BAPPEBTI/SI/9/2006';
      description =
          'Izin resmi operasional pialang berjangka komoditi dari Kementerian Perdagangan Republik Indonesia. '
          'Menjamin kepatuhan integritas pasar emas dan instrumen derivatif.';
    } else if (regulator == 'BBJ') {
      title = 'Keanggotaan BBJ / JFX';
      registration = 'SPAB-044/BBJ/03/02';
      description =
          'Surat Persetujuan Anggota Bursa (SPAB) dari PT Bursa Berjangka Jakarta '
          'yang memberikan hak transmisi order perdagangan emas Loco London dan produk multilateral.';
    } else if (regulator == 'KBI') {
      title = 'Keanggotaan PT KBI';
      registration = '36/AK-KBI/IX/2006';
      description =
          'Izin registrasi Lembaga Kliring Berjangka Indonesia (Persero) BUMN '
          'untuk penjaminan penyelesaian dana transaksi fisik maupun derivatif secara transparan.';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: primary,
                      size: 25,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: surfaceLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _modalRow(
                        'Status Lembaga',
                        'TERVERIFIKASI AKTIF',
                        valueColor: tertiary,
                      ),
                      const SizedBox(height: 12),
                      _modalRow(
                        'Nomor Registrasi',
                        registration,
                      ),
                      const SizedBox(height: 12),
                      _modalRow(
                        'Kategori Keanggotaan',
                        'Pialang Penuh / Berjangka',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  description,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Text(
                      'Tutup Tinjauan Legalitas',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  return DefaultTextStyle.merge(
    style: GoogleFonts.roboto(),
    child: Scaffold(
      backgroundColor: surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    _buildHero(),
const SizedBox(height: 14),
                    _buildTabSwitcher(),
                    const SizedBox(height: 16),
                    if (selectedTab == 0) _buildLegalitas(),
                    if (selectedTab == 1) _buildNetwork(),
                    if (selectedTab == 2) _buildCustomerCare(),
                    const SizedBox(height: 16),
                    _buildRiskNotice(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildHeader() {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: const BoxDecoration(
      color: Colors.white,
    ),
    child: Row(
      children: [
        IconButton(
  onPressed: () {
    Navigator.pop(context);
  },
  icon: const Icon(
  Icons.arrow_back,
  size: 24,
  color: Color(0xFF1F2937),
),
  tooltip: 'Kembali',
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(
    minWidth: 36,
    minHeight: 40,
  ),
),
const SizedBox(width: 4),
        // LOGO PERUSAHAAN
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo_perusahaan.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.trending_up,
                color: Color(0xFFD96812),
              );
            },
          ),
        ),

        const SizedBox(width: 10),

        // NAMA DAN SUBTITLE
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'EQUITY ',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    TextSpan(
                      text: 'PULSE',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF58220),
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const Text(
                'MARKET INTELLIGENCE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // NOTIFIKASI
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
            color: Color(0xFF1F2937),
          ),
        ),

        // PROFIL
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFF3E8),
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD96812),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text(
          'EWF HUB',
          style: TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Icon(
            Icons.chevron_right,
            size: 15,
            color: Color(0xFF817563),
          ),
        ),
        Text(
          'Profil Institusi',
          style: TextStyle(
            color: primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Pialang Resmi BAPPEBTI',
                style: TextStyle(
                  color: tertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


Widget _buildHero() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    decoration: BoxDecoration(
  color: const Color(0xFFF58220),
  borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: CustomPaint(
      painter: _HeroPatternPainter(primary: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PT Equityworld Futures',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _tabButton(
            index: 0,
            icon: Icons.shield_outlined,
            title: 'Legalitas',
          ),
          _tabButton(
            index: 1,
            icon: Icons.location_city_outlined,
            title: 'Jaringan Cabang',
          ),
          _tabButton(
            index: 2,
            icon: Icons.support_agent,
            title: 'Layanan Care',
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool active = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: active ? primary : textSecondary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? textPrimary : textSecondary,
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegalitas() {
    return Column(
      children: [
        _sectionCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(Icons.account_balance),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tentang EWF',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'PT Equityworld Futures (EWF) merupakan perusahaan '
                          'pialang berjangka resmi di Indonesia yang terdaftar '
                          'dan diawasi oleh Badan Pengawas Perdagangan Berjangka '
                          'Komoditi (BAPPEBTI), anggota Bursa Berjangka Jakarta '
                          '(BBJ), dan anggota PT Kliring Berjangka Indonesia (Persero).',
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: surfaceLow,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    _metric(
                      'Pengawasan',
                      'BAPPEBTI',
                    ),
                    _metric(
                      'Bursa Mitra',
                      'BBJ / JFX',
                    ),
                    _metric(
                      'Penjaminan',
                      'KBI (Persero)',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: primary,
              size: 19,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Legalitas & Registrasi Bursa',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: tertiary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'Aktif & Terverifikasi',
                style: TextStyle(
                  color: tertiary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _legalCard(
          icon: Icons.policy_outlined,
          title: 'BAPPEBTI',
          badge: 'Regulator',
          description: 'Izin Operasional Pialang Berjangka',
          registration: '988/BAPPEBTI/SI/9/2006',
          regulator: 'BAPPEBTI',
        ),
        const SizedBox(height: 9),
        _legalCard(
          icon: Icons.candlestick_chart_outlined,
          title: 'BBJ / JFX',
          badge: 'Bursa',
          description: 'Anggota Bursa Berjangka Jakarta',
          registration: 'SPAB-044/BBJ/03/02',
          regulator: 'BBJ',
        ),
        const SizedBox(height: 9),
        _legalCard(
          icon: Icons.assured_workload_outlined,
          title: 'PT KBI (Persero)',
          badge: 'Kliring BUMN',
          description: 'Penjamin Transaksi & Kliring Finansial',
          registration: '36/AK-KBI/IX/2006',
          regulator: 'KBI',
        ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legalCard({
    required IconData icon,
    required String title,
    required String badge,
    required String description,
    required String registration,
    required String regulator,
  }) {
    return _sectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _smallIconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'No: ',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 9,
                      ),
                    ),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceLow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          registration,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showLegalitas(regulator),
            style: IconButton.styleFrom(
              backgroundColor: surfaceLow,
              foregroundColor: primary,
            ),
            icon: const Icon(
              Icons.open_in_new,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetwork() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.domain_outlined,
              color: primary,
              size: 19,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kantor Pusat (Head Office)',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Jakarta Pusat',
              style: TextStyle(
                color: textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(
              Icons.share_location_outlined,
              color: primary,
              size: 19,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kantor Cabang Resmi (5 Kota)',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'Nasional',
              style: TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _branchCard(
          icon: Icons.apartment_outlined,
          title: 'Cabang Jakarta Cyber 2',
          address:
              'Cyber 2 Tower Lt. 19, Jl. H.R. Rasuna Said, Kuningan',
          phone: '(021) 2902-1555',
          phoneRaw: '02129021555',
        ),
        const SizedBox(height: 9),
        _branchCard(
          icon: Icons.location_city_outlined,
          title: 'Cabang Surabaya',
          address: 'Trillium Office Lt. 2, Jl. Pemuda No. 108-116',
          phone: '(031) 6000-3688',
          phoneRaw: '03160003688',
        ),
        const SizedBox(height: 9),
        _branchCard(
          icon: Icons.store_outlined,
          title: 'Cabang Semarang',
          address:
              'Ruko Peterongan Plaza Blok A No. 10, Jl. MT Haryono',
          phone: '(024) 845-6677',
          phoneRaw: '0248456677',
        ),
        const SizedBox(height: 9),
        _branchCard(
          icon: Icons.business_outlined,
          title: 'Cabang Medan',
          address:
              'B&G Tower Lt. 8, Jl. Putri Hijau No. 10, Kesawan',
          phone: '(061) 457-8900',
          phoneRaw: '0614578900',
        ),
        const SizedBox(height: 9),
        _branchCard(
          icon: Icons.domain_verification_outlined,
          title: 'Cabang Manado',
          address:
              'Komp. Mega Mas Blok 1D No. 22-23, Jl. Piere Tendean',
          phone: '(0431) 882-1666',
          phoneRaw: '04318821666',
        ),
      ],
    );
  }

  Widget _headOfficeCard() {
    return _sectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF213145),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BuildingPainter(
                      primary: primary,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF213145).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Pusat Operasional EWF',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tertiary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Open 08:30 - 17:30',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sahid Sudirman Center',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Lt. 9, Jl. Jend. Sudirman No. 86, Jakarta Pusat 10220',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: surfaceLow,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.call,
                          color: primary,
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Telepon Hunting Resmi',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '(021) 2788-9280',
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _callNumber('02127889280');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Panggil',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.phone_forwarded,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _branchCard({
    required IconData icon,
    required String title,
    required String address,
    required String phone,
    required String phoneRaw,
  }) {
    return _sectionCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          _smallIconBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Telp: $phone',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _callNumber(phoneRaw),
            style: IconButton.styleFrom(
              backgroundColor: surfaceLow,
              foregroundColor: primary,
            ),
            icon: const Icon(
              Icons.phone,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCare() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.contact_support_outlined,
              color: primary,
              size: 19,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Customer Care & Layanan Internal',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '24/5 Trading Desk',
              style: TextStyle(
                color: textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _contactCard(
          icon: Icons.headset_mic_outlined,
          title: 'Hotline Layanan Pelanggan',
          value: '0800-1-393-888',
          subtitle: 'Bebas Pulsa Nasional (Toll Free)',
          buttonText: 'Hubungi',
          onPressed: () {
            _callNumber('08001393888');
          },
        ),
        const SizedBox(height: 10),
        _contactCard(
          icon: Icons.alternate_email,
          title: 'Email Resmi & Verifikasi',
          value: 'care@equityworld-futures.com',
          subtitle: 'Respon maksimal 1 jam kerja',
          buttonText: 'Kirim Email',
          onPressed: () {
            _sendEmail('care@equityworld-futures.com');
          },
        ),
        const SizedBox(height: 10),
        _operationalHours(),
      ],
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return _sectionCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: tertiary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: surfaceLow,
              foregroundColor: primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _operationalHours() {
    return _sectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: primary,
                size: 20,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Jam Operasional Layanan Finansial',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _operationRow(
            dotColor: tertiary,
            title: 'Layanan Administrasi & Kantor',
            value: 'Senin - Jumat: 08.30 - 17.30 WIB',
          ),
          const SizedBox(height: 8),
          _operationRow(
            dotColor: primary,
            title: 'Sistem Transaksi Pasar Emas (Gold Desk)',
            value: '24 Jam (Senin 06.00 - Sabtu 04.00)',
          ),
          const SizedBox(height: 8),
          _operationRow(
            dotColor: const Color(0xFF565E74),
            title: 'Layanan Penarikan Dana (Withdrawal)',
            value: 'Hari Kerja: Sesuai Cut-off Kliring',
          ),
        ],
      ),
    );
  }

  Widget _operationRow({
    required Color dotColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: textPrimary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemberitahuan Risiko & Regulasi',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Perdagangan Berjangka memiliki risiko finansial dan peluang '
                  'imbal hasil yang tinggi. Pastikan seluruh transaksi dan '
                  'konfirmasi akun resmi hanya disalurkan melalui rekening '
                  'terpisah (Segregated Account) PT Equityworld Futures yang '
                  'terdaftar pada BAPPEBTI & PT KBI.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 9,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFDCE9FF),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 23,
      ),
    );
  }

  Widget _smallIconBox(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        icon,
        color: primary,
        size: 21,
      ),
    );
  }
}

class _HeroPatternPainter extends CustomPainter {
  final Color primary;

  _HeroPatternPainter({
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = primary.withValues(alpha: 0.20);

    for (int i = 0; i < 7; i++) {
      final x = size.width * (0.12 + i * 0.14);

      canvas.drawLine(
        Offset(x, size.height * 0.05),
        Offset(x + size.width * 0.08, size.height),
        paint,
      );
    }

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      size.height * 0.28,
      fillPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.91, size.height * 0.58),
      size.height * 0.18,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeroPatternPainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}

class _BuildingPainter extends CustomPainter {
  final Color primary;

  _BuildingPainter({
    required this.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final buildingPaint = Paint()
      ..color = const Color(0xFF31445D)
      ..style = PaintingStyle.fill;

    final windowPaint = Paint()
      ..color = primary.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = const Color(0xFF162538)
      ..style = PaintingStyle.fill;

    final buildingWidth = size.width * 0.58;
    final buildingLeft = size.width * 0.20;

    canvas.drawRect(
      Rect.fromLTWH(
        buildingLeft,
        size.height * 0.10,
        buildingWidth,
        size.height * 0.90,
      ),
      buildingPaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        size.height * 0.73,
        size.width,
        size.height * 0.27,
      ),
      darkPaint,
    );

    for (int row = 0; row < 6; row++) {
      for (int col = 0; col < 7; col++) {
        final x =
            buildingLeft + 12 + col * ((buildingWidth - 24) / 7);
        final y = size.height * 0.17 + row * 14;

        canvas.drawRect(
          Rect.fromLTWH(
            x,
            y,
            11,
            7,
          ),
          windowPaint,
        );
      }
    }

    final sidePaint = Paint()
      ..color = const Color(0xFF465A73)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.80,
        size.height * 0.22,
        size.width * 0.14,
        size.height * 0.58,
      ),
      sidePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BuildingPainter oldDelegate) {
    return oldDelegate.primary != primary;
  }
}