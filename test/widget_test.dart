import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nurse_device_auth/main.dart';

void main() {
  testWidgets('Boots without crashing', (WidgetTester tester) async {
    // Avoid pumpAndSettle: the camera preview keeps animating and secure
    // storage has no platform-channel mock in the test harness, so neither
    // ever "settles" here. A bounded pump is enough to prove the widget
    // tree builds without throwing.
    await tester.pumpWidget(const NurseDeviceAuthApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
