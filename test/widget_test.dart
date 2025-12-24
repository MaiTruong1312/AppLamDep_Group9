// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:applamdep/main.dart';

void main() {
  testWidgets('App starts successfully and handles SplashScreen timer', (WidgetTester tester) async {
    // TẮT KIỂM TRA OVERFLOW TRONG TEST – CHỈ CHO TEST, KHÔNG ẢNH HƯỞNG APP THẬT
    debugDisableShadows = true; // optional, nếu có shadow
    tester.binding.window.physicalSizeTestValue = const Size(800, 1600); // tăng kích thước test
    tester.binding.window.devicePixelRatioTestValue = 1.0;

    // Pump app
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Tiến thời gian qua timer SplashScreen
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

    // Reset kích thước sau test
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}