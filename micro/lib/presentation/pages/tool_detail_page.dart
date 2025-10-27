import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tools_provider.dart';
import '../widgets/tool_execution_widget.dart';

class ToolDetailPage extends ConsumerWidget {
  final String toolId;

  const ToolDetailPage({
    super.key,
    required this.toolId,
  });

  @override
  ConsumerStatefulWidget<ToolDetailPage> createState() => _ToolDetailPageState();
}

class _ToolDetailPageState extends ConsumerState<ToolDetailPage> {
  final bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    // Pre-load tool details when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(toolsProviderProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final toolsState = ref.watch(toolsStateProvider);
    final tool = toolsState.toolCache[widget.toolId];
    
    if (tool == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tool Not Found'),
        ),
        body: const Center(
          child: Text(
            'Tool with ID ${widget.toolId} not found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(tool.name),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareTool(),
            tooltip: 'Share tool',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshTool(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tool header
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      tool.isMobileOptimized ? Icons.phone_android : Icons.computer,
                      color: tool.isMobileOptimized 
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.outline,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tool.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v${tool.version}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tool description
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Text(
                  tool.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            
            // Tool metadata
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMetadataRow('Category', tool.category),
                    _buildMetadataRow('Server', tool.serverName),
                    _buildMetadataRow('Version', tool.version),
                    _buildMetadataRow('Mobile Optimized', tool.isMobileOptimized ? 'Yes' : 'No'),
                    _buildMetadataRow('Execution Time', '${tool.performanceMetrics.averageExecutionTime.inMilliseconds}ms'),
                    _buildMetadataRow('Memory Usage', '${tool.performanceMetrics.memoryUsageMB.toStringAsFixed(1)}MB'),
                    _buildMetadataRow('Success Rate', '${(tool.performanceMetrics.successRate * 100).toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            
            // Tool capabilities
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capabilities',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (tool.capabilities.isNotEmpty) ...[
                      ...tool.capabilities.map((capability) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                    Icons.check_circle_outline,
                                    color: Theme.of(context).colorScheme.primary,
                                    size: 16,
                                  ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                      capability.name,
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      const Text(
                        'No capabilities defined',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
              ),
            
            // Tool execution section
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Execute Tool',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ToolExecutionWidget(
                      toolId: widget.toolId,
                      tool: tool,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _refreshTool() {
    ref.read(toolsProviderProvider).refreshTools();
  }

  void _shareTool() {
    final tool = ref.read(toolsStateProvider).getToolById(widget.toolId);
    if (tool != null) {
      // Share tool details
      final toolDetails = '''
Tool: ${tool.name}
Version: ${tool.version}
Category: ${tool.category}
Description: ${tool.description}
Mobile Optimized: ${tool.isMobileOptimized ? 'Yes' : 'No'}
      ''';
      
      // Share using platform share
      // In a real app, you would use share_plus package or platform-specific sharing
      // For now, we'll just show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tool details shared!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}