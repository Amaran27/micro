import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/ai/agent/agent_providers.dart';

/// Widget to display available agent tools and capabilities
class AgentToolsWidget extends ConsumerWidget {
  const AgentToolsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(agentToolsProvider);

    return toolsAsync.when(
      data: (toolsByCategory) {
        final totalTools = toolsByCategory.values
            .fold<int>(0, (sum, tools) => sum + tools.length);

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.build, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Available Tools',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Chip(
                      label: Text('$totalTools tools'),
                      backgroundColor: Colors.green.withOpacity(0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (totalTools == 0)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No tools available. Tools will appear here once agents are initialized.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ...toolsByCategory.entries.map((entry) {
                    final category = entry.key;
                    final tools = entry.value;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            category,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...tools.map((tool) => ListTile(
                          dense: true,
                          leading: const Icon(Icons.functions, size: 16),
                          title: Text(tool['name'] ?? 'Unknown'),
                          subtitle: Text(
                            tool['description'] ?? 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                        const Divider(),
                      ],
                    );
                  }),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Error loading tools: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact tools info chip for showing in headers
class AgentToolsChip extends ConsumerWidget {
  const AgentToolsChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsAsync = ref.watch(agentToolsProvider);

    return toolsAsync.when(
      data: (toolsByCategory) {
        final totalTools = toolsByCategory.values
            .fold<int>(0, (sum, tools) => sum + tools.length);

        return ActionChip(
          avatar: const Icon(Icons.build, size: 16),
          label: Text('$totalTools tools'),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Available Tools'),
                content: SizedBox(
                  width: 500,
                  height: 400,
                  child: AgentToolsWidget(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(
        width: 80,
        height: 32,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => Chip(
        avatar: const Icon(Icons.error, size: 16, color: Colors.red),
        label: const Text('Error'),
      ),
    );
  }
}
