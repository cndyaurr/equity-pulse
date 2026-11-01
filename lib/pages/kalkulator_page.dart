import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'berita_page.dart';
import 'harga_emas_page.dart';
import 'pivot_point_page.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'dashboard_page.dart';

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});

  @override
  State<KalkulatorPage> createState() => _KalkulatorPageState();
}

class _KalkulatorPageState extends State<KalkulatorPage> {
  static const Color _white = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _primary = Color(0xFFF58220);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _surfaceContainer = Color(0xFFFFE5CC);
  static const double tozFixed = 31.10;

  int selectedTab = 0;
  bool _showHistory = false;
  final List<Map<String, dynamic>> _calculationHistory = [];

  final TextEditingController digitalBeliController = TextEditingController(
    text: '1450000',
  );
  final TextEditingController digitalJualController = TextEditingController(
    text: '1465000',
  );
  final TextEditingController digitalLotController = TextEditingController(
    text: '5',
  );

  double digitalSelisih = 0;
  double digitalKotor = 0;
  double digitalFee = 0;
  double digitalPajak = 0;
  double digitalNet = 0;
  double digitalNetPercentage = 0;

  final TextEditingController fisikKursController = TextEditingController(
    text: '16250',
  );
  final TextEditingController fisikModalController = TextEditingController(
    text: '100000000',
  );
  final TextEditingController fisikBeliController = TextEditingController(
    text: '2380',
  );
  final TextEditingController fisikJualController = TextEditingController(
    text: '2410',
  );

  double fisikBeliPerGram = 0;
  double fisikJualPerGram = 0;
  double fisikSelisihPerGram = 0;
  double fisikJumlahGram = 0;
  double fisikCuan = 0;
  double fisikTotalNilai = 0;
  double fisikRoi = 0;

  @override
  void initState() {
    super.initState();

    digitalBeliController.addListener(calculateDigital);
    digitalJualController.addListener(calculateDigital);
    digitalLotController.addListener(calculateDigital);

    fisikKursController.addListener(calculateFisik);
    fisikModalController.addListener(calculateFisik);
    fisikBeliController.addListener(calculateFisik);
    fisikJualController.addListener(calculateFisik);

    calculateDigital();
    calculateFisik();
  }

  @override
  void dispose() {
    digitalBeliController.dispose();
    digitalJualController.dispose();
    digitalLotController.dispose();
    fisikKursController.dispose();
    fisikModalController.dispose();
    fisikBeliController.dispose();
    fisikJualController.dispose();
    super.dispose();
  }

