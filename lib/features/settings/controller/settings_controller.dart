import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/gps_accuracy.dart';
import '../../../models/measurement_unit.dart';

const _themeModeKey = 'theme_mode';
const _measurementUnitKey = 'measurement_unit';
const _gpsAccuracyKey = 'gps_accuracy';

/// Loads and persists app preferences through SharedPreferences.
class SettingsController extends ChangeNotifier {
  SharedPreferences? _preferences;

  ThemeMode themeMode = ThemeMode.light;
  MeasurementUnit measurementUnit = MeasurementUnit.metric;
  GpsAccuracy gpsAccuracy = GpsAccuracy.high;

  Future<void> load() async {
    _preferences = await SharedPreferences.getInstance();
    final preferences = _preferences!;
    final theme = preferences.getString(_themeModeKey);
    final units = preferences.getString(_measurementUnitKey);
    final gps = preferences.getString(_gpsAccuracyKey);

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
    await (_preferences ??= await SharedPreferences.getInstance()).setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> setMeasurementUnit(MeasurementUnit unit) async {
    measurementUnit = unit;
    notifyListeners();
    await (_preferences ??= await SharedPreferences.getInstance()).setString(
      _measurementUnitKey,
      unit == MeasurementUnit.imperial ? 'imperial' : 'metric',
    );
  }

  Future<void> setGpsAccuracy(GpsAccuracy accuracy) async {
    gpsAccuracy = accuracy;
    notifyListeners();
    await (_preferences ??= await SharedPreferences.getInstance()).setString(
      _gpsAccuracyKey,
      accuracy == GpsAccuracy.balanced ? 'balanced' : 'high',
    );
  }
}

final SettingsController settingsController = SettingsController();
