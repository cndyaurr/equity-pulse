import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/gold_price.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';

class HargaEmasPage extends StatefulWidget {
  const HargaEmasPage({super.key});

  @override
  State<HargaEmasPage> createState() => _HargaEmasPageState();
}

class _HargaEmasPageState extends State<HargaEmasPage> {
  // Palet warna standar EWF Gold Hub

  static const Color background = Color(0xFFF8FAFC);
  static const Color primary = Color(0xFFF58220);
  static const Color primaryDark = Color(0xFFD96812);
  static const Color primaryLight = Color(0xFFFFF3E8);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF64748B);

  GoldPrice? lgdPrice;
  GoldPrice? hsiPrice;
  GoldPrice? sniPrice;

  bool isLoadingPrices = false;
  String? priceError;

  Future<void> loadGoldPrices() async {
    setState(() {
      isLoadingPrices = true;
      priceError = null;
    });

    try {
      final prices = await ApiService.getGoldPrices();

      GoldPrice? lgd;
      GoldPrice? hsi;
      GoldPrice? sni;

      for (final item in prices) {
        switch (item.commodity.toUpperCase()) {
          case 'LGD':
            if (lgd == null ||
                (item.recordedAt != null &&
                    lgd.recordedAt != null &&
                    item.recordedAt!.isAfter(lgd.recordedAt!))) {
              lgd = item;
            }
            break;

          case 'HSI':
            if (hsi == null ||
                (item.recordedAt != null &&
                    hsi.recordedAt != null &&
                    item.recordedAt!.isAfter(hsi.recordedAt!))) {
              hsi = item;
            }
            break;

          case 'SNI':
            if (sni == null ||
                (item.recordedAt != null &&
                    sni.recordedAt != null &&
                    item.recordedAt!.isAfter(sni.recordedAt!))) {
              sni = item;
            }
            break;
        }
      }

      if (!mounted) return;

      setState(() {
        _goldPrices = prices;
        lgdPrice = lgd;
        hsiPrice = hsi;
        sniPrice = sni;
        isLoadingPrices = false;

        _currentPage = 1;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingPrices = false;
        priceError = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadGoldPrices();
  }
  // ============================================================
  // STATE
  // ============================================================

  int _selectedAsset = 0;
  int _selectedPeriod = 1;
  int _currentPage = 1;
  bool _isNestInfoExpanded = false;
  DateTime _startDate = DateTime(2026, 9, 24);
  DateTime _endDate = DateTime(2026, 10, 1);

  final List<String> _assets = ['LGD', 'HSI', 'SNI'];

  final List<String> _periods = ['Hari Ini', '7 Hari', '30 Hari', 'Kustom'];

  List<GoldPrice> _goldPrices = [];

  List<GoldPrice> get _selectedPrices {
    String commodity;

    switch (_selectedAsset) {
      case 1:
        commodity = 'HSI';
        break;
      case 2:
        commodity = 'SNI';
        break;
      default:
        commodity = 'LGD';
    }

    final data = _goldPrices
        .where(
          (item) =>
              item.commodity.toUpperCase() == commodity &&
              item.recordedAt != null,
        )
        .toList();

    data.sort((a, b) => a.recordedAt!.compareTo(b.recordedAt!));

    return data;
  }

  List<GoldPrice> get _filteredPrices {
    final all = _selectedPrices;

    if (all.isEmpty) {
      return [];
    }

    switch (_selectedPeriod) {
      case 0:
        final latestDate = all.last.recordedAt!.toLocal();

        return all.where((item) {
          final date = item.recordedAt!.toLocal();

          return date.year == latestDate.year &&
              date.month == latestDate.month &&
              date.day == latestDate.day;
        }).toList();

      case 1:
        final start = all.length > 7 ? all.length - 7 : 0;
        return all.sublist(start);

      case 2:
        final start = all.length > 30 ? all.length - 30 : 0;
        return all.sublist(start);

      case 3:
        final start = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
        );

        final end = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          23,
          59,
          59,
        );

        return all.where((item) {
          final date = item.recordedAt!.toLocal();

          return !date.isBefore(start) && !date.isAfter(end);
        }).toList();

      default:
        return all;
    }
  }

  List<OhlcData> get _ohlcData {
    final data = List<GoldPrice>.from(_filteredPrices);

    data.sort((a, b) => b.recordedAt!.compareTo(a.recordedAt!));

    return data.map((item) {
      final date = item.recordedAt!.toLocal();

      double change = 0;

      if (item.open != null && item.open != 0 && item.close != null) {
        change = ((item.close! - item.open!) / item.open!) * 100;
      }

      return OhlcData(
        date:
            '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}',
        open: item.open ?? item.price,
        high: item.high ?? item.price,
        low: item.low ?? item.price,
        close: item.close ?? item.price,
        change: change,
      );
    }).toList();
  }

  GoldPrice? _latestPriceForCommodity(String commodity) {
    final matches = _goldPrices.where((item) {
      return item.commodity.toUpperCase() == commodity.toUpperCase() &&
          item.recordedAt != null;
    }).toList();

    if (matches.isEmpty) return null;

    matches.sort((a, b) => b.recordedAt!.compareTo(a.recordedAt!));

    return matches.first;
  }

  // ============================================================
  // FORMATTER
  // ============================================================

  String _formatPrice(double value) {
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Pilih tanggal mulai',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
      helpText: 'Pilih tanggal akhir',
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _applyFilter() {
    setState(() {
      _selectedPeriod = 3;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filter diterapkan: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportData() async {
    final data = _ohlcData;

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data untuk diekspor.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      // Memuat logo watermark
      final logoData = await rootBundle.load(
        'assets/images/logo_perusahaan.png',
      );

      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

      // Membuat dokumen PDF
      final pdf = pw.Document();

      final assetName = _assets[_selectedAsset];

      String periodName = _periods[_selectedPeriod];

      if (_selectedPeriod == 3) {
        periodName = '${_formatDate(_startDate)} - ${_formatDate(_endDate)}';
      }

      final now = DateTime.now();

      final stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}';

      // Watermark untuk setiap halaman
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

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pageTheme,
          footer: (context) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(top: 15),
              child: pw.Column(
                children: [
                  pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'EQUICKLY - MARKET INTELLIGENCE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#64748B'),
                        ),
                      ),
                      pw.Text(
                        'Halaman ${context.pageNumber} '
                        'dari ${context.pagesCount}',
                        style: pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromHex('#64748B'),
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
              // HEADER
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(
                    logoImage,
                    width: 55,
                    height: 55,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EQUICKLY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#F58220'),
                        ),
                      ),
                      pw.Text(
                        'MARKET INTELLIGENCE',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromHex('#64748B'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 22),

              // JUDUL
              pw.Center(
                child: pw.Text(
                  'HISTORIS DATA HARGA',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1F2937'),
                  ),
                ),
              ),

              pw.SizedBox(height: 5),

              pw.Center(
                child: pw.Text(
                  'Data Open, High, Low, Close dan Perubahan',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColor.fromHex('#64748B'),
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              // INFORMASI DATA
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF3E8'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Instrumen: $assetName',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Periode: $periodName',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Total data: ${data.length} baris',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Tanggal ekspor: '
                      '${now.day.toString().padLeft(2, '0')}/'
                      '${now.month.toString().padLeft(2, '0')}/'
                      '${now.year} '
                      '${now.hour.toString().padLeft(2, '0')}:'
                      '${now.minute.toString().padLeft(2, '0')}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // TABEL OHLC
              pw.TableHelper.fromTextArray(
                headers: [
                  'Tanggal',
                  'Open',
                  'High',
                  'Low',
                  'Close',
                  'Perubahan (%)',
                ],
                data: data.map((item) {
                  return [
                    item.date,
                    item.open.toStringAsFixed(2),
                    item.high.toStringAsFixed(2),
                    item.low.toStringAsFixed(2),
                    item.close.toStringAsFixed(2),
                    item.change.toStringAsFixed(2),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                cellStyle: const pw.TextStyle(fontSize: 7),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F58220'),
                ),
                cellAlignment: pw.Alignment.center,
                cellPadding: const pw.EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 6,
                ),
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#E2E8F0'),
                  width: 0.5,
                ),
                oddRowDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFF9F4'),
                ),
              ),

              pw.SizedBox(height: 15),

              pw.Text(
                'Dokumen ini dihasilkan secara otomatis '
                'oleh EQUICKLY Market Intelligence.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#64748B'),
                ),
              ),
            ];
          },
        ),
      );

      // Simpan PDF ke direktori sementara
      final directory = await getTemporaryDirectory();

      final file = File('${directory.path}/historis_${assetName}_$stamp.pdf');

      await file.writeAsBytes(await pdf.save(), flush: true);

      if (!mounted) return;

      // Bagikan PDF
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Histori Data Harga $assetName',
          text:
              'Laporan histori data $assetName '
              'periode $periodName.',
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export PDF gagal: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: GoogleFonts.roboto(),
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          centerTitle: true,
          leadingWidth: 56,
          iconTheme: const IconThemeData(color: Color(0xFF1F2937), size: 26),
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
                      color: const Color(0xFF64748B),
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
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageTitle(),
                      const SizedBox(height: 14),

                      _buildAssetTabs(),
                      const SizedBox(height: 18),

                      _buildSelectedTradingViewChart(),
                      const SizedBox(height: 18),

                      _buildSettlementCard(),
                      const SizedBox(height: 18),

                      _buildFilterCard(),
                      const SizedBox(height: 18),

                      _buildOhlcCard(),
                      const SizedBox(height: 18),

                      _buildPagination(),
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
  // ============================================================
  // PAGE TITLE
  // ============================================================

  Widget _buildPageTitle() {
    return Text(
      'Data Harga Emas',
      style: GoogleFonts.roboto(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  // ============================================================
  // ASSET TABS
  // ============================================================

  Widget _buildAssetTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(_assets.length, (index) {
          final isSelected = _selectedAsset == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAsset = index;
                  _currentPage = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFF58220)
                      : const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFF58220,
                            ).withValues(alpha: 0.10),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _assets[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

Widget _buildSelectedTradingViewChart() {
  late String title;
  late String subtitle;
  late String symbol;

  switch (_selectedAsset) {
    case 1:
      title = 'HKK';
      subtitle = 'Hang Seng Index Futures';
      symbol = 'INDEX:HSI';
      break;

    case 2:
      title = 'JPK';
      subtitle = 'Nikkei 225 Japan';
      symbol = 'SPREADEX:NIKKEI';
      break;

    default:
      title = 'XUL';
      subtitle = 'Loco London Gold';
      symbol = 'OANDA:XAUUSD';
  }

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFFFE5CC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.show_chart,
                color: primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'TRADINGVIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2962FF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 320,
          child: _TradingViewChart(
            key: ValueKey(symbol),
            symbol: symbol,
          ),
        ),
      ],
    ),
  );
}



  Widget _buildSettlementCard() {
    final commodity = switch (_selectedAsset) {
      1 => 'HSI',
      2 => 'SNI',
      _ => 'LGD',
    };

    final latestPrice = _latestPriceForCommodity(commodity);

    final openYesterday = latestPrice?.open ?? latestPrice?.price;
    final closeYesterday = latestPrice?.close ?? latestPrice?.price;

    final signal = openYesterday == null || closeYesterday == null
        ? 'MENUNGGU DATA'
        : closeYesterday > openYesterday
            ? 'BUY'
            : closeYesterday < openYesterday
                ? 'SELL'
                : 'NETRAL';

    final signalColor = signal == 'BUY'
        ? const Color(0xFF00866A)
        : signal == 'SELL'
            ? const Color(0xFFD64545)
            : const Color(0xFFB7791F);

    final signalBg = signal == 'BUY'
        ? const Color(0xFFE7F7EF)
        : signal == 'SELL'
            ? const Color(0xFFFFEEEE)
            : const Color(0xFFFFF4DF);

    Widget priceRow({required String label, required double? value}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value == null ? 'Menunggu data' : _formatPrice(value),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DCC4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER NEST
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0DF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFFD97732),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'NEST',
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // DROPDOWN PENJELASAN NEST
          InkWell(
            onTap: () {
              setState(() {
                _isNestInfoExpanded = !_isNestInfoExpanded;
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97732),
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Apa Itu NEST?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isNestInfoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFD97732),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ISI PENJELASAN
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isNestInfoExpanded
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 5, bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFF0E2),
                          Color(0xFFF1F3F5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(
                          0xFFF58220,
                        ).withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mengenal NEST',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD96812),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'NEST merupakan konsep Follow the Trend yang mengacu pada harga penutupan (Close).\n\n'
                          '• Close > Open = BUY\n'
                          '• Close < Open = SELL',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(
              height: 1,
              color: Color(0xFFE9DCCB),
            ),
          ),

          // DATA OPEN, CLOSE, DAN SINYAL
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    priceRow(
                      label: 'Open Kemarin',
                      value: openYesterday,
                    ),
                    const SizedBox(height: 14),
                    priceRow(
                      label: 'Close Kemarin',
                      value: closeYesterday,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 88),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: signalBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: signalColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  signal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: signalColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (priceError != null) ...[
            const SizedBox(height: 10),
            Text(
              priceError!,
              style: const TextStyle(
                color: Color(0xFFD64545),
                fontSize: 10,
              ),
            ),
          ],

          if (isLoadingPrices) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFFF58220),
              backgroundColor: Color(0xFFFFE8D1),
            ),
          ],
        ],
      ),
    );
  }


  // ============================================================
  // FILTER CARD
  // ============================================================

  Widget _buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),

          // PERIOD
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_periods.length, (index) {
                final selected = _selectedPeriod == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPeriod = index;

                        _currentPage = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFF58220)
                            : const Color(0xFFFFF3E8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _periods[index],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // DATE
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Tanggal Mulai',
                  value: _formatDate(_startDate),
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDateField(
                  label: 'Tanggal Akhir',
                  value: _formatDate(_endDate),
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _applyFilter,
                  icon: const Icon(Icons.filter_alt_outlined, size: 17),
                  label: const Text('Terapkan Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
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
              const SizedBox(width: 9),
              OutlinedButton.icon(
                onPressed: _exportData,
                icon: const Icon(Icons.download_outlined, size: 17),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 15,
              color: textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 9, color: textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OHLC TABLE
  // ============================================================

  Widget _buildOhlcCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 17, 17, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buku Kuotasi Pasar OHLC',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Data Open, High, Low & Close',
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_ohlcData.length} Entri',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              headingRowHeight: 42,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 52,
              headingTextStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: textSecondary,
              ),
              dataTextStyle: const TextStyle(fontSize: 10, color: textPrimary),
              columns: const [
                DataColumn(label: Text('Tanggal')),
                DataColumn(label: Text('Open')),
                DataColumn(label: Text('High')),
                DataColumn(label: Text('Low')),
                DataColumn(label: Text('Close')),
                DataColumn(label: Text('Arah')),
              ],
              rows: _ohlcData.skip((_currentPage - 1) * 10).take(10).map((
                item,
              ) {
                final positive = item.change >= 0;

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        item.date,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DataCell(Text(_formatPrice(item.open))),
                    DataCell(Text(_formatPrice(item.high))),
                    DataCell(Text(_formatPrice(item.low))),
                    DataCell(
                      Text(
                        _formatPrice(item.close),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: positive
                              ? primaryLight
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${positive ? '+' : ''}${item.change.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: positive
                                ? primaryDark
                                : const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGINATION
  // ============================================================

  Widget _buildPagination() {
    final totalData = _filteredPrices.length;
    final totalPages = totalData == 0 ? 1 : (totalData / 10).ceil();

    if (_currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final start = totalData == 0 ? 0 : ((_currentPage - 1) * 10) + 1;
    final end = totalData == 0
        ? 0
        : (_currentPage * 10 > totalData ? totalData : _currentPage * 10);

    final visiblePages = <int>[];
    final maxVisible = totalPages < 5 ? totalPages : 5;

    for (int i = 1; i <= maxVisible; i++) {
      visiblePages.add(i);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Baris per halaman:',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryLight,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  '10',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              Text(
                'Menampilkan $start-$end dari $totalData data',
                style: const TextStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _paginationButton(
                icon: Icons.first_page,
                enabled: _currentPage > 1,
                onTap: () {
                  setState(() {
                    _currentPage = 1;
                  });
                },
              ),
              const SizedBox(width: 4),
              _paginationButton(
                icon: Icons.chevron_left,
                enabled: _currentPage > 1,
                onTap: () {
                  setState(() {
                    _currentPage--;
                  });
                },
              ),
              const SizedBox(width: 6),
              ...visiblePages.map((page) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _currentPage == page
                            ? primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '$page',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _currentPage == page
                              ? Colors.white
                              : textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              if (totalPages > 5) ...[
                const SizedBox(width: 3),
                const Text(
                  '...',
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
                const SizedBox(width: 3),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = totalPages;
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    child: Text(
                      '$totalPages',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _currentPage == totalPages
                            ? primary
                            : textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              _paginationButton(
                icon: Icons.chevron_right,
                enabled: _currentPage < totalPages,
                onTap: () {
                  setState(() {
                    _currentPage++;
                  });
                },
              ),
              const SizedBox(width: 4),
              _paginationButton(
                icon: Icons.last_page,
                enabled: _currentPage < totalPages,
                onTap: () {
                  setState(() {
                    _currentPage = totalPages;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? primaryLight : background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 17,
          color: enabled ? primary : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _TradingViewChart extends StatefulWidget {
  final String symbol;

  const _TradingViewChart({super.key, required this.symbol});

  @override
  State<_TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<_TradingViewChart> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFAFBFE))
      ..loadHtmlString(_html);
  }

  String get _html =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    html, body, #chart {
      margin: 0;
      padding: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
    }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script src="https://s3.tradingview.com/tv.js"></script>
  <script>
    new TradingView.widget({
      autosize: true,
      symbol: "${widget.symbol}",
      interval: "D",
      timezone: "Asia/Jakarta",
      theme: "light",
      style: "1",
      locale: "id",
      enable_publishing: false,
      hide_top_toolbar: false,
      hide_legend: false,
      save_image: false,
      container_id: "chart"
    });
  </script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
// ================================================================
// MODEL CHART
// ================================================================

class GoldChartPoint {
  final String date;
  final String shortDate;
  final double price;

  const GoldChartPoint({
    required this.date,
    required this.shortDate,
    required this.price,
  });
}

// ================================================================
// MODEL OHLC
// ================================================================

class OhlcData {
  final String date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double change;

  const OhlcData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.change,
  });
}

// ================================================================
// CUSTOM CHART PAINTER
// ================================================================

class GoldChartPainter extends CustomPainter {
  final List<GoldChartPoint> data;
  final int selectedIndex;

  GoldChartPainter({required this.data, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const leftPadding = 42.0;
    const rightPadding = 12.0;
    const topPadding = 18.0;
    const bottomPadding = 32.0;

    final chartWidth = size.width - leftPadding - rightPadding;

    final chartHeight = size.height - topPadding - bottomPadding;

    final prices = data.map((e) => e.price).toList();

    final minPrice = prices.reduce((a, b) => a < b ? a : b) - 8;

    final maxPrice = prices.reduce((a, b) => a > b ? a : b) + 8;

    // ------------------------------------------------------------
    // GRID
    // ------------------------------------------------------------

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    const gridCount = 4;

    for (int i = 0; i <= gridCount; i++) {
      final y = topPadding + (chartHeight / gridCount) * i;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );

      final value = maxPrice - ((maxPrice - minPrice) / gridCount) * i;

      final textPainter = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(0),
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // ------------------------------------------------------------
    // POINTS
    // ------------------------------------------------------------

    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = data.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + (chartWidth / (data.length - 1)) * i;

      final normalized = (data[i].price - minPrice) / (maxPrice - minPrice);

      final y = topPadding + chartHeight - normalized * chartHeight;

      points.add(Offset(x, y));
    }

    // ------------------------------------------------------------
    // AREA
    // ------------------------------------------------------------

    final areaPath = Path();

    areaPath.moveTo(points.first.dx, size.height - bottomPadding);

    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }

    areaPath.lineTo(points.last.dx, size.height - bottomPadding);

    areaPath.close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x33F58220), Color(0x00F58220)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(areaPath, areaPaint);

    // ------------------------------------------------------------
    // LINE
    // ------------------------------------------------------------

    final linePath = Path();

    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = const Color(0xFFF58220)
      ..strokeWidth = 2.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // ------------------------------------------------------------
    // X AXIS LABEL
    // ------------------------------------------------------------

    for (int i = 0; i < data.length; i++) {
      if (i % 2 != 0 && i != data.length - 1) {
        continue;
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: data[i].shortDate,
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      double x = points[i].dx - textPainter.width / 2;

      if (x < leftPadding) {
        x = leftPadding;
      }

      if (x + textPainter.width > size.width - rightPadding) {
        x = size.width - rightPadding - textPainter.width;
      }

      textPainter.paint(canvas, Offset(x, size.height - bottomPadding + 10));
    }

    // ------------------------------------------------------------
    // SELECTED POINT
    // ------------------------------------------------------------

    final safeSelectedIndex = selectedIndex.clamp(0, points.length - 1);
    final selected = points[safeSelectedIndex];

    final verticalPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(selected.dx, topPadding),
      Offset(selected.dx, size.height - bottomPadding),
      verticalPaint,
    );

    final outerCircle = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final selectedCircle = Paint()
      ..color = const Color(0xFFF58220)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(selected, 6, outerCircle);

    canvas.drawCircle(selected, 4, selectedCircle);
  }

  @override
  bool shouldRepaint(covariant GoldChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.data != data;
  }
}
