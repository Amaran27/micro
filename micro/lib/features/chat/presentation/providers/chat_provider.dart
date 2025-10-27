import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:langchain/langchain.dart';
import 'package:micro/features/chat/domain/usecases/send_message_usecase.dart';
import 'package:micro/infrastructure/ai/ai_provider_config.dart';
import 'package:micro/features/chat/data/sources/llm_data_source.dart';
import 'package:micro/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:micro/features/chat/domain/utils/chat_message_converter.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;

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
  (ref) => ChatNotifier(ref.watch(sendMessageUseCaseProvider),
      ref.watch(aiProviderConfigProvider)),
);

class ChatNotifier extends StateNotifier<ChatState> {
  final SendMessageUseCase _sendMessageUseCase;
  final AIProviderConfig _aiProviderConfig;

  ChatNotifier(this._sendMessageUseCase, this._aiProviderConfig)
      : super(ChatState()) {
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
      final langchainAiResponse = await _sendMessageUseCase(text);
      final aiResponse = convertLangchainChatMessage(langchainAiResponse);
      state = state.copyWith(
        messages: [...state.messages, aiResponse],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear all messages from the chat history
  void clearMessages() {
    state = state.copyWith(messages: []);
  }
}
