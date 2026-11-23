import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class KalkulatorPage extends StatefulWidget {
  const KalkulatorPage({super.key});

  @override
  State<KalkulatorPage> createState() => _KalkulatorPageState();
}

class _KalkulatorPageState extends State<KalkulatorPage> {
  static const Color _white = Colors.white;
  static const Color _textPrimary = Color(0xFF1F2937);

  static const Color _textSecondary = Color(0xFF64748B);
  static const double tozFixed = 31.10;
  static const String _historyKey = 'calculation_history';

  Future<void> _loadCalculationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getString(_historyKey);

    if (savedHistory == null) return;

    final List<dynamic> decoded = jsonDecode(savedHistory);

    if (!mounted) return;

    setState(() {
      _calculationHistory
        ..clear()
        ..addAll(
          decoded.map((item) {
            final map = Map<String, dynamic>.from(item);
            map['date'] = DateTime.parse(map['date'] as String);
            return map;
          }),
        );
    });
  }
String _formatRupiahRate(double rate) {
  return NumberFormat('#,##0.00', 'id_ID').format(rate);
}
  Future<void> _persistCalculationHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _calculationHistory.map((item) {
      return {...item, 'date': (item['date'] as DateTime).toIso8601String()};
    }).toList();

    await prefs.setString(_historyKey, jsonEncode(data));
  }

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

  // Penyimpanan kurs USD/IDR otomatis
  static const String _rateCacheKey = 'usd_idr_rate';
static const String _rateDateCacheKey = 'usd_idr_date';

  bool _isLoadingRate = false;
  String _rateStatus = 'Menyiapkan kurs USD/IDR...';
  String? _rateLastUpdatedText;
  final TextEditingController fisikKursController =
    TextEditingController(text: '16250');

final TextEditingController fisikModalController =
    TextEditingController();

final TextEditingController fisikBeliController =
    TextEditingController();

final TextEditingController fisikJualController =
    TextEditingController();

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
    _loadCalculationHistory();

    // Mengambil kurs USD/IDR secara otomatis
    _loadUsdIdrRate();

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
  final normalized = value
      .trim()
      .replaceAll('.', '')
      .replaceAll(',', '.');

  return double.tryParse(normalized) ?? 0;
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



