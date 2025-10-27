import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/mcp/core/models/tool.dart';

/// Tool execution widget for dynamic form generation and execution
class ToolExecutionWidget extends ConsumerWidget {
  final String toolId;
  final Tool tool;
  final Map<String, dynamic> initialParameters;

  const ToolExecutionWidget({
    super.key,
    required this.toolId,
    required this.tool,
    this.initialParameters = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        style: Theme.of(context).textTheme.titleLarge,
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

            // Tool description
            if (tool.description.isNotEmpty) ...[
              Text(
                tool.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // Execute button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _executeTool(context, ref),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Execute Tool'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeTool(BuildContext context, WidgetRef ref) async {
    try {
      // For now, just show a success message
      // In a real implementation, this would execute the actual tool
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tool execution not yet implemented'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to execute tool: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
