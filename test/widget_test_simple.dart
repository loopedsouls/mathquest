import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adaptivecheck/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(ResponsiveWrapper());

    // Basic smoke test - just verify the app builds without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