Future<void> _loadUsdIdrRate() async {
  if (!mounted) return;

  setState(() {
    _isLoadingRate = true;
    _rateStatus = 'Memeriksa kurs JISDOR terbaru...';
  });

  final prefs = await SharedPreferences.getInstance();

  // Ambil kurs dan tanggal yang pernah tersimpan.
  final cachedRate = prefs.getDouble(_rateCacheKey);
  final cachedDate = prefs.getString(_rateDateCacheKey);

  // Tampilkan kurs tersimpan terlebih dahulu.
  if (cachedRate != null && cachedRate > 0) {
    fisikKursController.text = _formatRupiahRate(cachedRate);
    calculateFisik();

    if (mounted) {
      setState(() {
        _rateLastUpdatedText = cachedDate;
        _rateStatus = 'Menggunakan kurs tersimpan';
      });
    }
  }

  try {
    final response = await http
        .get(
          Uri.parse('http://127.0.0.1:8000/api/kurs/jisdor'),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data JISDOR');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (data['success'] != true) {
      throw Exception('API JISDOR tidak berhasil');
    }

    final rate = (data['rate'] as num?)?.toDouble();
    final date = data['date']?.toString();

    if (rate == null || rate <= 0 || date == null || date.isEmpty) {
      throw Exception('Data kurs JISDOR tidak valid');
    }

    // Masukkan kurs terbaru ke kalkulator.
    fisikKursController.text = _formatRupiahRate(rate);

    // Hitung ulang hasil kalkulator.
    calculateFisik();

    // Simpan kurs dan tanggal JISDOR.
    await prefs.setDouble(_rateCacheKey, rate);
    await prefs.setString(_rateDateCacheKey, date);

    if (!mounted) return;

    setState(() {
      _rateLastUpdatedText = date;
      _rateStatus = 'Kurs JISDOR berhasil diperbarui';
      _isLoadingRate = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isLoadingRate = false;

      _rateStatus = cachedRate != null
          ? 'Koneksi gagal. Menggunakan kurs JISDOR tersimpan.'
          : 'Gagal mengambil kurs JISDOR. Periksa koneksi.';
    });
  }
}


  Widget _buildRateStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoadingRate)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFFF58220),
              ),
            )
          else
            const Icon(
              Icons.check_circle_outline,
              size: 13,
              color: Color(0xFF00855B),
            ),

          const SizedBox(width: 6),

          Expanded(
            child: Text(
              '$_rateStatus${_rateLastUpdatedText == null ? '' : ' • Update: $_rateLastUpdatedText'}\n'
            'Sumber: Bank Indonesia - JISDOR (USD/IDR)',
              style: GoogleFonts.roboto(
                fontSize: 9,
                height: 1.4,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          TextButton(
            onPressed: _isLoadingRate ? null : _loadUsdIdrRate,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFFF58220),
            ),
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
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

  fisikModalController.clear();
  fisikBeliController.clear();
  fisikJualController.clear();

  _loadUsdIdrRate();

  calculateDigital();
  calculateFisik();
}

Future<void> _exportCalculationPdf() async {
  try {
    // PDF hanya memuat jenis kalkulator yang sedang dibuka.
    final isDigital = selectedTab == 0;
    final reportType = isDigital ? 'Emas Digital' : 'Emas Fisik';

    final now = DateTime.now();

    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    // Memuat logo EQUICKLY untuk header dan watermark.
    final logoData = await rootBundle.load(
      'assets/images/logo_perusahaan.png',
    );

    final logoImage = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    final pdf = pw.Document();

    final orange = PdfColor.fromHex('#F58220');
    final dark = PdfColor.fromHex('#1F2937');
    final grey = PdfColor.fromHex('#64748B');
    final lightOrange = PdfColor.fromHex('#FFF3E8');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    // Membuat baris informasi PDF.
    pw.Widget infoRow(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(
              color: borderColor,
              width: 0.5,
            ),
          ),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: grey,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 5,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: dark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Judul setiap bagian laporan.
    pw.Widget sectionTitle(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: pw.BoxDecoration(
          color: lightOrange,
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: orange,
          ),
        ),
      );
    }

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (context) {
        return pw.Center(
          child: pw.Opacity(
            opacity: 0.10,
            child: pw.Image(
              logoImage,
              width: 280,
              height: 280,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      },
    );

    final kursDate = _rateLastUpdatedText ?? 'Tidak tersedia';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        header: (context) {
          return pw.Column(
            children: [
              pw.Row(
                children: [
                  pw.Image(
                    logoImage,
                    width: 48,
                    height: 48,
                  ),
                  pw.SizedBox(width: 10),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EQUICKLY',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: orange,
                        ),
                      ),
                      pw.Text(
                        'MARKET INTELLIGENCE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: grey,
                        ),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'LAPORAN KALKULATOR',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: orange, thickness: 1.2),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 15),
            child: pw.Column(
              children: [
                pw.Divider(color: borderColor),
                pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'EQUICKLY - MARKET INTELLIGENCE',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: grey,
                      ),
                    ),
                    pw.Text(
                      'Halaman ${context.pageNumber} '
                      'dari ${context.pagesCount}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        build: (context) {
          return [
            // INFORMASI LAPORAN
            pw.Text(
              'LAPORAN HASIL PERHITUNGAN ${reportType.toUpperCase()}',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: dark,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Dokumen hasil simulasi perhitungan $reportType.',
              style: pw.TextStyle(
                fontSize: 9,
                color: grey,
              ),
            ),
            pw.SizedBox(height: 10),
            infoRow(
              'Tanggal laporan',
              DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(now),
            ),
            infoRow('Jenis laporan', reportType),
            pw.SizedBox(height: 18),

            // =================================================
            // EMAS DIGITAL
            // =================================================
            if (isDigital) ...[
            sectionTitle('PERHITUNGAN EMAS DIGITAL'),
            pw.SizedBox(height: 8),

            infoRow(
              'Harga beli per unit',
              formatRupiah(parseNumber(digitalBeliController.text)),
            ),
            infoRow(
              'Harga jual per unit',
              formatRupiah(parseNumber(digitalJualController.text)),
            ),
            infoRow(
              'Volume kontrak',
              '${parseNumber(digitalLotController.text)} Lot',
            ),
            infoRow(
              'Selisih harga',
              formatRupiah(digitalSelisih),
            ),
            infoRow(
              'Hasil kotor',
              formatRupiah(digitalKotor),
            ),
            infoRow(
              'Broker fee',
              formatRupiah(digitalFee),
            ),
            infoRow(
              'PPN 11%',
              formatRupiah(digitalPajak),
            ),

            pw.SizedBox(height: 10),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightOrange,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(color: orange),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HASIL AKHIR BERSIH (NET PROFIT)',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    formatRupiah(digitalNet),
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${digitalNetPercentage >= 0 ? '+' : ''}'
                    '${digitalNetPercentage.toStringAsFixed(2)}% Net',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: grey,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),
            pw.Text(
              'Formula Perhitungan Digital',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: dark,
              ),
            ),
            pw.SizedBox(height: 5),
            infoRow(
              'Selisih point',
              'Harga jual - Harga beli',
            ),
            infoRow(
              'Hasil kotor',
              'Lot x Selisih x Rp10.000.000',
            ),
            infoRow(
              'Broker fee',
              'Rp300.000 x Lot',
            ),
            infoRow(
              'PPN',
              '11% x Total Broker Fee',
            ),
            infoRow(
              'Net profit',
              'Hasil kotor - Fee - PPN',
            ),

            pw.SizedBox(height: 20),
            ],

            // =================================================
            // EMAS FISIK
            // =================================================
            if (!isDigital) ...[
            sectionTitle('PERHITUNGAN EMAS FISIK'),
            pw.SizedBox(height: 8),

            infoRow(
              'Kurs USD/IDR',
              'Rp ${_formatRupiahRate(parseNumber(fisikKursController.text))}',
            ),
            infoRow(
              'Tanggal kurs JISDOR',
              kursDate,
            ),
            infoRow(
              'Modal alokasi tunai',
              formatRupiah(parseNumber(fisikModalController.text)),
            ),
            infoRow(
              'Harga beli spot',
              '\$${parseNumber(fisikBeliController.text).toStringAsFixed(2)} / oz',
            ),
            infoRow(
              'Harga jual spot',
              '\$${parseNumber(fisikJualController.text).toStringAsFixed(2)} / oz',
            ),
            infoRow(
              'Standar Troy Ounce',
              '31,10 Gram',
            ),

            pw.SizedBox(height: 8),
            pw.Text(
              'Hasil Konversi dan Perhitungan',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: dark,
              ),
            ),
            pw.SizedBox(height: 5),

            infoRow(
              'Harga beli per gram',
              formatRupiah(fisikBeliPerGram),
            ),
            infoRow(
              'Harga jual per gram',
              formatRupiah(fisikJualPerGram),
            ),
            infoRow(
              'Selisih per gram',
              formatRupiah(fisikSelisihPerGram),
            ),
            infoRow(
              'Total gram diperoleh',
              '${fisikJumlahGram.toStringAsFixed(4)} Gram',
            ),

            pw.SizedBox(height: 10),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightOrange,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(color: orange),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ESTIMASI KEUNTUNGAN (NET PROFIT)',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: orange,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    formatRupiah(fisikCuan),
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    '${fisikRoi >= 0 ? '+' : ''}'
                    '${fisikRoi.toStringAsFixed(2)}% ROI',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: grey,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: orange),
                  infoRow(
                    'Total valuasi penjualan',
                    formatRupiah(fisikTotalNilai),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 8),
            pw.Text(
              'Formula Perhitungan Fisik',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: dark,
              ),
            ),
            pw.SizedBox(height: 5),
            infoRow(
              'Harga beli per gram',
              '(Harga beli USD x Kurs) / 31,10',
            ),
            infoRow(
              'Harga jual per gram',
              '(Harga jual USD x Kurs) / 31,10',
            ),
            infoRow(
              'Jumlah gram',
              'Modal / Harga beli per gram',
            ),
            infoRow(
              'Keuntungan',
              'Selisih per gram x Jumlah gram',
            ),
            infoRow(
              'ROI',
              '(Keuntungan / Modal) x 100%',
            ),

            ],
            pw.SizedBox(height: 18),
            pw.Text(
              'Catatan: Laporan ini merupakan hasil simulasi '
              'berdasarkan parameter yang dimasukkan pada kalkulator. '
              'Nilai hasil perhitungan bukan merupakan jaminan '
              'keuntungan transaksi.',
              style: pw.TextStyle(
                fontSize: 8,
                color: grey,
              ),
            ),
            if (!isDigital) ...[
              pw.SizedBox(height: 5),
              pw.Text(
                'Kurs USD/IDR menggunakan sumber Bank Indonesia - JISDOR. '
                'Tanggal kurs mengikuti tanggal publikasi data yang tersedia.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: grey,
                ),
              ),
            ],
          ];
        },
      ),
    );

    // Simpan PDF sementara lalu buka menu berbagi.
    final directory = await getTemporaryDirectory();

    final file = File(
      '${directory.path}/laporan_kalkulator_${isDigital ? 'digital' : 'fisik'}_$stamp.pdf',
    );

    await file.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    if (!mounted) return;

    await SharePlus.instance.share(
  ShareParams(
    files: [XFile(file.path)],
    text: 'Laporan hasil perhitungan EQUICKLY',
  ),
);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal membuat PDF: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
  void setDigitalLot(int value) {
    digitalLotController.text = value.toString();
  }


  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
