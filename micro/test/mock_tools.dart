/// Mock Tools for Swarm Testing
/// Provides realistic tool implementations for testing swarm functionality

import 'package:micro/infrastructure/ai/agent/tools/tool_interface.dart';
import 'package:micro/infrastructure/ai/agent/models/agent_models.dart';

/// Simple echo tool for testing basic functionality
class EchoTool implements Tool {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echoes the input back to the caller';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.string,
    description: 'Text to echo back',
    required: true,
  );

  @override
  Future<String> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 10)); // Simulate work
    return input.toString();
  }
}

/// Sentiment analysis tool for testing NLP capabilities
class SentimentTool implements Tool {
  @override
  String get name => 'sentiment';

  @override
  String get description => 'Analyzes sentiment of text and returns score';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.string,
    description: 'Text to analyze for sentiment',
    required: true,
  );

  @override
  Future<Map<String, dynamic>> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 50));
    
    final text = input.toString().toLowerCase();
    double score = 0.5; // Neutral
    
    // Simple keyword-based sentiment analysis
    final positiveWords = ['good', 'great', 'excellent', 'amazing', 'love', 'perfect', 'wonderful'];
    final negativeWords = ['bad', 'terrible', 'awful', 'hate', 'worst', 'horrible', 'poor'];
    
    int positiveCount = 0;
    int negativeCount = 0;
    
    for (final word in positiveWords) {
      if (text.contains(word)) positiveCount++;
    }
    
    for (final word in negativeWords) {
      if (text.contains(word)) negativeCount++;
    }
    
    if (positiveCount > negativeCount) {
      score = 0.5 + (positiveCount - negativeCount) * 0.1;
    } else if (negativeCount > positiveCount) {
      score = 0.5 - (negativeCount - positiveCount) * 0.1;
    }
    
    score = score.clamp(0.0, 1.0);
    
    return {
      'sentiment_score': score,
      'confidence': 0.85,
      'positive_words': positiveCount,
      'negative_words': negativeCount,
      'analysis': score > 0.6 ? 'positive' : score < 0.4 ? 'negative' : 'neutral'
    };
  }
}

/// Calculator tool for mathematical operations
class CalculatorTool implements Tool {
  @override
  String get name => 'calculator';

  @override
  String get description => 'Performs mathematical calculations';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.object,
    description: 'Mathematical operation and operands',
    required: true,
    properties: {
      'operation': ToolInput(
        type: ToolInputType.string,
        description: 'Operation: add, subtract, multiply, divide, power',
        required: true,
      ),
      'a': ToolInput(
        type: ToolInputType.number,
        description: 'First operand',
        required: true,
      ),
      'b': ToolInput(
        type: ToolInputType.number,
        description: 'Second operand',
        required: false,
      ),
    },
  );

  @override
  Future<double> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 20));
    
    if (input is! Map) {
      throw ArgumentError('Input must be a map');
    }
    
    final operation = input['operation'] as String?;
    final a = input['a'] as num?;
    final b = input['b'] as num?;
    
    if (operation == null || a == null) {
      throw ArgumentError('Operation and first operand are required');
    }
    
    switch (operation.toLowerCase()) {
      case 'add':
        if (b == null) throw ArgumentError('Second operand required for addition');
        return a + b;
      case 'subtract':
        if (b == null) throw ArgumentError('Second operand required for subtraction');
        return a - b;
      case 'multiply':
        if (b == null) throw ArgumentError('Second operand required for multiplication');
        return a * b;
      case 'divide':
        if (b == null) throw ArgumentError('Second operand required for division');
        if (b == 0) throw ArgumentError('Cannot divide by zero');
        return a / b;
      case 'power':
        if (b == null) throw ArgumentError('Second operand required for power');
        return a.toDouble() * b;
      case 'sqrt':
        if (a < 0) throw ArgumentError('Cannot calculate square root of negative number');
        return a.toDouble();
      default:
        throw ArgumentError('Unknown operation: $operation');
    }
  }
}

/// Statistics tool for data analysis
class StatsTool implements Tool {
  @override
  String get name => 'stats';

