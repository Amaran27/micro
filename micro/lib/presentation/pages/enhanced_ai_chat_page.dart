import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';
import 'package:micro/presentation/providers/app_providers.dart';
import 'package:micro/infrastructure/ai/provider_registry.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';

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
  // Tracks whether\u00a0loading dialog is currently visible so we can dismiss safely.
  bool _loadingDialogVisible = false;

  // Agent mode state
  bool _agentMode = false;
  bool _showAgentPanel = false;
  final bool _autoDetectAgentCommands = true;

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
      // Get the current model from chat provider state
      final chatState = ref.read(chatProvider);
      // The chat provider handles model selection internally
      // Just initialize the UI placeholder for now
      setState(() {
        _currentModelId = null;
        _currentModel = 'Select a model';
      });
    } catch (e) {
      print('DEBUG: UI error loading model: $e');
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

    // Auto-detect agent commands
    if (_autoDetectAgentCommands && _isAgentCommand(message.text)) {
      // Enable agent mode if not already enabled
      if (!_agentMode) {
        setState(() {
          _agentMode = true;
          _showAgentPanel = true;
        });
      }

      // Handle agent command (will be expanded later)
      await _handleAgentCommand(message.text);
      return;
    }

    // Add user message to our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.sendMessage(message.text);

    // The AI response will be handled by the listener below
  }

  /// Check if message is an agent command
  bool _isAgentCommand(String text) {
    return text.trim().startsWith('/agent') ||
        text.trim().startsWith('/create') ||
        text.trim().startsWith('/execute') ||
        text.trim().startsWith('/status');
  }

  /// Handle agent command
  Future<void> _handleAgentCommand(String command) async {
    final commandText = command.trim();

    // Add command as user message
    final chatMessage = ChatMessage(
      text: commandText,
      user: const ChatUser(id: 'user', firstName: 'You'),
      createdAt: DateTime.now(),
    );
    _messagesController.addMessage(chatMessage);

    // Show response message
    final responseMessage = ChatMessage(
      text: _getAgentCommandResponse(commandText),
      user: const ChatUser(id: 'ai', firstName: 'AI Agent'),
      createdAt: DateTime.now(),
    );
    _messagesController.addMessage(responseMessage);
  }

  /// Get response for agent command
  String _getAgentCommandResponse(String command) {
    if (command.startsWith('/agent create')) {
      return 'Agent creation is not yet implemented. Use the agent panel to create agents.';
    } else if (command.startsWith('/agent list')) {
      return 'No agents created yet. Use the agent panel to create your first agent.';
    } else if (command.startsWith('/agent execute')) {
      return 'Agent execution is not yet implemented. Create an agent first.';
    } else if (command.startsWith('/agent status')) {
      return 'Agent status monitoring is not yet implemented.';
    } else {
      return 'Unknown agent command. Available commands: /agent create, /agent list, /agent execute, /agent status';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

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
                            : Theme.of(context).colorScheme.errorContainer,
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
                  // Agent mode toggle
                  Container(
                    decoration: BoxDecoration(
                      color: _agentMode
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Agent',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _agentMode
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Switch(
                          value: _agentMode,
                          onChanged: (value) {
                            setState(() {
                              _agentMode = value;
                              _showAgentPanel = value;
                            });
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
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

            // Collapsible Agent Panel (only shown when agent mode is active)
            if (_agentMode && _showAgentPanel)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Panel header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_toy,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Agent Panel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              _showAgentPanel
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _showAgentPanel = !_showAgentPanel;
                              });
                            },
                            style: IconButton.styleFrom(
                              minimumSize: const Size(24, 24),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Panel content
                    Expanded(
                      child: _buildAgentPanelContent(),
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
                    hintText: _agentMode
                        ? 'Type message or /agent command...'
                        : 'Type your message...',
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
                  if (!_agentMode) ...[
                    ExampleQuestion(question: 'What can you help me with?'),
                    ExampleQuestion(
                        question: 'Explain a complex concept in simple terms'),
                    ExampleQuestion(question: 'Help me solve a problem'),
                  ],
                  if (_agentMode) ...[
                    ExampleQuestion(
                        question: '/agent create research_assistant'),
                    ExampleQuestion(question: '/agent status'),
                    ExampleQuestion(question: 'Execute analysis on my data'),
                  ],
                  ExampleQuestion(question: 'Write some code for me'),
                ],

                // Welcome message
                welcomeMessageConfig: WelcomeMessageConfig(
                  title: _agentMode ? 'AI Agent Mode' : 'AI Assistant',
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
        const Text(
            'An AI-powered assistant that helps you with various tasks using multiple AI models.'),
      ],
    );
  }

  /// Build agent panel content
  Widget _buildAgentPanelContent() {
    return Consumer(
      builder: (context, ref, child) {
        return TabBarView(
          children: [
            // Agent creation and management
            _buildAgentCreationTab(ref),
            // Agent execution
            _buildAgentExecutionTab(ref),
            // Agent memory
            _buildAgentMemoryTab(ref),
          ],
        );
      },
    );
  }

  /// Build agent creation and management tab
  Widget _buildAgentCreationTab(WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Create Agent',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure an autonomous agent to help you with tasks',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAgentCreationDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Create New Agent'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Quick Agent Commands',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCommandChip('/agent create'),
            _buildCommandChip('/agent list'),
            _buildCommandChip('/agent execute'),
            _buildCommandChip('/agent status'),
          ],
        ),
      ],
    );
  }

  /// Build agent execution tab
  Widget _buildAgentExecutionTab(WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Agent Execution'),
          Text(
            'Monitor and control running agents',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build agent memory tab
  Widget _buildAgentMemoryTab(WidgetRef ref) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Agent Memory'),
          Text(
            'View and manage agent memories',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// Build command chip
  Widget _buildCommandChip(String command) {
    return ActionChip(
      avatar: const Icon(Icons.code, size: 16),
      label: Text(command),
      onPressed: () {
        // Insert command into input field
        // This will be implemented when we integrate with the chat input
      },
    );
  }

  /// Show agent creation dialog
  void _showAgentCreationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Agent'),
        content: const Text('Agent creation dialog will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Create'),
          ),
        ],
      ),
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
      case 'zhipu-ai':
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
    // Watch the new reactive provider for favorite models by provider
    final enabledConfigsAsync = ref.read(enabledProviderConfigsProvider);

    // If the provider is currently loading, show a loading dialog
    if (enabledConfigsAsync.isLoading) {
      _showLoadingDialog(context);

      ref.read(enabledProviderConfigsProvider.future).then((configs) {
        _dismissLoadingDialog(context);

        // Get models from provider configs (use favorites or defaults from registry)
        final registry = ProviderRegistry();
        final allModels = <String, List<String>>{};
        for (final config in configs) {
          final metadata = registry.getProvider(config.providerId);
          final favorites = config.favoriteModels;
          final customModels = config.customModels;
          // Show selected favorites when present, otherwise use defaults + custom
          final models = favorites.isNotEmpty
              ? favorites
              : (List<String>.from(metadata?.defaultModels ?? [])
                ..addAll(customModels));

          if (models.isNotEmpty) {
            allModels[config.providerId] = models;
          }
        }

        if (allModels.isEmpty ||
            allModels.values.every((models) => models.isEmpty)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Models Available'),
              content: const Text(
                'No AI models are available. Please go to Settings to configure AI providers.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).go('/settings');
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );
          return;
        }

        _presentFavoriteModelsSheet(context, allModels);
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

    enabledConfigsAsync.when(
      data: (configs) {
        // Get models from provider configs (use favorites or defaults from registry)
        final registry = ProviderRegistry();
        final allModels = <String, List<String>>{};
        for (final config in configs) {
          final metadata = registry.getProvider(config.providerId);
          final favorites = config.favoriteModels;
          final customModels = config.customModels;
          // Show selected favorites when present, otherwise use defaults + custom
          final models = favorites.isNotEmpty
              ? favorites
              : (List<String>.from(metadata?.defaultModels ?? [])
                ..addAll(customModels));

          if (models.isNotEmpty) {
            allModels[config.providerId] = models;
          }
        }

        if (allModels.isEmpty ||
            allModels.values.every((models) => models.isEmpty)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Models Available'),
              content: const Text(
                'No AI models are available. Please go to Settings to configure AI providers.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    GoRouter.of(context).go('/settings');
                  },
                  child: const Text('Go to Settings'),
                ),
              ],
            ),
          );
          return;
        }

        _presentFavoriteModelsSheet(context, allModels);
      },
      loading: () {
        _showLoadingDialog(context);
      },
      error: (error, stackTrace) {
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

  void _presentFavoriteModelsSheet(
      BuildContext parentContext, Map<String, List<String>> favoriteModels) {
    showModalBottomSheet<void>(
      context: parentContext,
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
                              subtitle:
                                  Text(_getProviderDisplayName(providerId)),
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                              trailing:
                                  isSelected ? const Icon(Icons.check) : null,
                              onTap: () async {
                                // Close the sheet using its own context
                                Navigator.pop(context);

                                // The chat provider handles model selection internally
                                try {
                                  // Save the last selected model in preferences
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);
                                  await prefs.setString(
                                      'last_selected_model', model);

                                  setState(() {
                                    _currentModelId = model;
                                    _currentModel = _formatModelName(model);
                                  });

                                  if (mounted) {
                                    ScaffoldMessenger.of(parentContext)
                                        .showSnackBar(
                                      SnackBar(
                                          content: Text('Switched to $model')),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(parentContext)
                                        .showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to switch model: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
