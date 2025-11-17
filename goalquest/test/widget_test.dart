//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/app.dart';

void main() {
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build the app with a test initial route
    await tester.pumpWidget(const GoalQuestApp(initialRoute: '/auth'));

    // Let Flutter build the first frame
    await tester.pumpAndSettle();

    // Check something that SHOULD exist on the Auth Screen
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });
}

