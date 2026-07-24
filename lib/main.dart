import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/settings/controller/settings_controller.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'services/tracking_notification_service.dart';
import 'widgets/stride_navigation_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await settingsController.load();
  await TrackingNotificationService.init();
  runApp(const StrideApp());
}

class StrideApp extends StatelessWidget {
  const StrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, _) => MaterialApp(
        title: 'Stride',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: settingsController.themeMode,
        home: StrideNavigationScaffold(
          destinations: const [
            StrideNavigationDestination(
              label: 'Home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              screen: HomeScreen(),
            ),
            StrideNavigationDestination(
              label: 'History',
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              screen: HistoryScreen(),
            ),
            StrideNavigationDestination(
              label: 'Profile',
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              screen: ProfileScreen(),
            ),
            StrideNavigationDestination(
              label: 'Settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings,
              screen: SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }
}
