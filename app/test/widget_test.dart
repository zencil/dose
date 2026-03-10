import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dose/main.dart';

void main() {
  testWidgets('App launches and displays title', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(onboardingComplete: true));

    // 2. Verify that the "Dose" title is present in the AppBar.
    // Note: We use find.text containing 'Dose' because the actual text might be
    // "Good Morning" depending on the time, or "Dose" on the home screen.
    // However, on launch, it defaults to the Home page which has the title "Dose".
    expect(find.text('Dose'), findsOneWidget);

    // 3. Verify that the "+" add button is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
