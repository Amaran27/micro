import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';

/// Enhanced AI Chat Page with Markdown Support
/// 
/// This page provides a modern chat interface with:
/// - Markdown rendering for AI responses
/// - Streaming text support for real-time responses
/// - Customizable themes
/// - Message history
/// - Responsive design
class EnhancedAIChatPage extends ConsumerStatefulWidget {
  const EnhancedAIChatPage({super.key});

  @override
  ConsumerState<EnhancedAIChatPage> createState() => _EnhancedAIChatPageState();
}

class _EnhancedAIChatPageState extends ConsumerState<EnhancedAIChatPage> {
  late final ChatMessagesController _messagesController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messagesController = ChatMessagesController();
    _scrollController = ScrollController();
    
    // Load existing messages from the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingMessages();
    });
  }

  @override
  void dispose() {
    _messagesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadExistingMessages() {
    final chatState = ref.read(chatProvider);
    
    // Convert existing messages to the format expected by flutter_gen_ai_chat_ui
    for (final message in chatState.messages) {
      final chatMessage = _convertToChatMessage(message);
      _messagesController.addMessage(chatMessage);
    }
  }

  /// Convert our app's ChatMessage to the format expected by flutter_gen_ai_chat_ui
  ChatMessage _convertToChatMessage(micro.ChatMessage message) {
    return ChatMessage(
      id: message.id,
      text: message.content,
      user: message.type == MessageType.user
          ? ChatUser(id: 'user', firstName: 'You')
          : ChatUser(id: 'ai', firstName: 'AI'),
      createdAt: message.timestamp,
    );
  }

  /// Convert from flutter_gen_ai_chat_ui's ChatMessage to our app's ChatMessage
  micro.ChatMessage _convertFromChatMessage(ChatMessage message) {
    return micro.ChatMessage(
      id: message.id,
      timestamp: message.createdAt ?? DateTime.now(),
      type: message.user.id == 'user' ? MessageType.user : MessageType.assistant,
      content: message.text,
      status: MessageStatus.sent,
      userId: message.user.id,
    );
  }

  /// Handle sending a message
  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message immediately
    final userMessageId = _messagesController.addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: message,
        user: ChatUser(id: 'user', firstName: 'You'),
        createdAt: DateTime.now(),
      ),
    );

    // Send message through our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.sendMessage(message);

    // The AI response will be handled by the listener below
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Listen for changes in the chat state and update the UI
    ref.listen<ChatState>(chatProvider, (previous, next) {
      // Check if new messages were added
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        // Get the new messages
        final newMessages = next.messages.sublist(
          previous?.messages.length ?? 0,
        );
        
        // Add them to our controller
        for (final message in newMessages) {
          // Skip if this is a user message that was already added
          if (message.type == MessageType.user) continue;
          
          final chatMessage = _convertToChatMessage(message);
          _messagesController.addMessage(chatMessage);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions(context);
            },
          ),
        ],
      ),
      body: AiChatWidget(
        // User and AI configurations
        currentUser: ChatUser(
          id: 'user',
          firstName: 'You',
        ),
        aiUser: ChatUser(
          id: 'ai',
          firstName: 'AI Assistant',
        ),
        
        // Controller for managing messages
        controller: _messagesController,
        
        // Message handling
        onSendMessage: _handleSendMessage,
        
        // Configuration
        enableAnimation: true,
        enableMarkdownStreaming: true,
        streamingWordByWord: false,
        streamingDuration: const Duration(milliseconds: 30),
        
        // Input options
        inputOptions: InputOptions(
          unfocusOnTapOutside: false,
          textInputAction: TextInputAction.newline,
          sendOnEnter: true,
          hintText: 'Ask me anything...',
        ),
        
        // Message styling
        messageOptions: MessageOptions(
          showTime: true,
          showUserName: true,
          bubbleStyle: BubbleStyle(
            userBubbleColor: Colors.blue.withOpacity(0.1),
            aiBubbleColor: Colors.grey[100]!,
            userNameColor: Colors.blue.shade700,
            aiNameColor: Colors.grey.shade700,
            bottomLeftRadius: 22,
            bottomRightRadius: 22,
            topRightRadius: 22,
            topLeftRadius: 22,
            enableShadow: true,
          ),
        ),
        
        // Loading configuration
        loadingConfig: LoadingConfig(
          isLoading: chatState.isLoading,
          showCenteredIndicator: true,
        ),
        
        // Error handling
        errorConfig: ErrorConfig(
          showError: chatState.error != null,
          errorMessage: chatState.error?.toString(),
        ),
        
        // Example questions
        exampleQuestions: [
          ExampleQuestion(question: 'What can you help me with?'),
          ExampleQuestion(question: 'Explain a complex concept in simple terms'),
          ExampleQuestion(question: 'Help me solve a problem'),
          ExampleQuestion(question: 'Write some code for me'),
        ],
        
        // Welcome message
        welcomeMessageConfig: WelcomeMessageConfig(
          title: 'AI Assistant',
          subtitle: 'How can I help you today?',
          avatarUrl: null,
          showWelcomeMessage: true,
        ),
        
        // Scroll behavior
        scrollBehaviorConfig: ScrollBehaviorConfig(
          autoScrollBehavior: AutoScrollBehavior.onNewMessage,
          scrollToFirstResponseMessage: true,
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Clear History'),
                onTap: () {
                  Navigator.pop(context);
                  _clearHistory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearHistory() {
    // Clear messages in the UI controller
    _messagesController.clearMessages();
    
    // Also clear messages in our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    // Note: We need to implement a clearMessages method in ChatNotifier
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat history cleared')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Micro AI Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.chat),
      children: [
        const Text(
          'A privacy-first, autonomous agentic mobile assistant built with Flutter.',
        ),
      ],
    );
  }
}