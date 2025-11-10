/// Mock tools for testing and demonstration
/// These implement AgentTool interface for swarm intelligence testing

import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/models/agent_models.dart';
import 'dart:convert';
import 'dart:math' as math;

/// Base class for mock tools with common implementations
abstract class BaseMockTool implements AgentTool {
  @override
  bool canHandle(String action) {
    // Simple check: if action contains tool name
    return action.toLowerCase().contains(metadata.name.toLowerCase());
  }

  @override
  List<String> getRequiredPermissions() {
    return metadata.requiredPermissions;
  }

  @override
  void validateParameters(Map<String, dynamic> parameters) {
    // Basic validation - check required parameters exist
    final requiredParams = _getRequiredParams();
    for (final param in requiredParams) {
      if (!parameters.containsKey(param)) {
        throw ArgumentError('Missing required parameter: $param');
      }
    }
  }

  /// Override this to specify required parameters
  List<String> _getRequiredParams();
}

/// Calculator tool for basic math operations
class CalculatorTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'calculator',
        description:
            'Performs basic math operations: add, subtract, multiply, divide, power, sqrt',
        capabilities: ['math', 'calculation', 'arithmetic'],
        requiredPermissions: [],
        parameters: {
          'operation':
              'Operation to perform (add|subtract|multiply|divide|power|sqrt)',
          'a': 'First number',
          'b': 'Second number (not needed for sqrt)',
        },
      );

  @override
  List<String> _getRequiredParams() => ['operation', 'a'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final operation = params['operation'] as String;
    final a = _parseNumber(params['a']);
    final b = params.containsKey('b') ? _parseNumber(params['b']) : 0.0;

    double result;
    switch (operation.toLowerCase()) {
      case 'add':
        result = a + b;
        break;
      case 'subtract':
        result = a - b;
        break;
      case 'multiply':
        result = a * b;
        break;
      case 'divide':
        if (b == 0) throw ArgumentError('Division by zero');
        result = a / b;
        break;
      case 'power':
        result = math.pow(a, b).toDouble();
        break;
      case 'sqrt':
        if (a < 0)
          throw ArgumentError('Cannot take square root of negative number');
        result = math.sqrt(a);
        break;
      default:
        throw ArgumentError('Unknown operation: $operation');
    }

    return result.toString();
  }

  double _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Invalid number: $value');
  }
}

/// Statistics tool for data analysis
class StatsTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'stats',
        description:
            'Calculate statistics: mean, median, mode, std_dev, min, max, sum, count',
        capabilities: ['statistics', 'analysis', 'data'],
        requiredPermissions: [],
        parameters: {
          'operation':
              'Statistic to calculate (mean|median|mode|std_dev|min|max|sum|count)',
          'values': 'Array of numbers to analyze',
        },
      );

  @override
  List<String> _getRequiredParams() => ['operation', 'values'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final operation = params['operation'] as String;
    final values =
        (params['values'] as List).map((v) => _parseNumber(v)).toList();

    if (values.isEmpty) throw ArgumentError('Empty values array');

    dynamic result;
    switch (operation.toLowerCase()) {
      case 'mean':
        result = values.reduce((a, b) => a + b) / values.length;
        break;
      case 'median':
        final sorted = List<double>.from(values)..sort();
        final mid = sorted.length ~/ 2;
        result = sorted.length.isOdd
            ? sorted[mid]
            : (sorted[mid - 1] + sorted[mid]) / 2;
        break;
      case 'mode':
        final frequency = <double, int>{};
        for (final v in values) {
          frequency[v] = (frequency[v] ?? 0) + 1;
        }
        final maxFreq = frequency.values.reduce(math.max);
        result = frequency.entries
            .where((e) => e.value == maxFreq)
            .map((e) => e.key)
            .toList();
        break;
      case 'std_dev':
        final mean = values.reduce((a, b) => a + b) / values.length;
        final variance =
            values.map((v) => math.pow(v - mean, 2)).reduce((a, b) => a + b) /
                values.length;
        result = math.sqrt(variance);
        break;
      case 'min':
        result = values.reduce(math.min);
        break;
      case 'max':
        result = values.reduce(math.max);
        break;
      case 'sum':
        result = values.reduce((a, b) => a + b);
        break;
      case 'count':
        result = values.length;
        break;
      default:
        throw ArgumentError('Unknown operation: $operation');
    }

    return result.toString();
  }

  double _parseNumber(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.parse(value);
    throw ArgumentError('Invalid number: $value');
  }
}

