import 'package:flutter/material.dart';

import '../services/live_quote_service.dart';

class LiveQuotesTable extends StatefulWidget {
  final LiveQuoteService service;

  const LiveQuotesTable({super.key, required this.service});

  @override
  State<LiveQuotesTable> createState() => _LiveQuotesTableState();
}

class _LiveQuotesTableState extends State<LiveQuotesTable> {
  late final LiveQuoteService _service;

  static const Color _orange = Color(0xFFF58220);
  static const Color _green = Color(0xFF00866A);
  static const Color _red = Color(0xFFD64545);
  static const Color _secondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _service = widget.service;
    _service.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  String _formatPrice(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  }

  Widget _statusIndicator() {
    final connected = _service.isConnected;
    final color = connected ? _green : _red;
    final text = _service.isConnecting
        ? 'Menghubungkan...'
        : connected
        ? 'WebSocket terhubung'
        : 'Koneksi terputus';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 8, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gold = _service.quotes['XUL10'];
    final hkk = _service.quotes['HKK50_BBJ'];
    final jpk = _service.quotes['JPK50_BBJ'];

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
              const Expanded(
                child: Text(
                  'Live Quotes',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sambungkan ulang',
                visualDensity: VisualDensity.compact,
                onPressed: _service.reconnect,
                icon: const Icon(Icons.refresh, size: 20, color: _orange),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Market quotes for XUL, HKK and JPK',
            style: TextStyle(fontSize: 11, color: _secondary),
          ),
          const SizedBox(height: 8),
          _statusIndicator(),
          if (_service.errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _service.errorMessage!,
              style: const TextStyle(fontSize: 10, color: _red),
            ),
          ],
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFFFF3E8)),
              headingTextStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
              dataTextStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
              columnSpacing: 20,
              horizontalMargin: 10,
              columns: const [
                DataColumn(label: Text('Symbol')),
                DataColumn(label: Text('Last')),
                DataColumn(label: Text('Bid')),
                DataColumn(label: Text('Ask')),
                DataColumn(label: Text('Open')),
                DataColumn(label: Text('High')),
                DataColumn(label: Text('Low')),
                DataColumn(label: Text('Change (%)')),
              ],
              rows: [
                _row('XUL', 'Loco London Gold', gold),
                _row('HKK', 'Hang Seng Index Futures', hkk),
                _row('JPK', 'Nikkei 225 Futures (IDR)', jpk),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  double? _percentChange(LiveQuote? quote) {
    final price = quote?.price;
    final open = quote?.open;

    if (price == null || open == null || open == 0) return null;
    return ((price - open) / open) * 100;
  }

  String _formatPercent(LiveQuote? quote) {
    final percent = _percentChange(quote);
    if (percent == null) return '—';

    final sign = percent > 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(2)}%';
  }

  DataRow _row(String code, String name, LiveQuote? quote) {
    final change = _percentChange(quote);

    return DataRow(
      cells: [
        DataCell(Tooltip(message: name, child: Text(code))),
        DataCell(Text(_formatPrice(quote?.price))),
        DataCell(Text(_formatPrice(quote?.bid))),
        DataCell(Text(_formatPrice(quote?.ask))),
        DataCell(Text(_formatPrice(quote?.open))),
        DataCell(Text(_formatPrice(quote?.high))),
        DataCell(Text(_formatPrice(quote?.low))),
        DataCell(
          Text(
            _formatPercent(quote),
            style: TextStyle(
              color: change == null
                  ? _secondary
                  : change >= 0
                  ? _green
                  : _red,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