  double parseNumber(String value) {
    return double.tryParse(value.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  String formatRupiah(double value) {
    final rounded = value.round();
    final negative = rounded < 0;
    final number = rounded.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(number[i]);
    }

    return 'Rp ${negative ? '-' : ''}${buffer.toString()}';
  }

  String formatNumber(double value) {
    final number = value.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      if (i > 0 && (number.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(number[i]);
    }

    return buffer.toString();
  }

  void calculateDigital() {
    final beli = parseNumber(digitalBeliController.text);
    final jual = parseNumber(digitalJualController.text);
    final lot = parseNumber(digitalLotController.text);

    final selisih = jual - beli;
    final kotor = lot * selisih * 10000000;
    final fee = 300000 * lot;
    final pajak = 0.11 * fee;
    final net = kotor - fee - pajak;

    double percentage = 0;
    if (kotor > 0) {
      percentage = (net / kotor) * 100;
    }

    if (!mounted) return;

    setState(() {
      digitalSelisih = selisih;
      digitalKotor = kotor;
      digitalFee = fee;
      digitalPajak = pajak;
      digitalNet = net;
      digitalNetPercentage = percentage;
    });
  }

  void calculateFisik() {
    final kurs = parseNumber(fisikKursController.text);
    final modal = parseNumber(fisikModalController.text);
    final beliUsd = parseNumber(fisikBeliController.text);
    final jualUsd = parseNumber(fisikJualController.text);

    final beliPerGram = (beliUsd * kurs) / tozFixed;
    final jualPerGram = (jualUsd * kurs) / tozFixed;
    final selisihGram = jualPerGram - beliPerGram;

    double jumlahGram = 0;
    if (beliPerGram > 0) {
      jumlahGram = modal / beliPerGram;
    }

    final cuan = selisihGram * jumlahGram;
    final totalNilaiJual = modal + cuan;

    double roi = 0;
    if (modal > 0) {
      roi = (cuan / modal) * 100;
    }

    if (!mounted) return;

    setState(() {
      fisikBeliPerGram = beliPerGram;
      fisikJualPerGram = jualPerGram;
      fisikSelisihPerGram = selisihGram;
      fisikJumlahGram = jumlahGram;
      fisikCuan = cuan;
      fisikTotalNilai = totalNilaiJual;
      fisikRoi = roi;
    });
  }

  void resetCalculator() {
    digitalBeliController.text = '1450000';
    digitalJualController.text = '1465000';
    digitalLotController.text = '5';

    fisikKursController.text = '16250';
    fisikModalController.text = '100000000';
    fisikBeliController.text = '2380';
    fisikJualController.text = '2410';

    calculateDigital();
    calculateFisik();
  }

  void setDigitalLot(int value) {
    digitalLotController.text = value.toString();
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final items = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Dashboard'),
      (
        icon: Icons.newspaper_outlined,
        activeIcon: Icons.newspaper,
        label: 'Berita',
      ),
      (icon: Icons.show_chart, activeIcon: Icons.show_chart, label: 'Data'),
      (
        icon: Icons.table_chart_outlined,
        activeIcon: Icons.table_chart,
        label: 'Pivot',
      ),
      (
        icon: Icons.calculate_outlined,
        activeIcon: Icons.calculate,
        label: 'Kalkulator',
      ),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              final active = index == 4;

              return SizedBox(
                width: 82,
                child: InkWell(
                  onTap: () {
                    switch (index) {
                      case 0:
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                        break;

                      case 1:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const BeritaPage()),
                        );
                        break;

                      case 2:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HargaEmasPage(),
                          ),
                        );
                        break;

                      case 3:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PivotPointPage(),
                          ),
                        );
                        break;

                      case 4:
                        // Sudah berada di halaman Kalkulator.
                        break;
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? items[index].activeIcon : items[index].icon,
                        size: 27,
                        color: active
                            ? const Color(0xFFF58220)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].label,
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? const Color(0xFFF58220)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PivotPointPage()),
        );
      },
      child: Theme(
        data: baseTheme.copyWith(
          textTheme: GoogleFonts.robotoTextTheme(baseTheme.textTheme),
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalkulator',
                          style: GoogleFonts.roboto(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildTabs(),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: selectedTab == 0
                              ? _buildDigitalSection()
                              : _buildFisikSection(),
                        ),
                        const SizedBox(height: 16),
                        _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigation(context),
        ),
      ),
    );
  }

  // HEADER: disamakan dengan Dashboard.

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: _white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'EQUITY ',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: 'PULSE',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'MARKET INTELLIGENCE',
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary,
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
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_none, color: _textPrimary),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _surfaceContainer,
              child: Text(
                'A',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EDF2),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Expanded(
          child: _calcTab(
            index: 0,
            icon: Icons.currency_bitcoin,
            title: 'Emas Digital',
          ),
        ),
        Expanded(
          child: _calcTab(
            index: 1,
            icon: Icons.edit_note,
            title: 'Emas Fisik',
          ),
        ),
      ],
    ),
  );
}

  
Widget _calcTab({
  required int index,
  required IconData icon,
  required String title,
}) {
  final selected = selectedTab == index;

  return GestureDetector(
    onTap: () => setState(() => selectedTab = index),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFF58220)
            : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(9),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFFF58220)
                      .withValues(alpha: 0.10),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected
                ? Colors.white
                : const Color(0xFF475569),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : const Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildDigitalSection() {
    return Column(
      key: const ValueKey('digital'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDigitalParameters(),
        const SizedBox(height: 12),
        _buildDigitalResultCards(),
        const SizedBox(height: 12),
        _buildDigitalNetCard(),
        const SizedBox(height: 12),
        _buildDigitalFormula(),
      ],
    );
  }

  Widget _buildDigitalParameters() {
  return _sectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Parameter Transaksi',
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5CC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '1 Lot = Rp10.000.000',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD96812),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _calculatorInput(
          label: 'Harga Beli / Unit',
          prefix: 'Rp',
          controller: digitalBeliController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),

        _calculatorInput(
          label: 'Harga Jual / Unit',
          prefix: 'Rp',
          controller: digitalJualController,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _calculatorInput(
                label: 'Volume Kontrak',
                suffix: 'Lot',
                controller: digitalLotController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF58220).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${parseNumber(digitalLotController.text).round()} Lot',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF58220),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Text(
              'Preset Lot:',
              style: GoogleFonts.roboto(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [1, 2, 5, 10, 20].map((lot) {
                    final selected =
                        parseNumber(digitalLotController.text).round() == lot;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => setDigitalLot(lot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFF58220)
                                : const Color(0xFFFFF3E8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$lot Lot',
                            style: GoogleFonts.roboto(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildDigitalResultCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.32,
      children: [
        _resultCard(
          title: 'Spread / Selisih',
          value: formatRupiah(digitalSelisih),
          subtitle: 'Jual - Beli',
          icon: Icons.trending_up,
          iconColor: const Color(0xFF006947),
        ),
        _resultCard(
          title: 'Hasil Kotor',
          value: formatRupiah(digitalKotor),
          subtitle: 'Lot × Selisih × 1jt',
          icon: Icons.pie_chart_outline,
          iconColor: const Color(0xFFF58220),
        ),
        _resultCard(
          title: 'Broker Fee',
          value: formatRupiah(digitalFee),
          subtitle: 'Rp 300.000 / Lot',
          icon: Icons.receipt_long,
          iconColor: const Color(0xFF565E74),
          valueColor: const Color(0xFFBA1A1A),
        ),
        _resultCard(
          title: 'Pajak (PPN 11%)',
          value: formatRupiah(digitalPajak),
          subtitle: '11% × Total Fee',
          icon: Icons.account_balance,
          iconColor: const Color(0xFF565E74),
          valueColor: const Color(0xFFBA1A1A),
        ),
      ],
    );
  }

  Widget _buildDigitalNetCard() {
    final positive = digitalNet >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCC4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            bottom: -35,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF58220).withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: positive
                          ? const Color(0xFF4EDEA3)
                          : const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'HASIL AKHIR BERSIH (NET PROFIT)',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: const Color(0xFFD96812),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F7EF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${digitalNetPercentage >= 0 ? '+' : ''}${digitalNetPercentage.toStringAsFixed(2)}% Net',
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF00866A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                formatRupiah(digitalNet),
                style: GoogleFonts.roboto(
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Setelah dikurangi Beban Fee & PPN',
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kotor: ${formatRupiah(digitalKotor)}',
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Text(
                    'Potongan: -${formatRupiah(digitalFee + digitalPajak)}',
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      color: const Color(0xFFFF8A8A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: digitalKotor > 0
                          ? digitalNet.clamp(0, digitalKotor).round()
                          : 1,
                      child: Container(
                        height: 7,
                        color: const Color(0xFF00866A),
                      ),
                    ),
                    Expanded(
                      flex: digitalKotor > 0
                          ? (digitalKotor - digitalNet)
                                .clamp(0, digitalKotor)
                                .round()
                          : 1,
                      child: Container(
                        height: 7,
                        color: const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalFormula() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 18,
                color: Color(0xFFF58220),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Formula Standardisasi Digital (BBJ / ICDX)',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _formulaRow('1. Selisih Point', 'Harga Jual − Harga Beli'),
          const SizedBox(height: 5),
          _formulaRow('2. Gross Revenue', 'Lot × Selisih × Rp 10.000.000'),
          const SizedBox(height: 5),
          _formulaRow(
            '3. Total Biaya Operasional',
            'Fee (Rp300k/Lot) + PPN (11%)',
          ),
        ],
      ),
    );
  }

  Widget _buildFisikSection() {
    return Column(
      key: const ValueKey('fisik'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTozNotice(),
        const SizedBox(height: 12),
        _buildFisikParameters(),
        const SizedBox(height: 12),
        _buildFisikResultCards(),
        const SizedBox(height: 12),
        _buildFisikNetCard(),
        const SizedBox(height: 12),
        _buildFisikFootnote(),
      ],
    );
  }

  Widget _buildTozNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF58220).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFFF58220), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standar Bobot Tetap',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Troy Ounce Internasional (Non-Editable)',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '31.10 Gram',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF58220),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFisikParameters() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Parameter Pembelian Fisik',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00855B).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'USD/IDR Live Basis',
                  style: GoogleFonts.roboto(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF006947),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _calculatorInput(
            label: 'Kurs Tukar Dollar (USD/IDR)',
            prefix: 'Rp',
            controller: fisikKursController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _calculatorInput(
            label: 'Modal Alokasi Tunai',
            prefix: 'Rp',
            controller: fisikModalController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          _calculatorInput(
            label: 'Harga Beli Spot (USD / oz)',
            prefix: '\$',
            controller: fisikBeliController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          _calculatorInput(
            label: 'Harga Jual Spot (USD / oz)',
            prefix: '\$',
            controller: fisikJualController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }

  Widget _buildFisikResultCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.28,
      children: [
        _resultCard(
          title: 'Beli / Gram',
          value: formatRupiah(fisikBeliPerGram),
          subtitle: '(USD × Kurs) / 31.1',
          icon: Icons.sell_outlined,
          iconColor: const Color(0xFF475569),
        ),
        _resultCard(
          title: 'Jual / Gram',
          value: formatRupiah(fisikJualPerGram),
          subtitle: '(USD × Kurs) / 31.1',
          icon: Icons.shopping_cart_outlined,
          iconColor: const Color(0xFF475569),
        ),
        _resultCard(
          title: 'Selisih / Gram',
          value:
              '${fisikSelisihPerGram >= 0 ? '+' : '-'}${formatRupiah(fisikSelisihPerGram.abs())}',
          subtitle: 'Margin Kotor Fisik',
          icon: Icons.trending_up,
          iconColor: const Color(0xFF006947),
          valueColor: const Color(0xFF006947),
        ),
        _resultCard(
          title: 'Total Gram Didapat',
          value: '${fisikJumlahGram.toStringAsFixed(2)} gr',
          subtitle: 'Modal / Beli Gram',
          icon: Icons.scale_outlined,
          iconColor: const Color(0xFFF58220),
          valueColor: const Color(0xFFF58220),
        ),
      ],
    );
  }


Widget _buildFisikNetCard() {
  final positive = fisikCuan >= 0;

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0DCC4)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -35,
          bottom: -35,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF58220).withValues(alpha: 0.06),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: positive
                        ? const Color(0xFF4EDEA3)
                        : const Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HASIL AKHIR BERSIH (NET PROFIT)',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: const Color(0xFFD96812),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F7EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${fisikRoi >= 0 ? '+' : ''}${fisikRoi.toStringAsFixed(2)}% ROI',
                    style: GoogleFonts.roboto(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00866A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatRupiah(fisikCuan),
              style: GoogleFonts.roboto(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Selisih/Gram × Bobot Didapat',
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.scale,
                    size: 16,
                    color: Color(0xFFD96812),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Valuasi Penjualan Fisik:',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                  Text(
                    formatRupiah(fisikTotalNilai),
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _buildFisikFootnote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.help_outline, size: 20, color: Color(0xFF475569)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan Konversi Fisik',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Perhitungan mengasumsikan transaksi bullion murni '
                  '24 Karat (99.99%). Standar satuan troy ounce (oz) '
                  'konstan di 31.1035 gram. Biaya cetak & sertifikasi '
                  '(Antam/UBS) tidak diperhitungkan.',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    height: 1.45,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _calculatorInput({
    required String label,
    required TextEditingController controller,
    String? prefix,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E8),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    prefix,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Masukkan nilai',
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 11,
                      color: const Color(0xFF817563),
                    ),
                    contentPadding: EdgeInsets.only(
                      left: prefix == null ? 12 : 8,
                      right: suffix == null ? 12 : 8,
                      top: 11,
                      bottom: 11,
                    ),
                  ),
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    suffix,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              fontSize: 8,
              color: const Color(0xFF817563),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formulaRow(String title, String formula) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 10,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              formula,
              textAlign: TextAlign.right,
              style: GoogleFonts.roboto(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // HISTORI PERHITUNGAN

  void _saveCalculationToHistory() {
    final now = DateTime.now();
    final Map<String, dynamic> item;

    if (selectedTab == 0) {
      item = {
        'type': 'Emas Digital',
        'date': now,
        'details':
            'Beli ${formatRupiah(parseNumber(digitalBeliController.text))} • '
            'Jual ${formatRupiah(parseNumber(digitalJualController.text))} • '
            'Lot ${digitalLotController.text}',
        'result': formatRupiah(digitalNet),
        'positive': digitalNet >= 0,
      };
    } else {
      item = {
        'type': 'Emas Fisik',
        'date': now,
        'details':
            'Modal ${formatRupiah(parseNumber(fisikModalController.text))} • '
            'Kurs ${formatNumber(parseNumber(fisikKursController.text))} • '
            'ROI ${fisikRoi.toStringAsFixed(2)}%',
        'result': formatRupiah(fisikCuan),
        'positive': fisikCuan >= 0,
      };
    }

    setState(() {
      _calculationHistory.insert(0, item);
      _showHistory = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Perhitungan ditambahkan ke histori sesi ini.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE5CC)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _showHistory = !_showHistory),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC58A).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      color: Color(0xFFF58220),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histori Perhitungan',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_calculationHistory.length} perhitungan di sesi ini',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showHistory
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (_showHistory) ...[
            const Divider(height: 1, color: Color(0xFFFFE5CC)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveCalculationToHistory,
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                      label: const Text('Simpan Perhitungan Saat Ini'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_calculationHistory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 34,
                            color: Colors.blueGrey.shade200,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada histori perhitungan',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tekan tombol di atas untuk menyimpan hasil.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._calculationHistory.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final date = item['date'] as DateTime;
                      final dateText =
                          '${date.day.toString().padLeft(2, '0')}/'
                          '${date.month.toString().padLeft(2, '0')}/${date.year} '
                          '${date.hour.toString().padLeft(2, '0')}:'
                          '${date.minute.toString().padLeft(2, '0')}';
                      final isPositive = item['positive'] as bool;

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFE5CC)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFC58A,
                                ).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item['type'] == 'Emas Digital'
                                    ? Icons.show_chart_rounded
                                    : Icons.savings_outlined,
                                color: const Color(0xFFF58220),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['type'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    dateText,
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item['details'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item['result'] as String,
                                    style: GoogleFonts.roboto(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isPositive
                                          ? const Color(0xFF087443)
                                          : const Color(0xFFB42318),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus histori',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                () => _calculationHistory.removeAt(index),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      );
                    }),
                  if (_calculationHistory.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () =>
                            setState(() => _calculationHistory.clear()),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Hapus semua'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB42318),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