Navigator.of(context).pop();
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

Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton.icon(
    onPressed: _exportCalculationPdf,
    icon: const Icon(
      Icons.save_alt_rounded,
      size: 18,
    ),
    label: const Text('Export'),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF58220),
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
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
    automaticallyImplyLeading: false,
    leading: IconButton(
      onPressed: () {
        Navigator.of(context).pop();
      },
      icon: const Icon(
        Icons.arrow_back,
        color: Color(0xFF1F2937),
        size: 24,
      ),
    ),
    titleSpacing: 0,
    centerTitle: true,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EQUICKLY',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFFF9800),
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
            MaterialPageRoute(
              builder: (_) => const NotificationsScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.notifications_none,
          color: _textPrimary,
        ),
      ),
    ],
  );
}

  Widget _buildTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(child: _calcTab(index: 0, title: 'Emas Digital')),
          Expanded(child: _calcTab(index: 1, title: 'Emas Fisik')),
        ],
      ),
    );
  }

  Widget _calcTab({required int index, required String title}) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF58220) : const Color(0xFFFFF3E8),
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF58220).withValues(alpha: 0.10),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
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
                  'Kurs Harian Otomatis',
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
            readOnly: true,
          ),

          _buildRateStatus(),
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
                    const Icon(Icons.scale, size: 16, color: Color(0xFFD96812)),
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
    bool readOnly = false,
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
                  readOnly: readOnly,
                  inputFormatters: [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
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

    _persistCalculationHistory();

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
                        backgroundColor: const Color(0xFFF58220),
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
                              onPressed: () async {
                                setState(() {
                                  _calculationHistory.removeAt(index);
                                });

                                await _persistCalculationHistory();
                              },
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
                        onPressed: () async {
                          setState(() {
                            _calculationHistory.clear();
                          });

                          await _persistCalculationHistory();
                        },
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
