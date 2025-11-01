import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure/ai/agent/agent_providers.dart';

/// Simple test app to verify the agent system works
class TestApp extends ConsumerStatefulWidget {
  const TestApp({super.key});

  @override
  ConsumerState<TestApp> createState() => _TestAppState();
}

class _TestAppState extends ConsumerState<TestApp> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro Agent System Test'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final agentService = ref.watch(agentServiceProvider);
                return agentService.when(
                  data: (service) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agent System Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text('✅ Agent service initialized'),
                          const Text('✅ Ready to execute tasks'),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Initializing agent system...'),
                        ],
                      ),
                    ),
                  ),
                  error: (error, stack) => Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Agent System Error',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Error: $error'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter a task for the agent',
                border: OutlineInputBorder(),
                hintText: 'e.g., "Analyze system performance"',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _executeTask(context),
                child: const Text('Execute Task'),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent Features',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Autonomous task execution'),
                    Text('• Multi-step reasoning'),
                    Text('• Memory management'),
                    Text('• Tool integration'),
                    Text('• Error recovery'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeTask(BuildContext context) {
    final task = _controller.text.trim();
    if (task.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task')),
      );
      return;
    }

    _controller.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executing task: $task')),
    );
  }
}

void main() {
  runApp(
    const ProviderScope(
      child: MaterialApp(
        home: TestApp(),
      ),
    ),
  );
}
