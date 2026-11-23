import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/pivot_point.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PivotPointPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const PivotPointPage({super.key, this.user});

  @override
  State<PivotPointPage> createState() => _PivotPointPageState();
}

class _PivotPointPageState extends State<PivotPointPage> {
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFFF58220);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF64748B);
  PivotPoint? _pivotData;
  bool _isLoading = true;
  String? _errorMessage;
  Widget _buildPivotInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isPivotInfoExpanded = !_isPivotInfoExpanded;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFFD96812),
                  size: 17,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'Apa Itu Pivot Point?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isPivotInfoExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFD96812),
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isPivotInfoExpanded
              ? Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 5, bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF0E2), Color(0xFFF1F3F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF58220).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mengenal Pivot Point',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD96812),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pivot Point : harga wajar atau harga pasaran, untuk menentukan aksi beli dan jual yang mengacu pada harga pembukaan(open)\n'
                        'Open < pivot point (buy)\n'
                        'Open > pivot point (sell) \n',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.6,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPivotPoint();
  }

  String _currentAsset = 'LGD';
  bool _isPivotInfoExpanded = false;

  final TextEditingController _openController = TextEditingController(
    text: '0.00',
  );

  final TextEditingController _highController = TextEditingController(
    text: '0.00',
  );

  final TextEditingController _lowController = TextEditingController(
    text: '0.00',
  );

  final TextEditingController _closeController = TextEditingController(
    text: '0.00',
  );

  double _range = 0.00;
  double _pp = 0.00;

  double _r1 = 0.00;
  double _r2 = 0.00;
  double _r3 = 0.00;
  double _r4 = 0.00;

  double _s1 = 0.00;
  double _s2 = 0.00;
  double _s3 = 0.00;
  double _s4 = 0.00;

  double _m7 = 0.00;
  double _m6 = 0.00;
  double _m5 = 0.00;
  double _m4 = 0.00;
  double _m3 = 0.00;
  double _m2 = 0.00;
  double _m1 = 0.00;
  double _m0 = 0.00;

  String _signal = 'BUY';
  String _signalLogic = '';
  String _ruleExplanation = '';

  @override
  void dispose() {
    _openController.dispose();
    _highController.dispose();
    _lowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  double _parseController(TextEditingController controller) {
    return double.tryParse(controller.text) ?? 0;
  }

  String _format(double value) {
    return value.toStringAsFixed(_currentAsset == 'LGD' ? 2 : 0);
  }

  String _formatPivot(double value) {
    return value.toStringAsFixed(2);
  }

  Future<void> _loadPivotPoint() async {
    try {
      final data = await ApiService.getPivotPoint(_currentAsset);

      if (!mounted) return;

      final open = data.open;
      final high = data.high;
      final low = data.low;
      final close = data.close;

      _openController.text = _format(open);
      _highController.text = _format(high);
      _lowController.text = _format(low);
      _closeController.text = _format(close);

      final pp = data.pivot;
      final range = data.range;

      final r1 = data.r1;
      final r2 = data.r2;
      final r3 = data.r3;
      final r4 = data.r4;

      final s1 = data.s1;
      final s2 = data.s2;
      final s3 = data.s3;
      final s4 = data.s4;

      final m7 = (r4 + r3) / 2;
      final m6 = (r3 + r2) / 2;
      final m5 = (r2 + r1) / 2;
      final m4 = (r1 + pp) / 2;
      final m3 = (pp + s1) / 2;
      final m2 = (s1 + s2) / 2;
      final m1 = (s2 + s3) / 2;
      final m0 = (s3 + s4) / 2;

      String signal;
      String signalLogic;
      String ruleExplanation;

      if (_currentAsset == 'LGD') {
        if (open < pp) {
          signal = 'BUY';
          signalLogic = 'Open (${_format(open)}) < PP (${_format(pp)})';
          ruleExplanation = 'Open berada di bawah Pivot Point.';
        } else {
          signal = 'SELL';
          signalLogic = 'Open (${_format(open)}) > PP (${_format(pp)})';
          ruleExplanation = 'Open berada di atas Pivot Point.';
        }
      } else {
        if (open > pp) {
          signal = 'BUY';
          signalLogic = 'Open (${_format(open)}) > PP (${_format(pp)})';
          ruleExplanation = 'Open indeks berada di atas Pivot Point.';
        } else {
          signal = 'SELL';
          signalLogic = 'Open (${_format(open)}) < PP (${_format(pp)})';
          ruleExplanation = 'Open indeks berada di bawah Pivot Point.';
        }
      }

      setState(() {
        _pivotData = data;
        _isLoading = false;
        _errorMessage = null;

        _range = range;
        _pp = pp;

        _r1 = r1;
        _r2 = r2;
        _r3 = r3;
        _r4 = r4;

        _s1 = s1;
        _s2 = s2;
        _s3 = s3;
        _s4 = s4;

        _m7 = m7;
        _m6 = m6;
        _m5 = m5;
        _m4 = m4;
        _m3 = m3;
        _m2 = m2;
        _m1 = m1;
        _m0 = m0;

        _signal = signal;
        _signalLogic = signalLogic;
        _ruleExplanation = ruleExplanation;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Gagal mengambil data pivot point.';
      });
    }
  }

  void _calculatePivot() {
    final open = _parseController(_openController);
    final high = _parseController(_highController);
    final low = _parseController(_lowController);
    final close = _parseController(_closeController);

    final range = high - low;
    final pp = (high + low + close) / 3;

    final r1 = (2 * pp) - low;
    final r2 = pp + range;
    final r3 = pp + (range * 2);
    final r4 = pp + (range * 3);

    final s1 = (2 * pp) - high;
    final s2 = pp - range;
    final s3 = pp - (range * 2);
    final s4 = pp - (range * 3);

    final m7 = (r4 + r3) / 2;
    final m6 = (r3 + r2) / 2;
    final m5 = (r2 + r1) / 2;
    final m4 = (r1 + pp) / 2;
    final m3 = (pp + s1) / 2;
    final m2 = (s1 + s2) / 2;
    final m1 = (s2 + s3) / 2;
    final m0 = (s3 + s4) / 2;

    String signal;
    String signalLogic;
    String ruleExplanation;

    if (_currentAsset == 'LGD') {
      if (open < pp) {
        signal = 'BUY';
        signalLogic = 'Open (${_format(open)}) < PP (${_format(pp)})';
        ruleExplanation = 'Open berada di bawah Pivot Point.';
      } else {
        signal = 'SELL';
        signalLogic = 'Open (${_format(open)}) > PP (${_format(pp)})';
        ruleExplanation = 'Open berada di atas Pivot Point.';
      }
    } else {
      if (open > pp) {
        signal = 'BUY';
        signalLogic = 'Open (${_format(open)}) > PP (${_format(pp)})';
        ruleExplanation = 'Open indeks berada di atas Pivot Point.';
      } else {
        signal = 'SELL';
        signalLogic = 'Open (${_format(open)}) < PP (${_format(pp)})';
        ruleExplanation = 'Open indeks berada di bawah Pivot Point.';
      }
    }

    setState(() {
      _range = range;
      _pp = pp;

      _r1 = r1;
      _r2 = r2;
      _r3 = r3;
      _r4 = r4;

      _s1 = s1;
      _s2 = s2;
      _s3 = s3;
      _s4 = s4;

      _m7 = m7;
      _m6 = m6;
      _m5 = m5;
      _m4 = m4;
      _m3 = m3;
      _m2 = m2;
      _m1 = m1;
      _m0 = m0;

      _signal = signal;
      _signalLogic = signalLogic;
      _ruleExplanation = ruleExplanation;
    });
  }


Future<void> _exportPivotPdf() async {
  try {
    // Memuat logo perusahaan
    final logoData = await rootBundle.load(
      'assets/images/logo_perusahaan.png',
    );

    final logo = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    final pdf = pw.Document();

    // Mengambil nilai OHLC
    final open = _parseController(_openController);
    final high = _parseController(_highController);
    final low = _parseController(_lowController);
    final close = _parseController(_closeController);

    final range = high - low;
    final pp = (high + low + close) / 3;

    // Data resistance dan support
    final resistanceSupport = <Map<String, String>>[
      {'label': 'R4', 'value': _format(_r4)},
      {'label': 'R3', 'value': _format(_r3)},
      {'label': 'R2', 'value': _format(_r2)},
      {'label': 'R1', 'value': _format(_r1)},
      {'label': 'S1', 'value': _format(_s1)},
      {'label': 'S2', 'value': _format(_s2)},
      {'label': 'S3', 'value': _format(_s3)},
      {'label': 'S4', 'value': _format(_s4)},
    ];

    // Data mid level
    final midLevels = <Map<String, String>>[
      {'label': 'M7', 'value': _format(_m7)},
      {'label': 'M6', 'value': _format(_m6)},
      {'label': 'M5', 'value': _format(_m5)},
      {'label': 'M4', 'value': _format(_m4)},
      {'label': 'M3', 'value': _format(_m3)},
      {'label': 'M2', 'value': _format(_m2)},
      {'label': 'M1', 'value': _format(_m1)},
      {'label': 'M0', 'value': _format(_m0)},
    ];

    // Membuat tabel sederhana untuk level R, S, dan M
    pw.Widget buildValueTable(
      String title,
      List<Map<String, String>> rows,
    ) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E2E8F0'),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F58220'),
                ),
                children: [
                  'LEVEL',
                  'HASIL',
                ].map((text) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(7),
                    child: pw.Text(
                      text,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...rows.map((item) {
                final label = item['label']!;
                final isResistance = label.startsWith('R');
                final isSupport = label.startsWith('S');

                final rowColor = isResistance
                    ? PdfColor.fromHex('#E8F5F0')
                    : isSupport
                        ? PdfColor.fromHex('#FFF0EE')
                        : PdfColor.fromHex('#F8FAFC');

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowColor),
                  children: [
                    item['label']!,
                    item['value']!,
                  ].map((text) {
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(7),
                      child: pw.Text(
                        text,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return [
            // HEADER
            pw.Row(
              children: [
                pw.Image(logo, width: 48, height: 48),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EQUICKLY',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#F58220'),
                      ),
                    ),
                    pw.Text(
                      'MARKET INTELLIGENCE',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            pw.Center(
              child: pw.Text(
                'PIVOT POINT ANALYSIS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

            pw.SizedBox(height: 14),

            // PARAMETER OHLC
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF3E8'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Parameter OHLC - $_currentAsset',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('Open: ${_format(open)}'),
                  pw.Text('High: ${_format(high)}'),
                  pw.Text('Low: ${_format(low)}'),
                  pw.Text('Close: ${_format(close)}'),
                  pw.Text('Range: ${_formatPivot(range)}'),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // DETAIL PERHITUNGAN PP SAJA
            pw.Text(
              'DETAIL PERHITUNGAN PIVOT POINT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#D96812'),
              ),
            ),

            pw.SizedBox(height: 8),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF3E8'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(
                  color: PdfColor.fromHex('#F58220'),
                  width: 0.8,
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PP (Pivot Point)',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#D96812'),
                    ),
                  ),

                  pw.SizedBox(height: 10),

                  pw.Text(
                    'PP = (High + Low + Close) ÷ 3',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),

                  pw.SizedBox(height: 8),

                  pw.Text(
                    '= (${_formatPivot(high)} + ${_formatPivot(low)} + ${_formatPivot(close)}) ÷ 3',
                    style: const pw.TextStyle(
                      fontSize: 10,
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(11),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FFE5CC'),
                      borderRadius: pw.BorderRadius.circular(7),
                    ),
                    child: pw.Text(
                      'PP = ${_formatPivot(pp)}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#D96812'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // RESISTANCE DAN SUPPORT
            buildValueTable(
              'RESISTANCE & SUPPORT LEVEL',
              resistanceSupport,
            ),

            pw.SizedBox(height: 14),

            // MID LEVEL
            buildValueTable(
              'MID LEVEL',
              midLevels,
            ),

            pw.SizedBox(height: 14),

            // SIGNAL
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex(
                  _signal == 'BUY' ? '#E8F5F0' : '#FFF0EE',
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'SIGNAL: $_signal',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _signalLogic,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    _ruleExplanation,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),
            pw.Divider(),

            pw.Text(
              'Generated by EQUICKLY | Market Intelligence',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ];
        },
      ),
    );

    // SIMPAN PDF
    final bytes = await pdf.save();
    final directory = await getTemporaryDirectory();

    final file = File(
      '${directory.path}/Pivot_$_currentAsset.pdf',
    );

    await file.writeAsBytes(bytes);

    // BAGIKAN PDF
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Pivot Point $_currentAsset',
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gagal membuat PDF: $e'),
      ),
    );
  }
}


  Future<void> _switchAsset(String asset) async {
    setState(() {
      _currentAsset = asset;
      _isLoading = true;
      _errorMessage = null;
    });

    await _loadPivotPoint();
  }

  void _resetValues() {
    _switchAsset(_currentAsset);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: GoogleFonts.roboto(),
      child: Scaffold(
        backgroundColor: _background,
        appBar: _buildHeader(),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pivot Point',
                        style: GoogleFonts.roboto(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),

                      const SizedBox(height: 5),

                      _buildPivotInfoCard(),

                      const SizedBox(height: 10),

                      _buildAssetBar(),
                      const SizedBox(height: 16),

                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildErrorState(_errorMessage!)
                      else if (_pivotData != null)
                        _buildWorkspace()
                      else
                        _buildErrorState('Data pivot point belum tersedia.'),
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
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937), size: 24),
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
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          },
          icon: const Icon(Icons.notifications_none, color: _textPrimary),
        ),
      ],
    );
  }

  Widget _buildAssetBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _assetButton(label: 'LGD', asset: 'LGD'),
          ),
          Expanded(
            child: _assetButton(label: 'HSI', asset: 'HSI'),
          ),
        ],
      ),
    );
  }

  Widget _assetButton({required String label, required String asset}) {
    final selected = _currentAsset == asset;

    return GestureDetector(
      onTap: () {
        if (_currentAsset != asset) {
          _switchAsset(asset);
        }
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
          label,
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

  Widget _buildWorkspace() {
    return Column(
      children: [
        _buildParameterCard(),
        const SizedBox(height: 16),
        _buildSignalCard(),
        const SizedBox(height: 16),
        _buildPivotLadder(),
      ],
    );
  }

  Widget _buildParameterCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: Color(0xFFF58220), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Parameter OHLC',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inputField(label: 'OPEN', controller: _openController),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(label: 'HIGH', controller: _highController),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _inputField(label: 'LOW', controller: _lowController),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _inputField(
                  label: 'CLOSE',
                  controller: _closeController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _calculatePivot,
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Hitung Pivot'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF58220),
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
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _resetValues,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Reset Form'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Text(
                _currentAsset == 'HSI' ? 'INDEX' : 'USD',
                style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _calculatePivot(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignalCard() {
    final isBuy = _signal == 'BUY';
    final signalColor = isBuy
        ? const Color(0xFF00866A)
        : const Color(0xFFD64545);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: Color(0xFFF58220),
                size: 21,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sinyal Pasar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Range: ${_formatPivot(_range)}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD96812),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ARAH PIVOT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _signalLogic,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: signalColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _signal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Color(0xFFD96812),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _ruleExplanation,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.4,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCalculationDetail(String label) {
    final high = _parseController(_highController);
    final low = _parseController(_lowController);
    final close = _parseController(_closeController);

    final pp = (high + low + close) / 3;
    final range = high - low;

    late String formula;
    late String substitution;
    late double result;

    switch (label) {
      case 'R1':
        formula = 'R1 = (2 × PP) − Low';
        substitution = '= (2 × ${_formatPivot(pp)}) − ${_formatPivot(low)}';
        result = (2 * pp) - low;
        break;

      case 'R2':
        formula = 'R2 = PP + (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} + (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp + range;
        break;

      case 'R3':
        formula = 'R3 = PP + 2 × (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} + 2 × (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp + (range * 2);
        break;

      case 'R4':
        formula = 'R4 = PP + 3 × (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} + 3 × (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp + (range * 3);
        break;

      case 'S1':
        formula = 'S1 = (2 × PP) − High';
        substitution = '= (2 × ${_formatPivot(pp)}) − ${_formatPivot(high)}';
        result = (2 * pp) - high;
        break;

      case 'S2':
        formula = 'S2 = PP − (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} − (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp - range;
        break;

      case 'S3':
        formula = 'S3 = PP − 2 × (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} − 2 × (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp - (range * 2);
        break;

      case 'S4':
        formula = 'S4 = PP − 3 × (High − Low)';
        substitution =
            '= ${_formatPivot(pp)} − 3 × (${_formatPivot(high)} − ${_formatPivot(low)})';
        result = pp - (range * 3);
        break;

      case 'PP':
        formula = 'PP = (High + Low + Close) ÷ 3';
        substitution =
            '= (${_formatPivot(high)} + ${_formatPivot(low)} + ${_formatPivot(close)}) ÷ 3';
        result = pp;
        break;

      default:
        return;
    }

    // Warna berdasarkan jenis Pivot Point
    final detailColor = label.startsWith('R')
        ? const Color(0xFF00866A)
        : label.startsWith('S')
        ? const Color(0xFFD64545)
        : const Color(0xFFD96812);

    final detailBackground = label.startsWith('R')
        ? const Color(0xFFE8F5F0)
        : label.startsWith('S')
        ? const Color(0xFFFFF0EE)
        : const Color(0xFFFFF3E8);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: detailColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formula,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                substitution,
                style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: detailBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$label = ${_format(result)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: detailColor,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Tutup',
                style: TextStyle(color: Color(0xFFD96812)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPivotLadder() {
    return Stack(
      alignment: Alignment.center,
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFFF58220),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hasil Pivot Point',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              _ladderRow(label: 'R4', value: _r4, isResistance: true),
              _midRow(value: _m7),
              _ladderRow(label: 'R3', value: _r3, isResistance: true),
              _midRow(value: _m6),
              _ladderRow(label: 'R2', value: _r2, isResistance: true),
              _midRow(value: _m5),
              _ladderRow(label: 'R1', value: _r1, isResistance: true),
              _midRow(value: _m4),
              _pivotRow(),
              _midRow(value: _m3),
              _ladderRow(label: 'S1', value: _s1, isResistance: false),
              _midRow(value: _m2),
              _ladderRow(label: 'S2', value: _s2, isResistance: false),
              _midRow(value: _m1),
              _ladderRow(label: 'S3', value: _s3, isResistance: false),
              _midRow(value: _m0),
              _ladderRow(label: 'S4', value: _s4, isResistance: false),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _exportPivotPdf,
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _ladderRow({
    required String label,
    required double value,
    required bool isResistance,
  }) {
    final rowColor = isResistance
        ? const Color(0xFFE8F5F0)
        : const Color(0xFFFFF0EE);

    final valueColor = isResistance
        ? const Color(0xFF00866A)
        : const Color(0xFFD64545);

    final formulas = {
      'R1': '(2 × PP) − Low',
      'R2': 'PP + Range',
      'R3': 'PP + 2 × Range',
      'R4': 'PP + 3 × Range',
      'S1': '(2 × PP) − High',
      'S2': 'PP − Range',
      'S3': 'PP − 2 × Range',
      'S4': 'PP − 3 × Range',
    };

    return InkWell(
      onTap: () => _showCalculationDetail(label),
      borderRadius: BorderRadius.circular(7),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: rowColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                formulas[label]!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ),
            Text(
              _format(value),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(width: 5),
            Icon(Icons.chevron_right, size: 15, color: valueColor),
          ],
        ),
      ),
    );
  }

  Widget _midRow({required double value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 38,
            child: Text(
              'Mid',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Level Tengah',
              style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ),
          Text(
            _format(value),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pivotRow() {
    return InkWell(
      onTap: () => _showCalculationDetail('PP'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFF58220).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 38,
              child: Text(
                'PP',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD96812),
                ),
              ),
            ),
            const Expanded(
              child: Text(
                '(High + Low + Close) ÷ 3',
                style: TextStyle(fontSize: 9, color: Color(0xFFD96812)),
              ),
            ),
            Text(
              _formatPivot(_pp),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD96812),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFD96812)),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1F2937).withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildErrorState(String message) {
    return _card(
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 34,
            color: Color(0xFFF58220),
          ),
          const SizedBox(height: 10),
          const Text(
            'Data Pivot Point',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _loadPivotPoint();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF58220),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
