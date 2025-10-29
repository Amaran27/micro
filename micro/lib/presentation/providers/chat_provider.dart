import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langchain/langchain.dart' as lc;
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_openai/langchain_openai.dart';

import '../../domain/models/chat/chat_message.dart';
import '../../domain/models/chat/conversation.dart';
import '../../domain/models/chat/tool_execution_result.dart';
import '../../domain/models/chat/autonomous_suggestion.dart';
import '../../domain/models/autonomous/context_analysis.dart';
import '../../domain/models/autonomous/user_intent.dart';
import '../../domain/models/autonomous/autonomous_action.dart';
import '../providers/tools_provider.dart';
import '../providers/ai_providers.dart';
import '../../core/utils/logger.dart';

/// Chat state management class
class ChatState {
  final List<Conversation> conversations;
  final Conversation? currentConversation;
  final List<ChatMessage> currentMessages;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final List<AutonomousSuggestion> suggestions;
  final List<ChatToolExecutionResult> activeExecutions;
  final Map<String, dynamic> typingUsers;
  final bool isAutonomousEnabled;
  final ContextAnalysis? currentContext;
  final UserIntent? lastRecognizedIntent;
  final AutonomousAction? lastAutonomousAction;

  const ChatState({
    this.conversations = const [],
    this.currentConversation,
    this.currentMessages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.suggestions = const [],
    this.activeExecutions = const [],
    this.typingUsers = const {},
    this.isAutonomousEnabled = false,
    this.currentContext,
    this.lastRecognizedIntent,
    this.lastAutonomousAction,
  });

  ChatState copyWith({
    List<Conversation>? conversations,
    Conversation? currentConversation,
    List<ChatMessage>? currentMessages,
    bool? isLoading,
    bool? isSending,
    String? error,
    List<AutonomousSuggestion>? suggestions,
    List<ChatToolExecutionResult>? activeExecutions,
    Map<String, dynamic>? typingUsers,
    bool? isAutonomousEnabled,
    ContextAnalysis? currentContext,
    UserIntent? lastRecognizedIntent,
    AutonomousAction? lastAutonomousAction,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      currentMessages: currentMessages ?? this.currentMessages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
      suggestions: suggestions ?? this.suggestions,
      activeExecutions: activeExecutions ?? this.activeExecutions,
      typingUsers: typingUsers ?? this.typingUsers,
      isAutonomousEnabled: isAutonomousEnabled ?? this.isAutonomousEnabled,
      currentContext: currentContext ?? this.currentContext,
      lastRecognizedIntent: lastRecognizedIntent ?? this.lastRecognizedIntent,
      lastAutonomousAction: lastAutonomousAction ?? this.lastAutonomousAction,
    );
  }
}

/// Provider for chat functionality
class ChatProvider extends Notifier<ChatState> {
  ToolsProvider get _toolsProvider => ref.watch(toolsProviderProvider.notifier);
  AppLogger get _logger => AppLogger();

  @override
  ChatState build() {
    return const ChatState();
  }

