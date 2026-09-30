import 'package:flutter/material.dart';

enum AppThemeOption { light, dark, navy }

extension AppThemeOptionX on AppThemeOption {
  String get label {
    switch (this) {
      case AppThemeOption.light:
        return 'Açık';
      case AppThemeOption.dark:
        return 'Koyu';
      case AppThemeOption.navy:
        return 'Lacivert';
    }
  }
}

/// Theme-aware surface/text colors. Status colors (success/error/etc.) stay
/// out of this on purpose — their meaning doesn't change with the theme, only
/// their backgrounds do, and that's computed as an alpha overlay at the call
/// site instead of being baked in here.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color fieldFill;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color navBackground;
  final Color buttonBackground;
  final Color buttonForeground;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.fieldFill,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.navBackground,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  factory AppPalette.forOption(AppThemeOption option, Color accent) {
    switch (option) {
      case AppThemeOption.light:
        return const AppPalette(
          background: Colors.white,
          surface: Color(0xFFF7F7F8),
          fieldFill: Color(0xFFF7F7F8),
          border: Color(0xFFD9D9DE),
          textPrimary: Color(0xFF1A1A1A),
          textSecondary: Color(0xFF8A8A93),
          divider: Color(0xFFEDEDF0),
          navBackground: Colors.white,
          buttonBackground: Color(0xFF1A1A1A),
          buttonForeground: Colors.white,
        );
      case AppThemeOption.dark:
        return AppPalette(
          background: const Color(0xFF121214),
          surface: const Color(0xFF1D1D20),
          fieldFill: const Color(0xFF1D1D20),
          border: const Color(0xFF34343A),
          textPrimary: Colors.white,
          textSecondary: const Color(0xFFA0A0A8),
          divider: const Color(0xFF2A2A2E),
          navBackground: const Color(0xFF1A1A1D),
          buttonBackground: accent,
          buttonForeground: Colors.white,
        );
      case AppThemeOption.navy:
        return const AppPalette(
          background: Color(0xFF0B1B32),
          surface: Color(0xFF122A4A),
          fieldFill: Color(0xFF122A4A),
          border: Color(0xFF23436C),
          textPrimary: Colors.white,
          textSecondary: Color(0xFFA9BBD6),
          divider: Color(0xFF1B3455),
          navBackground: Color(0xFF0E223E),
          buttonBackground: Color(0xFFF7F7F8),
          buttonForeground: Color(0xFF0B1B32),
        );
    }
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? fieldFill,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? navBackground,
    Color? buttonBackground,
    Color? buttonForeground,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      fieldFill: fieldFill ?? this.fieldFill,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      navBackground: navBackground ?? this.navBackground,
      buttonBackground: buttonBackground ?? this.buttonBackground,
      buttonForeground: buttonForeground ?? this.buttonForeground,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      buttonBackground:
          Color.lerp(buttonBackground, other.buttonBackground, t)!,
      buttonForeground:
          Color.lerp(buttonForeground, other.buttonForeground, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  Color get accent => Theme.of(this).colorScheme.primary;
}

/// Curated set of accent ("menu") colors the user can pick from in Settings.
const List<Color> kAccentColorOptions = [
  Color(0xFFF7941D), // brand orange (default)
  Color(0xFF2F6FED), // blue
  Color(0xFF16A34A), // green
  Color(0xFFE0473E), // red
  Color(0xFF9333EA), // purple
  Color(0xFF0D9488), // teal
];
