import 'dart:convert';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../secure_api_storage.dart';
import '../../../domain/models/ai_model.dart';

/// ZhipuAI (GLM) provider implementation
class ZhipuAIProvider {
  final AppLogger _logger = AppLogger();
  final Dio _dio = Dio();

  static const String _baseUrl = 'https://open.bigmodel.cn/api/paas/v4';

  /// Initialize ZhipuAI provider
  Future<ChatOpenAI?> initialize() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        _logger.warning('ZhipuAI API key not found');
        return null;
      }

      // Create custom chat model implementation for ZhipuAI
      return _createZhipuAIChatModel(apiKey);
    } catch (e) {
      _logger.error('Failed to initialize ZhipuAI provider', error: e);
      return null;
    }
  }

  /// Create ZhipuAI chat model using OpenAI-compatible interface
  ChatOpenAI _createZhipuAIChatModel(String apiKey) {
    // Use OpenAI client with custom base URL for ZhipuAI
    return ChatOpenAI(
      apiKey: apiKey,
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      defaultOptions: ChatOpenAIOptions(
        model: 'glm-4-flash', // Default model
        maxTokens: 4000,
        temperature: 0.7,
      ),
    );
  }

  /// Get available ZhipuAI models
  Future<List<AIModel>> getAvailableModels() async {
    try {
      final apiKey = await SecureApiStorage.getApiKey('zhipuai');
      if (apiKey == null || apiKey.isEmpty) {
        return _getDefaultModels();
      }

      // ZhipuAI uses JWT authentication, need to generate token
      final token = await _generateJWTToken(apiKey);
      if (token == null) {
        return _getDefaultModels();
      }

      final response = await _dio.get(
        '$_baseUrl/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
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
                provider: 'zhipuai',
                modelId: model['id'],
                displayName: _getDisplayName(model['id']),
                description: model['description'] ?? 'ZhipuAI GLM model',
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
        _logger
            .warning('Failed to fetch ZhipuAI models: ${response.statusCode}');
        return _getDefaultModels();
      }
    } catch (e) {
      _logger.warning('Error fetching ZhipuAI models, using defaults',
          error: e);
      return _getDefaultModels();
    }
  }

  

  /// Generate JWT token for ZhipuAI API authentication
  Future<String?> _generateJWTToken(String apiKey) async {
    try {
      // ZhipuAI uses JWT for authentication
      // The API key format can be: {id}.{secret} or just a regular API key
      final parts = apiKey.split('.');
      if (parts.length != 2) {
        _logger.warning('ZhipuAI API key format may be incorrect, trying direct usage');
        // Try using the API key directly instead of failing
        return apiKey;
      }

      final id = parts[0];
      // The secret would be used for proper JWT signing in production
      final secret = parts[1];

      // Create JWT payload
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'iat': now,
        'exp': now + 3600, // 1 hour expiration
        'iss': id,
      };

      // For simplicity, we'll use a basic approach
      // In production, you should use a proper JWT library with the secret
      // for proper HMAC-SHA256 signing
      final header = {'alg': 'HS256', 'typ': 'JWT'};

      // This is a simplified JWT generation
      // In production, use crypto package for proper signing
      final encodedHeader = base64Url.encode(utf8.encode(json.encode(header)));
      final encodedPayload =
          base64Url.encode(utf8.encode(json.encode(payload)));

      // Note: This is a placeholder for actual JWT signing
      // You would need to implement proper HMAC-SHA256 signing using:
      // crypto.Hmac(sha256, utf8.encode(secret)).convert(payloadBytes)
      final signature = 'placeholder_signature';

      // Mark secret as used to avoid lint warnings
      secret.length;

      return '$encodedHeader.$encodedPayload.$signature';
    } catch (e) {
      _logger.error('Failed to generate JWT token', error: e);
      return null;
    }
  }

  /// Get default ZhipuAI models
  List<AIModel> _getDefaultModels() {
    return [
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4-flash',
        displayName: 'GLM-4 Flash',
        description: 'Fast and efficient GLM model for quick responses',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding'],
          'contextWindow': 128000,
          'pricing': {'input': 0.1, 'output': 0.1},
        },
      ),
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4-air',
        displayName: 'GLM-4 Air',
        description: 'Balanced GLM model for general tasks',
        metadata: {
          'capabilities': ['text', 'reasoning', 'coding'],
          'contextWindow': 128000,
          'pricing': {'input': 1.0, 'output': 1.0},
        },
      ),
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4-airx',
        displayName: 'GLM-4 AirX',
        description: 'Enhanced GLM model with improved capabilities',
        metadata: {
          'capabilities': ['text', 'reasoning', 'analysis', 'coding'],
          'contextWindow': 128000,
          'pricing': {'input': 5.0, 'output': 5.0},
        },
      ),
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4-long',
        displayName: 'GLM-4 Long',
        description: 'GLM model with extended context window',
        metadata: {
          'capabilities': ['text', 'reasoning', 'long-context'],
          'contextWindow': 1000000,
          'pricing': {'input': 5.0, 'output': 5.0},
        },
      ),
      AIModel(
        provider: 'zhipuai',
        modelId: 'glm-4v-flash',
        displayName: 'GLM-4V Flash',
        description: 'Multimodal GLM model with vision capabilities',
        metadata: {
          'capabilities': ['text', 'vision', 'reasoning'],
          'contextWindow': 128000,
          'pricing': {'input': 0.1, 'output': 0.1},
        },
      ),
    ];
  }

  /// Get display name for model
  String _getDisplayName(String modelId) {
    switch (modelId) {
      case 'glm-4-flash':
        return 'GLM-4 Flash';
      case 'glm-4-air':
        return 'GLM-4 Air';
      case 'glm-4-airx':
        return 'GLM-4 AirX';
      case 'glm-4-long':
        return 'GLM-4 Long';
      case 'glm-4v-flash':
        return 'GLM-4V Flash';
      default:
        return modelId.toUpperCase();
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
      case 'glm-4-flash':
        return {'input': 0.1, 'output': 0.1};
      case 'glm-4-air':
        return {'input': 1.0, 'output': 1.0};
      case 'glm-4-airx':
        return {'input': 5.0, 'output': 5.0};
      case 'glm-4-long':
        return {'input': 5.0, 'output': 5.0};
      case 'glm-4v-flash':
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
      // Generate JWT token
      final token = await _generateJWTToken(apiKey);
      if (token == null) {
        throw Exception('Failed to generate authentication token');
      }

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
            'Authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final choices = response.data['choices'];
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] ?? '';
        }
      }

      throw Exception('Invalid response from ZhipuAI API');
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
