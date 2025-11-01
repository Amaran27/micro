import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure/ai/agent/agent_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Agent System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AgentTestPage(),
    );
  }
}

class AgentTestPage extends ConsumerWidget {
  const AgentTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentManagement = ref.watch(agentManagementProvider);
    final agentExecution = ref.watch(agentExecutionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent System Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            agentManagement.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
              data: (state) {
                final status = state['status'] as String? ?? 'unknown';
                final agentCount = (state['agents'] as List?)?.length ?? 0;

                return Column(
                  children: [
                    Text('Status: $status'),
                    Text('Agents: $agentCount'),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(agentManagementProvider.notifier)
                            .initialize();
                      },
                      child: const Text('Initialize Agents'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            agentExecution.when(
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Execution Error: $error'),
              data: (result) {
                if (result == null) {
                  return ElevatedButton(
                    onPressed: () async {
                      await ref
                          .read(agentExecutionProvider.notifier)
                          .executeGoal(
                        goal: 'Hello, test the agent system',
                        context: {'test': true},
                      );
                    },
                    child: const Text('Test Agent Execution'),
                  );
                }

                return Column(
                  children: [
                    Text('Result: ${result.result}'),
                    Text('Success: ${result.success}'),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(agentExecutionProvider.notifier).reset();
                      },
                      child: const Text('Clear Result'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
