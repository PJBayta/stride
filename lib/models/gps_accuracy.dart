/// GPS tracking accuracy preference. Experimental: both modes currently use
/// the same [LocationAccuracy.high] under the hood and only differ in how
/// far the device must move before a new fix is delivered. May change once
/// tuned from real-world testing.
enum GpsAccuracy {
  high(
    'High Accuracy',
    'Best for outdoor activity tracking',
    distanceFilter: 2,
  ),
  balanced('Balanced', 'Optimized battery usage', distanceFilter: 5);

  const GpsAccuracy(this.title, this.subtitle, {required this.distanceFilter});

  final String title;
  final String subtitle;

  /// Minimum distance, in meters, the device must move before a new GPS
  /// reading is delivered.
  final int distanceFilter;
}
