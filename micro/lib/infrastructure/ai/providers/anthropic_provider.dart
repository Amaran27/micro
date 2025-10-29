import 'dart:convert';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../secure_api_storage.dart';
import '../../../domain/models/ai_model.dart';

/// Anthropic Claude AI provider implementation
class AnthropicProvider {
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();

  static const String _baseUrl = 'https://api.anthropic.com/v1';
  static const String _version = '2023-06-01';

  /// Initialize Anthropic Claude provider
  Future<ChatOpenAI?> initialize() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('claude');
      if (apiKey == null || apiKey.isEmpty) {
        _logger.warning('Anthropic API key not found');
        return null;
      }

      // Create custom chat model implementation for Anthropic
      return _createAnthropicChatModel(apiKey);
    } catch (e) {
      _logger.error('Failed to initialize Anthropic provider', error: e);
      return null;
    }
  }

  /// Get available Anthropic models
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('claude');
      if (apiKey == null || apiKey.isEmpty) {
        return _getDefaultModels();
      }

      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': _version,
            'content-type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = <AIModel>[];

        if (data['data'] != null) {
          for (final model in data['data']) {
            if (model['id'] != null) {
              models.add(AIModel(
                provider: 'claude',
                modelId: model['id'],
                displayName: _getDisplayName(model['id']),
                description: model['description'] ?? 'Anthropic Claude model',
                metadata: {
                  'capabilities': _getModelCapabilities(model['id']),
                  'contextWindow': _getContextWindow(model['id']),
                  'pricing': _getModelPricing(model['id']),
                },
              ));
            }
          }
        }

        return models.isNotEmpty ? models : _getDefaultModels();
      } else {
        _logger.warning(
            'Failed to fetch Anthropic models: ${response.statusCode}');
        return _getDefaultModels();
      }
    } catch (e) {
      _logger.warning('Error fetching Anthropic models, using defaults',
          error: e);
      return _getDefaultModels();
    }
  }

  /// Create Anthropic chat model using OpenAI-compatible interface
  ChatOpenAI _createAnthropicChatModel(String apiKey) {
    // We'll use a custom approach since Anthropic has a different API format
    // For now, we'll use the OpenAI interface as a base with custom endpoints
    return ChatOpenAI(
      apiKey: apiKey,
      baseUrl: _baseUrl,
      defaultOptions: ChatOpenAIOptions(
        model: 'claude-3-haiku-20240307',
        maxTokens: 1000,
        temperature: 0.7,
      ),
      headers: {
        'anthropic-version': _version,
      },
    );
  }

  /// Get default Anthropic models
  List<AIModel> _getDefaultModels() {
    return [
      AIModel(
        provider: 'claude',
        modelId: 'claude-3-5-sonnet-20241022',
        displayName: 'Claude 3.5 Sonnet',
        description: 'Most powerful Claude model for complex tasks',
        metadata: {
          'capabilities': ['text', 'reasoning', 'analysis', 'coding'],
          'contextWindow': 200000,
          'pricing': {'input': 3.0, 'output': 15.0},
        },
      ),
      AIModel(
        provider: 'anthropic',
        modelId: 'claude-3-5-haiku-20241022',
        displayName: 'Claude 3.5 Haiku',
        description: 'Fast and efficient Claude model',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding'],
          'contextWindow': 200000,
          'pricing': {'input': 0.8, 'output': 4.0},
        },
      ),
      AIModel(
        provider: 'anthropic',
        modelId: 'claude-3-opus-20240229',
        displayName: 'Claude 3 Opus',
        description: 'Most capable Claude model for highly complex tasks',
        metadata: {
          'capabilities': ['text', 'reasoning', 'analysis', 'coding', 'math'],
          'contextWindow': 200000,
          'pricing': {'input': 15.0, 'output': 75.0},
        },
      ),
      AIModel(
        provider: 'anthropic',
        modelId: 'claude-3-sonnet-20240229',
        displayName: 'Claude 3 Sonnet',
        description: 'Balanced Claude model for most tasks',
        metadata: {
          'capabilities': ['text', 'reasoning', 'analysis', 'coding'],
          'contextWindow': 200000,
          'pricing': {'input': 3.0, 'output': 15.0},
        },
      ),
      AIModel(
        provider: 'anthropic',
        modelId: 'claude-3-haiku-20240307',
        displayName: 'Claude 3 Haiku',
        description: 'Fastest Claude model for simple tasks',
        metadata: {
          'capabilities': ['text', 'reasoning'],
          'contextWindow': 200000,
          'pricing': {'input': 0.25, 'output': 1.25},
        },
      ),
    ];
  }

  /// Get display name for model
  String _getDisplayName(String modelId) {
    switch (modelId) {
      case 'claude-3-5-sonnet-20241022':
        return 'Claude 3.5 Sonnet';
      case 'claude-3-5-haiku-20241022':
        return 'Claude 3.5 Haiku';
      case 'claude-3-opus-20240229':
        return 'Claude 3 Opus';
      case 'claude-3-sonnet-20240229':
        return 'Claude 3 Sonnet';
      case 'claude-3-haiku-20240307':
        return 'Claude 3 Haiku';
      default:
        return modelId
            .split('-')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  /// Get model capabilities
  List<String> _getModelCapabilities(String modelId) {
    const baseCapabilities = ['text', 'reasoning'];

    if (modelId.contains('opus') || modelId.contains('sonnet')) {
      return [...baseCapabilities, 'analysis', 'coding', 'math'];
    }

    if (modelId.contains('haiku')) {
      return baseCapabilities;
    }

    return baseCapabilities;
  }

  /// Get context window size
  int _getContextWindow(String modelId) {
    // Claude 3 models have 200K context window
    return 200000;
  }

  /// Get model pricing (per 1M tokens)
  Map<String, double> _getModelPricing(String modelId) {
    switch (modelId) {
      case 'claude-3-5-sonnet-20241022':
        return {'input': 3.0, 'output': 15.0};
      case 'claude-3-5-haiku-20241022':
        return {'input': 0.8, 'output': 4.0};
      case 'claude-3-opus-20240229':
        return {'input': 15.0, 'output': 75.0};
      case 'claude-3-sonnet-20240229':
        return {'input': 3.0, 'output': 15.0};
      case 'claude-3-haiku-20240307':
        return {'input': 0.25, 'output': 1.25};
      default:
        return {'input': 1.0, 'output': 5.0};
    }
  }

  /// Send chat message to Anthropic API directly
  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      // Convert messages to Anthropic format
      final anthropicMessages = _convertMessagesToAnthropicFormat(messages);

      final requestData = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': anthropicMessages,
      };

      final response = await _dio.post(
        '$_baseUrl/messages',
        data: requestData,
        options: Options(
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': _version,
            'content-type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data['content'];
        if (content != null && content.isNotEmpty) {
          return content[0]['text'] ?? '';
        }
      }

      throw Exception('Invalid response from Anthropic API');
    } catch (e) {
      _logger.error('Error sending message to Anthropic', error: e);
      rethrow;
    }
  }

  /// Convert messages to Anthropic format
  List<Map<String, String>> _convertMessagesToAnthropicFormat(
    List<Map<String, String>> messages,
  ) {
    final anthropicMessages = <Map<String, String>>[];

    for (final message in messages) {
      anthropicMessages.add({
        'role': message['role'] == 'assistant' ? 'assistant' : 'user',
        'content': message['content'] ?? '',
      });
    }

    return anthropicMessages;
  }
}