  @override
  String get description => 'Performs statistical calculations on data';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.object,
    description: 'Statistical operation and data',
    required: true,
    properties: {
      'operation': ToolInput(
        type: ToolInputType.string,
        description: 'Operation: mean, median, mode, std, variance, min, max, sum',
        required: true,
      ),
      'values': ToolInput(
        type: ToolInputType.array,
        description: 'List of numeric values',
        required: true,
      ),
    },
  );

  @override
  Future<double> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 30));
    
    if (input is! Map) {
      throw ArgumentError('Input must be a map');
    }
    
    final operation = input['operation'] as String?;
    final values = input['values'] as List?;
    
    if (operation == null || values == null) {
      throw ArgumentError('Operation and values are required');
    }
    
    final numbers = values.map((v) => v as num).toList();
    if (numbers.isEmpty) {
      throw ArgumentError('Values list cannot be empty');
    }
    
    switch (operation.toLowerCase()) {
      case 'sum':
        return numbers.reduce((a, b) => a + b).toDouble();
      case 'mean':
        return numbers.reduce((a, b) => a + b) / numbers.length;
      case 'median':
        numbers.sort();
        final mid = numbers.length ~/ 2;
        if (numbers.length.isOdd) {
          return numbers[mid].toDouble();
        } else {
          return ((numbers[mid - 1] + numbers[mid]) / 2).toDouble();
        }
      case 'min':
        return numbers.reduce((a, b) => a < b ? a : b).toDouble();
      case 'max':
        return numbers.reduce((a, b) => a > b ? a : b).toDouble();
      case 'variance':
        final mean = numbers.reduce((a, b) => a + b) / numbers.length;
        final variance = numbers.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / numbers.length;
        return variance;
      case 'std':
        final mean = numbers.reduce((a, b) => a + b) / numbers.length;
        final variance = numbers.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / numbers.length;
        return variance.toDouble();
      default:
        throw ArgumentError('Unknown operation: $operation');
    }
  }
}

/// Knowledge base tool for domain-specific information
class KnowledgeBaseTool implements Tool {
  @override
  String get name => 'knowledge_base';

  @override
  String get description => 'Retrieves information from knowledge base';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.object,
    description: 'Knowledge query parameters',
    required: true,
    properties: {
      'domain': ToolInput(
        type: ToolInputType.string,
        description: 'Knowledge domain: flutter, development, mobile, performance',
        required: true,
      ),
      'query': ToolInput(
        type: ToolInputType.string,
        description: 'Specific query or topic',
        required: true,
      ),
    },
  );

  @override
  Future<Map<String, dynamic>> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 40));
    
    if (input is! Map) {
      throw ArgumentError('Input must be a map');
    }
    
    final domain = input['domain'] as String?;
    final query = input['query'] as String?;
    
    if (domain == null || query == null) {
      throw ArgumentError('Domain and query are required');
    }
    
    // Mock knowledge base responses
    switch (domain.toLowerCase()) {
      case 'flutter':
        return _getFlutterKnowledge(query);
      case 'development':
        return _getDevelopmentKnowledge(query);
      case 'mobile':
        return _getMobileKnowledge(query);
      case 'performance':
        return _getPerformanceKnowledge(query);
      default:
        return {
          'domain': domain,
          'query': query,
          'result': 'No specific knowledge found',
          'confidence': 0.3
        };
    }
  }
  
  Map<String, dynamic> _getFlutterKnowledge(String query) {
    final flutterKnowledge = {
      'widget_tree': {
        'description': 'Flutter widget tree optimization',
        'tips': ['Use const widgets', 'Avoid unnecessary rebuilds', 'Implement proper keys'],
        'confidence': 0.9
      },
      'state_management': {
        'description': 'Flutter state management patterns',
        'tips': ['Choose right pattern', 'Minimize rebuilds', 'Use providers efficiently'],
        'confidence': 0.85
      },
      'performance': {
        'description': 'Flutter performance optimization',
        'tips': ['Profile with Flutter Inspector', 'Optimize images', 'Use lazy loading'],
        'confidence': 0.88
      },
    };
    
    final lowerQuery = query.toLowerCase();
    for (final key in flutterKnowledge.keys) {
      if (lowerQuery.contains(key)) {
        return flutterKnowledge[key]!;
      }
    }
    
    return {
      'domain': 'flutter',
      'query': query,
      'general_tips': ['Use proper widget lifecycle', 'Optimize build methods', 'Handle memory correctly'],
      'confidence': 0.7
    };
  }
  
  Map<String, dynamic> _getDevelopmentKnowledge(String query) {
    return {
      'domain': 'development',
      'query': query,
      'best_practices': [
        'Write clean, maintainable code',
        'Implement proper error handling',
        'Use version control effectively',
        'Test thoroughly'
      ],
      'confidence': 0.8
    };
  }
  
  Map<String, dynamic> _getMobileKnowledge(String query) {
    return {
      'domain': 'mobile',
      'query': query,
      'insights': [
        'Consider mobile network conditions',
        'Optimize for battery life',
        'Handle offline scenarios',
        'Design for touch interfaces'
      ],
      'confidence': 0.82
    };
  }
  
  Map<String, dynamic> _getPerformanceKnowledge(String query) {
    return {
      'domain': 'performance',
      'query': query,
      'optimization_areas': [
        'CPU usage optimization',
        'Memory management',
        'Network request optimization',
        'UI rendering performance'
      ],
      'confidence': 0.87
    };
  }
}

