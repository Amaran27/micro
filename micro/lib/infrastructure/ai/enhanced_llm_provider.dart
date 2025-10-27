import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';

import '../../infrastructure/ai/ai_provider_config.dart';

/// Enhanced LLM provider with multiple fallback options
class EnhancedLLMProvider {
  final AIProviderConfig _config;
  final AppLogger _logger;

  // Primary models for different providers
  late final ChatOpenAI? _openAI;
  late final ChatGoogleGenerativeAI? _googleAI;

  // Active provider selection
  BaseChatModel? _currentModel;
  String _currentProvider = 'openai';

  EnhancedLLMProvider(this._config, this._logger);

  /// Initialize all available providers
  Future<void> initialize() async {
    await _config.initialize();

    try {
      // Initialize OpenAI if available
      final openAIModel = _config.getBestAvailableChatModel();
      if (openAIModel is ChatOpenAI) {
        _openAI = openAIModel;
        _currentModel = _openAI;
        _currentProvider = 'openai';
        _logger.info('OpenAI provider initialized');
      }

      // Initialize Google AI if available
      final googleAIModel = _config.getBestAvailableChatModel();
      if (googleAIModel is ChatGoogleGenerativeAI) {
        _googleAI = googleAIModel;
        _currentModel ??= _googleAI;
        _currentProvider = 'google';
        _logger.info('Google AI provider initialized');
      }

      // Set fallback if primary is not available
      if (_currentModel == null && _googleAI != null) {
        _currentModel = _googleAI;
        _currentProvider = 'google';
        _logger.info('Using Google AI as fallback');
      }
    } catch (e) {
      _logger.error('Failed to initialize LLM providers', error: e);
      // Continue with no providers if initialization fails
    }
  }

  /// Get current active model
  BaseChatModel? get currentModel => _currentModel;

  /// Get current provider name
  String get currentProvider => _currentProvider;

  /// Switch to specific provider
  Future<bool> switchToProvider(String provider) async {
    switch (provider.toLowerCase()) {
      case 'openai':
        if (_openAI != null) {
          _currentModel = _openAI;
          _currentProvider = 'openai';
          _logger.info('Switched to OpenAI');
          return true;
        }
        break;
      case 'google':
        if (_googleAI != null) {
          _currentModel = _googleAI;
          _currentProvider = 'google';
          _logger.info('Switched to Google AI');
          return true;
        }
        break;
      case 'anthropic':
        // TODO: Add Anthropic Claude support
        _logger.info('Anthropic Claude not yet implemented');
        return false;
      case 'ollama':
        // TODO: Add Ollama support
        _logger.info('Ollama not yet implemented');
        return false;
      default:
        _logger.warning('Unknown provider: $provider');
        return false;
    }
    return false;
  }

  /// Get available providers
  List<String> get availableProviders {
    final providers = <String>[];
    if (_openAI != null) providers.add('OpenAI (GPT-4o)');
    if (_googleAI != null) providers.add('Google AI (Gemini 1.5)');
    // TODO: Add Anthropic and Ollama when implemented
    return providers;
  }

  /// Get provider-specific capabilities
  Map<String, dynamic> getProviderCapabilities() {
    switch (_currentProvider) {
      case 'openai':
        return {
          'maxTokens': 4000,
          'supportsStreaming': true,
          'supportsVision': true,
          'supportsTools': true,
          'costPerToken': 'high',
          'reasoning': 'excellent',
          'speed': 'medium',
        };
      case 'google':
        return {
          'maxTokens': 8192,
          'supportsStreaming': true,
          'supportsVision': true,
          'supportsTools': false,
          'costPerToken': 'low',
          'reasoning': 'good',
          'speed': 'fast',
        };
      default:
        return {
          'error': 'Unknown provider',
        };
    }
  }

  /// Generate completion with current provider
  Future<String> generateCompletion(
    String prompt, {
    Map<String, dynamic>? options,
  }) async {
    if (_currentModel == null) {
      return 'No AI provider available. Please check your API keys.';
    }

    try {
      final result = await _currentModel!.invoke(
        PromptValue.string(prompt),
        options: options,
      );

      if (result.output.isNotEmpty) {
        return result.output;
      } else {
        return 'I apologize, but I could not generate a response.';
      }
    } catch (e) {
      _logger.error('LLM generation failed', error: e);
      return 'Error: ${e.toString()}';
    }
  }

  /// Generate streaming completion
  Stream<String> generateStreamingCompletion(
    String prompt, {
    Map<String, dynamic>? options,
  }) async* {
    if (_currentModel == null) {
      yield 'No AI provider available.';
      return;
    }

    try {
      await for (final chunk
          in _currentModel!.stream(Prompt: PromptValue.string(prompt))) {
        yield chunk.output;
      }
    } catch (e) {
      _logger.error('Streaming LLM generation failed', error: e);
      yield 'Error: ${e.toString()}';
    }
  }

  /// Check if current provider supports tools
  bool get supportsTools {
    switch (_currentProvider) {
      case 'openai':
        return true;
      case 'google':
        return false; // TODO: Update when Gemini supports tools
      default:
        return false;
    }
  }

  /// Check if current provider supports vision
  bool get supportsVision {
    switch (_currentProvider) {
      case 'openai':
      case 'google':
        return true;
      default:
        return false;
    }
  }

  /// Get recommended provider for task type
  String getRecommendedProvider(String taskType) {
    switch (taskType.toLowerCase()) {
      case 'coding':
      case 'reasoning':
      case 'analysis':
        return 'openai'; // Best for complex tasks
      case 'chat':
      case 'quick':
      case 'summarization':
        return 'google'; // Best for speed and cost
      case 'creative':
      case 'writing':
        return 'anthropic'; // Best for creative tasks (when implemented)
      case 'private':
      case 'offline':
        return 'ollama'; // Best for privacy
      default:
        return 'google'; // Good default
    }
  }

  /// Provider status summary
  Map<String, dynamic> getStatusSummary() {
    return {
      'currentProvider': _currentProvider,
      'availableProviders': availableProviders,
      'isInitialized': _currentModel != null,
      'capabilities': getProviderCapabilities(),
      'supportsTools': supportsTools,
      'supportsVision': supportsVision,
    };
  }
}
