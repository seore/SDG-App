import 'package:flutter_test/flutter_test.dart';
import 'package:goalquest/app.dart';

void main() {
  testWidgets('App builds and shows the auth screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GoalQuestApp(initialRoute: '/auth'));
    // The auth screen has looping entrance animations, so pump a fixed time
    // instead of pumpAndSettle.
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('SDG Journey'), findsOneWidget);
    expect(find.text('Log in'), findsWidgets); // toggle + submit button
    expect(find.text('Sign up'), findsOneWidget);
  });
}
