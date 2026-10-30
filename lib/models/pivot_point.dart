
class PivotPoint {
  final String commodity;
  final String date;

  final double open;
  final double high;
  final double low;
  final double close;

  final double pivot;
  final double buy;
  final double sell;
  final double range;

  final double r1;
  final double r2;
  final double r3;
  final double r4;

  final double s1;
  final double s2;
  final double s3;
  final double s4;

  final double nest;
  final String unit;

  PivotPoint({
    required this.commodity,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.pivot,
    required this.buy,
    required this.sell,
    required this.range,
    required this.r1,
    required this.r2,
    required this.r3,
    required this.r4,
    required this.s1,
    required this.s2,
    required this.s3,
    required this.s4,
    required this.nest,
    required this.unit,
  });

  factory PivotPoint.fromJson(Map<String, dynamic> json) {
    final source = json['source'] is Map
        ? Map<String, dynamic>.from(json['source'])
        : <String, dynamic>{};

    final resistance = json['resistance'] is Map
        ? Map<String, dynamic>.from(json['resistance'])
        : <String, dynamic>{};

    final support = json['support'] is Map
        ? Map<String, dynamic>.from(json['support'])
        : <String, dynamic>{};

    return PivotPoint(
      commodity: json['commodity']?.toString() ?? '',
      date: json['date']?.toString() ?? '',

      open: _toDouble(source['open']),
      high: _toDouble(source['high']),
      low: _toDouble(source['low']),
      close: _toDouble(source['close']),

      pivot: _toDouble(json['pivot']),
      buy: _toDouble(json['buy']),
      sell: _toDouble(json['sell']),
      range: _toDouble(json['range']),

      r1: _toDouble(resistance['r1']),
      r2: _toDouble(resistance['r2']),
      r3: _toDouble(resistance['r3']),
      r4: _toDouble(resistance['r4']),

      s1: _toDouble(support['s1']),
      s2: _toDouble(support['s2']),
      s3: _toDouble(support['s3']),
      s4: _toDouble(support['s4']),

      nest: _toDouble(json['nest']),
      unit: json['unit']?.toString() ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
