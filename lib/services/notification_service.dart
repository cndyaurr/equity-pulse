
import 'dart:convert';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';

/// Handler untuk pesan yang diterima ketika aplikasi berada
/// di background atau tidak sedang terbuka.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Pesan FCM diterima di background: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static const String channelId = 'equickly_high_importance';
  static const String channelName = 'EQUICKLY Notifications';
  static const String channelDescription =
      'Notifikasi berita, harga emas, dan informasi pasar EQUICKLY';

  /// Menyimpan pesan terakhir yang diterima.
  /// Nantinya dapat digunakan untuk menampilkan popup di dalam aplikasi.
  static final ValueNotifier<RemoteMessage?> latestMessage =
      ValueNotifier<RemoteMessage?>(null);

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    // Meminta izin notifikasi.
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Inisialisasi notifikasi lokal.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
    );

    // Membuat channel Android.
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Mendaftarkan handler background.
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Pesan yang diterima saat aplikasi terbuka.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      latestMessage.value = message;
      _showLocalNotification(message);
    });

    // Pengguna menekan notifikasi ketika aplikasi berada di background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      latestMessage.value = message;
    });
// Mendaftarkan token baru ketika Firebase memperbaruinya.
// ignore: deprecated_member_use
_messaging.onTokenRefresh.listen((newToken) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');

    // Hanya daftarkan jika pengguna masih login.
    if (authToken == null || authToken.isEmpty) {
      debugPrint('Token FCM diperbarui, pengguna belum login.');
      return;
    }

    final registered = await ApiService.registerDeviceToken(
      authToken: authToken,
      fcmToken: newToken,
      platform: 'android',
    );

    debugPrint(
      registered
          ? 'FCM token terbaru berhasil didaftarkan.'
          : 'Gagal mendaftarkan FCM token terbaru.',
    );
  } catch (e) {
    debugPrint('Error memperbarui FCM token: $e');
  }
});

    // Pengguna membuka aplikasi melalui notifikasi ketika aplikasi tertutup.
    final initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      latestMessage.value = initialMessage;
    }

    _initialized = true;

    debugPrint('NotificationService berhasil diinisialisasi.');
  }

  static Future<String?> getDeviceToken() async {
  // ignore: deprecated_member_use
  final token = await _messaging.getToken();

  debugPrint('FCM DEVICE TOKEN: $token');

  return token;
}

static Stream<String> get onTokenRefresh {
  // ignore: deprecated_member_use
  return _messaging.onTokenRefresh;
}

  /// Menampilkan notifikasi lokal ketika aplikasi sedang terbuka.
  static Future<void> _showLocalNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    final title = notification?.title ??
        message.data['title']?.toString() ??
        'EQUICKLY';

    final body = notification?.body ??
        message.data['body']?.toString() ??
        'Ada informasi terbaru untuk Anda.';

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(2147483647);

    await _localNotifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }
}
