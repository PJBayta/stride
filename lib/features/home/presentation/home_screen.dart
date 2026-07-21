import 'package:flutter/material.dart';

import '../../tracking/presentation/live_session_sheet.dart';
import '../../tracking/presentation/session_summary_sheet.dart';

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
                        activityLabel: _selectedActivity.label,
                        activityIcon: _selectedActivity.icon,
                        onFinish: () => _showSessionSummary(context, sheetContext),
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
            const _RecentActivityCard(
              title: 'Run Session',
              detail: 'Today, 06:30 AM',
              distance: '5.24 km',
              duration: '28:45',
              icon: Icons.directions_run,
              placeholderIcon: Icons.terrain_outlined,
            ),
            const SizedBox(height: 10),
            const _RecentActivityCard(
              title: 'Bike Session',
              detail: 'Yesterday, 05:15 PM',
              distance: '12.80 km',
              duration: '45:10',
              icon: Icons.directions_bike,
              placeholderIcon: Icons.route_outlined,
            ),
            const SizedBox(height: 10),
            const _RecentActivityCard(
              title: 'Walk Session',
              detail: 'Oct 24, 08:00 AM',
              distance: '3.16 km',
              duration: '35:20',
              icon: Icons.directions_walk,
              placeholderIcon: Icons.park_outlined,
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionSummary(BuildContext homeContext, BuildContext sheetContext) {
    Navigator.of(sheetContext).pop();
    showModalBottomSheet<void>(
      context: homeContext,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (summaryContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SessionSummarySheet(
          onSave: () {
            Navigator.of(summaryContext).pop();
            ScaffoldMessenger.of(homeContext).showSnackBar(
              const SnackBar(content: Text('Activity saved (placeholder).')),
            );
          },
          onHome: () => Navigator.of(summaryContext).pop(),
          onDiscard: () {
            Navigator.of(summaryContext).pop();
            ScaffoldMessenger.of(homeContext).showSnackBar(
              const SnackBar(content: Text('Activity discarded (placeholder).')),
            );
          },
        ),
      ),
    );
  }
}

enum ActivityType {
  run('Run', Icons.directions_run),
  walk('Walk', Icons.directions_walk),
  bike('Bike', Icons.directions_bike);

  const ActivityType(this.label, this.icon);

  final String label;
  final IconData icon;
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
  });

  final String title;
  final String detail;
  final String distance;
  final String duration;
  final IconData icon;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
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
