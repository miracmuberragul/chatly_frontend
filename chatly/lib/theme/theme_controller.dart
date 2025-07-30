import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _mode;
  ThemeController(this._mode);

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    debugPrint('ThemeController.setMode -> $_mode'); // <--- log
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode', _mode.index);
    } catch (_) {}
  }

  static Future<ThemeController> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt('theme_mode');
      final ThemeMode mode = switch (idx) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      debugPrint('ThemeController.init -> $mode'); // <--- log
      return ThemeController(mode);
    } catch (_) {
      return ThemeController(ThemeMode.system);
    }
  }
}
