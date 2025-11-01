import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen_ai_chat_ui/flutter_gen_ai_chat_ui.dart';
import 'package:flutter/services.dart';

import '../providers/app_providers.dart';
import '../providers/ai_providers.dart';
import '../../widgets/api_configuration_dialog.dart';
import '../widgets/provider_model_selection_dialog.dart';

class EnhancedAIChatPage extends ConsumerStatefulWidget {
  const EnhancedAIChatPage({super.key});

  @override
  ConsumerState<EnhancedAIChatPage> createState() => _EnhancedAIChatPageState();
}

class _EnhancedAIChatPageState extends ConsumerState<EnhancedAIChatPage> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatMessagesController _messagesController = ChatMessagesController();
  String? _currentModelId;
  String _currentModel = 'No model selected';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialModel();
    _loadExistingMessages();
  }

  void _loadInitialModel() async {
    try {
      // Get the current model using the new provider
      final currentModelAsync = ref.read(currentSelectedModelProvider);
      // Wait for the AsyncValue to be ready and extract the value
      final currentModel = currentModelAsync.when(
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
          _currentModel = 'No model selected';
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
          print('DEBUG: Adding message to UI: ${message.type} - ${message.content}');
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
            // Header with model info and settings
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Assistant',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 16,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentModel,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      // Navigate to provider settings
                      Navigator.of(context).pushNamed('/provider-settings');
                    },
                    tooltip: 'AI Provider Settings',
                  ),
                ],
              ),
            ),

            // Main chat interface
            Expanded(
              child: ChatWidget(
                messages: _messagesController,
                inputOptions: ChatInputOptions(
                  controller: _promptController,
                  onSendMessage: _handleSendMessage,
                  sendButtonVisibility: SendButtonVisibility.inside,
                  placeholder: 'Type your message here...',
                ),
                chatOptions: const ChatOptions(
                  showUsername: false,
                  showTimestamp: false,
                  showTypingIndicator: true,
                ),
                onSendMessage: _handleSendMessage,
                user: const ChatUser(
                  id: 'user',
                  name: 'You',
                ),
                aiUser: ChatUser(
                  id: 'ai',
                  name: 'AI Assistant',
                ),
                loadingWidget: chatState.isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('AI is thinking...'),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI immediately
    final userMessage = ChatMessage(
      text: message,
      user: const ChatUser(id: 'user', name: 'You'),
      createdAt: DateTime.now(),
    );
    _messagesController.addMessage(userMessage);

    // Clear input field
    _promptController.clear();

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Send message through chat provider
      await ref.read(chatProvider.notifier).sendMessage(message);

      // The AI response will be handled by the listener below
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });

      // Show error message
      final errorMessage = ChatMessage(
        text: 'Error: ${e.toString()}',
        user: const ChatUser(id: 'ai', name: 'AI Assistant'),
        createdAt: DateTime.now(),
      );
      _messagesController.addMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  ChatMessage _convertToChatMessage(dynamic message) {
    return ChatMessage(
      text: message.content,
      user: message.type == 'user'
          ? const ChatUser(id: 'user', name: 'You')
          : const ChatUser(id: 'ai', name: 'AI Assistant'),
      createdAt: DateTime.now(),
    );
  }

  String _formatModelName(String modelId) {
    // Convert model ID to display name
    if (modelId.contains('gpt-')) {
      return 'OpenAI: ${modelId.split('-').sublist(1).join('-')}';
    } else if (modelId.contains('gemini')) {
      return 'Gemini: ${modelId.split('-').last}';
    } else if (modelId.contains('claude')) {
      return 'Claude: ${modelId.split('-').last}';
    } else if (modelId.contains('glm')) {
      return 'GLM: ${modelId.split('-').last}';
    }
    return modelId;
  }

  String _getProviderDisplayName(String providerId) {
    // Convert provider ID to display name
    if (providerId == 'openai') return 'OpenAI';
    if (providerId == 'google') return 'Google';
    if (providerId == 'anthropic') return 'Anthropic';
    if (providerId == 'zhipuai') return 'ZhipuAI';
    return providerId;
  }

  void _showModelSelectionDialog() async {
    // Show a dialog with available models
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select AI Model'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: ref.watch(favoriteModelsProvider.future),
            builder: (context, AsyncSnapshot<Map<String, List<String>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No favorite models found'));
              }

              final favoriteModels = snapshot.data!;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...models.map((model) {
                              final isSelected = model == _currentModelId;

                              return ListTile(
                                title: Text(
                                  _formatModelName(model),
                                  style: isSelected
                                      ? TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(context).primaryColor,
                                        )
                                      : null,
                                ),
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
                                  Navigator.pop(context);

                                  // Update the active model
                                  try {
                                    final modelService = ref.read(modelSelectionServiceProvider);
                                    await modelService.setActiveModel(
                                        providerId, model);

                                    // Save the last selected model
                                    final prefs =
                                        ref.read(sharedPreferencesProvider);
                                    await prefs.setString(
                                        'last_selected_model', model);

                                    setState(() {
                                      _currentModelId = model;
                                      _currentModel =
                                          _formatModelName(model);
                                    });

                                    // Show success message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Switched to $model'),
                                      ),
                                    );
                                  } catch (e) {
                                    // Show error message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to switch model: $e'),
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}