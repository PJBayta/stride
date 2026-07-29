import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as latlong;

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../features/settings/controller/settings_controller.dart';
import '../../../models/activity_type.dart';
import '../../../models/finished_session.dart';
import 'route_map_view.dart';

/// Matches the Material bottom-sheet motion for both opening and dismissal.
const summarySheetAnimationStyle = AnimationStyle(
  duration: Duration(milliseconds: 320),
  reverseDuration: Duration(milliseconds: 240),
);

/// Shows [SessionSummarySheet] for an already-saved activity, e.g. when
/// tapping a card in Home's recent list or the History tab. "Save" just
/// closes the sheet; "Discard" deletes the activity (its GPS points
/// cascade-delete with it).
Future<void> showActivitySummarySheet(BuildContext context, Activity activity) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: summarySheetAnimationStyle,
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.92,
      child: SessionSummarySheet.fromActivity(
        activity: activity,
        onSave: () => Navigator.of(sheetContext).pop(),
        onHome: () => Navigator.of(sheetContext).pop(),
        onDiscard: () async {
          await appDatabase.activitiesDao.deleteActivity(activity.id);
          if (!sheetContext.mounted) return;
          Navigator.of(sheetContext).pop();
          ScaffoldMessenger.of(
            sheetContext,
          ).showSnackBar(const SnackBar(content: Text('Activity discarded.')));
        },
      ),
    ),
  );
}

/// Session summary shown after a tracking session is completed.
///
/// Can represent either an in-memory [FinishedSession] (before user confirms Save)
/// or an already persisted [Activity].
class SessionSummarySheet extends StatelessWidget {
  SessionSummarySheet.fromFinishedSession({
    super.key,
    required FinishedSession session,
    required this.onSave,
    required this.onHome,
    required this.onDiscard,
  })  : activityType = session.activityType,
        startTime = session.startTime,
        durationSeconds = session.duration.inSeconds,
        distanceMeters = session.distanceMeters,
        avgSpeed = session.avgSpeedMps,
        avgPace = session.avgPaceSecondsPerKm,
        calories = session.calories,
        steps = session.steps,
        savedActivityId = null,
        positions = session.positions;

  SessionSummarySheet.fromActivity({
    super.key,
    required Activity activity,
    required this.onSave,
    required this.onHome,
    required this.onDiscard,
  })  : activityType = ActivityType.fromDbValue(activity.activityType),
        startTime = activity.startTime,
        durationSeconds = activity.durationSeconds,
        distanceMeters = activity.distanceMeters,
        avgSpeed = activity.avgSpeed,
        avgPace = activity.avgPace,
        calories = activity.calories,
        steps = activity.steps,
        savedActivityId = activity.id,
        positions = null;

  final ActivityType activityType;
  final DateTime startTime;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeed;
  final double avgPace;
  final int calories;
  final int steps;
  final int? savedActivityId;
  final List<dynamic>? positions;

  final VoidCallback onSave;
  final VoidCallback onHome;
  final VoidCallback onDiscard;

  bool get _isSavedActivity => savedActivityId != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final units = settingsController.measurementUnit;
    final distance = units.distanceFromMeters(distanceMeters);
    final speed = units.speedFromMetersPerSecond(avgSpeed);
    final pace = units.paceFromSecondsPerKm(avgPace);

    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Session Summary',
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(activityType.icon, color: colors.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${activityType.label} Session',
                        style: text.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formatSessionTimestamp(startTime),
                        style: text.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'COMPLETED',
                    style: text.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (positions != null)
              RouteMapView.fromCoordinates(
                coordinates: [
                  for (final p in positions!)
                    latlong.LatLng(p.latitude as double, p.longitude as double),
                ],
              )
            else if (savedActivityId != null)
              FutureBuilder<List<GpsPoint>>(
                future: appDatabase.gpsPointsDao.getPointsForActivity(
                  savedActivityId!,
                ),
                builder: (context, snapshot) {
                  return RouteMapView(
                    points: snapshot.data ?? const <GpsPoint>[],
                  );
                },
              )
            else
              const RouteMapView.fromCoordinates(coordinates: []),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'DISTANCE',
                    value: distance.toStringAsFixed(2),
                    unit: units.distanceLabel.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'DURATION',
                    value: formatDuration(
                      Duration(seconds: durationSeconds),
                    ),
                    unit: '',
                  ),
                ),
                // Steps are only meaningful for foot-based activities.
                // Bike sessions always store 0, so we hide the card entirely.
                if (activityType != ActivityType.bike) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryMetric(
                      label: 'STEPS',
                      value: steps.toString(),
                      unit: 'STEPS',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    label: 'AVG PACE',
                    value: formatPace(pace),
                    unit: units.paceLabel.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'SPEED',
                    value: speed.toStringAsFixed(1),
                    unit: units.speedLabel.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryMetric(
                    label: 'CALORIES',
                    value: calories.toString(),
                    unit: 'KCAL',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isSavedActivity)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.done),
                      label: const Text('DONE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                      onPressed: onDiscard,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('DELETE ACTIVITY'),
                    ),
                  ),
                ],
              )
            else ...[
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('SAVE ACTIVITY'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onHome,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('HOME'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: colors.error,
                      ),
                      onPressed: onDiscard,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('DISCARD ACTIVITY'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.unit,
  });
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 92,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: RichText(
              text: TextSpan(
                style: text.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
