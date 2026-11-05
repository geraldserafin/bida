import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the households on the dashboard show (F38): the calendar month, the
/// current period of the chosen household, or a range of days.
enum DashboardRange { month, period, custom }

/// User preferences: theme, the last household and what the dashboard shows.
/// Persisted in secure storage (small, device-local, no server).
class AppSettings extends ChangeNotifier {
  static const _kThemeMode = 'pref_theme_mode';
  static const _kHousehold = 'pref_household';
  static const _kRange = 'pref_dashboard_range';
  static const _kFrom = 'pref_dashboard_from';
  static const _kTo = 'pref_dashboard_to';

  final FlutterSecureStorage _storage;

  AppSettings({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  /// The household chosen last (F06); null before there is one.
  String? _householdId;
  String? get householdId => _householdId;

  DashboardRange _range = DashboardRange.month;
  DashboardRange get dashboardRange => _range;

  DateTime? _from;
  DateTime? _to;

  /// The days of a custom range, both included.
  DateTimeRange? get customRange => _from == null || _to == null
      ? null
      : DateTimeRange(start: _from!, end: _to!);

  Future<void> load() async {
    final tm = await _storage.read(key: _kThemeMode);
    _themeMode = switch (tm) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    _householdId = await _storage.read(key: _kHousehold);
    _range =
        DashboardRange.values.asNameMap()[await _storage.read(key: _kRange)] ??
        DashboardRange.month;
    _from = DateTime.tryParse(await _storage.read(key: _kFrom) ?? '');
    _to = DateTime.tryParse(await _storage.read(key: _kTo) ?? '');
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.write(key: _kThemeMode, value: mode.name);
  }

  Future<void> setHousehold(String? id) async {
    if (id == _householdId) return;
    _householdId = id;
    notifyListeners();
    if (id == null) {
      await _storage.delete(key: _kHousehold);
    } else {
      await _storage.write(key: _kHousehold, value: id);
    }
  }

  Future<void> setDashboardRange(
    DashboardRange range, {
    DateTimeRange? custom,
  }) async {
    _range = range;
    if (custom != null) {
      _from = custom.start;
      _to = custom.end;
      await _storage.write(key: _kFrom, value: custom.start.toIso8601String());
      await _storage.write(key: _kTo, value: custom.end.toIso8601String());
    }
    notifyListeners();
    await _storage.write(key: _kRange, value: range.name);
  }
}
