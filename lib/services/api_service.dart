import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gold_price.dart';
import '../models/pivot_point.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static Future<List<GoldPrice>> getGoldPrices() async {
    final response = await http.get(Uri.parse('$baseUrl/gold-prices'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];

      return data
          .map((item) => GoldPrice.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Gagal mengambil data harga emas: ${response.statusCode}');
  }

  static Future<GoldPrice> getLatestGoldPrice() async {
    final response = await http.get(Uri.parse('$baseUrl/gold-prices/latest'));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      return GoldPrice.fromJson(json['data'] as Map<String, dynamic>);
    }

    throw Exception(
      'Gagal mengambil harga emas terbaru: ${response.statusCode}',
    );
  }

  static Future<GoldPrice?> getGoldPriceByCommodity(String commodity) async {
    final prices = await getGoldPrices();

    for (final price in prices) {
      if (price.commodity.toUpperCase() == commodity.toUpperCase()) {
        return price;
      }
    }

    return null;
  }

  static Future<PivotPoint> getPivotPoint(String commodity) async {
    // Backend menerima kode komoditas LGD atau HSI.
    final symbol = commodity.toUpperCase() == 'XAUUSD'
        ? 'LGD'
        : commodity.toUpperCase();

    final response = await http.get(
      Uri.parse(
        '$baseUrl/pivot-points',
      ).replace(queryParameters: {'commodity': symbol}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data pivot point: ${response.statusCode} '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];

      if (data is Map<String, dynamic>) {
        return PivotPoint.fromJson(data);
      }

      if (decoded.containsKey('pivot')) {
        return PivotPoint.fromJson(decoded);
      }
    }

    if (decoded is List) {
      final items = decoded.whereType<Map<String, dynamic>>().toList();

      final matchingItems = items.where(
        (item) =>
            (item['symbol'] ?? item['commodity'] ?? '')
                .toString()
                .toUpperCase() ==
            symbol,
      );

      if (matchingItems.isNotEmpty) {
        return PivotPoint.fromJson(matchingItems.first);
      }
    }

    throw Exception('Format respons Pivot Point tidak sesuai.');
  }
}
