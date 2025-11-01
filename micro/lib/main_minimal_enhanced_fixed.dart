import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure/ai/agent/agent_providers.dart';

/// Minimal enhanced AI chat app
class MinimalEnhancedAIApp extends ConsumerStatefulWidget {
  const MinimalEnhancedAIApp({super.key});

  @override
  ConsumerState<MinimalEnhancedAIApp> createState() =>
      _MinimalEnhancedAIAppState();
}

class _MinimalEnhancedAIAppState extends ConsumerState<MinimalEnhancedAIApp> {
  final TextEditingController messageController = TextEditingController();
  bool isLoading = false;
  String currentTask = 'chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✨ Enhanced AI Chat - Comprehensive'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          // Agent status
          Consumer(
            builder: (context, ref, child) {
              return IconButton(
                icon: Icon(
                  Icons.smart_toy,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                tooltip: 'Agent Status',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Agent system is ready')),
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
              builder: (context, ref, child) {
                final agentService = ref.watch(agentServiceProvider);
                return agentService.when(
                  data: (service) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 Enhanced Agent System',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Status: Agent system initialized',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                      ),
                      const Text(
                        'Ready for tasks',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),

          // Message input and display
          Expanded(
            child: Container(
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
                        items: const [
                          'chat',
                          'coding',
                          'analysis',
                          'translation',
                          'creative'
                        ]
                            .map((task) => DropdownMenuItem<String>(
                                  value: task,
                                  child: Text(task),
                                ))
                            .toList(),
                        onChanged: (task) {
                          setState(() {
                            currentTask = task ?? 'chat';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text('Task: $currentTask'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextField(
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
                    ),
                    maxLines: 5,
                    minLines: 1,
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () => _sendMessage(context, ref, currentTask),
                    child: Text(isLoading ? 'Processing...' : 'Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, WidgetRef ref, String task) async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    messageController.clear();

    // Show processing message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '🤖 Message sent! Processing with ${task.toUpperCase()}...')),
    );

    try {
      final agentService = ref.read(agentServiceProvider);

      // Execute task with agent
      final result = await agentService.value?.executeGoal(
        goal: message,
        context: 'Task type: $task',
        parameters: {
          'task_type': task,
          'temperature': task == 'creative' ? 0.8 : 0.3,
        },
      );

      // Show response
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (result != null && result.success)
                  ? '✅ ${task.toUpperCase()} completed successfully'
                  : '❌ Task failed: ${result?.error ?? 'Unknown error'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ ${task.toUpperCase()} Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
