import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pivot_point.dart';
import '../services/api_service.dart';
import 'dashboard_page.dart';
import 'berita_page.dart';
import 'harga_emas_page.dart';
import 'kalkulator_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class PivotPointPage extends StatefulWidget {
  const PivotPointPage({super.key});

  @override
  State<PivotPointPage> createState() => _PivotPointPageState();
}

class _PivotPointPageState extends State<PivotPointPage> {
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFFF58220);
  static const Color _surfaceContainer = Color(0xFFFFE5CC);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF64748B);
  PivotPoint? _pivotData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPivotPoint();
  }

  String _currentAsset = 'LGD';

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

  void _copyPivot() {
    Clipboard.setData(ClipboardData(text: 'PP: ${_formatPivot(_pp)}'));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hasil PP berhasil disalin'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      const SizedBox(height: 20),

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
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

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
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
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

  Widget _buildAssetBar() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _assetButton(label: 'LGD (Loco London Gold)', asset: 'LGD'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _assetButton(label: 'HSI (Hang Seng Index)', asset: 'HSI'),
          ),
        ],
      ),
    );
  }

  Widget _assetButton({required String label, required String asset}) {
    final active = _currentAsset == asset;

    return GestureDetector(
      onTap: () => _switchAsset(asset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF58220) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: active ? const Color(0xFFF58220) : const Color(0xFFE2E8F0),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0xFFF58220).withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.white : const Color(0xFFCBD5E1),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
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

  Widget _buildPivotLadder() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: Color(0xFFF58220), size: 21),
              SizedBox(width: 8),
              Expanded(
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
            child: TextButton.icon(
              onPressed: _copyPivot,
              icon: const Icon(Icons.content_copy_rounded, size: 15),
              label: const Text('Salin Nilai PP'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD96812),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ladderRow({
    required String label,
    required double value,
    required bool isResistance,
  }) {
    final rowColor = isResistance
        ? const Color(0xFFFFF0EE)
        : const Color(0xFFE8F5F0);

    final valueColor = isResistance
        ? const Color(0xFFD64545)
        : const Color(0xFF00866A);

    return Container(
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
          const Expanded(
            child: Text(
              'Pivot Level',
              style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
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
        ],
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
    return Container(
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
              'Pivot Point',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD96812),
              ),
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
        ],
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

  Widget _buildBottomNavigation() {
    final items = [
      const _BottomItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Dashboard',
      ),
      const _BottomItem(
        icon: Icons.newspaper_outlined,
        activeIcon: Icons.newspaper_rounded,
        label: 'Berita',
      ),
      const _BottomItem(
        icon: Icons.show_chart_rounded,
        activeIcon: Icons.show_chart_rounded,
        label: 'Data',
      ),
      const _BottomItem(
        icon: Icons.table_chart_outlined,
        activeIcon: Icons.table_chart_rounded,
        label: 'Pivot',
      ),
      const _BottomItem(
        icon: Icons.calculate_outlined,
        activeIcon: Icons.calculate_rounded,
        label: 'Kalkulator',
      ),
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(items.length, (index) {
              final active = index == 3;

              return SizedBox(
                width: 82,
                child: InkWell(
                  onTap: () {
                    switch (index) {
                      case 0:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardPage(),
                          ),
                        );
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
                        break;

                      case 4:
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KalkulatorPage(),
                          ),
                        );
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
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? const Color(0xFFD96812)
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
}

class _BottomItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _BottomItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
