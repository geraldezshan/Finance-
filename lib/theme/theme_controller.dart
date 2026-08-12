import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-wide light/dark mode, persisted to the device.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  bool get isDark => mode.value == ThemeMode.dark;

  Future<void> load() async {
    try {
      final v = await _storage.read(key: _key);
      mode.value = v == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      mode.value = ThemeMode.light;
    }
  }

  Future<void> setDark(bool dark) async {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      await _storage.write(key: _key, value: dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
