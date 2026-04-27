import 'package:flutter/material.dart';

class AppTheme {
  // ── Core colors ──────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF2196F3);
  static const Color accent        = Color(0xFF00BCD4);
  static const Color gold          = Color(0xFFFFC107);
  static const Color danger        = Color(0xFFF44336);
  static const Color success       = Color(0xFF4CAF50);
  static const Color warning       = Color(0xFFFF9800);

  // ── Backgrounds ───────────────────────────────────────────────────────
  static const Color bg0           = Color(0xFF0A0E1A);
  static const Color bg1           = Color(0xFF0F1623);
  static const Color bg2           = Color(0xFF161D2E);
  static const Color bg3           = Color(0xFF1E2740);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFE8EAF0);
  static const Color textSecondary = Color(0xFF8892A4);

  // ── Theme ─────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg0,
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      error: danger,
      surface: bg1,
    ),
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: textPrimary,   fontSize: 16),
      bodyMedium: TextStyle(color: textPrimary,   fontSize: 14),
      bodySmall:  TextStyle(color: textSecondary, fontSize: 12),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg1,
      foregroundColor: textPrimary,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
  );

  // ── Button styles ──────────────────────────────────────────────────────
  static ButtonStyle glassElevatedButtonStyle({Color? color, double radius = 10}) {
    final c = color ?? primary;
    return ElevatedButton.styleFrom(
      backgroundColor: c.withOpacity(0.15),
      foregroundColor: c,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: c.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }

  static ButtonStyle outlinedButtonStyle({Color? color, double radius = 10}) {
    final c = color ?? primary;
    return OutlinedButton.styleFrom(
      foregroundColor: c,
      side: BorderSide(color: c),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );
  }

  static ButtonStyle dangerButtonStyle({double radius = 10}) =>
      glassElevatedButtonStyle(color: danger, radius: radius);

  static ButtonStyle successButtonStyle({double radius = 10}) =>
      glassElevatedButtonStyle(color: success, radius: radius);

  // ── Card / container decorations ──────────────────────────────────────
  static BoxDecoration cardDecoration({Color? color, double radius = 12}) =>
      BoxDecoration(
        color: color ?? bg1,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFF2A3550), width: 0.5),
      );

  static BoxDecoration glassDecoration({double radius = 12}) =>
      BoxDecoration(
        color: bg2.withOpacity(0.8),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: primary.withOpacity(0.2), width: 0.5),
      );

  /// Glowing card decoration — used in AgentScreen and other AI screens
  static BoxDecoration glowCard({Color? color, double radius = 14, double glowRadius = 12, double glowOpacity = 0.25, double intensity = 1.0}) {
    final c = color ?? primary;
    return BoxDecoration(
      color: bg1,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: c.withOpacity(0.35), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: c.withOpacity(glowOpacity),
          blurRadius: glowRadius,
          spreadRadius: 1,
        ),
      ],
    );
  }

  // ── Text styles ────────────────────────────────────────────────────────
  static const TextStyle headingLarge = TextStyle(
    color: textPrimary, fontSize: 22, fontWeight: FontWeight.bold,
  );
  static const TextStyle headingMedium = TextStyle(
    color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
  );
  static const TextStyle headingSmall = TextStyle(
    color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyRegular = TextStyle(
    color: textPrimary, fontSize: 14,
  );
  static const TextStyle bodyMuted = TextStyle(
    color: textSecondary, fontSize: 13,
  );
  static const TextStyle caption = TextStyle(
    color: textSecondary, fontSize: 11,
  );
  static const TextStyle monoPrice = TextStyle(
    color: textPrimary, fontSize: 16, fontFamily: 'Courier',
    fontWeight: FontWeight.w600,
  );
}