/// Data processing tool for transformation operations
class DataProcessorTool implements Tool {
  @override
  String get name => 'data_processor';

  @override
  String get description => 'Processes and transforms data structures';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.object,
    description: 'Data processing parameters',
    required: true,
    properties: {
      'operation': ToolInput(
        type: ToolInputType.string,
        description: 'Operation: transform, filter, map, reduce, sort',
        required: true,
      ),
      'data': ToolInput(
        type: ToolInputType.any,
        description: 'Data to process',
        required: true,
      ),
      'transformation': ToolInput(
        type: ToolInputType.string,
        description: 'Type of transformation to apply',
        required: false,
      ),
    },
  );

  @override
  Future<dynamic> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 25));
    
    if (input is! Map) {
      throw ArgumentError('Input must be a map');
    }
    
    final operation = input['operation'] as String?;
    final data = input['data'];
    final transformation = input['transformation'] as String?;
    
    if (operation == null || data == null) {
      throw ArgumentError('Operation and data are required');
    }
    
    switch (operation.toLowerCase()) {
      case 'transform':
        return _transformData(data, transformation);
      case 'filter':
        return _filterData(data, transformation);
      case 'sort':
        return _sortData(data);
      case 'count':
        return _countData(data);
      case 'flatten':
        return _flattenData(data);
      default:
        throw ArgumentError('Unknown operation: $operation');
    }
  }
  
  dynamic _transformData(dynamic data, String? transformation) {
    if (transformation == 'extract_scores' && data is List) {
      return data.map((item) {
        if (item is Map && item.containsKey('score')) {
          return item['score'] as num;
        }
        return 0;
      }).toList();
    }
    
    if (transformation == 'extract_names' && data is List) {
      return data.map((item) {
        if (item is Map && item.containsKey('name')) {
          return item['name'] as String;
        }
        return '';
      }).where((name) => name.isNotEmpty).toList();
    }
    
    return data;
  }
  
  List<dynamic> _filterData(dynamic data, String? transformation) {
    if (data is List) {
      return data.where((item) {
        if (transformation == 'positive' && item is Map) {
          return (item['sentiment'] as num?)?.toDouble() ?? 0 > 0.5;
        }
        if (transformation == 'high_score' && item is Map) {
          return (item['score'] as num?)?.toDouble() ?? 0 > 80;
        }
        return true;
      }).toList();
    }
    return [data];
  }
  
  List<dynamic> _sortData(dynamic data) {
    if (data is List) {
      final sorted = List<dynamic>.from(data);
      sorted.sort((a, b) {
        if (a is num && b is num) return a.compareTo(b);
        if (a is String && b is String) return a.compareTo(b);
        return 0;
      });
      return sorted;
    }
    return [data];
  }
  
  int _countData(dynamic data) {
    if (data is List) return data.length;
    if (data is Map) return data.length;
    return 1;
  }
  
  List<dynamic> _flattenData(dynamic data) {
    List<dynamic> result = [];
    
    void flatten(dynamic item) {
      if (item is List) {
        for (final sub in item) {
          flatten(sub);
        }
      } else {
        result.add(item);
      }
    }
    
    flatten(data);
    return result;
  }
}

/// Error-prone tool for testing error handling
class ErrorProneTool implements Tool {
  @override
  String get name => 'error_prone';

  @override
  String get description => 'Tool that intentionally throws errors for testing';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.any,
    description: 'Any input (will cause error)',
    required: false,
  );

  @override
  Future<dynamic> call(dynamic input) async {
    await Future.delayed(Duration(milliseconds: 10));
    throw Exception('Intentional test error from ErrorProneTool');
  }
}

/// Slow tool for testing timeout handling
class SlowTool implements Tool {
  @override
  String get name => 'slow';

  @override
  String get description => 'Tool that takes a long time to complete';

  @override
  ToolInput get inputSchema => ToolInput(
    type: ToolInputType.string,
    description: 'Input to process slowly',
    required: true,
  );

  @override
  Future<String> call(dynamic input) async {
    // Simulate slow operation (but not too slow for tests)
    await Future.delayed(Duration(milliseconds: 100));
    return 'Slow processing completed for: $input';
  }
}