import 'package:flutter_test/flutter_test.dart';

import 'package:controle_pharma/main.dart';

void main() {
  testWidgets('App should render dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ControlePharmaApp(isUnlocked: true));

    // Verify that the app title is displayed
    expect(find.text('Contrôle Pharma'), findsOneWidget);
  });
}
