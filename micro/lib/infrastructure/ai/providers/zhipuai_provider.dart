import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../secure_api_storage.dart';
import '../../../domain/models/ai_model.dart';

/// ZhipuAI (GLM) provider implementation
/// NOTE: This requires langchain_openai package to be added to pubspec.yaml
/// Currently, this is a placeholder implementation
class ZhipuAIProvider {
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();

  static const String _baseUrl = 'https://api.z.ai/api/paas/v4';

  /// Initialize ZhipuAI provider
  Future<dynamic> initialize() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        _logger.warning('ZhipuAI API key not found');
        return null;
      }

      _logger.warning(
          'ZhipuAI: langchain_openai package not available. Using placeholder.');
      return null; // Placeholder
    } catch (e) {
      _logger.error('Failed to initialize ZhipuAI provider', error: e);
      return null;
    }
  }

  /// Get available ZhipuAI models
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        return _getDefaultModels();
      }

      // ZhipuAI uses Bearer token authentication
      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept-Language': 'en-US,en',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final models = <AIModel>[];

        _logger.info('ZhipuAI API response: $data');

        if (data['data'] != null) {
          for (final model in data['data']) {
            if (model['id'] != null) {
              final modelId = model['id'] as String;
              _logger.info('Processing ZhipuAI model: $modelId');

              // Only process models that we know exist and are valid
              if (_isValidModel(modelId)) {
                models.add(AIModel(
                  provider: 'zhipuai',
                  modelId: modelId,
                  displayName: _getDisplayName(modelId),
                  description: model['description'] ?? 'ZhipuAI GLM model',
                  metadata: {
                    'capabilities': _getModelCapabilities(modelId),
                    'contextWindow': _getContextWindow(modelId),
                    'pricing': _getModelPricing(modelId),
                    'created': model['created'],
                    'ownedBy': model['owned_by'] ?? 'z-ai',
                  },
                ));
              } else {
                _logger.warning('Skipping unknown model: $modelId');
              }
            }
          }
        }

        _logger.info(
            'Successfully fetched ${models.length} models from ZhipuAI API');
        return models; // Do not silently fall back; let caller decide
      } else {
        _logger.warning(
            'Failed to fetch ZhipuAI models: ${response.statusCode}, body: ${response.data}');
        return [];
      }
    } catch (e) {
      _logger.warning('Error fetching ZhipuAI models', error: e);
      return [];
    }
  }

  /// Check if model ID is valid and known
  bool _isValidModel(String modelId) {
    const validModels = {
      'glm-4',
      'glm-4-plus',
      'glm-4-0520',
      'glm-4-air',
      'glm-4-airx',
      'glm-4-long',
      'glm-4-flash',
      'glm-4.5',
      'glm-4.5-flash',
      'glm-4.5-air',
      'glm-4.5v',
      'glm-4.6',
      'glm-4.6-flash',
    };
    return validModels.contains(modelId);
  }

  /// Get default ZhipuAI models
  List<AIModel> _getDefaultModels() {
    return [
      // GLM-4.5-Flash (FREE)
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4.5-flash',
        displayName: 'GLM-4.5 Flash (Free)',
        description: 'Free model for testing and light usage',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding', 'analysis'],
          'contextWindow': 128000,
          'pricing': {'input': 0.0, 'output': 0.0},
          'free': true,
        },
      ),
      // GLM-4.6 (latest)
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4.6',
        displayName: 'GLM-4.6',
        description: 'Latest flagship model with enhanced capabilities',
        metadata: {
          'capabilities': [
            'text',
            'reasoning',
            'coding',
            'analysis',
            'multilingual'
          ],
          'contextWindow': 128000,
          'pricing': {'input': 0.1, 'output': 0.1},
        },
      ),
      // GLM-4.5 (balanced)
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4.5',
        displayName: 'GLM-4.5',
        description: 'Balanced performance model for general tasks',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding', 'analysis'],
          'contextWindow': 128000,
          'pricing': {'input': 0.05, 'output': 0.05},
        },
      ),
      // GLM-4.5-air (lightweight)
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4.5-air',
        displayName: 'GLM-4.5 Air',
        description: 'Lightweight model for faster responses',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding', 'analysis'],
          'contextWindow': 128000,
          'pricing': {'input': 0.5, 'output': 0.5},
        },
      ),
      // Legacy models for fallback
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4',
        displayName: 'GLM-4',
        description: 'Original GLM-4 model',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding', 'analysis'],
          'contextWindow': 128000,
          'pricing': {'input': 0.1, 'output': 0.1},
        },
      ),
    ];
  }

  /// Get display name for model
  String _getDisplayName(String modelId) {
    switch (modelId) {
      case 'glm-4-plus':
        return 'GLM-4 Plus';
      case 'glm-4-0520':
        return 'GLM-4 0520';
      case 'glm-4':
        return 'GLM-4';
      case 'glm-4-air':
        return 'GLM-4 Air';
      case 'glm-4-airx':
        return 'GLM-4 AirX';
      case 'glm-4-long':
        return 'GLM-4 Long';
      case 'glm-4-flash':
        return 'GLM-4 Flash';
      case 'glm-4.6':
        return 'GLM-4.6';
      case 'glm-4.5-flash':
        return 'GLM-4.5 Flash';
      case 'glm-4.5-air':
        return 'GLM-4.5 Air';
      case 'glm-4.6-flash':
        return 'GLM-4.6 Flash';
      default:
        return modelId.toUpperCase().replaceAll('-', ' ');
    }
  }

  /// Get model capabilities
  List<String> _getModelCapabilities(String modelId) {
    const baseCapabilities = ['text', 'reasoning'];

    if (modelId.contains('v')) {
      return [...baseCapabilities, 'vision'];
    }

    if (modelId.contains('long')) {
      return [...baseCapabilities, 'long-context'];
    }

    if (modelId.contains('airx') || modelId.contains('air')) {
      return [...baseCapabilities, 'coding', 'analysis'];
    }

    // Enhanced capabilities for newer models
    if (modelId.contains('4.5') || modelId.contains('4.6')) {
      return [...baseCapabilities, 'coding', 'analysis', 'multilingual'];
    }

    return baseCapabilities;
  }

  /// Get context window size
  int _getContextWindow(String modelId) {
    if (modelId.contains('long')) {
      return 1000000; // 1M tokens for long context model
    }
    return 128000; // 128K tokens for standard models
  }

  /// Get model pricing (per 1M tokens in RMB)
  Map<String, double> _getModelPricing(String modelId) {
    switch (modelId) {
      case 'glm-4-plus':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4-0520':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4-flash':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4-air':
        return {'input': 1.0, 'output': 1.0};
      case 'glm-4-airx':
        return {'input': 5.0, 'output': 5.0};
      case 'glm-4-long':
        return {'input': 5.0, 'output': 5.0};
      case 'glm-4.5-flash':
        return {'input': 0.05, 'output': 0.05};
      case 'glm-4.5-air':
        return {'input': 0.5, 'output': 0.5};
      case 'glm-4.6':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4.6-flash':
        return {'input': 0.1, 'output': 0.1};
      default:
        return {'input': 1.0, 'output': 1.0};
    }
  }

  /// Send chat message to ZhipuAI API directly
  Future<String> sendMessage({
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    try {
      // Log API key format for debugging (without revealing the key)
      final keyType = apiKey.contains('.') ? 'multi-part' : 'simple';
      final keyLength = apiKey.length;
      _logger.info(
          'ZhipuAI sendMessage - API key format: $keyType, length: $keyLength, model: $model');

      // Convert messages to ZhipuAI format
      final zhipuaiMessages = _convertMessagesToZhipuAIFormat(messages);

      final requestData = {
        'model': model,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'messages': zhipuaiMessages,
      };

      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        data: requestData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept-Language': 'en-US,en',
          },
        ),
      );

      _logger.info('ZhipuAI API response status: ${response.statusCode}');
      _logger.info('ZhipuAI API response data: ${response.data}');

      if (response.statusCode == 200) {
        final choices = response.data['choices'];
        _logger.info('ZhipuAI choices: $choices');

        if (choices != null && choices.isNotEmpty) {
          final content = choices[0]['message']['content'] ?? '';
          _logger.info('ZhipuAI extracted content: "$content"');
          return content;
        }

        _logger.warning('ZhipuAI no choices in response');
      }

      throw Exception(
          'Invalid response from ZhipuAI API: ${response.statusCode}');
    } catch (e) {
      _logger.error('Error sending message to ZhipuAI', error: e);
      rethrow;
    }
  }

  /// Convert messages to ZhipuAI format
  List<Map<String, String>> _convertMessagesToZhipuAIFormat(
    List<Map<String, String>> messages,
  ) {
    final zhipuaiMessages = <Map<String, String>>[];

    for (final message in messages) {
      zhipuaiMessages.add({
        'role': message['role'] == 'assistant' ? 'assistant' : 'user',
        'content': message['content'] ?? '',
      });
    }

    return zhipuaiMessages;
  }
}

/// Custom exception for ZhipuAI authentication errors
class ZhipuAIAuthenticationException implements Exception {
  final String message;

  const ZhipuAIAuthenticationException(this.message);

  @override
  String toString() => message;
}
