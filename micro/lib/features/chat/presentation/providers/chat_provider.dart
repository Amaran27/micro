import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:langchain/langchain.dart';
import 'package:micro/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_adapter.dart';
import 'package:micro/infrastructure/ai/interfaces/provider_config.dart' as pc;
import 'package:micro/infrastructure/ai/adapters/zhipuai_adapter.dart';
import 'package:micro/infrastructure/ai/adapters/chat_google_adapter.dart';
import 'package:micro/infrastructure/ai/adapters/chat_openai_adapter.dart';
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:micro/features/chat/domain/utils/chat_message_converter.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/presentation/providers/ai_providers.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';

class ChatState {
  final List<micro.ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<micro.ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final aiProviderConfigProvider = Provider((ref) => AIProviderConfig());

final llmDataSourceProvider = Provider(
  (ref) => LlmDataSource(ref.watch(aiProviderConfigProvider)),
);

final chatRepositoryProvider = Provider(
  (ref) => ChatRepositoryImpl(ref.watch(llmDataSourceProvider)),
);

final sendMessageUseCaseProvider = Provider(
  (ref) => SendMessageUseCase(ref.watch(chatRepositoryProvider)),
);

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(ref.watch(aiProviderConfigProvider), ref),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final AIProviderConfig _aiProviderConfig;
  final Ref _ref;

  ChatNotifier(this._aiProviderConfig, this._ref) : super(ChatState()) {
    _initializeAIProvider();
  }

