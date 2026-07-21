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

    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Your completed activities will appear here.'), findsOneWidget);
  });
}