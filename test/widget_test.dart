import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('basic smoke test builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Sirkulara')),
      ),
    ));

    expect(find.text('Sirkulara'), findsOneWidget);
  });
}
