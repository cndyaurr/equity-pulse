class GoldPrice {
  final int id;
  final String commodity;
  final double price;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final DateTime? recordedAt;

  GoldPrice({
    required this.id,
    required this.commodity,
    required this.price,
    this.open,
    this.high,
    this.low,
    this.close,
    this.recordedAt,
  });

  factory GoldPrice.fromJson(Map<String, dynamic> json) {
    return GoldPrice(
      id: int.tryParse(json['id'].toString()) ?? 0,
      commodity: json['commodity']?.toString() ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0,
      open: json['open'] == null
          ? null
          : double.tryParse(json['open'].toString()),
      high: json['high'] == null
          ? null
          : double.tryParse(json['high'].toString()),
      low: json['low'] == null
          ? null
          : double.tryParse(json['low'].toString()),
      close: json['close'] == null
          ? null
          : double.tryParse(json['close'].toString()),
      recordedAt: json['recorded_at'] == null
          ? null
          : _parseDateOnly(json['recorded_at'].toString()),
    );
  }

  static DateTime? _parseDateOnly(String value) {
    if (value.length < 10) return null;

    // Pertahankan tanggal pencatatan dari database.
    return DateTime.tryParse(value.substring(0, 10));
  }
}
