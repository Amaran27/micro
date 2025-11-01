import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:dio/dio.dart';

/// OpenAI MDO provider
class OpenAIMDOProvider {
  static const String providerId = 'openai';
  static const String providerName = 'OpenAI';
  static const String providerType = 'commercial';
  static const String description = 'OpenAI ChatGPT models';

  // Models will be fetched dynamically from the API
  List<Map<String, dynamic>> models = [];

  final String apiKey;
  final String? selectedModel;

  OpenAIMDOProvider({
    required this.apiKey,
    this.selectedModel,
  });

  /// Get available models
  List<Map<String, dynamic>> getAvailableModels() {
    return models;
  }

  /// Get model by ID
  Map<String, dynamic>? getModel(String modelId) {
    for (final model in models) {
      if (model['id'] == modelId) {
        return model;
      }
    }
    return null;
  }

  /// Get selected model
  Map<String, dynamic>? getSelectedModel() {
    if (selectedModel != null) {
      return getModel(selectedModel!);
    }
    // If no model is selected, return the first available model
    return models.isNotEmpty ? models.first : null;
  }

  /// Initialize chat model
  Future<ChatOpenAI> initializeChatModel() async {
    final model = getSelectedModel();
    if (model == null) {
      throw Exception('No OpenAI model selected');
    }

    // Fetch models if not already loaded
    if (models.isEmpty) {
      await fetchModels();
    }

    return ChatOpenAI(
      apiKey: apiKey,
      defaultOptions: ChatOpenAIOptions(
        model: model['id'],
        temperature: 0.7,
        maxTokens: model['maxTokens'] ?? 4000,
      ),
    );
  }

  /// Initialize image model
  Future<ChatOpenAI> initializeImageModel() async {
    final model = getSelectedModel();
    if (model == null || !(model['supportsVision'] as bool)) {
      throw Exception('Selected OpenAI model does not support images');
    }

    // Fetch models if not already loaded
    if (models.isEmpty) {
      await fetchModels();
    }

    return ChatOpenAI(
      apiKey: apiKey,
      defaultOptions: ChatOpenAIOptions(
        model: model['id'],
        temperature: 0.7,
        maxTokens: model['maxTokens'] ?? 4000,
      ),
    );
  }

  /// Fetch models from OpenAI API
  Future<void> fetchModels() async {
    if (models.isNotEmpty) return; // Already fetched

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.openai.com/v1/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> apiModels = data['data'];

        // Filter for GPT models and add required metadata
        models = apiModels
            .where((model) => (model['id'] as String).startsWith('gpt-'))
            .map((model) => {
                  'id': model['id'],
                  'name': model['id'],
                  'description': 'OpenAI GPT model',
                  'strength': _getModelStrength(model['id']),
                  'contextWindow': _getContextWindow(model['id']),
                  'maxTokens': _getContextWindow(model['id']),
                  'supportsVision': _supportsVision(model['id']),
                  'supportsTools': true,
                  'supportsFunctionCalling': true,
                  'costPerToken': _getCostPerToken(model['id']),
                })
            .toList();
      }
    } catch (e) {
      // If API fails, add fallback models
      models = [
        {
          'id': 'gpt-4o-mini',
          'name': 'GPT-4o-mini',
          'description': 'Fast and efficient model',
          'strength': 9,
          'contextWindow': 128000,
          'maxTokens': 128000,
          'supportsVision': true,
          'supportsTools': true,
          'supportsFunctionCalling': true,
          'costPerToken': 'medium',
        }
      ];
    }
  }

  /// Get model strength based on model ID
  int _getModelStrength(String modelId) {
    if (modelId.contains('gpt-4o')) return 10;
    if (modelId.contains('gpt-4')) return 9;
    if (modelId.contains('gpt-3.5')) return 8;
    return 7;
  }

  /// Get context window size based on model ID
  int _getContextWindow(String modelId) {
    if (modelId.contains('gpt-4o')) return 128000;
    if (modelId.contains('gpt-4')) return 8192;
    if (modelId.contains('gpt-3.5')) return 16385;
    return 4096;
  }

  /// Check if model supports vision
  bool _supportsVision(String modelId) {
    return modelId.contains('gpt-4o') || modelId.contains('vision');
  }

  /// Get cost per token based on model ID
  String _getCostPerToken(String modelId) {
    if (modelId.contains('gpt-4o')) return 'high';
    if (modelId.contains('gpt-4')) return 'high';
    return 'medium';
  }

  /// Create completion message
  Future<String> createCompletion({
    required String prompt,
    Map<String, dynamic>? options,
  }) async {
    try {
      final chat = await initializeChatModel();

      final promptValue = PromptValue.string(prompt);
      final response = await chat.invoke(promptValue);

      return response.outputAsString;
    } catch (e) {
      throw Exception('OpenAI completion failed: $e');
    }
  }

  /// Create streaming completion
  Stream<String> createStreamingCompletion({
    required String prompt,
    Map<String, dynamic>? options,
  }) async* {
    try {
      final chat = await initializeChatModel();

      final promptValue = PromptValue.string(prompt);
      final stream = chat.stream(promptValue);

      await for (final chunk in stream) {
        yield chunk.outputAsString;
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  /// Create image completion
  Future<String> createImageCompletion({
    required String prompt,
    String? imageModel,
  }) async {
    try {
      final chat = await initializeImageModel();

      String content = prompt;
      if (imageModel != null) {
        content += "\n\nImage: $imageModel";
      }

      final promptValue = PromptValue.string(content);
      final response = await chat.invoke(promptValue);

      return response.outputAsString;
    } catch (e) {
      throw Exception('OpenAI image completion failed: $e');
    }
  }
}
