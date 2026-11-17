import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_recipe_planner/features/results/results_screen.dart';

void main() {
  testWidgets('ResultsScreen build test', (WidgetTester tester) async {
    // Wrap in ProviderScope and MaterialApp since it uses Riverpod and routing
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ResultsScreen()),
        ),
      ),
    );

    // Pump to ensure all microtasks and animations run
    await tester.pumpAndSettle();
  });
}
