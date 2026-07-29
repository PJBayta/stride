import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../../data/database/app_database.dart';
import '../../../models/activity_stats.dart';
import '../../../models/user_profile.dart';
import '../controller/profile_controller.dart';
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
        listenable: Listenable.merge([settingsController, profileController]),
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
              profileController.profile.name,
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => const _EditProfileSheet(),
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

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  String? _gender;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = profileController.profile;
    _nameController = TextEditingController(text: profile.name);
    _weightController = TextEditingController(
      text: profile.weightKg.toStringAsFixed(1),
    );
    _heightController = TextEditingController(
      text: profile.heightCm?.toStringAsFixed(1) ?? '',
    );
    _gender = profile.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await profileController.saveProfile(
      UserProfile(
        name: _nameController.text.trim(),
        weightKg: double.parse(_weightController.text.trim()),
        heightCm: _heightController.text.trim().isEmpty
            ? null
            : double.parse(_heightController.text.trim()),
        gender: _gender,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Edit Profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                validator: _validatePositiveNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Height (cm) · optional'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? null
                    : _validatePositiveNumber(value),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender · optional'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'non_binary', child: Text('Non-binary')),
                  DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                ],
                onChanged: (value) => setState(() => _gender = value),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'SAVING...' : 'SAVE CHANGES'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePositiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed <= 0 ? 'Enter a value greater than 0' : null;
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
