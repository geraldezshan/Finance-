import 'package:flutter/material.dart';

/// Central place for the Finance+ color palette and theme.
class AppColors {
  static const Color primary = Color(0xFF2E9E3F); // logo / nav green
  static const Color primaryDark = Color(0xFF1F7A2E);
  static const Color accent = Color(0xFF4CD137); // brighter START green
  static const Color bg = Color(0xFFF7F9F7);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF1C2A1F);
  static const Color textGrey = Color(0xFF7A867C);
  static const Color border = Color(0xFFE2E8E3);

  // Per-category colors used in the donut chart / bars.
  static const Map<String, Color> category = {
    'Needs': Color(0xFF1F7A2E),
    'Wants': Color(0xFF4CD137),
    'Debt': Color(0xFF8BC34A),
    'Savings': Color(0xFF66BB6A),
    'Tithes': Color(0xFFA5D6A7),
  };
}

class AppTheme {
  static final ThemeData _light = _build(
      brightness: Brightness.light,
      scaffold: AppColors.bg,
      appBarFg: AppColors.textDark);
  static final ThemeData _dark = _build(
      brightness: Brightness.dark,
      scaffold: const Color(0xFF14201A),
      appBarFg: Colors.white);

  static ThemeData get light => _light;

  /// Dark mode is a real dark theme, so text on the page background flips
  /// automatically. White cards (SoftCard) force their own light context.
  static ThemeData get dark => _dark;

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color appBarFg,
  }) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: brightness,
      ),
      // Transparent so the app-wide background (color / gradient / image,
      // chosen in Settings) shows through every screen. The default
      // background paints these same [scaffold] colors, so nothing changes
      // until the user picks a custom background.
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: appBarFg,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}