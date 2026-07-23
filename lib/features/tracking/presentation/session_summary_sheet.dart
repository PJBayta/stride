import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_type.dart';

/// Session summary shown after a live session is finished and saved.
///
/// The activity is already persisted by the time this sheet is shown (saving
/// happens on Finish); "Save" here just confirms and closes, while "Discard"
/// deletes the just-saved row (its GPS points cascade-delete with it).
class SessionSummarySheet extends StatelessWidget {
  const SessionSummarySheet({
    super.key,
    required this.activity,
    required this.onSave,
    required this.onHome,
    required this.onDiscard,
  });

  final Activity activity;
  final VoidCallback onSave;
  final VoidCallback onHome;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final type = ActivityType.fromDbValue(activity.activityType);
    final distanceKm = activity.distanceMeters / 1000;
    final speedKmh = activity.avgSpeed * 3.6;

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
            Text('Session Summary', textAlign: TextAlign.center, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(14)),
                  child: Icon(type.icon, color: colors.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${type.label} Session', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text(formatSessionTimestamp(activity.startTime), style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Text('COMPLETED', style: text.labelSmall?.copyWith(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _GpsMapPlaceholder(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _SummaryMetric(label: 'DISTANCE', value: distanceKm.toStringAsFixed(2), unit: 'KM')),
                const SizedBox(width: 12),
                Expanded(child: _SummaryMetric(label: 'DURATION', value: formatDuration(Duration(seconds: activity.durationSeconds)), unit: '')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _SummaryMetric(label: 'AVG PACE', value: formatPace(activity.avgPace), unit: '/KM')),
                const SizedBox(width: 12),
                Expanded(child: _SummaryMetric(label: 'SPEED', value: speedKmh.toStringAsFixed(1), unit: 'KM/H')),
                const SizedBox(width: 12),
                Expanded(child: _SummaryMetric(label: 'CALORIES', value: activity.calories.toString(), unit: 'KCAL')),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(height: 52, child: FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save_outlined), label: const Text('SAVE ACTIVITY'))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: onHome, icon: const Icon(Icons.home_outlined), label: const Text('HOME'))),
                const SizedBox(width: 12),
                Expanded(child: TextButton.icon(onPressed: onDiscard, icon: const Icon(Icons.delete_outline), label: const Text('DISCARD'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsMapPlaceholder extends StatelessWidget {
  const _GpsMapPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 180,
      decoration: BoxDecoration(color: colors.tertiaryContainer, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          Center(child: Icon(Icons.map_outlined, size: 64, color: colors.onTertiaryContainer.withValues(alpha: 0.55))),
          Positioned(
            top: 12,
            left: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(color: colors.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.gps_fixed, size: 14, color: colors.primary),
                    const SizedBox(width: 5),
                    Text('GPS PLACEHOLDER', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          Center(child: Icon(Icons.directions_run, size: 34, color: colors.primary)),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value, required this.unit});
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
      decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          FittedBox(
            child: RichText(
              text: TextSpan(
                style: text.titleLarge?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
                children: [TextSpan(text: value), TextSpan(text: ' $unit', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
