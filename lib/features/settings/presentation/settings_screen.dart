import 'package:flutter/material.dart';

import '../../../models/gps_accuracy.dart';
import '../../../models/measurement_unit.dart';
import '../controller/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListenableBuilder(
        listenable: settingsController,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          children: [
            _SectionLabel(title: 'APPEARANCE', icon: Icons.wb_sunny_outlined),
            _SettingsCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: const Text('Display preference for Stride'),
                value: settingsController.themeMode == ThemeMode.dark,
                onChanged: (value) => settingsController.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(
              title: 'UNITS & MEASUREMENTS',
              icon: Icons.straighten,
            ),
            _SettingsCard(
              child: RadioGroup<MeasurementUnit>(
                groupValue: settingsController.measurementUnit,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setMeasurementUnit(value);
                  }
                },
                child: Column(
                  children: MeasurementUnit.values
                      .map(
                        (unit) => RadioListTile<MeasurementUnit>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(unit.title),
                          subtitle: Text(unit.subtitle),
                          value: unit,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(title: 'GPS TRACKING', icon: Icons.near_me_outlined),
            _SettingsCard(
              child: RadioGroup<GpsAccuracy>(
                groupValue: settingsController.gpsAccuracy,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setGpsAccuracy(value);
                  }
                },
                child: Column(
                  children: GpsAccuracy.values
                      .map(
                        (accuracy) => RadioListTile<GpsAccuracy>(
                          contentPadding: EdgeInsets.zero,
                          title: Text(accuracy.title),
                          subtitle: Text(accuracy.subtitle),
                          value: accuracy,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 22),
            _SectionLabel(title: 'ABOUT APPLICATION', icon: Icons.info_outline),
            _SettingsCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_outlined),
                    title: const Text('Version'),
                    trailing: Chip(
                      label: Text('v1.0.0', style: text.labelSmall),
                    ),
                  ),
                  const Divider(height: 1),
                  _AboutTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                  ),
                  const Divider(height: 1),
                  _AboutTile(
                    icon: Icons.shield_outlined,
                    title: 'Terms of Service',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Stride keeps activity information on your device until a future sync option is introduced.',
              textAlign: TextAlign.center,
              style: text.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: child,
    ),
  );
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$title is coming soon.'))),
  );
}
