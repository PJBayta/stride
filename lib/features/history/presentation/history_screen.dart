import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_stats.dart';
import '../../../models/activity_type.dart';
import '../../settings/controller/settings_controller.dart';
import '../../tracking/presentation/session_summary_sheet.dart';
import '../../../widgets/activity_card.dart';

HistoryFilter _filterForActivityType(ActivityType type) => switch (type) {
  ActivityType.run => HistoryFilter.running,
  ActivityType.bike => HistoryFilter.cycling,
  ActivityType.walk => HistoryFilter.walking,
};

const _monthNames = [
  'JANUARY',
  'FEBRUARY',
  'MARCH',
  'APRIL',
  'MAY',
  'JUNE',
  'JULY',
  'AUGUST',
  'SEPTEMBER',
  'OCTOBER',
  'NOVEMBER',
  'DECEMBER',
];

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
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthName = _monthNames[now.month - 1];

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
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
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
            ),
            const SizedBox(height: 20),
            StreamBuilder<ActivityStats>(
              stream: appDatabase.activitiesDao.watchStats(since: monthStart),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MonthlySummaryError(message: snapshot.error.toString());
                }

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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.primary.withValues(alpha: 0.16),
                        colors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL DISTANCE THIS $monthName',
                        style: text.labelSmall?.copyWith(
                          color: colors.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: text.headlineMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(text: distance.toStringAsFixed(1)),
                            TextSpan(
                              text: ' ${units.distanceLabel}',
                              style: text.titleSmall?.copyWith(
                                color: colors.primary.withValues(alpha: 0.85),
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
                            color: colors.onSurface,
                          ),
                          const SizedBox(width: 34),
                          _SummaryValue(
                            label: 'AVG. PACE',
                            value: '${formatPace(pace)} ${units.paceLabel}',
                            color: colors.onSurface,
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
                    'All activities',
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
                  final filterLabel = _selectedFilter == HistoryFilter.all
                      ? 'activities'
                      : '${_selectedFilter.label.toLowerCase()} activities';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.route_outlined,
                              size: 28,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'No $filterLabel yet',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Text(
                              'Your runs, rides, and walks will show up '
                              'here once you log your first session.',
                              textAlign: TextAlign.center,
                              style: text.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final activity in activities)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ActivityCard.fromActivity(
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

class _MonthlySummaryError extends StatelessWidget {
  const _MonthlySummaryError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'Could not load this month\'s activity summary.\n$message',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colors.onErrorContainer,
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
