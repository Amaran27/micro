import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';
import 'package:micro/presentation/providers/ai_providers.dart';

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
  String _currentModel = 'GPT-4'; // Default display name
  String _currentModelId = 'gpt-4'; // Default model ID

  @override
  void initState() {
    super.initState();
    _messagesController = ChatMessagesController();
    _scrollController = ScrollController();

    // Load initial model selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialModel();
      _loadExistingMessages();
    });
  }

  void _loadInitialModel() {
    final currentModel = ref.read(currentSelectedModelProvider);
    if (currentModel != null) {
      setState(() {
        _currentModelId = currentModel;
        _currentModel = _formatModelName(currentModel);
      });
    }
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
      text: message.content,
      user: message.type == micro.MessageType.user
          ? ChatUser(id: 'user', firstName: 'You')
          : ChatUser(id: 'ai', firstName: 'AI'),
      createdAt: message.timestamp,
    );
  }

  /// Handle sending a message
  Future<void> _handleSendMessage(ChatMessage message) async {
    if (message.text.trim().isEmpty) return;

    // Add user message to our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.sendMessage(message.text);

    // The AI response will be handled by the listener below
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Update current model when provider changes
    ref.listen<String?>(currentSelectedModelProvider, (previous, next) {
      if (next != null && next != _currentModelId) {
        setState(() {
          _currentModelId = next;
          _currentModel = _formatModelName(next);
        });
      }
    });

    // Listen for changes in the chat state and update the UI
    ref.listen<ChatState>(chatProvider, (previous, next) {
      // Check if new messages were added
      if (next.messages.length > (previous?.messages.length ?? 0)) {
        // Get new messages
        final newMessages = next.messages.sublist(
          previous?.messages.length ?? 0,
        );

        // Add them to our controller
        for (final message in newMessages) {
          final chatMessage = _convertToChatMessage(message);
          _messagesController.addMessage(chatMessage);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header with model selection
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Model selection dropdown
                  GestureDetector(
                    onTap: () => _showModelSelection(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentModel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      _showOptions(context);
                    },
                  ),
                ],
              ),
            ),

            // Chat widget
            Expanded(
              child: AiChatWidget(
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
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                // Message styling
                messageOptions: MessageOptions(
                  showTime: true,
                  showUserName: true,
                  bubbleStyle: BubbleStyle(
                    userBubbleColor: Colors.blue.withValues(alpha: 0.1),
                    aiBubbleColor: Colors.grey[100]!,
                    userNameColor: Colors.blue.shade700,
                    aiNameColor: Colors.grey.shade700,
                    bottomLeftRadius: 22,
                    bottomRightRadius: 22,
                    enableShadow: true,
                  ),
                ),

                // Loading configuration
                loadingConfig: LoadingConfig(
                  isLoading: chatState.isLoading,
                  showCenteredIndicator: true,
                ),

                // Example questions
                exampleQuestions: [
                  ExampleQuestion(question: 'What can you help me with?'),
                  ExampleQuestion(
                      question: 'Explain a complex concept in simple terms'),
                  ExampleQuestion(question: 'Help me solve a problem'),
                  ExampleQuestion(question: 'Write some code for me'),
                ],

                // Welcome message
                welcomeMessageConfig: WelcomeMessageConfig(
                  title: 'AI Assistant',
                ),

                // Scroll behavior
                scrollBehaviorConfig: ScrollBehaviorConfig(
                  autoScrollBehavior: AutoScrollBehavior.onNewMessage,
                  scrollToFirstResponseMessage: true,
                ),
              ),
            ),
          ],
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
                leading: const Icon(Icons.model_training),
                title: const Text('Change Model'),
                onTap: () {
                  Navigator.pop(context);
                  _showModelSelection(context);
                },
              ),
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
    // Clear messages in UI controller
    _messagesController.clearMessages();

    // Also clear messages in our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    chatNotifier.clearMessages();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat history cleared')),
    );
  }

  /// Format model ID to display name
  String _formatModelName(String modelId) {
    switch (modelId.toLowerCase()) {
      case 'gpt-4':
      case 'gpt-4o':
      case 'gpt-4o-mini':
        return 'GPT-4';
      case 'gpt-3.5-turbo':
        return 'GPT-3.5 Turbo';
      case 'claude-3-5-sonnet-20241022':
      case 'claude-3-sonnet-20240229':
        return 'Claude';
      case 'gemini-1.5-flash':
      case 'gemini-1.5-pro':
        return 'Gemini';
      default:
        // Extract first part before any hyphens or dots for display
        final parts = modelId.split(RegExp(r'[-\.]'));
        if (parts.isNotEmpty) {
          return parts[0].toUpperCase();
        }
        return modelId.toUpperCase();
    }
  }

  void _showModelSelection(BuildContext context) {
    final favoriteModels = ref.watch(favoriteModelsProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select AI Model',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: favoriteModels.isEmpty
                      ? const Center(
                          child: Text('No favorite models available'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: favoriteModels.length,
                          itemBuilder: (context, index) {
                            final providerId =
                                favoriteModels.keys.elementAt(index);
                            final models = favoriteModels[providerId] ?? [];

                            if (models.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    providerId.toUpperCase(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                ...models.map((model) {
                                  final isSelected = model == _currentModelId;
                                  return ListTile(
                                    title: Text(_formatModelName(model)),
                                    subtitle: Text(model),
                                    leading: Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : null,
                                    ),
                                    trailing: isSelected
                                        ? const Icon(Icons.check)
                                        : null,
                                    onTap: () async {
                                      Navigator.pop(context);

                                      // Update the active model in ModelSelectionService
                                      try {
                                        final modelService = ref.read(
                                            modelSelectionServiceProvider);
                                        await modelService.setActiveModel(
                                            providerId, model);

                                        setState(() {
                                          _currentModelId = model;
                                          _currentModel =
                                              _formatModelName(model);
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Model switched to ${_formatModelName(model)}')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to switch model: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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
