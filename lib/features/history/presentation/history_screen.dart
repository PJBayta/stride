import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_stats.dart';
import '../../../models/activity_type.dart';
import '../../settings/controller/settings_controller.dart';
import '../../tracking/presentation/session_summary_sheet.dart';

HistoryFilter _filterForActivityType(ActivityType type) => switch (type) {
  ActivityType.run => HistoryFilter.running,
  ActivityType.bike => HistoryFilter.cycling,
  ActivityType.walk => HistoryFilter.walking,
};

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: HistoryFilter.values
                    .map(
                      (filter) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter.label),
                          selected: filter == _selectedFilter,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<ActivityStats>(
              stream: appDatabase.activitiesDao.watchStats(
                since: DateTime(DateTime.now().year, DateTime.now().month),
              ),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? ActivityStats.zero;
                final units = settingsController.measurementUnit;
                final distance = units.distanceFromMeters(
                  stats.totalDistanceMeters,
                );
                final pace = units.paceFromSecondsPerKm(
                  stats.avgPaceSecondsPerKm,
                );

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DISTANCE THIS MONTH',
                        style: text.labelSmall?.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: text.headlineMedium?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(text: distance.toStringAsFixed(1)),
                            TextSpan(
                              text: ' ${units.distanceLabel}',
                              style: text.titleSmall?.copyWith(
                                color: colors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _SummaryValue(
                            label: 'SESSIONS',
                            value: stats.totalActivities.toString(),
                            color: colors.onPrimary,
                          ),
                          const SizedBox(width: 34),
                          _SummaryValue(
                            label: 'AVG. PACE',
                            value: '${formatPace(pace)} ${units.paceLabel}',
                            color: colors.onPrimary,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(child: Divider(color: colors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'ALL ACTIVITIES',
                    style: text.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.outlineVariant)),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<Activity>>(
              stream: appDatabase.activitiesDao.watchAllActivities(),
              builder: (context, snapshot) {
                final allActivities = snapshot.data ?? const <Activity>[];
                final activities = allActivities
                    .where(
                      (activity) =>
                          _selectedFilter == HistoryFilter.all ||
                          _filterForActivityType(
                                ActivityType.fromDbValue(activity.activityType),
                              ) ==
                              _selectedFilter,
                    )
                    .toList();

                if (activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No ${_selectedFilter.label.toLowerCase()} activities yet.',
                        style: text.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final activity in activities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityHistoryCard.fromActivity(
                          activity,
                          onTap: () =>
                              showActivitySummarySheet(context, activity),
                        ),
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

enum HistoryFilter {
  all('All'),
  running('Running'),
  cycling('Cycling'),
  walking('Walking');

  const HistoryFilter(this.label);
  final String label;
}

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({
    required this.typeLabel,
    required this.date,
    required this.distance,
    required this.duration,
    required this.energy,
    required this.icon,
    required this.imageIcon,
    required this.onTap,
  });

  factory _ActivityHistoryCard.fromActivity(
    Activity activity, {
    required VoidCallback onTap,
  }) {
    final type = ActivityType.fromDbValue(activity.activityType);
    final units = settingsController.measurementUnit;
    return _ActivityHistoryCard(
      typeLabel: type.label,
      date: formatHistoryTimestamp(activity.startTime),
      distance:
          '${units.distanceFromMeters(activity.distanceMeters).toStringAsFixed(1)} ${units.distanceLabel}',
      duration: formatDuration(Duration(seconds: activity.durationSeconds)),
      energy: '${activity.calories} kcal',
      icon: type.icon,
      imageIcon: type.placeholderIcon,
      onTap: onTap,
    );
  }

  final String typeLabel;
  final String date;
  final String distance;
  final String duration;
  final String energy;
  final IconData icon;
  final IconData imageIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              Container(
                width: 72,
                height: double.infinity,
                color: colors.tertiaryContainer,
                alignment: Alignment.center,
                child: Icon(imageIcon, color: colors.onTertiaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            typeLabel.toUpperCase(),
                            style: text.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(icon, size: 15, color: colors.primary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: text.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(label: 'DISTANCE', value: distance),
                          ),
                          Expanded(
                            child: _Stat(label: 'TIME', value: duration),
                          ),
                          Expanded(
                            child: _Stat(label: 'ENERGY', value: energy),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
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
