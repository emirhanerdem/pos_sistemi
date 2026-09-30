import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import 'app_palette.dart';

/// App-wide theme state (theme option + accent/menu color), persisted to
/// the SQLite `app_settings` table so the choice survives app restarts.
class ThemeController extends ChangeNotifier {
  ThemeController._internal();
  static final ThemeController instance = ThemeController._internal();

  static const _themeKey = 'theme_option';
  static const _accentKey = 'accent_color';

  AppThemeOption _option = AppThemeOption.light;
  Color _accent = kAccentColorOptions.first;
  bool _loaded = false;

  AppThemeOption get option => _option;
  Color get accent => _accent;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final storedOption = await DatabaseHelper.instance.getSetting(_themeKey);
    final storedAccent = await DatabaseHelper.instance.getSetting(_accentKey);

    if (storedOption != null) {
      _option = AppThemeOption.values.firstWhere(
        (o) => o.name == storedOption,
        orElse: () => AppThemeOption.light,
      );
    }
    if (storedAccent != null) {
      final value = int.tryParse(storedAccent);
      if (value != null) _accent = Color(value);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setOption(AppThemeOption option) async {
    if (option == _option) return;
    _option = option;
    notifyListeners();
    await DatabaseHelper.instance.setSetting(_themeKey, option.name);
  }

  Future<void> setAccent(Color color) async {
    if (color.toARGB32() == _accent.toARGB32()) return;
    _accent = color;
    notifyListeners();
    await DatabaseHelper.instance.setSetting(
      _accentKey,
      color.toARGB32().toString(),
    );
  }
}
