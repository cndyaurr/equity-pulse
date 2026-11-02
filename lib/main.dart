
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/login.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadSavedTheme();

  runApp(const EwfGoldHubApp());
}

class EwfGoldHubApp extends StatelessWidget {
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
          home: const LoginPage(),
        );
      },
    );
  }
}