  Future<void> _initializeAIProvider() async {
    await _aiProviderConfig.initialize();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final langchainUserMessage =
        ChatMessage.human(ChatMessageContent.text(text));
    final userMessage = convertLangchainChatMessage(langchainUserMessage);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // Get the current selected model
      // Get the current selected model
      final currentModelIdAsync = _ref.read(currentSelectedModelProvider);
      // Wait for the AsyncValue to be ready and extract the value
      final currentModelId = currentModelIdAsync.when(
        data: (value) {
          print('DEBUG: currentSelectedModelProvider returned: $value');
          return value;
        },
        loading: () {
          print('DEBUG: currentSelectedModelProvider is loading');
          return null;
        },
        error: (error, stack) {
          print('DEBUG: currentSelectedModelProvider error: $error');
          return null;
        },
      );

      print('DEBUG: Final currentModelId: $currentModelId');

      ProviderAdapter? adapter;

      // If no specific model is selected, try to get the active model for each provider
      if (currentModelId == null) {
        final activeModels = _aiProviderConfig.getAllActiveModels();
        print('DEBUG: Active models: $activeModels');

        // Check if ZhipuAI has an active model
        final zhipuaiModel = activeModels['zhipu-ai'];
        if (zhipuaiModel != null) {
          adapter = _aiProviderConfig.getProvider('zhipu-ai');
          print('DEBUG: Using active ZhipuAI model: $zhipuaiModel');
        }
      }

      if (currentModelId != null) {
        // Get the provider for the selected model
        String providerId = _detectProviderFromModel(currentModelId);

        print(
            'DEBUG: Current model ID: $currentModelId, detected provider: $providerId');

        // First try to get adapter from new provider system
        try {
          final configsAsync = _ref.read(providersConfigProvider);
          final configs = await configsAsync.when(
            data: (data) async => data,
            loading: () async => [],
            error: (e, s) async {
              print('DEBUG: Error reading new configs: $e');
              return [];
            },
          );

          if (configs.isNotEmpty) {
            try {
              // Find config for this provider that has this model
              ProviderConfig? matchingConfig;

              // First try to find a config with the exact model as favorite
              for (final c in configs) {
                if (c.providerId == providerId &&
                    c.isEnabled &&
                    c.testPassed &&
                    c.favoriteModels.contains(currentModelId)) {
                  matchingConfig = c;
                  break;
                }
              }

              // If not found, try to find any enabled config for this provider
              if (matchingConfig == null) {
                for (final c in configs) {
                  if (c.providerId == providerId && c.isEnabled) {
                    matchingConfig = c;
                    break;
                  }
                }
              }

              if (matchingConfig != null) {
                print(
                    'DEBUG: Found new provider config: ${matchingConfig.providerId}');

                // Create adapter for this provider
                adapter = await _createAdapterFromConfig(
                    matchingConfig, currentModelId);
                print(
                    'DEBUG: Created adapter from new config: ${adapter?.providerId}');
              } else {
                print(
                    'DEBUG: No matching config found for provider: $providerId');
              }
            } catch (e) {
              print('DEBUG: Error finding config: $e');
            }
          }
        } catch (e) {
          print('DEBUG: Error reading new provider configs: $e');
        }

        // Fallback to old system if new system didn't provide adapter
        if (adapter == null) {
          adapter = _aiProviderConfig.getProvider(providerId);
          print(
              'DEBUG: Fallback to old provider system adapter: ${adapter?.providerId}');
        }

        print(
            'DEBUG: Final adapter: ${adapter?.providerId}, current model: ${adapter?.currentModel}');

        // If we couldn't get an adapter or it doesn't have the right model, try direct provider lookup
        if (adapter == null || adapter.currentModel != currentModelId) {
          if (currentModelId.toLowerCase().startsWith('glm-')) {
            adapter = _aiProviderConfig.getProvider('zhipu-ai');
            print('DEBUG: Using direct ZhipuAI provider for GLM model');
          } else if (currentModelId.toLowerCase().startsWith('gemini-')) {
            adapter = _aiProviderConfig.getProvider('google');
            print('DEBUG: Using direct Google provider for Gemini model');
          }
        }

        // Switch to the selected model if different from current
        final currentAdapter = adapter;
        if (currentAdapter != null &&
            currentAdapter.currentModel != currentModelId) {
          await currentAdapter.switchModel(currentModelId);
          print('DEBUG: Switched adapter to model: $currentModelId');
        }
      }

      // Fallback to any available provider if we couldn't get a specific one
      if (adapter == null) {
        // If no specific model is selected, try to use the active ZhipuAI model
        if (currentModelId == null) {
          final activeModels = _aiProviderConfig.getAllActiveModels();
          print('DEBUG: Active models when no currentModelId: $activeModels');

          // Check if ZhipuAI has an active model
          final zhipuaiModel = activeModels['zhipuai'];
          if (zhipuaiModel != null) {
            adapter = _aiProviderConfig.getProvider('zhipuai');
            print('DEBUG: Using active ZhipuAI model: $zhipuaiModel');
          } else {
            // Try Google as fallback
            final googleModel = activeModels['google'];
            if (googleModel != null) {
              adapter = _aiProviderConfig.getProvider('google');
              print('DEBUG: Using active Google model: $googleModel');
            }
          }
        }
        // Otherwise try to get a provider based on the current model prefix
        else if (currentModelId.toLowerCase().startsWith('glm-')) {
          adapter = _aiProviderConfig.getProvider('zhipuai');
          print(
              'DEBUG: Fallback to ZhipuAI adapter for GLM model: $currentModelId');
        } else if (currentModelId.toLowerCase().startsWith('gemini-')) {
          adapter = _aiProviderConfig.getProvider('google');
          print(
              'DEBUG: Using Google adapter for Gemini model: $currentModelId');
        } else {
          // For any other model, try to detect the provider
          final detectedProvider = _detectProviderFromModel(currentModelId);
          adapter = _aiProviderConfig.getProvider(detectedProvider);
          print(
              'DEBUG: Using detected provider $detectedProvider for model: $currentModelId');
        }
      }

      final finalAdapter = adapter;
      if (finalAdapter != null && finalAdapter.isInitialized) {
        print(
            'DEBUG: Using adapter: ${finalAdapter.providerId} with model: ${finalAdapter.currentModel}');
        // Use the adapter's sendMessage method
        final aiResponse = await finalAdapter.sendMessage(
          text: text,
          history: state.messages,
        );

        state = state.copyWith(
          messages: [...state.messages, aiResponse],
          isLoading: false,
        );
      } else {
        // Fallback response if no AI adapter is available
        final aiResponse = micro.ChatMessage.assistant(
          id: DateTime.now().toIso8601String(),
          content:
              'Sorry, no AI provider is currently available. Please configure an AI provider in settings.',
        );

        state = state.copyWith(
          messages: [...state.messages, aiResponse],
          isLoading: false,
        );
      }
    } catch (e) {
      print('DEBUG: Error in sendMessage: $e');
      print('DEBUG: Creating error message for rate limit');

      // Create an error message for the chat
      String errorMessage;
      if (e.toString().contains('RateLimitException') ||
          e.toString().contains('429')) {
        errorMessage =
            'I\'ve reached my usage limit for now. Please try again later or switch to a different AI provider in settings.';
      } else if (e.toString().contains('quota') ||
          e.toString().contains('billing')) {
        errorMessage =
            'The AI service quota has been exceeded. Please check your billing details or try a different provider.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage =
            'Network connection issue. Please check your internet connection and try again.';
      } else {
        errorMessage =
            'Sorry, I encountered an error while processing your message. Please try again.';
      }

      print('DEBUG: Creating error message: $errorMessage');

      final errorResponse = micro.ChatMessage.assistant(
        id: DateTime.now().toIso8601String(),
        content: errorMessage,
      );

      print('DEBUG: Error response created: ${errorResponse.content}');
      print(
          'DEBUG: Current messages count before error: ${state.messages.length}');

      state = state.copyWith(
        messages: [...state.messages, errorResponse],
        isLoading: false,
        error: e.toString(),
      );

      print('DEBUG: Messages count after error: ${state.messages.length}');
      print('DEBUG: Error message added to state');
    }
  }

  /// Clear all messages from the chat history
  void clearMessages() {
    state = state.copyWith(messages: []);
  }

  /// Create adapter from new ProviderConfig
  Future<ProviderAdapter?> _createAdapterFromConfig(
      dynamic config, String modelId) async {
    try {
      final providerId = config.providerId;
      final apiKey = config.apiKey;

      print('DEBUG: Creating adapter for $providerId with model $modelId');

      ProviderAdapter? adapter;

      switch (providerId) {
        case 'zhipu-ai':
          adapter = ZhipuAIAdapter();
          final zhipuConfig = pc.ZhipuAIConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(zhipuConfig);
          break;
        case 'google':
          adapter = ChatGoogleAdapter();
          final googleConfig = pc.GoogleConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(googleConfig);
          break;
        case 'openai':
          adapter = ChatOpenAIAdapter();
          final openaiConfig = pc.OpenAIConfig(
            model: modelId,
            apiKey: apiKey,
          );
          await adapter.initialize(openaiConfig);
          break;
        default:
          print(
              'DEBUG: Provider $providerId not yet implemented for new system');
          return null;
      }

      print(
          'DEBUG: Successfully created and initialized adapter for $providerId');
      return adapter;
    } catch (e) {
      print('DEBUG: Error creating adapter from config: $e');
      return null;
    }
  }

  /// Detect provider from model ID
  String _detectProviderFromModel(String? modelId) {
    if (modelId == null) return 'google'; // Default fallback

    final lowerModelId = modelId.toLowerCase();

    // OpenAI models
    if (lowerModelId.startsWith('gpt-') ||
        lowerModelId.startsWith('o1-') ||
        lowerModelId.startsWith('dall-') ||
        lowerModelId.startsWith('whisper-') ||
        lowerModelId.startsWith('tts-')) {
      return 'openai';
    }

    // Anthropic Claude models
    if (lowerModelId.startsWith('claude-')) {
      return 'claude';
    }

    // Google models
    if (lowerModelId.startsWith('gemini-') ||
        lowerModelId.startsWith('palm-') ||
        lowerModelId.startsWith('bard-')) {
      return 'google';
    }

    // ZhipuAI models
    if (lowerModelId.startsWith('glm-') ||
        lowerModelId.startsWith('chatglm-')) {
      return 'zhipu-ai';
    }

    // Cohere models
    if (lowerModelId.startsWith('command-') ||
        lowerModelId.startsWith('base-') ||
        lowerModelId.startsWith('embed-')) {
      return 'cohere';
    }

    // Mistral models
    if (lowerModelId.startsWith('mistral-') ||
        lowerModelId.startsWith('codestral')) {
      return 'mistral';
    }

    // Stability AI models
    if (lowerModelId.contains('stable-diffusion') ||
        lowerModelId.contains('sdxl')) {
      return 'stability';
    }

    // Default to Google for unknown models
    return 'google';
  }
}
