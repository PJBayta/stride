import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stride/main.dart';

void main() {
  testWidgets('Stride app provides themed primary navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const StrideApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.useMaterial3, isTrue);
    expect(app.darkTheme?.useMaterial3, isTrue);
    expect(app.themeMode, ThemeMode.system);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Run Session'), findsOneWidget);

    await tester.tap(find.text('WALK'));
    await tester.pump();

    expect(find.text('START ACTIVITY'), findsOneWidget);

    await tester.tap(find.text('START ACTIVITY'));
    await tester.pumpAndSettle();

    expect(find.text('Live Session'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(find.text('Session Summary'), findsOneWidget);
    expect(find.text('Evening Run'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Activity History'), findsOneWidget);
    expect(find.text('TOTAL DISTANCE THIS MONTH'), findsOneWidget);
    expect(find.text('RUNNING'), findsOneWidget);
  });
}
