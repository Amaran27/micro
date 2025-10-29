import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';
import 'package:micro/presentation/providers/app_providers.dart';
import 'package:micro/presentation/providers/ai_providers.dart';
import 'package:micro/infrastructure/ai/model_selection_notifier.dart';

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
  String _currentModel = 'Loading...'; // Default display name
  String? _currentModelId; // Default model ID - nullable now
  // Tracks whether the loading dialog is currently visible so we can dismiss safely.
  bool _loadingDialogVisible = false;

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

  void _showLoadingDialog(BuildContext context) {
    if (_loadingDialogVisible) return;
    _loadingDialogVisible = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Loading models...'),
          ],
        ),
      ),
    );
  }

  void _dismissLoadingDialog(BuildContext context) {
    if (!_loadingDialogVisible) return;
    _loadingDialogVisible = false;
    try {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } catch (_) {}
  }

  void _loadInitialModel() async {
    try {
      // Get the current model using the new provider
      final currentModelAsync = ref.read(currentSelectedModelProvider);
      // Wait for the AsyncValue to be ready and extract the value
      final currentModel = await currentModelAsync.when(
        data: (value) => value,
        loading: () => null,
        error: (_, __) => null,
      );
      
      if (currentModel != null) {
        setState(() {
          _currentModelId = currentModel;
          _currentModel = _formatModelName(currentModel);
        });
      } else {
        // No model selected yet, show a placeholder
        setState(() {
          _currentModelId = null;
          _currentModel = 'Select a model';
        });
      }
    } catch (e) {
      setState(() {
        _currentModelId = null;
        _currentModel = 'Error loading model';
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
    ref.listen<AsyncValue<String?>>(currentSelectedModelProvider, (previous, next) {
      final nextValue = next.when(
        data: (value) => value,
        loading: () => null,
        error: (_, __) => null,
      );
      if (nextValue != null && nextValue != _currentModelId) {
        setState(() {
          _currentModelId = nextValue;
          _currentModel = _formatModelName(nextValue);
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

        print('DEBUG: New messages detected: ${newMessages.length}');
        for (final message in newMessages) {
          print(
              'DEBUG: Adding message to UI: ${message.type} - ${message.content}');
          final chatMessage = _convertToChatMessage(message);
          print('DEBUG: Converted message: ${chatMessage.text}');
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
                        color: _currentModelId != null
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentModelId != null
                                ? Icons.smart_toy
                                : Icons.warning,
                            size: 16,
                            color: _currentModelId != null
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentModel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _currentModelId != null
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: _currentModelId != null
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
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

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Micro AI Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.smart_toy, size: 48),
      children: [
        const Text('An AI-powered assistant that helps you with various tasks using multiple AI models.'),
      ],
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

  /// Get provider display name
  String _getProviderDisplayName(String providerId) {
    switch (providerId.toLowerCase()) {
      case 'google':
        return 'Google AI';
      case 'openai':
        return 'OpenAI';
      case 'zhipuai':
      case 'z_ai':
        return 'ZhipuAI GLM';
      case 'claude':
        return 'Anthropic Claude';
      case 'azure':
        return 'Azure OpenAI';
      case 'cohere':
        return 'Cohere';
      case 'mistral':
        return 'Mistral AI';
      default:
        return providerId.toUpperCase();
    }
  }

  void _showModelSelection(BuildContext context) {
    final favoriteModelsAsync = ref.read(favoriteModelsProvider);

    // If the provider is currently loading, show a loading dialog and await
    // the provider's future. Once it resolves, dismiss the dialog and
    // present the sheet or the 'go to settings' message.
    if (favoriteModelsAsync.isLoading) {
      _showLoadingDialog(context);

      // Await the provider's future and then act accordingly
      ref.read(favoriteModelsProvider.future).then((favoriteModels) {
        // Dismiss loading dialog
        _dismissLoadingDialog(context);

        if (favoriteModels.isEmpty ||
            favoriteModels.values.every((models) => models.isEmpty)) {
          // No favorite models available, show a message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Favorite Models'),
              content: const Text(
                'You haven\'t selected any favorite models yet. Please go to Settings to configure AI providers and select your favorite models.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to settings
                    GoRouter.of(context).go('/settings');
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );
          return;
        }

        _presentFavoriteModelsSheet(context, favoriteModels);
      }).catchError((e) {
        _dismissLoadingDialog(context);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load models: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });

      return;
    }

    favoriteModelsAsync.when(
      data: (favoriteModels) {
        if (favoriteModels.isEmpty ||
            favoriteModels.values.every((models) => models.isEmpty)) {
          // No favorite models available, show a message
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Favorite Models'),
              content: const Text(
                'You haven\'t selected any favorite models yet. Please go to Settings to configure AI providers and select your favorite models.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Navigate to settings
                    GoRouter.of(context).go('/settings');
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );
          return;
        }

        _presentFavoriteModelsSheet(context, favoriteModels);
      },
      loading: () {
        // Show loading indicator using the dialog helpers above.
        _showLoadingDialog(context);
      },
      error: (error, stackTrace) {
        // Show error message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load models: $error'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _presentFavoriteModelsSheet(BuildContext context, Map<String, List<String>> favoriteModels) {
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
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: favoriteModels.length,
                    itemBuilder: (context, index) {
                      final providerId = favoriteModels.keys.elementAt(index);
                      final models = favoriteModels[providerId] ?? [];

                      if (models.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              _getProviderDisplayName(providerId),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                            ),
                          ),
                          ...models.map((model) {
                            final isSelected = model == _currentModelId;
                            return ListTile(
                              title: Text(model,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                              subtitle: Text(_getProviderDisplayName(providerId)),
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                              trailing: isSelected ? const Icon(Icons.check) : null,
                              onTap: () async {
                                Navigator.pop(context);

                                // Update the active model in ModelSelectionService
                                try {
                                  final modelService =
                                      ref.read(modelSelectionServiceProvider);
                                  await modelService.setActiveModel(
                                      providerId, model);

                                  // Save the last selected model
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);
                                  await prefs.setString(
                                      'last_selected_model', model);

                                  setState(() {
                                    _currentModelId = model;
                                    _currentModel = _formatModelName(model);
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Switched to $model')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to switch model: $e'),
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
}
