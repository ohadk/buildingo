import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Buildingo "Organic" design system — exact tokens from /Buildingo design:
/// linen ground, terracotta accent, sage second accent, gold highlights.
class DiraColors {
  static const cream = Color(0xFFFAF3E0); // page ground
  static const creamCard = Color(0xFFFFFBF2); // neutral-100 cards
  static const creamDeep = Color(0xFFF2E8D6); // neutral-200

  static const terracotta = Color(0xFFC9705C); // accent-400
  static const terracottaSoft = Color(0xFFF3D9D1); // accent-200
  static const terracottaBlush = Color(0xFFE8B9AC); // accent-300
  static const brick = Color(0xFFA34A3A); // accent-500
  static const brickDark = Color(0xFF7A3427); // accent-700
  static const brickDeep = Color(0xFF431C15); // accent-900

  static const sage = Color(0xFF6B8A6B); // accent-2-500
  static const sageMist = Color(0xFF8FA98D); // accent-2-400
  static const sageDark = Color(0xFF4F6D4F); // accent-2-700
  static const sageDeep = Color(0xFF354A35); // accent-2-900 (nav chrome)
  static const sageLight = Color(0xFFDCE5D9); // accent-2-200
  static const sagePale = Color(0xFFEEF2EA); // accent-2-100

  static const gold = Color(0xFFD9B382); // gold-500
  static const goldLight = Color(0xFFF2E2C6); // gold-200
  static const goldDark = Color(0xFF6E5433); // gold-800

  static const ink = Color(0xFF241C18);
  static const inkSoft = Color(0xFF7F7360); // neutral-600
}

/// Suez One display face for headings (matches --font-heading).
TextStyle heading({
  double fontSize = 20,
  Color color = DiraColors.ink,
  double? height,
}) => GoogleFonts.suezOne(fontSize: fontSize, color: color, height: height);

ThemeData buildDiraTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: DiraColors.brick,
      primary: DiraColors.brick,
      secondary: DiraColors.sage,
      surface: DiraColors.cream,
    ),
    scaffoldBackgroundColor: DiraColors.cream,
  );
  final heeboText = GoogleFonts.heeboTextTheme(
    base.textTheme,
  ).apply(bodyColor: DiraColors.ink, displayColor: DiraColors.ink);
  return base.copyWith(
    textTheme: heeboText.copyWith(
      headlineLarge: GoogleFonts.suezOne(textStyle: heeboText.headlineLarge),
      headlineMedium: GoogleFonts.suezOne(textStyle: heeboText.headlineMedium),
      headlineSmall: GoogleFonts.suezOne(textStyle: heeboText.headlineSmall),
      titleLarge: GoogleFonts.suezOne(textStyle: heeboText.titleLarge),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: DiraColors.ink,
      elevation: 0,
      titleTextStyle: GoogleFonts.suezOne(fontSize: 20, color: DiraColors.ink),
    ),
    cardTheme: const CardThemeData(
      color: DiraColors.creamCard,
      elevation: 1.5,
      shadowColor: Color(0x1F2B261F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DiraColors.brick,
        foregroundColor: DiraColors.creamCard,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.heebo(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DiraColors.creamDeep,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: DiraColors.brick),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: DiraColors.ink.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: const BorderSide(color: DiraColors.brick, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: DiraColors.sageDeep,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: DiraColors.brick,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
  );
}

/// Blush header wash from the design: accent-300 → accent-200.
const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [DiraColors.terracottaBlush, DiraColors.terracottaSoft],
);
