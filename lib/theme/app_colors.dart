import 'package:flutter/material.dart';

/// Fixed, theme-independent status colors. Their meaning (success = green,
/// failure = red, ...) doesn't change with the selected theme, only the
/// surfaces and text around them do — see [AppPalette] for those.
class AppColors {
  AppColors._();

  static const Color orange = Color(0xFFF7941D);
  static const Color errorRed = Color(0xFFE0473E);
  static const Color success = Color(0xFF2FAE60);
  static const Color pendingBlue = Color(0xFF3B82F6);
}
