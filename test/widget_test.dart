// This is a basic Flutter widget test for the Rituals App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rituals_app/main.dart';

void main() {
  testWidgets('Rituals app loads home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: RitualsApp()));

    // Verify that the home screen loads
    expect(find.text('Rituallerim'), findsOneWidget);
    expect(find.text('Home Screen - Coming Soon'), findsOneWidget);

    // Verify that the floating action button is present
    expect(find.byIcon(Icons.chat), findsOneWidget);
  });
}
