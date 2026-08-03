import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/database/app_database.dart';
import '../features/settings/controller/settings_controller.dart';
import '../models/activity_type.dart';

/// Shared activity-card presentation for Home and Activity History.
class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.typeLabel,
    required this.date,
    required this.distance,
    required this.duration,
    required this.energy,
    required this.icon,
    required this.onTap,
  });

  factory ActivityCard.fromActivity(
    Activity activity, {
    required VoidCallback onTap,
  }) {
    final type = ActivityType.fromDbValue(activity.activityType);
    final units = settingsController.measurementUnit;
    return ActivityCard(
      typeLabel: type.label,
      date: formatHistoryTimestamp(activity.startTime),
      distance:
          '${units.distanceFromMeters(activity.distanceMeters).toStringAsFixed(1)} ${units.distanceLabel}',
      duration: formatDuration(Duration(seconds: activity.durationSeconds)),
      energy: '${activity.calories} kcal',
      icon: type.icon,
      onTap: onTap,
    );
  }

  final String typeLabel;
  final String date;
  final String distance;
  final String duration;
  final String energy;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final dateParts = date.split('•');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel.toUpperCase(),
                      style: text.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    dateParts.length == 2
                        ? RichText(
                            text: TextSpan(
                              style: text.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(text: dateParts[0].trimRight()),
                                const TextSpan(
                                  text: '  •  ',
                                  style: TextStyle(fontSize: 6),
                                ),
                                TextSpan(text: dateParts[1].trimLeft()),
                              ],
                            ),
                          )
                        : Text(
                            date,
                            style: text.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActivityStat(
                            label: 'DISTANCE',
                            value: distance,
                          ),
                        ),
                        Expanded(
                          child: _ActivityStat(label: 'TIME', value: duration),
                        ),
                        Expanded(
                          child: _ActivityStat(
                            label: 'ENERGY',
                            value: energy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityStat extends StatelessWidget {
  const _ActivityStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: text.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(
            value,
            style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
