import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:micro/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:micro/features/chat/domain/utils/chat_message_converter.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/presentation/providers/ai_providers.dart';

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
      final currentModelIdAsync = _ref.read(currentSelectedModelProvider);
      // Wait for the AsyncValue to be ready and extract the value
      final currentModelId = await currentModelIdAsync.when(
        data: (value) => value,
        loading: () => null,
        error: (_, __) => null,
      );

      BaseChatModel? chatModel;

      if (currentModelId != null) {
        // Get the provider for the selected model
        String providerId = _detectProviderFromModel(currentModelId);

        // Get the provider and create a new model with the selected model ID
        final baseProvider = _aiProviderConfig.getProvider(providerId);

        if (baseProvider is ChatGoogleGenerativeAI) {
          // Create a new Google AI instance with the selected model
          final config = _aiProviderConfig.getProviderConfig(providerId);
          if (config != null) {
            chatModel = ChatGoogleGenerativeAI(
              apiKey: config['apiKey'],
              defaultOptions: ChatGoogleGenerativeAIOptions(
                model: currentModelId,
                temperature: 0.7,
                topP: 1.0,
                topK: 40,
              ),
            );
          }
        } else if (baseProvider is ChatOpenAI) {
          // Create a new OpenAI instance with the selected model
          final config = _aiProviderConfig.getProviderConfig(providerId);
          if (config != null) {
            chatModel = ChatOpenAI(
              apiKey: config['apiKey'],
              defaultOptions: ChatOpenAIOptions(
                model: currentModelId,
                maxTokens: 1000,
                temperature: 0.7,
                topP: 1.0,
              ),
            );
          }
        }
      }

      // Fallback to any available model if we couldn't create a specific one
      chatModel ??= _aiProviderConfig.getBestAvailableChatModel();

      if (chatModel != null) {
        final humanMessage = ChatMessage.human(ChatMessageContent.text(text));
        final response = await chatModel.call([humanMessage]);
        final aiResponse = convertLangchainChatMessage(response);
        state = state.copyWith(
          messages: [...state.messages, aiResponse],
          isLoading: false,
        );
      } else {
        // Fallback response if no AI model is available
        final aiResponse = micro.ChatMessage.assistant(
          id: DateTime.now().toIso8601String(),
          content:
              'Sorry, no AI model is currently available. Please configure an AI provider in settings.',
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
