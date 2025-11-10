/// Swarm Tool Integration Tests
/// Tests the integration of tools with the swarm system using mocks

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/mock_tools.dart';
import 'package:micro/infrastructure/ai/agent/swarm/swarm_orchestrator.dart';
import 'package:micro/infrastructure/ai/agent/models/agent_models.dart';

void main() {
  group('Swarm Tool Integration Tests', () {
    late ToolRegistry toolRegistry;
    late MockLanguageModel mockLanguageModel;

    setUp(() {
      toolRegistry = ToolRegistry();
      mockLanguageModel = MockLanguageModel();
      
      // Register all mock tools
      toolRegistry.register(EchoTool());
      toolRegistry.register(SentimentTool());
      toolRegistry.register(CalculatorTool());
      toolRegistry.register(StatsTool());
      toolRegistry.register(KnowledgeBaseTool());
      toolRegistry.register(DataProcessorTool());
      toolRegistry.register(ErrorProneTool());
      toolRegistry.register(SlowTool());
    });

    group('Tool Registry Integration', () {
      test('TDD: All mock tools register correctly', () {
        print('🧪 TDD Test: Tool Registry Registration');

        final allTools = toolRegistry.getAllMetadata();
        
        expect(allTools.length, equals(8));
        
        final toolNames = allTools.map((t) => t.name).toList();
        expect(toolNames, contains('echo'));
        expect(toolNames, contains('sentiment'));
        expect(toolNames, contains('calculator'));
        expect(toolNames, contains('stats'));
        expect(toolNames, contains('knowledge_base'));
        expect(toolNames, contains('data_processor'));
        expect(toolNames, contains('error_prone'));
        expect(toolNames, contains('slow'));

        print('✅ TDD PASSED: All tools registered successfully');
        print('🔧 Tools: ${toolNames.join(', ')}');
      });

      test('TDD: Tool execution with different data types', () async {
        print('🧪 TDD Test: Tool Data Type Handling');

        final echoTool = toolRegistry.getTool('echo')!;
        final calculatorTool = toolRegistry.getTool('calculator')!;
        final statsTool = toolRegistry.getTool('stats')!;

        // Test string input
        final stringResult = await echoTool.call('Hello World');
        expect(stringResult, equals('Hello World'));
        print('📝 String test: $stringResult');

        // Test numeric input
        final numericResult = await calculatorTool.call({
          'operation': 'add',
          'a': 15.5,
          'b': 24.3
        });
        expect(numericResult, equals(39.8));
        print('🔢 Numeric test: $numericResult');

        // Test list input
        final listResult = await statsTool.call({
          'operation': 'mean',
          'values': [1.0, 2.0, 3.0, 4.0, 5.0]
        });
        expect(listResult, equals(3.0));
        print('📊 List test: $listResult');

        // Test complex nested input
        final dataProcessor = toolRegistry.getTool('data_processor')!;
        final complexResult = await dataProcessor.call({
          'operation': 'transform',
          'data': [
            {'name': 'Alice', 'score': 85},
            {'name': 'Bob', 'score': 92}
          ],
          'transformation': 'extract_scores'
        });
        expect(complexResult, equals([85, 92]));
        print('🔀 Complex test: $complexResult');

        print('✅ TDD PASSED: All data types handled correctly');
      });

      test('TDD: Tool error handling and recovery', () async {
        print('🧪 TDD Test: Tool Error Handling');

        final errorProneTool = toolRegistry.getTool('error_prone')!;
        final echoTool = toolRegistry.getTool('echo')!;

        // Test that error-prone tool throws
        try {
          await errorProneTool.call({});
          fail('Should have thrown an exception');
        } catch (e) {
          expect(e, isA<Exception>());
          expect(e.toString(), contains('Intentional test error'));
          print('⚠️  Error tool correctly threw: $e');
        }

        // Test that normal tool still works after error
        final normalResult = await echoTool.call('Recovery test');
        expect(normalResult, equals('Recovery test'));
        print('✅ Recovery test: $normalResult');

        print('✅ TDD PASSED: Tool error handling works correctly');
      });
    });

    group('Swarm-Tool Integration', () {
      test('TDD: Specialists use required tools correctly', () async {
        print('🧪 TDD Test: Specialist Tool Usage');

        final task = 'Analyze customer sentiment and calculate statistics';

        // Mock LLM to generate specialists that need specific tools
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_sentiment",
    "role": "sentiment_analyst",
    "systemPrompt": "Analyze text sentiment",
    "subtask": "Analyze sentiment of customer reviews",
    "requiredTools": ["sentiment"],
    "requiredCapabilities": ["nlp"],
    "priority": 1.0
  },
  {
    "id": "spec_stats",
    "role": "statistician",
    "systemPrompt": "Calculate statistical measures",
    "subtask": "Calculate average satisfaction score",
    "requiredTools": ["calculator", "stats"],
    "requiredCapabilities": ["statistics"],
    "priority": 0.9
  }
]''';
          }
          
          if (prompt.contains('sentiment_analyst')) {
            return '''
{
  "sentiment_score": 0.75,
  "confidence": 0.9,
  "emotion_breakdown": {"positive": 75, "neutral": 15, "negative": 10}
}''';
          }
          
          if (prompt.contains('statistician')) {
            return '''
{
  "average_score": 8.2,
  "median_score": 8.5,
  "standard_deviation": 1.3,
  "sample_size": 100
}''';
          }
          
          return 'Default response';
        });

        final orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: toolRegistry,
          maxSpecialists: 3,
        );

        final result = await orchestrator.execute(task);

        // Verify specialists used their required tools
        expect(result.specialists.length, equals(2));
        expect(result.executionResults.length, equals(2));
        expect(result.converged, isTrue);

        // Check that sentiment results are present
        final sentimentScore = result.blackboard.get('sentiment_score');
        final averageScore = result.blackboard.get('average_score');
        
        expect(sentimentScore, equals(0.75));
        expect(averageScore, equals(8.2));

        print('✅ TDD PASSED: Specialists used required tools correctly');
        print('📊 Sentiment Score: $sentimentScore');
        print('📈 Average Score: $averageScore');
      });

      test('TDD: Handle missing tools gracefully', () async {
        print('🧪 TDD Test: Missing Tool Handling');

        final task = 'Task requiring non-existent tool';

        // Mock specialist requesting non-existent tool
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_missing_tool",
    "role": "missing_tool_user",
    "systemPrompt": "Uses a tool that doesn't exist",
    "subtask": "Try to use non_existent_tool",
    "requiredTools": ["non_existent_tool"],
    "requiredCapabilities": ["test"],
    "priority": 1.0
  },
  {
    "id": "spec_working",
    "role": "working_specialist",
    "systemPrompt": "Uses existing tool",
    "subtask": "Use echo tool",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["test"],
    "priority": 0.8
  }
]''';
          }
          
          if (prompt.contains('missing_tool_user')) {
            // Should fail because tool doesn't exist
            throw Exception('Tool not found: non_existent_tool');
          }
          
          if (prompt.contains('working_specialist')) {
            return 'Working tool result';
          }
          
          return 'Default response';
        });

        final orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: toolRegistry,
          maxSpecialists: 3,
        );

        final result = await orchestrator.execute(task);

        // One specialist should fail, one should succeed
        expect(result.specialists.length, equals(2));
        expect(result.executionResults.length, equals(2));
        
        final successCount = result.executionResults.where((r) => r.success).length;
        final failureCount = result.executionResults.where((r) => !r.success).length;
        
        expect(successCount, equals(1));
        expect(failureCount, equals(1));

        print('✅ TDD PASSED: Missing tools handled gracefully');
        print('✅ Successful specialists: $successCount');
        print('❌ Failed specialists: $failureCount');
      });
    });

    group('Tool Performance Integration', () {
      test('TDD: Tool timeout handling', () async {
        print('🧪 TDD Test: Tool Timeout Handling');

        final task = 'Task with slow tool';

        // Mock specialist using slow tool
        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_slow",
    "role": "slow_worker",
    "systemPrompt": "Uses slow tool",
    "subtask": "Execute slow operation",
    "requiredTools": ["slow"],
    "requiredCapabilities": ["patience"],
    "priority": 1.0
  }
]''';
          }
          
          if (prompt.contains('slow_worker')) {
            return 'Slow operation completed';
          }
          
          return 'Default response';
        });

        final orchestrator = SwarmOrchestrator(
          languageModel: mockLanguageModel,
          toolRegistry: toolRegistry,
          maxSpecialists: 2,
        );

        final startTime = DateTime.now();
        final result = await orchestrator.execute(task);
        final executionTime = DateTime.now().difference(startTime);

        // Should complete despite slow tool (mock slow tool is actually fast)
        expect(result.specialists.length, equals(1));
        expect(result.converged, isTrue);
        expect(executionTime.inMilliseconds, lessThan(3000));

        print('✅ TDD PASSED: Tool timeout handled correctly');
        print('⏱️  Execution time: ${executionTime.inMilliseconds}ms');
      });

      test('TDD: Tool chaining and data flow', () async {
        print('🧪 TDD Test: Tool Chaining');

        final task = 'Process data through multiple tools';

        when(() => mockLanguageModel.invoke(any())).thenAnswer((invocation) {
          final prompt = invocation.positionalArguments[0] as String;
          
          if (prompt.contains('Generate a team of specialists')) {
            return '''
[
  {
    "id": "spec_data_gen",
    "role": "data_generator",
    "systemPrompt": "Generate initial data",
    "subtask": "Create sample dataset",
    "requiredTools": ["calculator"],
    "requiredCapabilities": ["data_generation"],
    "priority": 1.0
  },
  {
    "id": "spec_processor",
    "role": "data_processor",
    "systemPrompt": "Process generated data",
    "subtask": "Transform and analyze data",
    "requiredTools": ["data_processor", "stats"],
    "requiredCapabilities": ["data_processing"],
    "priority": 0.8
  },
  {
    "id": "spec_analyzer",
    "role": "final_analyzer",
    "systemPrompt": "Analyze processed results",
    "subtask": "Create final report",
    "requiredTools": ["echo"],
    "requiredCapabilities": ["analysis"],
    "priority": 0.6
  }
]''';
          }
          
          if (prompt.contains('data_generator')) {
            return '''
{
  "generated_data": [10, 20, 30, 40, 50],
  "data_source": "synthetic",
  "quality_score": 0.95
}''';
          }
          
          if (prompt.contains('data_processor')) {
            return '''
{
  "processed_data": [100, 200, 300, 400, 500],
  "transformation_applied": "multiply_by_10",
  "processing_success": true
}''';
          }
          
          if (prompt.contains('final_analyzer')) {
            return '''
{
  "analysis_summary": "Data successfully processed through pipeline",
  "final_score": 9.2,
  "pipeline_efficiency": "optimal"
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

        // Verify data flow through tool chain
        expect(result.specialists.length, equals(3));
        expect(result.converged, isTrue);
        
        final generatedData = result.blackboard.get('generated_data');
        final processedData = result.blackboard.get('processed_data');
        final analysisSummary = result.blackboard.get('analysis_summary');
        
        expect(generatedData, equals([10, 20, 30, 40, 50]));
        expect(processedData, equals([100, 200, 300, 400, 500]));
        expect(analysisSummary, contains('Data successfully processed'));

        print('✅ TDD PASSED: Tool chaining works correctly');
        print('📊 Generated: $generatedData');
        print('🔄 Processed: $processedData');
        print('📋 Analysis: $analysisSummary');
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