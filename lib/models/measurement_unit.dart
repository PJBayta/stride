/// The unit system used to display distance, speed, and pace throughout
/// the app. Persisted via [SettingsController]; nothing computes or stores
/// data in these units — conversion happens only at display time.
enum MeasurementUnit {
  metric('Metric (km, m)', 'Standard international units'),
  imperial('Imperial (mi, ft)', 'Customary units');

  const MeasurementUnit(this.title, this.subtitle);

  final String title;
  final String subtitle;

  String get distanceLabel => this == MeasurementUnit.imperial ? 'mi' : 'km';
  String get speedLabel => this == MeasurementUnit.imperial ? 'mph' : 'km/h';
  String get paceLabel => this == MeasurementUnit.imperial ? '/mi' : '/km';

  /// Converts a distance in meters to this unit system's distance unit.
  double distanceFromMeters(double meters) =>
      this == MeasurementUnit.imperial ? meters / 1609.344 : meters / 1000;

  /// Converts a speed in meters/second to this unit system's speed unit.
  double speedFromMetersPerSecond(double metersPerSecond) =>
      this == MeasurementUnit.imperial
      ? metersPerSecond * 2.236936
      : metersPerSecond * 3.6;

  /// Converts a seconds-per-kilometer pace to seconds-per-[distanceLabel].
  double paceFromSecondsPerKm(double secondsPerKm) =>
      this == MeasurementUnit.imperial ? secondsPerKm * 1.609344 : secondsPerKm;
}
