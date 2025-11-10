/// Swarm Blackboard Integration Tests
/// Tests the blackboard coordination system using mocks

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:micro/infrastructure/ai/agent/swarm/blackboard.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/agent/models/agent_models.dart';

void main() {
  group('Swarm Blackboard Integration Tests', () {
    late Blackboard blackboard;
    late ToolRegistry toolRegistry;
    late MockLanguageModel mockLanguageModel;

    setUp(() {
      blackboard = Blackboard();
      toolRegistry = ToolRegistry();
      mockLanguageModel = MockLanguageModel();
      
      // Register basic tools
      toolRegistry.register(EchoTool());
      toolRegistry.register(CalculatorTool());
      toolRegistry.register(KnowledgeBaseTool());
    });

    group('Blackboard Basic Operations', () {
      test('TDD: Basic blackboard read/write operations', () {
        print('🧪 TDD Test: Blackboard Basic Operations');

        // Test writing and reading different data types
        blackboard.write('string_value', 'Hello World', author: 'test_spec_1');
        blackboard.write('number_value', 42, author: 'test_spec_1');
        blackboard.write('list_value', [1, 2, 3], author: 'test_spec_1');
        blackboard.write('map_value', {'key': 'value'}, author: 'test_spec_1');

        // Test reading values
        expect(blackboard.get('string_value'), equals('Hello World'));
        expect(blackboard.get('number_value'), equals(42));
        expect(blackboard.get('list_value'), equals([1, 2, 3]));
        expect(blackboard.get('map_value'), equals({'key': 'value'}));

        // Test fact count
        expect(blackboard.factCount, equals(4));

        // Test getting all facts
        final allFacts = blackboard.getAllFacts();
        expect(allFacts.length, equals(4));
        expect(allFacts['string_value'], equals('Hello World'));

        print('✅ TDD PASSED: Basic operations work');
        print('📝 Facts: ${allFacts.keys.join(', ')}');
      });

      test('TDD: Blackboard version control and history', () {
        print('🧪 TDD Test: Blackboard Version Control');

        // Write initial value
        blackboard.write('test_key', 'version1', author: 'spec1');
        expect(blackboard.get('test_key'), equals('version1'));

        // Update value
        blackboard.write('test_key', 'version2', author: 'spec2');
        expect(blackboard.get('test_key'), equals('version2'));

        // Update again
        blackboard.write('test_key', 'version3', author: 'spec1');
        expect(blackboard.get('test_key'), equals('version3'));

        // Check history
        final history = blackboard.getHistory('test_key');
        expect(history.length, equals(3));
        expect(history[0].data, equals('version1'));
        expect(history[1].data, equals('version2'));
        expect(history[2].data, equals('version3'));

        // Check authors and versions
        expect(history[0].author, equals('spec1'));
        expect(history[1].author, equals('spec2'));
        expect(history[2].author, equals('spec1'));
        expect(history[0].version, equals(1));
        expect(history[1].version, equals(2));
        expect(history[2].version, equals(3));

        // Check current entry
        final currentEntry = blackboard.getEntry('test_key');
        expect(currentEntry!.data, equals('version3'));
        expect(currentEntry.author, equals('spec1'));
        expect(currentEntry.version, equals(3));

        print('✅ TDD PASSED: Version control works');
        print('📜 History length: ${history.length}');
        print('📝 Current version: ${currentEntry.version}');
      });

      test('TDD: Blackboard query system', () {
        print('🧪 TDD Test: Blackboard Query System');

        // Populate blackboard with diverse data
        blackboard.write('analysis_result', 0.85, author: 'analyst');
        blackboard.write('error_rate', 0.05, author: 'monitor');
        blackboard.write('recommendation', 'deploy', author: 'advisor');
        blackboard.write('user_feedback', 'positive', author: 'collector');
        blackboard.write('performance_score', 92.5, author: 'profiler');
        blackboard.write('memory_usage', 512, author: 'monitor');
        blackboard.write('cpu_load', 75.3, author: 'monitor');

        // Test numeric queries
        final numericFacts = blackboard.query((key, entry) => entry.data is num);
        expect(numericFacts.length, equals(5)); // 0.85, 0.05, 92.5, 512, 75.3

        // Test author queries
        final monitorFacts = blackboard.query((key, entry) => entry.author == 'monitor');
        expect(monitorFacts.length, equals(3)); // error_rate, memory_usage, cpu_load

        // Test value range queries
        final highScores = blackboard.query((key, entry) => entry.data is num && (entry.data as num) > 50);
        expect(highScores.length, equals(3)); // 92.5, 512, 75.3

        // Test key pattern queries
        final scoreFacts = blackboard.query((key, entry) => key.contains('score'));
        expect(scoreFacts.length, equals(1)); // performance_score

        // Test complex queries
        final complexQuery = blackboard.query((key, entry) => 
          entry.author == 'monitor' && entry.data is num && (entry.data as num) > 50);
        expect(complexQuery.length, equals(2)); // memory_usage, cpu_load

        print('✅ TDD PASSED: Query system works');
        print('📊 Total facts: ${blackboard.factCount}');
        print('🔢 Numeric facts: ${numericFacts.length}');
        print('👥 Monitor facts: ${monitorFacts.length}');
        print('🎯 High scores: ${highScores.length}');
      });
    });

    group('Blackboard Convergence Detection', () {
      test('TDD: Detect convergence when specialists agree', () {
        print('🧪 TDD Test: Convergence Detection');

        // Multiple specialists write similar results (indicating agreement)
        blackboard.write('confidence', 0.85, author: 'spec1');
        blackboard.write('confidence', 0.87, author: 'spec2');
        blackboard.write('confidence', 0.86, author: 'spec3');

        // Also write some consistent supporting data
        blackboard.write('analysis_complete', true, author: 'spec1');
        blackboard.write('analysis_complete', true, author: 'spec2');
        blackboard.write('quality_score', 0.9, author: 'spec1');
        blackboard.write('quality_score', 0.88, author: 'spec2');

        // Test convergence detection
        final convergence = blackboard.checkForConvergence();
        expect(converged, isTrue);

        print('✅ TDD PASSED: Convergence detected');
        print('🤝 Converged: $converged');
        print('📊 Fact count: ${blackboard.factCount}');
      });

      test('TDD: No convergence with conflicting data', () {
        print('🧪 TDD Test: No Convergence with Conflicts');

        // Specialists write conflicting results
        blackboard.write('recommendation', 'deploy', author: 'spec1');
        blackboard.write('recommendation', 'wait', author: 'spec2');
        blackboard.write('recommendation', 'reject', author: 'spec3');

        // Add some scattered numerical data
        blackboard.write('confidence', 0.9, author: 'spec1');
        blackboard.write('confidence', 0.3, author: 'spec2');

        // Test convergence detection
        final convergence = blackboard.checkForConvergence();
        expect(converged, isFalse);

        print('✅ TDD PASSED: No convergence correctly detected');
        print('⚠️  Converged: $converged');
        print('📊 Fact count: ${blackboard.factCount}');
      });

      test('TDD: Convergence with partial agreement', () {
        print('🧪 TDD Test: Partial Convergence');

        // Mix of agreeing and disagreeing data
        blackboard.write('ui_performance', 'excellent', author: 'ui_spec');
        blackboard.write('ui_performance', 'excellent', author: 'test_spec');
        blackboard.write('backend_performance', 'poor', author: 'backend_spec');
        blackboard.write('backend_performance', 'excellent', author: 'ops_spec');
        blackboard.write('overall_score', 8.5, author: 'analyst');
        blackboard.write('overall_score', 8.7, author: 'reviewer');

        // Should not converge due to conflicting backend performance
        final convergence = blackboard.checkForConvergence();
        expect(converged, isFalse);

        print('✅ TDD PASSED: Partial convergence handled correctly');
        print('📊 Converged: $converged');
        print('🔍 Areas of agreement: ui_performance, overall_score');
        print('⚠️  Areas of conflict: backend_performance');
      });
    });

    group('Blackboard Swarm Integration', () {
      test('TDD: Blackboard coordination during swarm execution', () async {
        print('🧪 TDD Test: Blackboard-Swarm Integration');

        final task = 'Analyze system performance and provide recommendations';

        // Mock specialists that coordinate through blackboard
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_monitor",
    "role": "performance_monitor",
    "systemPrompt": "Monitor system performance metrics",
    "subtask": "Collect performance data",
    "requiredTools": ["calculator"],
    "requiredCapabilities": ["monitoring"],
    "priority": 1.0
  },
  {
    "id": "spec_analyst",
    "role": "performance_analyst",
    "systemPrompt": "Analyze performance data",
    "subtask": "Interpret metrics and identify issues",
    "requiredTools": ["knowledge_base"],
    "requiredCapabilities": ["analysis"],
    "priority": 0.8
  },
  {
    "id": "spec_advisor",
    "role": "performance_advisor",
    "systemPrompt": "Provide optimization recommendations",
    "subtask": "Suggest improvements based on analysis",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["advisory"],
    "priority": 0.6
  }
]''';
          }
          
          if (prompt.contains('performance_monitor')) {
            return '''
{
  "cpu_usage": 75.2,
  "memory_usage": 68.5,
  "disk_io": 45.8,
  "network_latency": 120.5,
  "collection_timestamp": "2025-01-10T12:00:00Z"
}''';
          }
          
          if (prompt.contains('performance_analyst')) {
            return '''
{
  "analysis_summary": "CPU usage is high, memory is acceptable",
  "identified_issues": ["high_cpu", "moderate_network_latency"],
  "severity_level": "medium",
  "trend_analysis": "CPU usage increasing over time"
}''';
          }
          
          if (prompt.contains('performance_advisor')) {
            return '''
{
  "primary_recommendation": "Optimize CPU-intensive operations",
  "secondary_recommendations": ["Implement caching", "Upgrade network infrastructure"],
  "priority_actions": ["Profile CPU usage", "Optimize database queries"],
  "expected_improvement": "35% performance boost"
}''';
          }
          
          return 'Default response';
        });

        final orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: toolRegistry,
          maxSpecialists: 5,
        );

        final result = await orchestrator.execute(task);

        // Verify blackboard coordination
        expect(result.specialists.length, equals(3));
        expect(result.converged, isTrue);
        expect(result.blackboard.factCount, greaterThan(10));

        // Check that data flows correctly between specialists
        final cpuUsage = result.blackboard.get('cpu_usage');
        final issues = result.blackboard.get('identified_issues');
        final recommendation = result.blackboard.get('primary_recommendation');
        final improvement = result.blackboard.get('expected_improvement');

        expect(cpuUsage, equals(75.2));
        expect(issues, contains('high_cpu'));
        expect(recommendation, contains('Optimize CPU'));
        expect(improvement, equals('35% performance boost'));

        // Verify data source tracking
        final cpuEntry = result.blackboard.getEntry('cpu_usage');
        final issuesEntry = result.blackboard.getEntry('identified_issues');
        
        expect(cpuEntry!.author, equals('spec_monitor'));
        expect(issuesEntry!.author, equals('spec_analyst'));

        print('✅ TDD PASSED: Blackboard-Swarm integration successful');
        print('📊 Total facts: ${result.blackboard.factCount}');
        print('💻 CPU Usage: $cpuUsage%');
        print('🚨 Issues: $issues');
        print('💡 Recommendation: $recommendation');
        print('📈 Expected Improvement: $improvement');
      });

      test('TDD: Handle blackboard conflicts during swarm execution', () async {
        print('🧪 TDD Test: Blackboard Conflict Handling');

        final task = 'Analyze user feedback with conflicting opinions';

        // Mock specialists with conflicting analyses
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_positive",
    "role": "positive_analyst",
    "systemPrompt": "Focus on positive aspects",
    "subtask": "Find positive feedback patterns",
    "requiredTools": ["sentiment"],
    "requiredCapabilities": ["positive_analysis"],
    "priority": 1.0
  },
  {
    "id": "spec_negative",
    "role": "negative_analyst", 
    "systemPrompt": "Focus on negative aspects",
    "subtask": "Find negative feedback patterns",
    "requiredTools": ["sentiment"],
    "requiredCapabilities": ["negative_analysis"],
    "priority": 1.0
  },
  {
    "id": "spec_synthesizer",
    "role": "balanced_synthesizer",
    "systemPrompt": "Create balanced perspective",
    "subtask": "Synthesize conflicting views into balanced report",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["synthesis", "balance"],
    "priority": 0.7
  }
]''';
          }
          
          if (prompt.contains('positive_analyst')) {
            return '''
{
  "user_sentiment": "mostly_positive",
  "satisfaction_score": 8.2,
  "praised_features": ["ui_design", "performance", "reliability"],
  "positive_feedback_percentage": 75
}''';
          }
          
          if (prompt.contains('negative_analyst')) {
            return '''
{
  "user_sentiment": "mostly_negative",
  "satisfaction_score": 4.1,
          "critical_issues": ["bugs", "slow_loading", "poor_support"],
  "negative_feedback_percentage": 65
}''';
          }
          
          if (prompt.contains('balanced_synthesizer')) {
            return '''
{
  "balanced_sentiment": "mixed_feedback",
  "average_satisfaction": 6.15,
  "key_insights": "Strong UI but critical bugs need attention",
  "priority_actions": ["Fix critical bugs", "Maintain UI quality", "Improve support"],
  "recommendation": "Address stability issues while preserving strengths"
}''';
          }
          
          return 'Default response';
        });

        final orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: toolRegistry,
          maxSpecialists: 4,
        );

        final result = await orchestrator.execute(task);

        // Verify conflict handling
        expect(result.specialists.length, equals(3));
        expect(result.converged, isTrue); // Should converge with synthesizer
        
        // Check that conflicting data is preserved
        final positiveSentiment = result.blackboard.getHistory('user_sentiment');
        expect(positiveSentiment.length, equals(2)); // Both conflicting values
        expect(positiveSentiment[0].data, equals('mostly_positive'));
        expect(positiveSentiment[1].data, equals('mostly_negative'));

        // Check that synthesizer resolved the conflict
        final balancedSentiment = result.blackboard.get('balanced_sentiment');
        final priorityActions = result.blackboard.get('priority_actions');
        
        expect(balancedSentiment, equals('mixed_feedback'));
        expect(priorityActions, contains('Fix critical bugs'));

        print('✅ TDD PASSED: Blackboard conflicts handled correctly');
        print('⚖️  Conflicting sentiment values preserved');
        print('🔄 Synthesizer created balanced view');
        print('📋 Priority actions: $priorityActions');
      });
    });

    group('Blackboard Performance', () {
      test('TDD: Blackboard performance with many entries', () {
        print('🧪 TDD Test: Blackboard Performance');

        final startTime = DateTime.now();

        // Add many entries to test performance
        for (int i = 0; i < 1000; i++) {
          blackboard.write('key_$i', 'value_$i', author: 'spec_${i % 10}');
        }

        final writeTime = DateTime.now().difference(startTime);

        // Test read performance
        final readStartTime = DateTime.now();
        for (int i = 0; i < 1000; i++) {
          blackboard.get('key_$i');
        }
        final readTime = DateTime.now().difference(readStartTime);

        // Test query performance
        final queryStartTime = DateTime.now();
        final author5Facts = blackboard.query((key, entry) => entry.author == 'spec_5');
        final queryTime = DateTime.now().difference(queryStartTime);

        // Performance assertions
        expect(blackboard.factCount, equals(1000));
        expect(author5Facts.length, equals(100)); // 1000 entries / 10 specialists
        
        // Should be reasonably fast even with 1000 entries
        expect(writeTime.inMilliseconds, lessThan(100));
        expect(readTime.inMilliseconds, lessThan(50));
        expect(queryTime.inMilliseconds, lessThan(10));

        print('✅ TDD PASSED: Blackboard performance is excellent');
        print('📝 1000 entries written in ${writeTime.inMilliseconds}ms');
        print('📖 1000 entries read in ${readTime.inMilliseconds}ms');
        print('🔍 Query completed in ${queryTime.inMilliseconds}ms');
        print('👊 Facts by spec_5: ${author5Facts.length}');
      });
    });
  });
}

class MockLanguageModel extends Mock {
  dynamic invoke(String prompt) => super.noSuchMethod(
    Invocation.method(#invoke, [prompt]),
    returnValue: 'Default mock response',
  );
}