import 'package:flutter/material.dart';
import 'app_theme.dart';

class AppColors {
  // Direct const-compatible color values (use these inside const widgets)
  static const Color primary       = AppTheme.primary;
  static const Color accent        = AppTheme.accent;
  static const Color gold          = AppTheme.gold;
  static const Color danger        = AppTheme.danger;
  static const Color success       = AppTheme.success;
  static const Color warning       = AppTheme.warning;
  static const Color bg0           = AppTheme.bg0;
  static const Color bg1           = AppTheme.bg1;
  static const Color bg2           = AppTheme.bg2;
  static const Color bg3           = AppTheme.bg3;
  static const Color textPrimary   = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted      = AppTheme.textSecondary;

  // Named aliases (also const)
  static const Color primaryBlue   = AppTheme.primary;
  static const Color primaryGreen  = AppTheme.success;
  static const Color primaryGold   = AppTheme.gold;
  static const Color primaryRed    = AppTheme.danger;
  static const Color primaryOrange = AppTheme.warning;
  static const Color primaryCyan   = AppTheme.accent;

  // UI semantic colors
  static const Color border        = Color(0xFF2A3550);
  static const Color borderColor   = Color(0xFF2A3550);
  static const Color divider       = Color(0xFF2A3550);
  static const Color cardBg        = AppTheme.bg1;
  static const Color inputFill     = AppTheme.bg2;
  static const Color iconColor     = AppTheme.textSecondary;
  static const Color activeTab     = AppTheme.primary;
  static const Color inactiveTab   = AppTheme.textSecondary;

  // Trading semantic colors
  static const Color buyColor      = AppTheme.success;
  static const Color sellColor     = AppTheme.danger;
  static const Color profitColor   = AppTheme.success;
  static const Color lossColor     = AppTheme.danger;
  static const Color neutralColor  = AppTheme.warning;
  static const Color chartLine     = AppTheme.primary;
  static const Color stopButton    = AppTheme.danger;
  static const Color priorityHigh  = AppTheme.danger;
  static const Color priorityMedium = AppTheme.warning;
  static const Color priorityLow   = AppTheme.success;

  // Non-const (require withOpacity etc)
  static Color get shadowColor     => Colors.black54;
  static Color get overlayColor    => Colors.black87;
  static Color get shimmerBase     => AppTheme.bg2;
  static Color get shimmerHigh     => AppTheme.bg3;
}

