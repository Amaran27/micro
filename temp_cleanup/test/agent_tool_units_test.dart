import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/ai/agent/tools/platform_tools.dart';
import 'package:micro/infrastructure/ai/agent/tools/native_tools.dart';
import 'package:micro/infrastructure/ai/agent/tools/search_tools.dart';

void main() {
  group('Calculator Tool Unit Tests', () {
    late CalculatorTool calculator;

    setUp(() {
      calculator = CalculatorTool();
    });

    test('Addition works correctly', () async {
      final result = await calculator.invoke({
        'operation': 'add',
        'a': 10.0,
        'b': 5.0,
      });
      expect(result, contains('15'));
    });

    test('Subtraction works correctly', () async {
      final result = await calculator.invoke({
        'operation': 'subtract',
        'a': 10.0,
        'b': 5.0,
      });
      expect(result, contains('5'));
    });

    test('Multiplication works correctly', () async {
      final result = await calculator.invoke({
        'operation': 'multiply',
        'a': 10.0,
        'b': 5.0,
      });
      expect(result, contains('50'));
    });

    test('Division works correctly', () async {
      final result = await calculator.invoke({
        'operation': 'divide',
        'a': 10.0,
        'b': 5.0,
      });
      expect(result, contains('2'));
    });

    test('Division by zero returns error', () async {
      final result = await calculator.invoke({
        'operation': 'divide',
        'a': 10.0,
        'b': 0.0,
      });
      expect(result.toLowerCase(), contains('error'));
    });

    test('Invalid operation returns error', () async {
      final result = await calculator.invoke({
        'operation': 'invalid',
        'a': 10.0,
        'b': 5.0,
      });
      expect(result.toLowerCase(), contains('error'));
    });
  });

  group('DateTime Tool Unit Tests', () {
    late DateTimeTool dateTimeTool;

    setUp(() {
      dateTimeTool = DateTimeTool();
    });

    test('Current time returns valid datetime', () async {
      final result = await dateTimeTool.invoke({
        'action': 'current_time',
      });
      expect(result, isNotEmpty);
      // Should contain year in result
      expect(result, contains(DateTime.now().year.toString()));
    });

    test('Format date works', () async {
      final result = await dateTimeTool.invoke({
        'action': 'format',
        'format': 'yyyy-MM-dd',
      });
      expect(result, isNotEmpty);
      expect(result, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
    });
  });

  group('Text Processor Tool Unit Tests', () {
    late TextProcessorTool textProcessor;

    setUp(() {
      textProcessor = TextProcessorTool();
    });

    test('Word count is accurate', () async {
      final result = await textProcessor.invoke({
        'action': 'word_count',
        'text': 'Hello world from Flutter',
      });
      expect(result, contains('4'));
    });

    test('Character count is accurate', () async {
      final result = await textProcessor.invoke({
        'action': 'char_count',
        'text': 'Hello',
      });
      expect(result, contains('5'));
    });

    test('Uppercase conversion works', () async {
      final result = await textProcessor.invoke({
        'action': 'uppercase',
        'text': 'hello',
      });
      expect(result, contains('HELLO'));
    });

    test('Lowercase conversion works', () async {
      final result = await textProcessor.invoke({
        'action': 'lowercase',
        'text': 'HELLO',
      });
      expect(result, contains('hello'));
    });

    test('Text reversal works', () async {
      final result = await textProcessor.invoke({
        'action': 'reverse',
        'text': 'hello',
      });
      expect(result, contains('olleh'));
    });
  });

  group('Platform Info Tool Unit Tests', () {
    late PlatformInfoTool platformInfo;

    setUp(() {
      platformInfo = PlatformInfoTool();
    });

    test('Returns platform information', () async {
      final result = await platformInfo.invoke({});
      expect(result, isNotEmpty);
      expect(result.toLowerCase(), anyOf(
        contains('web'),
        contains('android'),
        contains('ios'),
        contains('desktop'),
      ));
    });
  });

  group('Web Search Tool Unit Tests', () {
    late WebSearchTool webSearch;

    setUp(() {
      webSearch = WebSearchTool();
    });

    test('Returns search framework message when no API configured', () async {
      final result = await webSearch.invoke({
        'query': 'test query',
      });
      expect(result, isNotEmpty);
      // Should indicate search is ready but needs API key
      expect(result.toLowerCase(), anyOf(
        contains('search'),
        contains('api'),
        contains('configure'),
      ));
    });
  });

  group('Knowledge Base Tool Unit Tests', () {
    late KnowledgeBaseTool knowledgeBase;

    setUp(() {
      knowledgeBase = KnowledgeBaseTool();
    });

    test('Returns knowledge base framework message', () async {
      final result = await knowledgeBase.invoke({
        'query': 'test query',
      });
      expect(result, isNotEmpty);
    });
  });

  group('Tool Schema Validation', () {
    test('All tools have valid names', () {
      final tools = [
        CalculatorTool(),
        DateTimeTool(),
        TextProcessorTool(),
        PlatformInfoTool(),
        WebSearchTool(),
        KnowledgeBaseTool(),
      ];

      for (final tool in tools) {
        expect(tool.name, isNotEmpty);
        expect(tool.name, matches(RegExp(r'^[a-z_]+$')));
      }
    });

    test('All tools have descriptions', () {
      final tools = [
        CalculatorTool(),
        DateTimeTool(),
        TextProcessorTool(),
        PlatformInfoTool(),
        WebSearchTool(),
        KnowledgeBaseTool(),
      ];

      for (final tool in tools) {
        expect(tool.description, isNotEmpty);
        expect(tool.description.length, greaterThan(10));
      }
    });
  });
}
