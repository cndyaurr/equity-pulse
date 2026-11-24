import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/login.dart';
import 'dart:convert';
import 'pages/dashboard_page.dart';
import 'services/api_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

const Color ewfOrange = Color(0xFFF58220);
const Color ewfOrangeDark = Color(0xFFD96812);
const Color ewfOrangeLight = Color(0xFFFFF3E8);
const Color ewfBackground = Color(0xFFF8FAFC);

// Pengaturan tema global.
final ValueNotifier<ThemeMode> themeModeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.light);

const String themePreferenceKey = 'app_theme_mode';

Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString(themePreferenceKey);

  themeModeNotifier.value =
      savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
}

Future<void> changeAppTheme(ThemeMode mode) async {
  themeModeNotifier.value = mode;

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    themePreferenceKey,
    mode == ThemeMode.dark ? 'dark' : 'light',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inisialisasi Firebase Cloud Messaging dan notifikasi lokal.
  await NotificationService.initialize();
// Mengambil token perangkat untuk Firebase Cloud Messaging.
final fcmToken = await NotificationService.getDeviceToken();

if (fcmToken != null) {
  debugPrint('FCM TOKEN BERHASIL DIDAPATKAN');
} else {
  debugPrint('FCM TOKEN BELUM TERSEDIA');
}

// Memantau perubahan token perangkat.
NotificationService.onTokenRefresh.listen((newToken) {
  debugPrint('FCM TOKEN DIPERBARUI');
});

  // Inisialisasi format tanggal Bahasa Indonesia untuk PDF.
  await initializeDateFormatting('id_ID', null);

  // Memuat pengaturan tema yang tersimpan.
  await loadSavedTheme();

  runApp(const EwfGoldHubApp());
}class EwfGoldHubApp extends StatelessWidget {
  const EwfGoldHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: ewfOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: ewfOrange,
      onPrimary: Colors.white,
      secondary: ewfOrangeDark,
      surface: Colors.white,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: ewfOrange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: ewfOrange,
      onPrimary: Colors.white,
      secondary: const Color(0xFFFFA45C),
      surface: const Color(0xFF1E293B),
    );

    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      fontFamily: GoogleFonts.roboto().fontFamily,
      textTheme: GoogleFonts.robotoTextTheme(),
      scaffoldBackgroundColor: ewfBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: ewfBackground,
        foregroundColor: Color(0xFF1F2937),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ewfOrange,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: ewfOrange,
        foregroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? ewfOrange
              : null;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ewfOrange,
      ),
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      fontFamily: GoogleFonts.roboto().fontFamily,
      textTheme: GoogleFonts.robotoTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: const Color(0xFFF1F5F9),
        displayColor: const Color(0xFFF1F5F9),
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Color(0xFFF1F5F9),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E293B),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ewfOrange,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: ewfOrange,
        foregroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? ewfOrange
              : null;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ewfOrange,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
      ),
    );

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'EWF Gold Hub',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentMode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            overscroll: false,
          ),
         home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? destination;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberSession =
        prefs.getBool('remember_session') ?? true;

    if (!rememberSession) {
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      if (!mounted) return;

      setState(() {
        destination = const LoginPage();
      });
      return;
    }

    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        destination = const LoginPage();
      });
      return;
    }

    Map<String, dynamic>? cachedUser;

    final savedUser = prefs.getString('user_data');

    if (savedUser != null && savedUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(savedUser);

        if (decoded is Map) {
          cachedUser = Map<String, dynamic>.from(decoded);
        }
      } catch (e) {
        debugPrint('Gagal membaca data pengguna: $e');
      }
    }

    try {
      final user = await ApiService.getProfile(token: token);

      await prefs.setString('user_data', jsonEncode(user));

      if (!mounted) return;

      setState(() {
        destination = DashboardPage(user: user);
      });
    } on InvalidAuthTokenException {
      await prefs.remove('auth_token');
      await prefs.remove('user_data');

      if (!mounted) return;

      setState(() {
        destination = const LoginPage();
      });
    } catch (e) {
      debugPrint('Validasi sesi gagal: $e');

      if (!mounted) return;

      setState(() {
        destination = cachedUser != null
            ? DashboardPage(user: cachedUser)
            : const LoginPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (destination != null) {
      return destination!;
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: ewfOrange,
        ),
      ),
    );
  }
}