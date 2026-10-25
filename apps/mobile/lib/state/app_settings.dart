import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// User preferences: theme mode and the day the budgeting month starts on.
/// Persisted in secure storage (small, device-local, no server).
class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'pref_theme_mode';
  static const _kFirstDay = 'pref_first_day';

  final FlutterSecureStorage _storage;

  AppSettings({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  int _firstDayOfMonth = 1;
  int get firstDayOfMonth => _firstDayOfMonth;

  Future<void> load() async {
    final tm = await _storage.read(key: _kThemeMode);
    _themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    final fd = int.tryParse(await _storage.read(key: _kFirstDay) ?? '');
    if (fd != null && fd >= 1 && fd <= 28) _firstDayOfMonth = fd;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.write(key: _kThemeMode, value: mode.name);
  }

  Future<void> setFirstDayOfMonth(int day) async {
    if (day < 1 || day > 28 || day == _firstDayOfMonth) return;
    _firstDayOfMonth = day;
    notifyListeners();
    await _storage.write(key: _kFirstDay, value: '$day');
  }
}
