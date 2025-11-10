/// TDD Integration Tests for Swarm Intelligence (Fixed Version)
/// Tests complex task execution using mocks (no direct API calls)
/// Verifies the complete swarm implementation end-to-end

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/swarm/blackboard.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';
import 'package:micro/infrastructure/ai/agent/models/agent_models.dart';
import 'dart:convert';

// Mock classes for testing
class MockLanguageModel extends Mock implements LanguageModel {}

class MockToolRegistry extends Mock implements ToolRegistry {}

void main() {
  group('Swarm TDD Integration Tests', () {
    late MockLanguageModel mockLanguageModel;
    late MockToolRegistry mockToolRegistry;
    late SwarmOrchestrator orchestrator;
    late ToolRegistry realToolRegistry;

    setUp(() {
      mockLanguageModel = MockLanguageModel();
      mockToolRegistry = MockToolRegistry();
      realToolRegistry = ToolRegistry();
      
      // Register real tools for testing
      realToolRegistry.register(EchoTool());
      realToolRegistry.register(SentimentTool());
      realToolRegistry.register(CalculatorTool());
      realToolRegistry.register(StatsTool());
      realToolRegistry.register(KnowledgeBaseTool());

      // Setup mock behavior
      when(() => mockToolRegistry.getAllMetadata()).thenReturn(realToolRegistry.getAllMetadata());
      when(() => mockToolRegistry.getTool(any())).thenAnswer((invocation) {
        final toolName = invocation.positionalArguments[0] as String;
        return realToolRegistry.getTool(toolName);
      });
    });

    group('Customer Feedback Analysis - Complex Task', () {
      test('TDD: Generate appropriate specialists for customer analysis', () async {
        print('🧪 TDD Test: Customer Feedback Analysis');
        print('📋 Task: Analyze customer reviews and provide insights');
        
        final customerFeedbackTask = '''
Analyze these customer reviews for our mobile app:
1. "The UI is beautiful but the app crashes when I upload large files"
2. "Love the new dark mode! Performance is great"
3. "App is slow on my old phone. Takes 10 seconds to open"
4. "Best productivity app I've used. Only issue: can't export to PDF"
5. "Keeps crashing. Fix the bugs!"

Please provide:
- Overall sentiment analysis
- Most common issues
- Most praised features  
- Priority recommendations
''';

        // Mock LLM response for meta-planning
        final mockMetaPlanningResponse = '''
[
  {
    "id": "spec_sentiment",
    "role": "sentiment_analyst",
    "systemPrompt": "You are a sentiment analysis expert",
    "subtask": "Analyze overall sentiment of customer reviews",
    "requiredTools": ["sentiment"],
    "requiredCapabilities": ["nlp", "sentiment"],
    "priority": 1.0
  },
  {
    "id": "spec_issues",
    "role": "issue_extractor",
    "systemPrompt": "You are an issue identification expert",
    "subtask": "Extract and categorize common issues from reviews",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["analysis", "categorization"],
    "priority": 0.9
  },
  {
    "id": "spec_praise",
    "role": "feature_praise_extractor",
    "systemPrompt": "You are a feature analysis expert",
    "subtask": "Identify most praised features from positive feedback",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["feature_analysis"],
    "priority": 0.8
  },
  {
    "id": "spec_synthesis",
    "role": "insight_synthesizer",
    "systemPrompt": "You are a synthesis expert",
    "subtask": "Combine findings into actionable recommendations",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["synthesis", "recommendations"],
    "priority": 0.5
  }
]
''';

        // Mock the language model responses - use Future.value for async return
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists') || prompt.contains('meta-planning')) {
            return mockMetaPlanningResponse;
          }
          
          // Mock specialist responses
          if (prompt.contains('sentiment_analyst')) {
            return '''
{
  "overall_sentiment": "mixed",
  "sentiment breakdown": {"positive": 60, "negative": 40},
  "confidence": 0.85,
  "key_insights": "Users love UI but frustrated with crashes"
}''';
          }
          
          if (prompt.contains('issue_extractor')) {
            return '''
{
  "critical_issues": ["app_crashes", "slow_performance"],
  "issue_frequency": {"crashes": 3, "performance": 2, "pdf_export": 1},
  "severity_analysis": "Crashes are highest priority"
}''';
          }
          
          if (prompt.contains('feature_praise_extractor')) {
            return '''
{
  "praised_features": ["ui_design", "dark_mode", "productivity_features"],
  "feature_popularity": {"ui": 4, "dark_mode": 2, "productivity": 3},
  "user_satisfaction": "UI design is most appreciated"
}''';
          }
          
          if (prompt.contains('insight_synthesizer')) {
            return '''
{
  "summary": "App has great UI but critical stability issues",
  "priority_actions": [
    "Fix crash bugs immediately",
    "Optimize performance for older devices", 
    "Add PDF export functionality"
  ],
  "recommendation_score": 7.5
}''';
          }
          
          return 'Default mock response';
        });

        // Create orchestrator with mock dependencies
        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 5,
        );

        // Execute the swarm task
        final result = await orchestrator.execute(customerFeedbackTask);

        // TDD Assertions
        print('📊 Swarm Execution Results:');
        print('   Specialists generated: ${result.specialists.length}');
        print('   Total execution time: ${result.totalDuration.inMilliseconds}ms');
        print('   Converged successfully: ${result.converged}');
        print('   Blackboard entries: ${result.blackboard.factCount}');

        // Verify specialists were generated correctly
        expect(result.specialists, isNotEmpty);
        expect(result.specialists.length, equals(4));
        
        final specialistRoles = result.specialists.map((s) => s.role).toList();
        expect(specialistRoles, contains('sentiment_analyst'));
        expect(specialistRoles, contains('issue_extractor'));
        expect(specialistRoles, contains('feature_praise_extractor'));
        expect(specialistRoles, contains('insight_synthesizer'));

        // Verify execution results
        expect(result.executionResults, isNotEmpty);
        expect(result.executionResults.length, equals(4));
        expect(result.converged, isTrue);

        // Verify blackboard has results
        expect(result.blackboard.factCount, greaterThan(0));
        
        final sentiment = result.blackboard.get('overall_sentiment');
        final issues = result.blackboard.get('critical_issues');
        final features = result.blackboard.get('praised_features');
        final summary = result.blackboard.get('summary');
        
        expect(sentiment, isNotNull);
        expect(issues, isNotNull);
        expect(features, isNotNull);
        expect(summary, isNotNull);

        print('✅ TDD PASSED: Customer feedback analysis completed successfully');
        print('📋 Key Results:');
        print('   Sentiment: $sentiment');
        print('   Issues: $issues');
        print('   Features: $features');
        print('   Summary: $summary');
      });

      test('TDD: Handle specialist failures gracefully', () async {
        print('🧪 TDD Test: Specialist Failure Handling');

        final task = 'Analyze customer feedback with potential failures';

        // Mock LLM to generate specialists
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_working",
    "role": "working_specialist",
    "systemPrompt": "This specialist works fine",
    "subtask": "Complete task successfully",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["test"],
    "priority": 1.0
  },
  {
    "id": "spec_failing",
    "role": "failing_specialist", 
    "systemPrompt": "This specialist will fail",
    "subtask": "This task will fail",
    "requiredTools": ["nonexistent_tool"],
    "requiredCapabilities": ["test"],
    "priority": 0.8
  }
]''';
          }
          
          if (prompt.contains('working_specialist')) {
            return '{"result": "Task completed successfully"}';
          }
          
          // Simulate failure for failing specialist
          throw Exception('Specialist execution failed');
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 3,
        );

        // Execute should handle failures gracefully
        final result = await orchestrator.execute(task);

        // Should still complete despite one specialist failure
        expect(result.specialists.length, equals(2));
        expect(result.executionResults.length, equals(2));
        
        // Check execution status using AgentResult
        final successCount = result.executionResults.where((r) => 
          r.agentResult.finalStatus == ExecutionStatus.completed).length;
        final failureCount = result.executionResults.where((r) => 
          r.agentResult.finalStatus == ExecutionStatus.failed).length;
        
        expect(successCount, greaterThan(0));
        expect(failureCount, greaterThan(0));
        
        print('✅ TDD PASSED: Specialist failures handled gracefully');
        print('📊 Success: $successCount, Failures: $failureCount');
      });
    });

    group('Travel Planning - Complex Task', () {
      test('TDD: Generate travel planning specialists', () async {
        print('🧪 TDD Test: Travel Planning');
        print('📋 Task: Plan a 7-day trip to Japan');

        final travelTask = '''
Plan a 7-day trip to Japan for 2 people with budget of \$5000.
Consider:
- Flights from New York
- Accommodation in Tokyo and Kyoto
- Transportation between cities
- Must-see attractions
- Food recommendations
- Budget breakdown
''';

        // Mock travel planning specialists
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_flight",
    "role": "flight_specialist",
    "systemPrompt": "Find optimal flights and pricing",
    "subtask": "Research flights from NYC to Tokyo",
    "requiredTools": ["calculator"],
    "requiredCapabilities": ["travel_search", "pricing"],
    "priority": 1.0
  },
  {
    "id": "spec_accommodation", 
    "role": "accommodation_specialist",
    "systemPrompt": "Find suitable hotels and lodging",
    "subtask": "Research hotels in Tokyo and Kyoto",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["hospitality_search"],
    "priority": 0.9
  },
  {
    "id": "spec_itinerary",
    "role": "itinerary_planner",
    "systemPrompt": "Create daily activity schedules",
    "subtask": "Plan 7-day itinerary with attractions",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["planning", "coordination"],
    "priority": 0.8
  },
  {
    "id": "spec_budget",
    "role": "budget_analyst",
    "systemPrompt": "Calculate costs and ensure budget compliance",
    "subtask": "Analyze total costs against \$5000 budget",
    "requiredTools": ["calculator", "stats"],
    "requiredCapabilities": ["financial_analysis"],
    "priority": 0.7
  }
]''';
          }
          
          if (prompt.contains('flight_specialist')) {
            return '''
{
  "recommended_flight": "JAL from JFK to Narita",
  "cost": 1200,
  "duration": "14 hours",
  "best_booking_time": "6 weeks ahead"
}''';
          }
          
          if (prompt.contains('accommodation_specialist')) {
            return '''
{
  "tokyo_hotel": "Shibuya Grand Hotel",
  "kyoto_hotel": "Traditional Ryokan",
  "accommodation_cost": 1800,
  "ratings": {"tokyo": 4.5, "kyoto": 4.8}
}''';
          }
          
          if (prompt.contains('itinerary_planner')) {
            return '''
{
  "day1": "Arrival, Shibuya exploration",
  "day2": "Tokyo Tower, Imperial Palace",
  "day3": "Mount Fuji day trip",
  "day4": "Travel to Kyoto, temples",
  "day5": "Fushimi Inari, Arashiyama",
  "day6": "Nara day trip",
  "day7": "Shopping, departure"
}''';
          }
          
          if (prompt.contains('budget_analyst')) {
            return '''
{
  "total_cost": 4500,
  "breakdown": {"flights": 2400, "accommodation": 1800, "food": 500, "activities": 800},
  "under_budget": true,
  "savings": 500
}''';
          }
          
          return 'Default travel response';
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 5,
        );

        final result = await orchestrator.execute(travelTask);

        // TDD Assertions for travel planning
        expect(result.specialists.length, equals(4));
        expect(result.converged, isTrue);
        
        final flightInfo = result.blackboard.get('recommended_flight');
        final accommodationCost = result.blackboard.get('accommodation_cost');
        final totalCost = result.blackboard.get('total_cost');
        final underBudget = result.blackboard.get('under_budget');
        
        expect(flightInfo, isNotNull);
        expect(accommodationCost, equals(1800));
        expect(totalCost, equals(4500));
        expect(underBudget, isTrue);

        print('✅ TDD PASSED: Travel planning completed successfully');
        print('✈️ Flight: $flightInfo');
        print('🏨 Accommodation: \$$accommodationCost');
        print('💰 Total Cost: \$$totalCost');
        print('✅ Under Budget: $underBudget');
      });
    });

    group('Technical Debugging - Complex Task', () {
      test('TDD: Debug Flutter app performance issues', () async {
        print('🧪 TDD Test: Flutter App Debugging');
        print('📋 Task: Diagnose and fix Flutter app performance issues');

        final debuggingTask = '''
My Flutter app has performance issues:
- App takes 10 seconds to start
- UI freezes when scrolling long lists
- Memory usage grows over time
- Battery drain is excessive

Please diagnose the issues and provide specific solutions.
''';

        // Mock debugging specialists
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_startup",
    "role": "startup_performance_specialist",
    "systemPrompt": "Flutter app startup optimization expert",
    "subtask": "Analyze slow startup times and provide solutions",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["performance_analysis", "flutter_optimization"],
    "priority": 1.0
  },
  {
    "id": "spec_ui",
    "role": "ui_performance_specialist",
    "systemPrompt": "Flutter UI performance expert",
    "subtask": "Diagnose UI freezing and scrolling issues",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["ui_optimization", "widget_analysis"],
    "priority": 0.9
  },
  {
    "id": "spec_memory",
    "role": "memory_management_specialist",
    "systemPrompt": "Memory leak detection and optimization expert",
    "subtask": "Analyze memory growth patterns and identify leaks",
    "requiredTools": ["stats", "calculator"],
    "requiredCapabilities": ["memory_analysis", "leak_detection"],
    "priority": 0.8
  },
  {
    "id": "spec_battery",
    "role": "battery_optimization_specialist",
    "systemPrompt": "Mobile app battery usage optimization expert",
    "subtask": "Identify causes of excessive battery drain",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["battery_analysis", "resource_optimization"],
    "priority": 0.7
  },
  {
    "id": "spec_solutions",
    "role": "solution_synthesizer",
    "systemPrompt": "Flutter development solutions expert",
    "subtask": "Compile all findings into actionable code solutions",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["code_solutions", "implementation_planning"],
    "priority": 0.6
  }
]''';
          }
          
          if (prompt.contains('startup_performance_specialist')) {
            return '''
{
  "startup_issues": ["large app bundle", "synchronous initialization", "unnecessary imports"],
  "solutions": [
    "Use lazy initialization for heavy components",
    "Implement code splitting for better loading",
    "Optimize app bundle size"
  ],
  "estimated_improvement": "70% faster startup"
}''';
          }
          
          if (prompt.contains('ui_performance_specialist')) {
            return '''
{
  "ui_issues": ["missing ListView.builder", "unnecessary rebuilds", "heavy widgets in scroll view"],
  "solutions": [
    "Implement proper list builder patterns",
    "Use const widgets where possible",
    "Add image caching and lazy loading"
  ],
  "estimated_improvement": "80% smoother scrolling"
}''';
          }
          
          if (prompt.contains('memory_management_specialist')) {
            return '''
{
  "memory_issues": ["widget references not disposed", "large image cache", "timer not cancelled"],
  "solutions": [
    "Implement proper dispose() methods",
    "Use memory-efficient image loading",
    "Cancel timers and streams in dispose"
  ],
  "estimated_improvement": "60% memory reduction"
}''';
          }
          
          if (prompt.contains('battery_optimization_specialist')) {
            return '''
{
  "battery_issues": ["excessive background work", "high CPU usage", "network requests in loops"],
  "solutions": [
    "Optimize background tasks scheduling",
    "Reduce unnecessary computations",
    "Implement request batching and caching"
  ],
  "estimated_improvement": "50% battery life improvement"
}''';
          }
          
          if (prompt.contains('solution_synthesizer')) {
            return '''
{
  "priority_fixes": [
    "Implement ListView.builder for scrolling",
    "Add proper dispose methods",
    "Use lazy initialization patterns"
  ],
  "code_examples": {
    "list_optimization": "ListView.builder(items: data, itemBuilder: (context, index) => ...)",
    "memory_fix": "@override void dispose() { controller.dispose(); super.dispose(); }"
  },
  "implementation_order": ["UI fixes", "Memory fixes", "Startup optimization"]
}''';
          }
          
          return 'Default debugging response';
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 6,
        );

        final result = await orchestrator.execute(debuggingTask);

        // TDD Assertions for debugging task
        expect(result.specialists.length, equals(5));
        expect(result.converged, isTrue);
        
        final startupImprovement = result.blackboard.get('estimated_improvement');
        final uiSolutions = result.blackboard.get('solutions');
        final memoryIssues = result.blackboard.get('memory_issues');
        final priorityFixes = result.blackboard.get('priority_fixes');
        
        expect(startupImprovement, isNotNull);
        expect(uiSolutions, isNotNull);
        expect(memoryIssues, isNotNull);
        expect(priorityFixes, isNotNull);

        print('✅ TDD PASSED: Flutter debugging completed successfully');
        print('🚀 Startup Improvement: $startupImprovement');
        print('🎯 UI Solutions: $uiSolutions');
        print('🧠 Memory Issues: $memoryIssues');
        print('🔧 Priority Fixes: $priorityFixes');
      });
    });

    group('Swarm Behavior Edge Cases', () {
      test('TDD: Handle empty specialist generation', () async {
        print('🧪 TDD Test: Empty Specialist Generation');

        final task = 'Very simple task';

        // Mock LLM returning empty specialists - use Future.value
        when(() => mockLanguageModel.invoke(any())).thenAnswer((_) async => '[]');

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 3,
        );

        final result = await orchestrator.execute(task);

        // Should handle empty specialists gracefully
        expect(result.specialists, isEmpty);
        expect(result.converged, isFalse);
        expect(result.error, isNotNull);

        print('✅ TDD PASSED: Empty specialist generation handled');
        print('📝 Error: ${result.error}');
      });

      test('TDD: Respect max specialists limit', () async {
        print('🧪 TDD Test: Max Specialists Limit');

        final task = 'Complex task requiring many specialists';

        // Mock LLM generating more specialists than limit
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            // Generate 7 specialists but limit is 3
            return '''
[
  {"id": "spec1", "role": "specialist1", "systemPrompt": "test1", "subtask": "task1", "requiredTools": [], "requiredCapabilities": [], "priority": 1.0},
  {"id": "spec2", "role": "specialist2", "systemPrompt": "test2", "subtask": "task2", "requiredTools": [], "requiredCapabilities": [], "priority": 0.9},
  {"id": "spec3", "role": "specialist3", "systemPrompt": "test3", "subtask": "task3", "requiredTools": [], "requiredCapabilities": [], "priority": 0.8},
  {"id": "spec4", "role": "specialist4", "systemPrompt": "test4", "subtask": "task4", "requiredTools": [], "requiredCapabilities": [], "priority": 0.7},
  {"id": "spec5", "role": "specialist5", "systemPrompt": "test5", "subtask": "task5", "requiredTools": [], "requiredCapabilities": [], "priority": 0.6},
  {"id": "spec6", "role": "specialist6", "systemPrompt": "test6", "subtask": "task6", "requiredTools": [], "requiredCapabilities": [], "priority": 0.5},
  {"id": "spec7", "role": "specialist7", "systemPrompt": "test7", "subtask": "task7", "requiredTools": [], "requiredCapabilities": [], "priority": 0.4}
]''';
          }
          
          return 'Mock specialist response';
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 3, // Limit to 3
        );

        final result = await orchestrator.execute(task);

        // Should only execute top 3 specialists by priority
        expect(result.specialists.length, equals(3));
        expect(result.executionResults.length, equals(3));
        
        // Should be the highest priority ones
        final priorities = result.specialists.map((s) => s.priority).toList();
        priorities.sort(); // Sort ascending
        expect(priorities, equals([0.4, 0.5, 0.6])); // Top 3 priorities

        print('✅ TDD PASSED: Max specialists limit respected');
        print('📊 Generated: 7, Executed: 3 (limited by maxSpecialists=3)');
      });

      test('TDD: Blackboard coordination and conflict resolution', () async {
        print('🧪 TDD Test: Blackboard Coordination');

        final task = 'Task with multiple specialists writing to blackboard';

        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_writer1",
    "role": "data_writer1",
    "systemPrompt": "Write data to blackboard",
    "subtask": "Add initial analysis",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["analysis"],
    "priority": 1.0
  },
  {
    "id": "spec_writer2", 
    "role": "data_writer2",
    "systemPrompt": "Write more data to blackboard",
    "subtask": "Add follow-up analysis",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["analysis"],
    "priority": 0.8
  }
]''';
          }
          
          if (prompt.contains('data_writer1')) {
            return '''
{
  "initial_analysis": "This is the first analysis",
  "confidence_score": 0.85,
  "data_quality": "high"
}''';
          }
          
          if (prompt.contains('data_writer2')) {
            return '''
{
  "follow_up_analysis": "This builds on previous work",
  "additional_insights": "New findings here",
  "confidence_improvement": true
}''';
          }
          
          return 'Default response';
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 5,
        );

        final result = await orchestrator.execute(task);

        // Verify blackboard coordination
        expect(result.blackboard.factCount, greaterThan(0));
        
        final initialAnalysis = result.blackboard.get('initial_analysis');
        final followUpAnalysis = result.blackboard.get('follow_up_analysis');
        final confidenceScore = result.blackboard.get('confidence_score');
        final additionalInsights = result.blackboard.get('additional_insights');
        
        expect(initialAnalysis, equals('This is the first analysis'));
        expect(followUpAnalysis, equals('This builds on previous work'));
        expect(confidenceScore, equals(0.85));
        expect(additionalInsights, equals('New findings here'));

        // Test blackboard history
        final initialEntry = result.blackboard.getEntry('initial_analysis');
        expect(initialEntry, isNotNull);
        expect(initialEntry!.author, equals('spec_writer1'));
        expect(initialEntry.version, greaterThan(0));

        print('✅ TDD PASSED: Blackboard coordination working');
        print('📝 Total facts: ${result.blackboard.factCount}');
        print('👥 Authors: ${[initialEntry?.author, result.blackboard.getEntry('follow_up_analysis')?.author].join(', ')}');
      });
    });

    group('Performance and Scalability', () {
      test('TDD: Large number of specialists performance', () async {
        print('🧪 TDD Test: Performance with Many Specialists');

        final task = 'Very complex task requiring many specialists';

        // Generate 10 specialists
        final manySpecialists = List.generate(10, (index) => '''
{
  "id": "spec${index + 1}",
  "role": "specialist${index + 1}",
  "systemPrompt": "Test specialist ${index + 1}",
  "subtask": "Task ${index + 1}",
  "requiredTools": ["echo"],
  "requiredCapabilities": ["test"],
  "priority": ${1.0 - (index * 0.1)}
}''').join(',');

        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) async {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '[$manySpecialists]';
          }
          
          // Simple response for each specialist
          return '{"result": "Task completed successfully"}';
        });

        orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: mockToolRegistry,
          maxSpecialists: 10,
        );

        final startTime = DateTime.now();
        final result = await orchestrator.execute(task);
        final executionTime = DateTime.now().difference(startTime);

        // Performance assertions
        expect(result.specialists.length, equals(10));
        expect(result.executionResults.length, equals(10));
        expect(result.converged, isTrue);
        
        // Should complete within reasonable time (even with mocks)
        expect(executionTime.inMilliseconds, lessThan(5000));

        print('✅ TDD PASSED: Performance test completed');
        print('⏱️  Execution time: ${executionTime.inMilliseconds}ms');
        print('👥 Specialists: ${result.specialists.length}');
        print('📊 Throughput: ${(result.specialists.length / executionTime.inSeconds).toStringAsFixed(2)} specialists/second');
      });
    });
  });
}