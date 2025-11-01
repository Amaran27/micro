import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';
import '../config/available_models.dart';

/// Google AI MDO provider
class GoogleAIMDOProvider {
  static const String providerId = 'google';
  static const String providerName = 'Google AI';
  static const String providerType = 'commercial';

  final String apiKey;
  String? selectedModelId;
  bool _isInitialized = false;

  GoogleAIMDOProvider({
    required this.apiKey,
    this.selectedModelId,
  });

  /// Initialize Google AI provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For demo purposes, we'll simulate initialization
      await Future.delayed(const Duration(milliseconds: 500));
      _isInitialized = true;
      print('Google AI MDO Provider initialized');
    } catch (e) {
      throw Exception('Failed to initialize Google AI MDO: $e');
    }
  }

  /// Get available Google AI models
  Map<String, dynamic> getAvailableModels() {
    final googleModels = AvailableModels.getAllProviders()
        .firstWhere((provider) => provider['name'] == 'Google AI');

    return {
      'provider': 'Google AI',
      'models': googleModels['models'] ?? [],
      'isInitialized': _isInitialized,
      'selectedModel': selectedModelId,
      'strength': googleModels['strength'],
      'type': googleModels['type'],
      'description': googleModels['description'],
    };
  }

  /// Select model
  void selectModel(String modelId) {
    if (!_isInitialized) return;

    final googleModels = AvailableModels.getAllProviders()
        .firstWhere((provider) => provider['name'] == 'Google AI');

    final models = googleModels['models'] as List;
    final modelExists = models.any((m) => m['id'] == modelId);

    if (modelExists) {
      selectedModelId = modelId;
      print('Google AI: Selected model $modelId');
    } else {
      print('Google AI: Model $modelId not found');
    }
  }

  /// Generate completion
  Future<String> generateCompletion(
    String prompt, {
    Map<String, dynamic>? options,
  }) async {
    if (!_isInitialized) return 'Google AI not initialized';

    final googleModels = AvailableModels.getAllProviders()
        .firstWhere((provider) => provider['name'] == 'Google AI');

    final models = googleModels['models'] as List;
    final selectedModel = models
        .firstWhere((m) => m['id'] == (selectedModelId ?? 'gemini-1.5-flash'));

    if (selectedModel == null) {
      throw Exception('No Google AI model selected');
    }

    try {
      // Simulate Google AI completion using langchain_google
      final chat = ChatGoogleGenerativeAI(
        apiKey: apiKey,
        model: selectedModel['id'],
      );

      final result = await chat.invoke(PromptValue.string(prompt));
      return result.content ?? 'No response from Google AI';
    } catch (e) {
      throw Exception('Google AI completion failed: $e');
    }
  }

  /// Generate streaming completion
  Stream<String> generateStreamingCompletion(
    String prompt, {
    Map<String, dynamic>? options,
  }) async* {
    if (!_isInitialized) {
      yield 'Google AI not initialized';
      return;
    }

    final googleModels = AvailableModels.getAllProviders()
        .firstWhere((provider) => provider['name'] == 'Google AI');

    final models = googleModels['models'] as List;
    final selectedModel = models
        .firstWhere((m) => m['id'] == (selectedModelId ?? 'gemini-1.5-flash'));

    if (selectedModel == null) {
      yield 'No Google AI model selected';
      return;
    }

    try {
      // Simulate Google AI streaming using langchain_google
      final chat = ChatGoogleGenerativeAI(
        apiKey: apiKey,
        model: selectedModel['id'],
      );

      final stream = chat.stream(PromptValue.string(prompt));

      await for (final chunk in stream) {
        yield chunk.output ?? '';
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  /// Get capabilities
  Map<String, dynamic> getCapabilities() {
    return {
      'provider': 'Google AI',
      'strength': 8,
      'supportsStreaming': true,
      'supportsVision': true,
      'supportsTools': false,
      'supportsFunctionCalling': false,
      'costPerToken': 'low',
      'reasoning': 'good',
      'speed': 'fast',
      'contextWindow': '32k',
      'providerType': 'commercial',
      'isInitialized': _isInitialized,
    };
  }

  /// Get current model info
  Map<String, dynamic> getCurrentModel() {
    if (!_isInitialized) return {'error': 'Not initialized'};

    final googleModels = AvailableModels.getAllProviders()
        .firstWhere((provider) => provider['name'] == 'Google AI');

    final models = googleModels['models'] as List;
    final selectedModel = models
        .firstWhere((m) => m['id'] == (selectedModelId ?? 'gemini-1.5-flash'));

    return {
      'provider': 'Google AI',
      'currentModel': selectedModel,
      'isInitialized': _isInitialized,
      'strength': googleModels['strength'],
    };
  }
}
