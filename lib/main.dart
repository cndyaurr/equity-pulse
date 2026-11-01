
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/login.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

const Color ewfOrange = Color(0xFFF58220);
const Color ewfOrangeDark = Color(0xFFD96812);
const Color ewfOrangeLight = Color(0xFFFFF3E8);
const Color ewfBackground = Color(0xFFF8FAFC);

void main() {
  runApp(const EwfGoldHubApp());
}

class EwfGoldHubApp extends StatelessWidget {
  const EwfGoldHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ewfOrange,
      brightness: Brightness.light,
    ).copyWith(
      primary: ewfOrange,
      onPrimary: Colors.white,
      secondary: ewfOrangeDark,
      surface: Colors.white,
    );

   return MaterialApp(
  navigatorKey: navigatorKey,
  debugShowCheckedModeBanner: false,
      title: 'EWF Gold Hub',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,

        // Font global seluruh aplikasi
        fontFamily: GoogleFonts.roboto().fontFamily,
        textTheme: GoogleFonts.robotoTextTheme(),

        scaffoldBackgroundColor: ewfBackground,

        appBarTheme: const AppBarTheme(
          backgroundColor: ewfBackground,
          foregroundColor: Color(0xFF1F2937),
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
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        overscroll: false,
      ),
      home: const LoginPage(),
    );
  }
}
