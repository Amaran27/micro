import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:micro/domain/models/chat/chat_message.dart' as micro;
import 'package:micro/features/chat/presentation/providers/chat_provider.dart';
import 'package:micro/presentation/providers/app_providers.dart';
import 'package:micro/infrastructure/ai/provider_registry.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';
// Removed: agent_execution_ui_provider (agent panel deprecated)
import 'package:micro/features/settings/presentation/providers/swarm_settings_providers.dart';
import 'package:micro/infrastructure/ai/model_selection_service.dart';

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

  // Agent and Swarm modes for different task complexities
  bool _agentMode = false;
  bool _swarmMode = false;

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
      // Load the actual selected model from storage
      final prefs = ref.read(sharedPreferencesProvider);
      final modelId = prefs.getString('last_selected_model');

      print('DEBUG: _loadInitialModel - last_selected_model: $modelId');

      if (modelId != null && modelId.isNotEmpty) {
        setState(() {
          _currentModelId = modelId;
          _currentModel = _formatModelName(modelId);
        });
        print('DEBUG: UI loaded model: $_currentModel');
      } else {
        // No model selected yet, show placeholder
        setState(() {
          _currentModelId = null;
          _currentModel = 'Select a model';
        });
        print('DEBUG: No model selected');
      }
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
    // Attach quick replies and system flag if present in metadata
    final quickReplies = message.metadata?['quickReplies'] as List<String>?;
    final isSystem = message.type == micro.MessageType.system ||
        message.metadata?['system'] == true;
    return ChatMessage(
      text: message.content,
      user: message.type == micro.MessageType.user
          ? ChatUser(id: 'user', firstName: 'You')
          : ChatUser(id: 'ai', firstName: 'AI'),
      createdAt: message.timestamp,
      isMarkdown: true, // Use built-in markdown support
      customProperties: {
        if (message.type == micro.MessageType.assistant) 'isStreaming': true,
      },
    );
  }

  /// Handle sending a message
  Future<void> _handleSendMessage(ChatMessage message) async {
    if (message.text.trim().isEmpty) return;

    // Prevent double-send while a response is in progress (fixes duplicate streaming)
    final chatState = ref.read(chatProvider);
    if (chatState.isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for the current response to finish.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Add user message to our provider
    final chatNotifier = ref.read(chatProvider.notifier);
    await chatNotifier.sendMessage(
      message.text,
      agentMode: false,
      swarmMode: _swarmMode,
    );

    // The AI response will be handled by the listener below
  }

  // Agent command helpers removed with agent UI simplification

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // Listen for changes in the chat state and update the UI
    ref.listen<ChatState>(chatProvider, (previous, next) {
      final prev = previous?.messages ?? const <micro.ChatMessage>[];
      final curr = next.messages;

      // Build quick lookup of previous IDs
      final prevIds = {for (final m in prev) m.id};
      final currIds = {for (final m in curr) m.id};

      // Any messages present now that were not present before are "new"
      final addedIds = currIds.difference(prevIds);

      if (addedIds.isNotEmpty) {
        final newMessages = curr.where((m) => addedIds.contains(m.id)).toList();
        print('DEBUG: New messages detected by ID diff: ${newMessages.length}');
        for (final message in newMessages) {
          print(
              'DEBUG: Adding message to UI: ${message.type} - ${message.content}');
          final chatMessage = _convertToChatMessage(message);
          _messagesController.addMessage(chatMessage);
        }
      }

      // Content updates are no longer handled here - flutter_gen_ai_chat_ui handles streaming internally
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom header with model selection (responsive, no overflow)
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AI Assistant',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showOptions(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
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

                      // Agent toggle removed (Swarm-first UX)

                      // Swarm mode toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _swarmMode
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Swarm',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _swarmMode
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Switch(
                              value: _swarmMode,
                              onChanged: (value) {
                                setState(() {
                                  _swarmMode = value;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Agent mode indicator removed (Swarm-first UX)

            // Swarm mode indicator
            if (_swarmMode)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Swarm Intelligence Mode Active',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Consumer(
                      builder: (context, ref, _) {
                        final asyncMax = ref.watch(maxSpecialistsProvider);
                        final label = asyncMax.when(
                          data: (v) => 'Max $v specialists',
                          loading: () => 'Configuring…',
                          error: (_, __) => 'Swarm ready',
                        );
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer
                                .withOpacity(0.8),
                          ),
                        );
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
                // Enable quicker perceived streaming animation after reply arrives
                streamingWordByWord: true,
                streamingDuration: const Duration(milliseconds: 12),

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

                // Example questions with custom styling
                exampleQuestions: _buildExampleQuestions(context),

                // Welcome message (no duplicate header title)
                welcomeMessageConfig: const WelcomeMessageConfig(
                  title: null,
                  questionsSectionTitle: 'Try one of these:',
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
                leading: const Icon(Icons.groups),
                title: const Text('Swarm Settings'),
                subtitle: const Text('Configure swarm intelligence'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings/swarm');
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

  /// Build example questions with custom styling
  List<ExampleQuestion> _buildExampleQuestions(BuildContext context) {
    // Lighter outlined pill style (no dark/black fill)
    final questionConfig = ExampleQuestionConfig(
      containerDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      containerPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      iconColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    final questions = <ExampleQuestion>[];

    questions.addAll([
      ExampleQuestion(
          question: 'What can you help me with?', config: questionConfig),
      ExampleQuestion(
          question: 'Explain a complex concept in simple terms',
          config: questionConfig),
      ExampleQuestion(
          question: 'Help me solve a problem', config: questionConfig),
    ]);

    questions.addAll([
      ExampleQuestion(
          question: 'Write some code for me', config: questionConfig),
      ExampleQuestion(
          question: 'Summarize this document', config: questionConfig),
      ExampleQuestion(question: 'Generate test cases', config: questionConfig),
    ]);

    return questions;
  }

  /// Build agent panel content
  // Removed: _buildAgentPanelContent() - No longer needed per Micro 2.0 spec
  // Agent mode is now just a toggle that enables tool use, no separate panel

  // Removed: _buildAgentCreationTab() - No longer needed per Micro 2.0 spec
  // Agent configuration is handled through agent mode toggle + Tools page

  // Removed unused agent panel helpers to reduce clutter and avoid lints

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

                                // Save model selection to both SharedPreferences AND ModelSelectionService
                                try {
                                  print(
                                      'DEBUG: Selecting model: $model for provider: $providerId');

                                  // Save to SharedPreferences (for immediate UI updates)
                                  final prefs =
                                      ref.read(sharedPreferencesProvider);
                                  await prefs.setString(
                                      'last_selected_model', model);
                                  print(
                                      'DEBUG: Saved to SharedPreferences: last_selected_model=$model');

                                  // Save to ModelSelectionService (for persistence across sessions)
                                  final modelService =
                                      ModelSelectionService.instance;
                                  await modelService.setActiveModel(
                                      providerId, model);
                                  print(
                                      'DEBUG: Saved to ModelSelectionService: $providerId -> $model');

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
                                  print('DEBUG: Error selecting model: $e');
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

  // Removed unused step/tool helper methods (execution panel deprecated).
}
