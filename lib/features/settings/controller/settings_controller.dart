import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/daos/settings_dao.dart';
import '../../../models/gps_accuracy.dart';
import '../../../models/measurement_unit.dart';

const _themeModeKey = 'theme_mode';
const _measurementUnitKey = 'measurement_unit';
const _gpsAccuracyKey = 'gps_accuracy';

/// Loads and persists user-facing app settings (theme, units, GPS accuracy)
/// through the existing `Settings` key/value table.
///
/// The Settings screen only reads this controller's state and calls its
/// setters — it doesn't talk to [SettingsDao] directly.
class SettingsController extends ChangeNotifier {
  SettingsController(this._dao);

  final SettingsDao _dao;

  ThemeMode themeMode = ThemeMode.light;
  MeasurementUnit measurementUnit = MeasurementUnit.metric;
  GpsAccuracy gpsAccuracy = GpsAccuracy.high;

  /// Loads persisted values, if any. Call once at app startup, before the
  /// first frame, so the UI never flashes the defaults then jumps.
  Future<void> load() async {
    final theme = await _dao.getValue(_themeModeKey);
    final units = await _dao.getValue(_measurementUnitKey);
    final gps = await _dao.getValue(_gpsAccuracyKey);

    themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    measurementUnit = units == 'imperial'
        ? MeasurementUnit.imperial
        : MeasurementUnit.metric;
    gpsAccuracy = gps == 'balanced' ? GpsAccuracy.balanced : GpsAccuracy.high;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _dao.setValue(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setMeasurementUnit(MeasurementUnit unit) async {
    measurementUnit = unit;
    notifyListeners();
    await _dao.setValue(
      _measurementUnitKey,
      unit == MeasurementUnit.imperial ? 'imperial' : 'metric',
    );
  }

  Future<void> setGpsAccuracy(GpsAccuracy accuracy) async {
    gpsAccuracy = accuracy;
    notifyListeners();
    await _dao.setValue(
      _gpsAccuracyKey,
      accuracy == GpsAccuracy.balanced ? 'balanced' : 'high',
    );
  }
}

SettingsController? _settingsControllerInstance;

/// The single [SettingsController] instance used by the app.
SettingsController get settingsController =>
    _settingsControllerInstance ??= SettingsController(appDatabase.settingsDao);
