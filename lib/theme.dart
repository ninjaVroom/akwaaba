import 'package:flutter/material.dart';

// Tokens from outputs/figma/akwaaba.design.json (colours read from the 2023 store screenshots).
class Ak {
  static const primary = Color(0xFFE8820C);
  static const logo = Color(0xFFF7931E);
  static const bg = Color(0xFFF4F4F4);
  static const surface = Colors.white;
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF555555);
  static const line = Color(0xFFE0E0E0);
  static const field = Color(0xFFEAEAEA);
  static const dark = Color(0xFF212121);
  static const tab = Color(0xFF3A3A3A);
  static const success = Color(0xFF4CAF50);
  static const link = Color(0xFF1E88E5);
  static const danger = Color(0xFFE53935);
  static const neutral = Color(0xFF9E9E9E);
  static const tint = Color(0xFFFFF3E0);
  static const lightText = Color(0xFFCCCCCC);
  static const whatsapp = Color(0xFF25D366);
  static const dangerTint = Color(0xFFFADBD8);

  static const radius = 16.0;
  static const shadow = [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))];
}

ThemeData akTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Ak.primary, primary: Ak.primary, surface: Ak.bg),
    scaffoldBackgroundColor: Ak.bg,
    // Bundled so web gets real weights (its fallback Roboto is regular-only, bolds render faked).
    fontFamily: 'Roboto',
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Ak.primary,
      foregroundColor: Ak.ink,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Ak.ink),
    ),
    radioTheme: RadioThemeData(fillColor: WidgetStateProperty.all(Ak.primary)),
    checkboxTheme: CheckboxThemeData(
      shape: const CircleBorder(),
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Ak.primary : null),
      side: const BorderSide(color: Ak.neutral, width: 1.5),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Ak.dark),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: Ak.primary),
  );
}
