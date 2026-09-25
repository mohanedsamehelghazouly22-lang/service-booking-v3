import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Service Booking environment loads', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Service Booking'))));
    expect(find.text('Service Booking'), findsOneWidget);
  });
}
