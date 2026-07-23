import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_stats.dart';
import '../../settings/controller/settings_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Athlete Profile'), centerTitle: true),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 2,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Alex Rivera',
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Member since 2023',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile editing is coming soon.'),
                ),
              ),
              child: const Text('EDIT PROFILE'),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PERFORMANCE SUMMARY',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'ALL TIME',
                    style: text.labelSmall?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StreamBuilder<ActivityStats>(
              stream: appDatabase.activitiesDao.watchStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? ActivityStats.zero;
                final units = settingsController.measurementUnit;
                final distance = units.distanceFromMeters(
                  stats.totalDistanceMeters,
                );
                final totalHours = stats.totalDurationSeconds / 3600;
                final speed = units.speedFromMetersPerSecond(stats.avgSpeedMps);
                final pace = units.paceFromSecondsPerKm(
                  stats.avgPaceSecondsPerKm,
                );

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.insights,
                            label: 'TOTAL ACTIVITIES',
                            value: stats.totalActivities.toString(),
                            unit: 'sessions',
                            caption: 'All recorded activities',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.trending_up,
                            label: 'TOTAL DISTANCE',
                            value: distance.toStringAsFixed(1),
                            unit: units.distanceLabel,
                            caption: 'Across all activities',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.timer_outlined,
                            label: 'TOTAL DURATION',
                            value: totalHours.toStringAsFixed(1),
                            unit: 'hrs',
                            caption: 'Active moving time',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.speed_outlined,
                            label: 'AVG SPEED',
                            value: speed.toStringAsFixed(1),
                            unit: units.speedLabel,
                            caption: 'Distance-weighted average',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.bolt_outlined,
                            label: 'AVG PACE',
                            value: formatPace(pace),
                            unit: units.paceLabel,
                            caption: 'Distance-weighted average',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PerformanceCard(
                            icon: Icons.local_fire_department_outlined,
                            label: 'TOTAL CALORIES',
                            value: stats.totalCalories.toString(),
                            unit: 'kcal',
                            caption: 'Estimated energy burned',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
  });
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: SizedBox(
        height: 158,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 19, color: colors.primary),
              ),
              const Spacer(),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              RichText(
                text: TextSpan(
                  style: text.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  children: [
                    TextSpan(text: value),
                    TextSpan(
                      text: ' $unit',
                      style: text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
