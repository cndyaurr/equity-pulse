import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/gold_price.dart';
import '../models/pivot_point.dart';

class InvalidAuthTokenException implements Exception {
  const InvalidAuthTokenException();
}

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
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

// ==========================================
// VALIDASI SESSION / PROFILE
// ==========================================

static Future<Map<String, dynamic>> getProfile({
  required String token,
}) async {
  final response = await http
      .get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers(token: token),
      )
      .timeout(timeoutDuration);

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw const InvalidAuthTokenException();
  }

  if (response.statusCode == 200) {
    final decoded = jsonDecode(response.body);

    if (decoded is Map &&
        decoded['success'] == true &&
        decoded['user'] is Map) {
      return Map<String, dynamic>.from(decoded['user'] as Map);
    }
  }

  throw Exception('Gagal memvalidasi sesi pengguna.');
}
  // ==========================================
  // GOLD PRICES
  // ==========================================

  static Future<List<GoldPrice>> getGoldPrices() async {
    final response = await http
        .get(Uri.parse('$baseUrl/gold-prices'), headers: _headers())
        .timeout(timeoutDuration);

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
    final response = await http
        .get(Uri.parse('$baseUrl/gold-prices/latest'), headers: _headers())
        .timeout(timeoutDuration);

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
    final symbol = commodity.toUpperCase() == 'XAUUSD'
        ? 'LGD'
        : commodity.toUpperCase();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/pivot-points',
          ).replace(queryParameters: {'commodity': symbol}),
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

  // ==========================================
  // REGISTER FCM DEVICE TOKEN
  // ==========================================

  static Future<bool> registerDeviceToken({
    required String authToken,
    required String fcmToken,
    String? deviceName,
    String platform = 'android',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/device-token'),
            headers: _headers(token: authToken),
            body: jsonEncode({
              'token': fcmToken,
              'device_name': deviceName,
              'platform': platform,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> && decoded['success'] == true;
      }

      debugPrint(
        'Gagal mendaftarkan FCM token: '
        '${response.statusCode} ${response.body}',
      );

      return false;
    } catch (e) {
      debugPrint('Error register FCM token: $e');
      return false;
    }
  }

  // ==========================================
  // REMOVE FCM DEVICE TOKEN
  // ==========================================

  static Future<bool> removeDeviceToken({
    required String authToken,
    required String fcmToken,
  }) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/device-token'),
            headers: _headers(token: authToken),
            body: jsonEncode({'token': fcmToken}),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> && decoded['success'] == true;
      }

      debugPrint(
        'Gagal menghapus FCM token: '
        '${response.statusCode} ${response.body}',
      );

      return false;
    } catch (e) {
      debugPrint('Error remove FCM token: $e');
      return false;
    }
  }

  // ==========================================
  // REQUEST PASSWORD OTP
  // ==========================================

  static Future<Map<String, dynamic>> requestPasswordOtp({
    required String token,
    required String method,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/profile/password/request-otp'),
            headers: _headers(token: token),
            body: jsonEncode({'method': method}),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return {
          'success': response.statusCode == 200,
          'message': decoded['message'] ?? 'Gagal mengirim kode OTP.',
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

  // ==========================================
  // VERIFY PASSWORD OTP
  // ==========================================

  static Future<Map<String, dynamic>> verifyPasswordOtp({
    required String token,
    required String method,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/profile/password/verify-otp'),
            headers: _headers(token: token),
            body: jsonEncode({'method': method, 'otp': otp}),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return {
          'success': response.statusCode == 200,
          'message': decoded['message'] ?? 'Verifikasi OTP gagal.',
          'verification_token': decoded['verification_token'],
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

  // ==========================================
  // CONFIRM PASSWORD CHANGE
  // ==========================================

  static Future<Map<String, dynamic>> confirmPasswordChange({
    required String token,
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
    String method = 'email',
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/profile/password/confirm'),
            headers: _headers(token: token),
            body: jsonEncode({
              'method': method,
              'verification_token': verificationToken,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      return {
        'success': response.statusCode == 200,
        'message': decoded is Map
            ? decoded['message'] ?? 'Gagal mengubah password.'
            : 'Format respons server tidak sesuai.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Tidak dapat mengubah password: $e'};
    }
  }

  // ==========================================
  // FORGOT PASSWORD - REQUEST OTP
  // ==========================================

  static Future<Map<String, dynamic>> requestForgotPasswordOtp({
    required String email,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/request-otp'),
            headers: _headers(),
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return {
          'success': response.statusCode == 200 && decoded['success'] == true,
          'message': decoded['message'] ?? 'Gagal mengirim OTP.',
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

  // ==========================================
  // FORGOT PASSWORD - VERIFY OTP
  // ==========================================

  static Future<Map<String, dynamic>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/verify-otp'),
            headers: _headers(),
            body: jsonEncode({'email': email.trim(), 'otp': otp.trim()}),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return {
          'success': response.statusCode == 200 && decoded['success'] == true,
          'message': decoded['message'] ?? 'Verifikasi OTP gagal.',
          'verification_token': decoded['verification_token'],
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

  // ==========================================
  // FORGOT PASSWORD - RESET PASSWORD
  // ==========================================

  static Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/forgot-password/reset'),
            headers: _headers(),
            body: jsonEncode({
              'email': email.trim(),
              'verification_token': verificationToken,
              'password': newPassword,
              'password_confirmation': confirmPassword,
            }),
          )
          .timeout(timeoutDuration);

      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return {
          'success': response.statusCode == 200 && decoded['success'] == true,
          'message': decoded['message'] ?? 'Gagal memperbarui password.',
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
        if (response.statusCode == 200 && decoded['success'] == true) {
          return {
            'success': true,
            'message': decoded['message'] ?? 'Kata sandi berhasil diperbarui.',
          };
        }

        return {
          'success': false,
          'message': decoded['message'] ?? 'Gagal memperbarui kata sandi.',
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
