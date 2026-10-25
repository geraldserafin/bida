import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/widgets/google_button.dart';

Future<void> show(
  WidgetTester tester, {
  required VoidCallback? onPressed,
  Brightness brightness = Brightness.light,
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: GoogleButton(
            label: 'Zaloguj przez Google',
            onPressed: onPressed,
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the label and the Google logo, and can be tapped', (
    tester,
  ) async {
    var taps = 0;
    await show(tester, onPressed: () => taps++);

    expect(find.text('Zaloguj przez Google'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.text('Zaloguj przez Google'));
    expect(taps, 1);
  });

  testWidgets('does nothing while disabled', (tester) async {
    await show(tester, onPressed: null);

    // no exception, and tapping reaches nothing
    await tester.tap(find.text('Zaloguj przez Google'), warnIfMissed: false);
    expect(find.text('Zaloguj przez Google'), findsOneWidget);
  });

  testWidgets('uses the dark colours of the guidelines in the dark theme', (
    tester,
  ) async {
    await show(tester, onPressed: () {}, brightness: Brightness.dark);

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(GoogleButton),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, const Color(0xFF131314));
  });
}
