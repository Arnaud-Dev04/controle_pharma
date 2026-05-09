/// Point d'entrée de l'application Contrôle Pharma
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

import 'providers/controle_provider.dart';
import 'providers/pharmacie_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/pharmacie_selection_screen.dart';
import 'screens/unlock_screen.dart';
import 'utils/constants.dart';
import 'utils/scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser les données de locale pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);

  // Initialiser SQLite pour le web
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Vérifier si l'application a déjà été déverrouillée
  final prefs = await SharedPreferences.getInstance();
  final isUnlocked = prefs.getBool(kUnlockKey) ?? false;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ControlePharmaApp(isUnlocked: isUnlocked));
}

class ControlePharmaApp extends StatelessWidget {
  /// true si l'app a déjà été déverrouillée (SharedPreferences)
  final bool isUnlocked;

  const ControlePharmaApp({super.key, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ControleProvider()),
        ChangeNotifierProvider(create: (_) => PharmacieProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: kAppName,
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            scrollBehavior: AppScrollBehavior(),

            // ============================================================
            // 🌞 THÈME CLAIR
            // ============================================================
            theme: _buildTheme(Brightness.light),

            // ============================================================
            // 🌙 THÈME SOMBRE
            // ============================================================
            darkTheme: _buildTheme(Brightness.dark),

            // Si déjà déverrouillée → sélection pharmacie
            // Sinon → écran d'activation (one-time)
            home: isUnlocked
                ? const PharmacieSelectionScreen()
                : const UnlockScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      brightness: brightness,
      primary: kPrimaryColor,
      error: kDangerColor,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      scaffoldBackgroundColor: isDark
          ? const Color(0xFF121212)
          : kBackgroundColor,

      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: kFontSizeXL,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E1E1E) : kCardColor,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(isDark ? 50 : 25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: kPaddingL,
            vertical: kPaddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: kFontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kPaddingM,
          vertical: kPaddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : kBorderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : kBorderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kDangerColor),
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : kTextSecondary,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey.shade800 : kBorderColor,
        thickness: 1,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
