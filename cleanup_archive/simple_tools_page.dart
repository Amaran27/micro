import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tools_provider.dart' as tools;

/// Simple tools page
class SimpleToolsPage extends ConsumerWidget {
  const SimpleToolsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolsState = ref.watch(tools.toolsStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(tools.toolsProviderProvider.notifier).refreshTools(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(tools.toolsProviderProvider.notifier).refreshTools(),
        child: Column(
          children: [
            // Loading indicator
            if (toolsState.isLoading) ...[
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ],

            // Error state
            if (toolsState.error != null) ...[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          toolsState.error!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            // Tools list
            if (!toolsState.isLoading && toolsState.error == null) ...[
              Expanded(
                child: toolsState.tools.isEmpty
                    ? const Center(
                        child: Text('No tools available'),
                      )
                    : ListView.builder(
                        itemCount: toolsState.tools.length,
                        itemBuilder: (context, index) {
                          final tool = toolsState.tools[index];
                          return ListTile(
                            leading: Icon(
                              tool.isMobileOptimized
                                  ? Icons.phone_android
                                  : Icons.computer,
                            ),
                            title: Text(tool.name),
                            subtitle: Text(tool.description),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () {
                              // Simple navigation - just show tool details for now
                            },
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