/// Sentiment analysis tool
class SentimentTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'sentiment',
        description:
            'Analyze sentiment of text: positive, negative, neutral, mixed',
        capabilities: ['nlp', 'sentiment', 'text_analysis'],
        requiredPermissions: [],
        parameters: {
          'text': 'Text to analyze',
        },
      );

  @override
  List<String> _getRequiredParams() => ['text'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final text = (params['text'] as String).toLowerCase();

    // Simple keyword-based sentiment (mock implementation)
    final positiveWords = [
      'good',
      'great',
      'excellent',
      'love',
      'amazing',
      'wonderful',
      'best',
      'happy',
      'beautiful'
    ];
    final negativeWords = [
      'bad',
      'terrible',
      'hate',
      'worst',
      'awful',
      'poor',
      'frustrating',
      'slow',
      'crash'
    ];

    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      positiveCount += word.allMatches(text).length;
    }

    for (final word in negativeWords) {
      negativeCount += word.allMatches(text).length;
    }

    String sentiment;
    double confidence;

    if (positiveCount > 0 && negativeCount > 0) {
      sentiment = 'mixed';
      confidence = 0.6;
    } else if (positiveCount > negativeCount) {
      sentiment = 'positive';
      confidence = math.min(0.9, 0.5 + (positiveCount * 0.1));
    } else if (negativeCount > positiveCount) {
      sentiment = 'negative';
      confidence = math.min(0.9, 0.5 + (negativeCount * 0.1));
    } else {
      sentiment = 'neutral';
      confidence = 0.7;
    }

    return '{"sentiment": "$sentiment", "confidence": ${confidence.toStringAsFixed(2)}, "positive_count": $positiveCount, "negative_count": $negativeCount}';
  }
}

/// Knowledge base lookup tool
class KnowledgeBaseTool extends BaseMockTool {
  final Map<String, String> _knowledge = {
    'diabetes':
        'Type 2 Diabetes is a chronic condition affecting blood sugar regulation. Common symptoms: excessive thirst, frequent urination, fatigue, blurred vision.',
    'hypertension':
        'High blood pressure (>130/80 mmHg). Risk factors: obesity, high sodium intake, stress, genetics.',
    'thyroid':
        'Thyroid disorders include hyperthyroidism (overactive) and hypothyroidism (underactive). Symptoms vary widely.',
    'app_performance':
        'Performance optimization techniques: lazy loading, image compression, caching, code splitting.',
    'customer_satisfaction':
        'Key metrics: NPS score, CSAT, retention rate, churn rate, feature adoption.',
  };

  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'knowledge_base',
        description: 'Look up information from knowledge base',
        capabilities: ['search', 'knowledge', 'lookup'],
        requiredPermissions: [],
        parameters: {
          'query': 'Search query or topic',
        },
      );

  @override
  List<String> _getRequiredParams() => ['query'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final query = (params['query'] as String).toLowerCase();

    // Find matching entries
    final matches = <String, String>{};
    for (final entry in _knowledge.entries) {
      if (entry.key.contains(query) || query.contains(entry.key)) {
        matches[entry.key] = entry.value;
      }
    }

    if (matches.isEmpty) {
      return '{"found": false, "message": "No knowledge base entries found for: $query"}';
    }

    return '{"found": true, "results": ${matches.length}, "data": ${matches.toString()}}';
  }
}

