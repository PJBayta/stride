import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_type.dart';
import '../../tracking/presentation/live_session_sheet.dart';
import '../../tracking/presentation/session_summary_sheet.dart';

const _recentActivitiesLimit = 3;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  ActivityType _selectedActivity = ActivityType.run;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'STRIDE ACTIVE',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Good Morning!',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'SELECT ACTIVITY',
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: ActivityType.values
                  .map(
                    (activity) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: activity == ActivityType.bike ? 0 : 10,
                        ),
                        child: _ActivitySelector(
                          activity: activity,
                          isSelected: activity == _selectedActivity,
                          onTap: () => setState(() => _selectedActivity = activity),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (sheetContext) => FractionallySizedBox(
                      heightFactor: 0.92,
                      child: LiveSessionSheet(
                        activityType: _selectedActivity,
                        onFinished: (activity) =>
                            _showSessionSummary(context, sheetContext, activity),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('START ACTIVITY'),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITIES',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<Activity>>(
              stream: appDatabase.activitiesDao.watchAllActivities(),
              builder: (context, snapshot) {
                final activities = snapshot.data ?? const <Activity>[];
                if (activities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'No activities yet. Start one above!',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final recent = activities.take(_recentActivitiesLimit).toList();
                return Column(
                  children: [
                    for (var i = 0; i < recent.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _RecentActivityCard.fromActivity(
                        recent[i],
                        onTap: () => showActivitySummarySheet(context, recent[i]),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionSummary(
    BuildContext homeContext,
    BuildContext sheetContext,
    Activity activity,
  ) {
    Navigator.of(sheetContext).pop();
    showModalBottomSheet<void>(
      context: homeContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (summaryContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SessionSummarySheet(
          activity: activity,
          onSave: () {
            Navigator.of(summaryContext).pop();
            ScaffoldMessenger.of(homeContext).showSnackBar(
              const SnackBar(content: Text('Activity saved.')),
            );
          },
          onHome: () => Navigator.of(summaryContext).pop(),
          onDiscard: () async {
            await appDatabase.activitiesDao.deleteActivity(activity.id);
            if (!summaryContext.mounted) return;
            Navigator.of(summaryContext).pop();
            ScaffoldMessenger.of(homeContext).showSnackBar(
              const SnackBar(content: Text('Activity discarded.')),
            );
          },
        ),
      ),
    );
  }
}

class _ActivitySelector extends StatelessWidget {
  const _ActivitySelector({
    required this.activity,
    required this.isSelected,
    required this.onTap,
  });

  final ActivityType activity;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final foregroundColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select ${activity.label}',
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(activity.icon, color: foregroundColor),
                const SizedBox(height: 10),
                Text(
                  activity.label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.title,
    required this.detail,
    required this.distance,
    required this.duration,
    required this.icon,
    required this.placeholderIcon,
    required this.onTap,
  });

  factory _RecentActivityCard.fromActivity(
    Activity activity, {
    required VoidCallback onTap,
  }) {
    final type = ActivityType.fromDbValue(activity.activityType);
    return _RecentActivityCard(
      title: '${type.label} Session',
      detail: formatRelativeSessionTimestamp(activity.startTime),
      distance: '${(activity.distanceMeters / 1000).toStringAsFixed(2)} km',
      duration: formatDuration(Duration(seconds: activity.durationSeconds)),
      icon: type.icon,
      placeholderIcon: type.placeholderIcon,
      onTap: onTap,
    );
  }

  final String title;
  final String detail;
  final String distance;
  final String duration;
  final IconData icon;
  final IconData placeholderIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              Container(
                width: 92,
                color: colorScheme.tertiaryContainer,
                alignment: Alignment.center,
                child: Icon(
                  placeholderIcon,
                  size: 32,
                  color: colorScheme.onTertiaryContainer,
                ),
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
                          Icon(icon, size: 15, color: colorScheme.primary),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              detail.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$distance   •   $duration',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
