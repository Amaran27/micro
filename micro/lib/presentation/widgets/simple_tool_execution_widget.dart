import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/mcp/core/models/tool.dart';
import '../../infrastructure/mcp/core/models/tool_result.dart';
import '../providers/tools_provider.dart' as tools;

// Alias to resolve naming conflicts

/// Simple tool execution widget
class SimpleToolExecutionWidget extends ConsumerWidget {
  final String toolId;
  final Tool tool;

  const SimpleToolExecutionWidget({
    super.key,
    required this.toolId,
    required this.tool,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final executionStatus =
        ref.watch(tools.toolExecutionStatusProvider)[toolId] ??
            ToolExecutionStatus.pending;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool header
            Row(
              children: [
                Icon(
                  tool.isMobileOptimized ? Icons.phone_android : Icons.computer,
                  color: tool.isMobileOptimized
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tool.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v${tool.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Execution status
            Text(
              'Status: ${executionStatus.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Execute button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _executeTool(ref),
                child: const Text('Execute Tool'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeTool(WidgetRef ref) {
    ref.read(tools.toolsProviderProvider.notifier).executeTool(
      toolId: toolId,
      parameters: {},
    );
  }
}
