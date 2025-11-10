import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:langchain/langchain.dart';
import 'package:langchain_core/tools.dart';

/// Platform detection utilities
class PlatformInfo {
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  
  static bool get isMobile =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  
  static bool get isWeb => kIsWeb;
  
  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

/// Calculator tool - works on all platforms
final class CalculatorTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  CalculatorTool()
      : super(
          name: 'calculator',
          description:
              'Performs basic arithmetic calculations. Supports +, -, *, / operations.',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'expression': {
                'type': 'string',
                'description': 'Mathematical expression to evaluate (e.g., "2 + 2", "10 * 5")'
              },
            },
            'required': ['expression'],
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    try {
      final expression = input['expression'] as String;
      final result = _evaluateSimpleExpression(expression);
      return 'Result: $result';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  double _evaluateSimpleExpression(String expr) {
    expr = expr.replaceAll(' ', '');
    
    // Handle basic operations
    if (expr.contains('+')) {
      final parts = expr.split('+');
      return double.parse(parts[0]) + double.parse(parts[1]);
    } else if (expr.contains('-') && !expr.startsWith('-')) {
      final parts = expr.split('-');
      return double.parse(parts[0]) - double.parse(parts[1]);
    } else if (expr.contains('*')) {
      final parts = expr.split('*');
      return double.parse(parts[0]) * double.parse(parts[1]);
    } else if (expr.contains('/')) {
      final parts = expr.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    }
    
    return double.parse(expr);
  }
}

/// DateTime tool - works on all platforms
final class DateTimeTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  DateTimeTool()
      : super(
          name: 'datetime',
          description:
              'Gets current date and time information, or formats dates.',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'description': 'Action to perform: "current", "format", "parse"',
                'enum': ['current', 'format', 'parse'],
              },
              'format': {
                'type': 'string',
                'description': 'Optional format string for date formatting',
              },
            },
            'required': ['action'],
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    final action = input['action'] as String;
    final now = DateTime.now();

    switch (action) {
      case 'current':
        return 'Current date and time: ${now.toIso8601String()}\n'
            'Local: ${now.toLocal()}\n'
            'UTC: ${now.toUtc()}';
      case 'format':
        return 'Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}\n'
            'Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      case 'parse':
        return 'Parsing not implemented yet';
      default:
        return 'Unknown action: $action';
    }
  }
}

/// Text processing tool - works on all platforms
final class TextProcessorTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  TextProcessorTool()
      : super(
          name: 'text_processor',
          description:
              'Processes text: count words/chars, uppercase, lowercase, reverse, etc.',
          inputJsonSchema: {
            'type': 'object',
            'properties': {
              'action': {
                'type': 'string',
                'description': 'Action: "count_words", "count_chars", "uppercase", "lowercase", "reverse"',
                'enum': ['count_words', 'count_chars', 'uppercase', 'lowercase', 'reverse'],
              },
              'text': {
                'type': 'string',
                'description': 'Text to process',
              },
            },
            'required': ['action', 'text'],
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    final action = input['action'] as String;
    final text = input['text'] as String;

    switch (action) {
      case 'count_words':
        final words = text.split(RegExp(r'\s+'));
        return 'Word count: ${words.length}';
      case 'count_chars':
        return 'Character count: ${text.length}';
      case 'uppercase':
        return text.toUpperCase();
      case 'lowercase':
        return text.toLowerCase();
      case 'reverse':
        return text.split('').reversed.join('');
      default:
        return 'Unknown action: $action';
    }
  }
}

/// Platform info tool - reports platform capabilities
final class PlatformInfoTool extends Tool<Map<String, dynamic>, ToolOptions, String> {
  PlatformInfoTool()
      : super(
          name: 'platform_info',
          description:
              'Gets information about the current platform and available capabilities.',
          inputJsonSchema: {
            'type': 'object',
            'properties': {},
          },
        );

  @override
  Map<String, dynamic> getInputFromJson(Map<String, dynamic> json) => json;

  @override
  Future<String> invokeInternal(
    Map<String, dynamic> input, {
    ToolOptions? options,
  }) async {
    return '''
Platform: ${PlatformInfo.platformName}
Type: ${PlatformInfo.isDesktop ? 'Desktop' : PlatformInfo.isMobile ? 'Mobile' : 'Web'}
Is Desktop: ${PlatformInfo.isDesktop}
Is Mobile: ${PlatformInfo.isMobile}
Is Web: ${PlatformInfo.isWeb}
''';
  }
}