  /// Send a message
  Future<void> sendMessage(String content, {String? conversationId}) async {
    _logger.info('Sending message: $content');

    try {
      state = state.copyWith(isSending: true, error: null);

      // Create message
      final message = ChatMessage.user(
        id: _generateMessageId(),
        content: content,
        userId: 'current_user',
      );

      // Add to current messages
      final updatedMessages = [...state.currentMessages, message];
      state = state.copyWith(currentMessages: updatedMessages);

      // Get AI response from AI provider
      try {
        // Get the properly initialized AI provider config from main.dart
        final aiProviderConfig = ref.read(aiProviderConfigProvider);
        final currentModelId = ref.read(currentSelectedModelProvider);

        _logger.info('Current selected model: $currentModelId');

        // Get the provider for the selected model
        String providerId = _detectProviderFromModel(currentModelId);

        // Get the provider and create a new model with the selected model ID
        final baseProvider = aiProviderConfig.getProvider(providerId);
        lc.BaseChatModel? chatModel;

        if (baseProvider is ChatGoogleGenerativeAI && currentModelId != null) {
          // Create a new Google AI instance with the selected model
          final config = aiProviderConfig.getProviderConfig(providerId);
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
        } else if (baseProvider is ChatOpenAI && currentModelId != null) {
          // Create a new OpenAI instance with the selected model
          final config = aiProviderConfig.getProviderConfig(providerId);
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

        // Fallback to any available model if we couldn't create a specific one
        chatModel ??= aiProviderConfig.getBestAvailableChatModel();

        if (chatModel != null) {
          // Build conversation history for context
          String conversationHistory = '';
          for (int i = 0; i < updatedMessages.length; i++) {
            final msg = updatedMessages[i];
            if (msg.isFromUser) {
              conversationHistory += 'User: ${msg.content}\n';
            } else {
              conversationHistory += 'Assistant: ${msg.content}\n';
            }
          }

          // Generate response using the AI model
          final result = await chatModel.invoke(
              lc.PromptValue.string('$conversationHistory\nAssistant:'));
          final aiResponseContent = result.outputAsString;

          final aiResponse = ChatMessage.assistant(
            id: _generateMessageId(),
            content: aiResponseContent,
          );

          final finalMessages = [...updatedMessages, aiResponse];
          state = state.copyWith(
            currentMessages: finalMessages,
            isSending: false,
          );
        } else {
          // Fallback response if no AI model is available
          final aiResponse = ChatMessage.assistant(
            id: _generateMessageId(),
            content:
                'Sorry, no AI model is currently available. Please configure an AI provider in settings.',
          );

          final finalMessages = [...updatedMessages, aiResponse];
          state = state.copyWith(
            currentMessages: finalMessages,
            isSending: false,
          );
        }
      } catch (aiError) {
        // Fallback response if AI generation fails
        _logger.error('Failed to generate AI response', error: aiError);
        final aiResponse = ChatMessage.assistant(
          id: _generateMessageId(),
          content:
              'Sorry, I encountered an error while generating a response. Please try again later.',
        );

        final finalMessages = [...updatedMessages, aiResponse];
        state = state.copyWith(
          currentMessages: finalMessages,
          isSending: false,
        );
      }

      _logger.info('Message sent successfully');
    } catch (e) {
      _logger.error('Failed to send message', error: e);
      state = state.copyWith(
        isSending: false,
        error: 'Failed to send message: ${e.toString()}',
      );
    }
  }

  /// Create a new conversation
  void createConversation(String title) {
    _logger.info('Creating conversation: $title');

    final conversation = Conversation(
      id: _generateConversationId(),
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final updatedConversations = [...state.conversations, conversation];
    state = state.copyWith(
      conversations: updatedConversations,
      currentConversation: conversation,
      currentMessages: [],
    );
  }

  /// Select conversation
  void selectConversation(String conversationId) {
    _logger.info('Selecting conversation: $conversationId');

    final conversation =
        state.conversations.where((c) => c.id == conversationId).firstOrNull;

    if (conversation != null) {
      state = state.copyWith(
        currentConversation: conversation,
        currentMessages: conversation.messages,
      );
    }
  }

  /// Execute tool
  Future<void> executeTool(
      String toolId, Map<String, dynamic> parameters) async {
    _logger.info('Executing tool: $toolId');

    try {
      // Execute tool through tools provider
      await _toolsProvider.executeTool(
        toolId: toolId,
        parameters: parameters,
      );

      // Get the result from tools provider state
      final toolResult = _toolsProvider.state.executionResults[toolId];
      final executionStatus = _toolsProvider.state.executionStatus[toolId];

      // Create execution result
      final executionResult = ChatToolExecutionResult(
        id: _generateExecutionId(),
        toolId: toolId,
        toolName: 'Tool $toolId',
        status: executionStatus == ToolExecutionStatus.completed
            ? ChatToolExecutionStatus.completed
            : executionStatus == ToolExecutionStatus.failed
                ? ChatToolExecutionStatus.failed
                : ChatToolExecutionStatus.executing,
        timestamp: DateTime.now(),
        parameters: parameters,
        result: toolResult,
      );

      final updatedExecutions = [...state.activeExecutions, executionResult];
      state = state.copyWith(activeExecutions: updatedExecutions);

      _logger.info('Tool executed successfully: $toolId');
    } catch (e) {
      _logger.error('Tool execution failed: $toolId', error: e);

      final executionResult = ChatToolExecutionResult.failed(
        id: _generateExecutionId(),
        toolId: toolId,
        toolName: 'Unknown Tool',
        errorMessage: e.toString(),
        parameters: parameters,
      );

      final updatedExecutions = [...state.activeExecutions, executionResult];
      state = state.copyWith(activeExecutions: updatedExecutions);
    }
  }

  /// Toggle autonomous mode
  void toggleAutonomousMode() {
    _logger.info('Toggling autonomous mode');

    state = state.copyWith(
      isAutonomousEnabled: !state.isAutonomousEnabled,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Generate message ID
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate conversation ID
  String _generateConversationId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate execution ID
  String _generateExecutionId() {
    return 'exec_${DateTime.now().millisecondsSinceEpoch}';
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

/// Provider for chat state
final chatProviderProvider = NotifierProvider<ChatProvider, ChatState>(() {
  return ChatProvider();
});

/// Provider for chat state
final chatStateProvider = Provider<ChatState>((ref) {
  return ref.watch(chatProviderProvider);
});
