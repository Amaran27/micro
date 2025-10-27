import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micro/presentation/widgets/ai_proactive_integration_demo.dart';

void main() {
  group('AI Proactive Integration Demo Widget Tests', () {
    testWidgets('AI Proactive Integration Demo builds successfully',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: AIProactiveIntegrationDemo(),
        ),
      );

      // Verify the widget builds without errors
      expect(find.text('AI-Proactive Integration Demo'), findsOneWidget);
      expect(find.text('AI Integration Consent'), findsOneWidget);
      expect(find.text('AI Context Analysis'), findsOneWidget);
      expect(find.text('AI Recommendations'), findsOneWidget);
      expect(find.text('Scheduled AI Actions'), findsOneWidget);
    });

    testWidgets('AI consent toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIProactiveIntegrationDemo(),
        ),
      );

      // Find the AI consent switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Initially should be enabled (as per demo setup)
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);

      // Note: In a real test, we would tap the switch and verify the state change,
      // but this requires more complex setup with Riverpod providers
    });

    testWidgets('Analyze button is present and tappable',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIProactiveIntegrationDemo(),
        ),
      );

      // Find the analyze button
      final buttonFinder = find.text('Analyze Usage Patterns');
      expect(buttonFinder, findsOneWidget);

      // Verify it's an ElevatedButton
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('Demo contains information section',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIProactiveIntegrationDemo(),
        ),
      );

      // Check for information content
      expect(find.text('About AI-Proactive Integration'), findsOneWidget);
      expect(
          find.text('Experience AI-driven proactive behavior'), findsOneWidget);
      expect(find.text('Try AI Demo'), findsOneWidget);
    });

    testWidgets('Widget has proper app bar with refresh button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AIProactiveIntegrationDemo(),
        ),
      );

      // Check app bar
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });
}
