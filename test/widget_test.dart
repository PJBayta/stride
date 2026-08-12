import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride/main.dart';
import 'package:stride/features/profile/controller/profile_controller.dart';
import 'package:stride/features/settings/controller/settings_controller.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'hasCompletedOnboarding': true,
      'profile_name': 'Test Athlete',
      'profile_weight_kg': 70.0,
    });
    await Future.wait([settingsController.load(), profileController.load()]);
  });

  testWidgets('Stride app provides themed primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StrideApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.light);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);

    await tester.tap(find.text('History'));
    await tester.pump();

    expect(find.text('Activity History'), findsOneWidget);
    expect(find.textContaining('TOTAL DISTANCE THIS '), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('Athlete Profile'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(find.text('Settings'), findsWidgets);
  });
}
