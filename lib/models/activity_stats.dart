/// Aggregate statistics computed dynamically from all recorded activities.
///
/// Never persisted — always derived fresh from the `Activities` table (see
/// `ActivitiesDao.watchStats`), so it can't drift out of sync with the data.
class ActivityStats {
  const ActivityStats({
    required this.totalActivities,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.totalCalories,
  });

  static const zero = ActivityStats(
    totalActivities: 0,
    totalDistanceMeters: 0,
    totalDurationSeconds: 0,
    totalCalories: 0,
  );

  final int totalActivities;
  final double totalDistanceMeters;
  final int totalDurationSeconds;
  final int totalCalories;

  /// Distance-weighted average speed across all activities, in m/s.
  double get avgSpeedMps =>
      totalDurationSeconds > 0 ? totalDistanceMeters / totalDurationSeconds : 0;

  /// Distance-weighted average pace across all activities, in seconds/km.
  double get avgPaceSecondsPerKm {
    final distanceKm = totalDistanceMeters / 1000;
    return distanceKm > 0 ? totalDurationSeconds / distanceKm : 0;
  }
}
