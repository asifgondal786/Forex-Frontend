// lib/core/theme/app_colors.dart
// Alias layer — keeps AppColors.X compiling while screens migrate to AppTheme.X
// DO NOT import config/theme.dart — that file is deleted.
// This file's ONLY job is to re-export AppTheme constants under the old names.

import 'app_theme.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Primary palette ────────────────────────────────────────────────────────
  static const primary        = AppTheme.primary;       // #00D4AA teal
  static const accent         = AppTheme.accent;        // #7C5CFC purple
  static const gold           = AppTheme.gold;          // #FFB800
  static const danger         = AppTheme.danger;        // #FF4757
  static const success        = AppTheme.success;       // #2ED573
  static const warning        = AppTheme.warning;       // #FF6B35

  // ── Background layers ──────────────────────────────────────────────────────
  static const bg0            = AppTheme.bg0;           // #090E1A  scaffold
  static const bg1            = AppTheme.bg1;           // #0D1421  card
  static const bg2            = AppTheme.bg2;           // #111927  elevated card
  static const bg3            = AppTheme.bg3;           // #1A2235  input / chip

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary    = AppTheme.textPrimary;   // #EEF2FF
  static const textSecondary  = AppTheme.textSecondary; // #8892B0

  // ── Legacy aliases (old names → new values) ────────────────────────────────
  static const darkBlue         = AppTheme.bg0;
  static const primaryBlue      = AppTheme.primary;
  static const primaryGreen     = AppTheme.success;
  static const successGreen     = AppTheme.success;
  static const errorRed         = AppTheme.danger;
  static const backgroundDark   = AppTheme.bg0;
  static const cardDark         = AppTheme.bg1;
  static const textMuted        = AppTheme.textSecondary;
  static const surface          = AppTheme.bg1;
  static const surfaceVariant   = AppTheme.bg2;
  static const border           = AppTheme.bg3;
}