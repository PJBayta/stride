import 'package:flutter/material.dart';

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
    final activities = _activities
        .where((activity) =>
            _selectedFilter == HistoryFilter.all ||
            activity.type == _selectedFilter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity History'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Additional filters are coming soon.')),
              );
            },
            icon: const Icon(Icons.tune),
            tooltip: 'More filters',
          ),
        ],
      ),
      body: ListView(
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
                        onSelected: (_) => setState(() => _selectedFilter = filter),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
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
                      const TextSpan(text: '124.8'),
                      TextSpan(
                        text: ' km',
                        style: text.titleSmall?.copyWith(color: colors.onPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _SummaryValue(label: 'SESSIONS', value: '24', color: colors.onPrimary),
                    const SizedBox(width: 34),
                    _SummaryValue(label: 'AVG. PACE', value: "5'42\" /km", color: colors.onPrimary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: Divider(color: colors.outlineVariant)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OCTOBER 2023',
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
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'No ${_selectedFilter.label.toLowerCase()} activities yet.',
                  style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
            )
          else
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityHistoryCard(activity: activity),
              ),
            ),
        ],
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

class _ActivityData {
  const _ActivityData({
    required this.type,
    required this.date,
    required this.distance,
    required this.duration,
    required this.energy,
    required this.icon,
    required this.imageIcon,
  });

  final HistoryFilter type;
  final String date;
  final String distance;
  final String duration;
  final String energy;
  final IconData icon;
  final IconData imageIcon;
}

const _activities = [
  _ActivityData(
    type: HistoryFilter.running,
    date: 'Oct 24, 2023 • 07:30 AM',
    distance: '5.2 km',
    duration: '28:45',
    energy: '420 kcal',
    icon: Icons.directions_run,
    imageIcon: Icons.terrain_outlined,
  ),
  _ActivityData(
    type: HistoryFilter.cycling,
    date: 'Oct 22, 2023 • 05:15 PM',
    distance: '18.5 km',
    duration: '52:10',
    energy: '680 kcal',
    icon: Icons.directions_bike,
    imageIcon: Icons.route_outlined,
  ),
  _ActivityData(
    type: HistoryFilter.walking,
    date: 'Oct 21, 2023 • 08:00 AM',
    distance: '3.1 km',
    duration: '45:20',
    energy: '180 kcal',
    icon: Icons.directions_walk,
    imageIcon: Icons.park_outlined,
  ),
];

class _ActivityHistoryCard extends StatelessWidget {
  const _ActivityHistoryCard({required this.activity});
  final _ActivityData activity;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: SizedBox(
          height: 112,
          child: Row(
            children: [
              Container(
                width: 72,
                height: double.infinity,
                color: colors.tertiaryContainer,
                alignment: Alignment.center,
                child: Icon(activity.imageIcon, color: colors.onTertiaryContainer),
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
                            activity.type.label.toUpperCase(),
                            style: text.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(activity.icon, size: 15, color: colors.primary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.date,
                        style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(child: _Stat(label: 'DISTANCE', value: activity.distance)),
                          Expanded(child: _Stat(label: 'TIME', value: activity.duration)),
                          Expanded(child: _Stat(label: 'ENERGY', value: activity.energy)),
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
  const _SummaryValue({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
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
        Text(label, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        FittedBox(
          child: Text(value, style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
