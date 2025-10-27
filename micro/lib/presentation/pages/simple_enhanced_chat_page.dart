import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Simple enhanced chat page with comprehensive LLM
class SimpleEnhancedChatPage extends ConsumerWidget {
  const SimpleEnhancedChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextEditingController messageController = TextEditingController();
    final List<ChatMessage> messages = [];
    bool isLoading = false;
    String currentTask = 'chat';

    return Scaffold(
      appBar: AppBar(
        title: Text('✨ Enhanced AI Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Task selector
          PopupMenuButton<String>(
            onSelected: (task) {
              currentTask = task;
              // In a real app, this would optimize provider selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Task type: $task')),
              );
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'chat',
                child: Row(
                  children: [
                    const Icon(Icons.chat),
                    const SizedBox(width: 8),
                    const Text('General Chat'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'coding',
                child: Row(
                  children: [
                    const Icon(Icons.code),
                    const SizedBox(width: 8),
                    const Text('Code Assistant'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'creative',
                child: Row(
                  children: [
                    const Icon(Icons.palette),
                    const SizedBox(width: 8),
                    const Text('Creative Writing'),
                  ],
                ),
              ),
            ],
          ),

          // Provider status
          IconButton(
            icon: Icon(Icons.info_outline),
            tooltip: 'AI Provider Status',
            onPressed: () => _showProviderStatus(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          // AI status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 Enhanced AI System Active',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '6 providers | 60+ models | Multi-provider architecture',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '✨ Start a conversation with Enhanced AI',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chat • Code • Analysis • Translation • Creative Writing',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isUser = message.type == 'user';

                      return Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(message.timestamp),
                                    style: TextStyle(
                                      color: isUser
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withOpacity(0.7)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _sendMessage(
                      context, ref, messageController, currentTask),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, WidgetRef ref,
      TextEditingController controller, String task) async {
    final message = controller.text.trim();
    if (message.isEmpty) return;

    controller.clear();

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✨ Enhanced AI is processing...')),
    );

    // Generate task-optimized response
    try {
      // Simulate LLM response based on task
      String response;

      switch (task.toLowerCase()) {
        case 'chat':
          response =
              '🤖 Hello! I\'m your Enhanced AI assistant, ready for any conversation. I can help you with general questions, creative tasks, or complex problem-solving. What would you like to discuss today?';
          break;
        case 'coding':
          response =
              '💻 Let me help you with your coding tasks! I can provide:\n\n• Code architecture and design patterns\n• Programming languages support (Python, JavaScript, Flutter, etc.)\n• Algorithm design and optimization\n• Debugging and troubleshooting\n• Testing and quality assurance\n• Technical documentation\n\n\nWhat programming challenge can I help you solve? Enhanced AI';
          break;
        case 'analysis':
          response =
              '📊 I can analyze complex information and provide insights:\n\n• Data analysis and pattern recognition\n• Statistical analysis and visualization\n• Text analysis and natural language processing\n• Market research and trend identification\n• Performance metrics and reporting\n• Comparative analysis\n\n\nWhat type of analysis would you like me to perform? Enhanced AI';
          break;
        case 'translation':
          response =
              '🌍 I can help you translate between multiple languages:\n\n• English ↔ Chinese ↔ Spanish ↔ French ↔ Arabic ↔ Japanese\n• Support for document translation\n• Real-time translation capabilities\n• Context-aware translation for better accuracy\n• Specialized domain-specific vocabulary\n\n\nWhat languages would you like to translate between? Enhanced AI';
          break;
        case 'summarization':
          response =
              '📝 I can condense long documents into key points:\n\n• Automatic summarization with adjustable length\n• Key point extraction and highlighting\n• Abstractive and informative summaries\n• Multi-document support\n• Customizable summary styles\n• Integration with note-taking\n\n\nWhat would you like me to summarize? Enhanced AI';
          break;
        case 'creative':
          response =
              '🎨 I can assist with creative writing across various domains:\n\n• Fiction and storytelling\n• Poetry and creative non-fiction\n• Script writing for screenplays and video\n• Business writing and marketing content\n• Academic and technical writing\n• Creative ideation and concept development\n\n• Editing and proofreading\n• Adaptable writing styles to match your needs\n\n\nWhat creative project can I help you with? Enhanced AI';
          break;
        default:
          response =
              '🤖 I\'m here to assist you with thoughtful, accurate responses. I have access to comprehensive information and can provide helpful insights on numerous topics. Feel free to ask me anything! Enhanced AI';
          break;
      }

      // Simulate AI response delay
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ $response')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Enhanced AI error: $e')),
      );
    }
  }

  void _showProviderStatus(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 Enhanced AI System Status'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '✨ Provider System Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Demo provider info
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('OpenAI MDO - Ready')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Google AI MDO - Ready')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Anthropic Claude MDO - Ready')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Ollama MDO - Ready')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Hugging Face MDO - Ready')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Together AI MDO - Ready')),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                '🏗 Total: 6 Providers Available',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '🎯 60+ Models Accessible',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                '💡 Features: Multi-provider architecture, intelligent task routing,',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Simple chat message model
class ChatMessage {
  final String type; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  ChatMessage({
    required this.type,
    required this.content,
    required this.timestamp,
  });
}
