
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gold_price.dart';
import '../models/pivot_point.dart';

class ApiService {
  // ==========================================
  // BASE URL
  // ==========================================

  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static const Duration timeoutDuration = Duration(seconds: 20);

  // ==========================================
  // HTTP HEADERS
  // ==========================================

  static Map<String, String> _headers({String? token}) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // GOLD PRICES
  // ==========================================

  static Future<List<GoldPrice>> getGoldPrices() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/gold-prices'),
          headers: _headers(),
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> data = json['data'] ?? [];

      return data
          .map(
            (item) => GoldPrice.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil data harga emas: ${response.statusCode}',
    );
  }

  static Future<GoldPrice> getLatestGoldPrice() async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/gold-prices/latest'),
          headers: _headers(),
        )
        .timeout(timeoutDuration);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      return GoldPrice.fromJson(
        json['data'] as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Gagal mengambil harga emas terbaru: ${response.statusCode}',
    );
  }

  static Future<GoldPrice?> getGoldPriceByCommodity(
    String commodity,
  ) async {
    final prices = await getGoldPrices();

    for (final price in prices) {
      if (price.commodity.toUpperCase() ==
          commodity.toUpperCase()) {
        return price;
      }
    }

    return null;
  }

  // ==========================================
  // PIVOT POINT
  // ==========================================

  static Future<PivotPoint> getPivotPoint(
    String commodity,
  ) async {
    final symbol = commodity.toUpperCase() == 'XAUUSD'
        ? 'LGD'
        : commodity.toUpperCase();

    final response = await http
        .get(
          Uri.parse('$baseUrl/pivot-points').replace(
            queryParameters: {
              'commodity': symbol,
            },
          ),
          headers: _headers(),
        )
        .timeout(timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data pivot point: '
        '${response.statusCode} ${response.body}',
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
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .toList();

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

    throw Exception(
      'Format respons Pivot Point tidak sesuai.',
    );
  }

  // ==========================================
  // CHANGE PASSWORD
  // ==========================================

  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/change-password'),
            headers: _headers(token: token),
            body: jsonEncode({
              'current_password': currentPassword,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }),
          )
          .timeout(timeoutDuration);

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        if (response.statusCode == 200 &&
            decoded['success'] == true) {
          return {
            'success': true,
            'message': decoded['message'] ??
                'Kata sandi berhasil diperbarui.',
          };
        }

        return {
          'success': false,
          'message': decoded['message'] ??
              'Gagal memperbarui kata sandi.',
        };
      }

      return {
        'success': false,
        'message': 'Format respons server tidak sesuai.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server: $e',
      };
    }
  }
}
