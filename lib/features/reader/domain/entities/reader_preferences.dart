import 'package:flutter/material.dart';

/// Available reading color themes.
enum ReaderThemeMode {
  light,
  sepia,
  night,
  oledBlack,
}

/// Color theme definition for the reading screen.
class ReaderThemeColors {
  final Color background;
  final Color text;
  final Color secondaryText;
  final Color accent;
  final Color cardBackground;
  final Color divider;

  const ReaderThemeColors({
    required this.background,
    required this.text,
    required this.secondaryText,
    required this.accent,
    required this.cardBackground,
    required this.divider,
  });

  static const light = ReaderThemeColors(
    background: Color(0xFFFAF9F6),
    text: Color(0xFF1C1917),
    secondaryText: Color(0xFF78716C),
    accent: Color(0xFF2563EB),
    cardBackground: Color(0xFFFFFFFF),
    divider: Color(0xFFE7E5E4),
  );

  static const sepia = ReaderThemeColors(
    background: Color(0xFFF4ECD8),
    text: Color(0xFF382F24),
    secondaryText: Color(0xFF7D705C),
    accent: Color(0xFF9A5B2D),
    cardBackground: Color(0xFFEADFC9),
    divider: Color(0xFFDACBB0),
  );

  static const night = ReaderThemeColors(
    background: Color(0xFF1E2022),
    text: Color(0xFFE2E8F0),
    secondaryText: Color(0xFF94A3B8),
    accent: Color(0xFF60A5FA),
    cardBackground: Color(0xFF2B2D30),
    divider: Color(0xFF3B3E43),
  );

  static const oledBlack = ReaderThemeColors(
    background: Color(0xFF000000),
    text: Color(0xFFD4D4D8),
    secondaryText: Color(0xFF71717A),
    accent: Color(0xFF38BDF8),
    cardBackground: Color(0xFF121212),
    divider: Color(0xFF27272A),
  );

  static ReaderThemeColors forMode(ReaderThemeMode mode) {
    switch (mode) {
      case ReaderThemeMode.light:
        return light;
      case ReaderThemeMode.sepia:
        return sepia;
      case ReaderThemeMode.night:
        return night;
      case ReaderThemeMode.oledBlack:
        return oledBlack;
    }
  }
}

/// User reading preferences.
class ReaderPreferences {
  final double fontSize;
  final double lineHeight;
  final String fontFamily;
  final ReaderThemeMode themeMode;
  final double horizontalPadding;

  const ReaderPreferences({
    this.fontSize = 18.0,
    this.lineHeight = 1.6,
    this.fontFamily = 'Default',
    this.themeMode = ReaderThemeMode.light,
    this.horizontalPadding = 20.0,
  });

  ReaderThemeColors get colors => ReaderThemeColors.forMode(themeMode);

  ReaderPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    String? fontFamily,
    ReaderThemeMode? themeMode,
    double? horizontalPadding,
  }) {
    return ReaderPreferences(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      fontFamily: fontFamily ?? this.fontFamily,
      themeMode: themeMode ?? this.themeMode,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    );
  }
}