/// Text extraction tool
class TextExtractorTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'text_extractor',
        description:
            'Extract specific information from text: emails, urls, numbers, dates',
        capabilities: ['extraction', 'parsing', 'text_processing'],
        requiredPermissions: [],
        parameters: {
          'text': 'Text to extract from',
          'type': 'What to extract (emails|urls|numbers|dates|keywords)',
        },
      );

  @override
  List<String> _getRequiredParams() => ['text', 'type'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final text = params['text'] as String;
    final type = params['type'] as String;

    List<String> results = [];

    switch (type.toLowerCase()) {
      case 'emails':
        final emailRegex = RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b');
        results = emailRegex.allMatches(text).map((m) => m.group(0)!).toList();
        break;
      case 'urls':
        final urlRegex = RegExp(r'https?://[^\s]+');
        results = urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
        break;
      case 'numbers':
        final numRegex = RegExp(r'\b\d+\.?\d*\b');
        results = numRegex.allMatches(text).map((m) => m.group(0)!).toList();
        break;
      case 'dates':
        final dateRegex = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
        results = dateRegex.allMatches(text).map((m) => m.group(0)!).toList();
        break;
      case 'keywords':
        results = text
            .split(RegExp(r'[\s,\.;:!?]+'))
            .where((w) => w.length > 4)
            .toList();
        break;
      default:
        throw ArgumentError('Unknown extraction type: $type');
    }

    return '{"type": "$type", "count": ${results.length}, "results": ${results.toString()}}';
  }
}

/// Echo tool (for testing)
class EchoTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'echo',
        description: 'Echo back the input (for testing)',
        capabilities: ['test', 'debug'],
        requiredPermissions: [],
        parameters: {
          'message': 'Message to echo',
        },
      );

  @override
  List<String> _getRequiredParams() => ['message'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    return params['message'].toString();
  }
}

/// List comparison tool
class ListCompareTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'list_compare',
        description: 'Compare two lists: find common, unique, differences',
        capabilities: ['comparison', 'list_operations'],
        requiredPermissions: [],
        parameters: {
          'list1': 'First list',
          'list2': 'Second list',
          'operation': 'Operation (common|unique1|unique2|all_unique)',
        },
      );

  @override
  List<String> _getRequiredParams() => ['list1', 'list2', 'operation'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final list1 = (params['list1'] as List).map((e) => e.toString()).toSet();
    final list2 = (params['list2'] as List).map((e) => e.toString()).toSet();
    final operation = params['operation'] as String;

    Set<String> result;

    switch (operation.toLowerCase()) {
      case 'common':
        result = list1.intersection(list2);
        break;
      case 'unique1':
        result = list1.difference(list2);
        break;
      case 'unique2':
        result = list2.difference(list1);
        break;
      case 'all_unique':
        result = list1.union(list2);
        break;
      default:
        throw ArgumentError('Unknown operation: $operation');
    }

    return '{"operation": "$operation", "count": ${result.length}, "results": ${result.toList().toString()}}';
  }
}

/// JSON validator tool
class JsonValidatorTool extends BaseMockTool {
  @override
  ToolMetadata get metadata => const ToolMetadata(
        name: 'json_validator',
        description: 'Validate and format JSON',
        capabilities: ['validation', 'json', 'formatting'],
        requiredPermissions: [],
        parameters: {
          'json': 'JSON string to validate',
        },
      );

  @override
  List<String> _getRequiredParams() => ['json'];

  @override
  Future<String> execute(Map<String, dynamic> params) async {
    final jsonStr = params['json'] as String;

    try {
      final parsed = json.decode(jsonStr);
      final formatted = json.encode(parsed);
      return '{"valid": true, "formatted": ${json.encode(formatted)}}';
    } catch (e) {
      return '{"valid": false, "error": "${e.toString()}"}';
    }
  }
}

/// Get all mock tools
List<AgentTool> getAllMockTools() {
  return [
    CalculatorTool(),
    StatsTool(),
    SentimentTool(),
    KnowledgeBaseTool(),
    TextExtractorTool(),
    EchoTool(),
    ListCompareTool(),
    JsonValidatorTool(),
  ];
}
