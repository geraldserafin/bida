import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_planner/widgets/phone_frame.dart';

Future<void> pumpAt(WidgetTester tester, Size window) async {
  tester.view.physicalSize = window;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(
      home: PhoneFrame(child: SizedBox.expand(key: Key('app'))),
    ),
  );
}

void main() {
  testWidgets('a wide window shows the app phone-sized', (tester) async {
    await pumpAt(tester, const Size(1440, 900));

    final size = tester.getSize(find.byKey(const Key('app')));
    expect(size.width, PhoneFrame.width);
    expect(size.height, lessThan(900));
  });

  testWidgets('a narrow window gives the app the whole screen', (tester) async {
    await pumpAt(tester, const Size(390, 800));

    expect(tester.getSize(find.byKey(const Key('app'))), const Size(390, 800));
  });
}
