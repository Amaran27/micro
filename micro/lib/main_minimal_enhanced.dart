import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure/ai/agent/agent_providers.dart';

import '../providers/ai_providers.dart';

/// Minimal enhanced AI chat app
class MinimalEnhancedAIApp extends ConsumerWidget {
  const MinimalEnhancedAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final llmProvider = ref.watch(comprehensiveLLMProvider);
    final TextEditingController messageController = TextEditingController();
    bool isLoading = false;
    String currentTask = 'chat';

    return Scaffold(
      appBar: AppBar(
        title: Text('✨ Enhanced AI Chat - Comprehensive'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Provider status
          Consumer(
            builder: (context, ref, child) {
              final status = llmProvider.getStatusSummary();
              return IconButton(
                icon: Icon(
                  status['isInitialized'] == true 
                      ? Icons.check_circle 
                      : Icons.error_outline,
                  color: status['isInitialized'] == true 
                      ? Colors.green 
                      : Colors.orange,
                ),
                tooltip: '${status['currentProvider']?.toString().toUpperCase() ?? 'NONE'}: ${status['totalModelsAvailable'] ?? 0} models',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Provider Status: ${status['currentProvider']}')),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // AI status section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Consumer(
              builder: (context, ref) {
                final status = llmProvider.getStatusSummary();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🤖 Comprehensive AI System Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Providers: ${status['totalModelsAvailable'] ?? 0} available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Current: ${status['currentProvider']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontStyle: FontStyle.italic,
                      ),
                    ),
                    Text(
                      'Initialization: ${status['isInitialized'] == true ? '✅ Success' : '❌ Failed'}',
                      style: TextStyle(
                        color: status['isInitialized'] == true ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Message input and display
          Expanded(
            child: Consumer(
              builder: (context, ref) {
                // Simple task-based message handling
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Task selector
                      Row(
                        children: [
                          const Icon(Icons.work_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: currentTask,
                            items: const ['chat', 'coding', 'analysis', 'translation', 'creative']
                                .map((task) => DropdownMenuItem<String>(
                                      value: task,
                                      child: Text(task),
                                    ))
                                .toList(),
                            onChanged: (task) {
                              currentTask = task ?? 'chat';
                            },
                          ),
                          const SizedBox(width: 8),
                          Text('Task: $currentTask'),
                        ],
                      ],
                      
                      const SizedBox(height: 8),
                      
                      TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _sendMessage(context, ref, messageController, currentTask),
                        child: Text(isLoading ? 'Processing...' : 'Send'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, WidgetRef ref, TextEditingController controller, String task) async {
    final message = controller.text.trim();
    if (message.isEmpty) return;

    controller.clear();

    // Set loading state
    // In a real app, this would use state management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🤖 Message sent! Processing with ${task.toUpperCase()}...')),
    );

    try {
      final llmProvider = ref.read(comprehensiveLLMProvider);
      
      // Generate task-optimized response
      String response;
      switch (task.toLowerCase()) {
        case 'chat':
          response = await llmProvider.generateCompletion(message);
          break;
        case 'coding':
          response = await llmProvider.generateCompletion(
            message,
            options: {
              'task_type': 'coding',
              'temperature': 0.1,
              'max_tokens': 4000,
              'include_examples': true,
            },
          );
          break;
        case 'analysis':
          response = await llmProvider.generateCompletion(
            message,
            options: {
              'task_type': 'analysis',
              'max_tokens': 10000,
              'temperature': 0.1,
            },
          );
          break;
        case 'translation':
          response = await llmProvider.generateCompletion(
            message,
            options: {
              'task_type': 'translation',
              'source_language': 'auto',
              'target_language': 'en',
            },
          );
          break;
        case 'creative':
          response = await llmProvider.generateCompletion(
            message,
            options: {
              'task_type': 'creative',
              'temperature': 0.8,
              'max_tokens': 2000,
            },
          );
          break;
        default:
          response = await llmProvider.generateCompletion(message);
          break;
      }

      // Show response
      await Future.delayed(const Duration(seconds: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ ${task.toUpperCase()} Response: ${response.substring(0, 50)}...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ ${task.toUpperCase()} Error: $e')),
      );
    }
  }
}

/// Main entry point for the enhanced AI app
void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: MinimalEnhancedAIApp(),
      ),
    ),
  );
}