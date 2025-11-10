import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'package:micro/infrastructure/ai/agent/agent_providers.dart';

/// Widget for executing agent goals and viewing results
class AgentExecutionWidget extends ConsumerStatefulWidget {
  final String? initialGoal;
  final String? agentId;
  final String? initialContext;
  final VoidCallback? onExecutionComplete;

  const AgentExecutionWidget({
    super.key,
    this.initialGoal,
    this.agentId,
    this.initialContext,
    this.onExecutionComplete,
  });

  @override
  ConsumerState<AgentExecutionWidget> createState() =>
      _AgentExecutionWidgetState();
}

class _AgentExecutionWidgetState extends ConsumerState<AgentExecutionWidget> {
  final _goalController = TextEditingController();
  final _contextController = TextEditingController();
  final _parametersController = TextEditingController();
  bool _showAdvanced = false;
  bool _isExecuting = false;
  agent_types.AgentResult? _lastResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialGoal != null) {
      _goalController.text = widget.initialGoal!;
    }
    if (widget.initialContext != null) {
      _contextController.text = widget.initialContext!;
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _contextController.dispose();
    _parametersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final executionAsync = ref.watch(agentExecutionProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Agent Execution',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _showAdvanced = !_showAdvanced),
                  icon: Icon(
                    _showAdvanced
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                  tooltip: 'Advanced options',
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildGoalInput(),
            const SizedBox(height: 16),
            _buildAgentSelector(),
            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              _buildAdvancedOptions(),
            ],
            const SizedBox(height: 16),
            _buildExecutionButtons(executionAsync),
            const SizedBox(height: 16),
            _buildExecutionResults(executionAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _goalController,
          decoration: InputDecoration(
            hintText: 'What do you want the agent to accomplish?',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: () {
                _goalController.clear();
                _contextController.clear();
                _parametersController.clear();
              },
              icon: const Icon(Icons.clear),
            ),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildAgentSelector() {
    return Consumer(
      builder: (context, ref, child) {
        final agentsAsync = ref.watch(agentManagementProvider);

        return switch (agentsAsync) {
          AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agent',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.agentId ?? value['activeAgent'] as String?,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Use Default Agent'),
                    ),
                    ...((value['agents'] as List<String>?) ?? [])
                        .map((agentId) => DropdownMenuItem(
                              value: agentId,
                              child: Text('Agent: $agentId'),
                            )),
                  ],
                  onChanged: (value) {
                    // Agent selection handled by parent or state
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAgentCreationDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Agent'),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showAgentList(context),
                      icon: const Icon(Icons.list),
                      label: const Text('View Agents'),
                    ),
                  ],
                ),
              ],
            ),
          AsyncError(:final error) => Text(
              'Error loading agents: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          AsyncLoading() => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        };
      },
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contextController,
          decoration: const InputDecoration(
            hintText: 'Additional context for the agent...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        Text(
          'Parameters (JSON)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _parametersController,
          decoration: const InputDecoration(
            hintText: '{"key": "value", ...}',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 8),
        Consumer(
          builder: (context, ref, child) {
            final toolsAsync = ref.watch(availableToolsProvider);

            return switch (toolsAsync) {
              AsyncData(:final value) => _ToolSelector(tools: value),
              AsyncError(:final error) => Text(
                  'Error loading tools: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              AsyncLoading() => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            };
          },
        ),
      ],
    );
  }

  Widget _buildExecutionButtons(
      AsyncValue<agent_types.AgentResult?> executionAsync) {
    final isExecuting = executionAsync is AsyncLoading;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isExecuting || _goalController.text.trim().isEmpty
                ? null
                : _executeGoal,
            icon: Icon(isExecuting ? Icons.stop : Icons.play_arrow),
            label: Text(isExecuting ? 'Cancel' : 'Execute Goal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isExecuting ? Colors.red : null,
              foregroundColor: isExecuting ? Colors.white : null,
            ),
          ),
        ),
        if (_lastResult != null) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _showLastResult,
            icon: const Icon(Icons.history),
            tooltip: 'View last result',
          ),
        ],
      ],
    );
  }

  Widget _buildExecutionResults(
      AsyncValue<agent_types.AgentResult?> executionAsync) {
    return switch (executionAsync) {
      AsyncData(:final value) => _buildResultView(value),
      AsyncError(:final error) => _buildErrorView(error),
      AsyncLoading() => const _LoadingView(),
    };
  }

  Widget _buildResultView(agent_types.AgentResult? result) {
    if (result == null) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isExecuting && result.success) {
        _isExecuting = true;
        _lastResult = result;
        widget.onExecutionComplete?.call();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: result.success ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.success ? Colors.green : Colors.red,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          result.success ? Icons.check_circle : Icons.error,
          color: result.success ? Colors.green : Colors.red,
        ),
        title: Text(
          result.success ? 'Execution Successful' : 'Execution Failed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: result.success ? Colors.green[800] : Colors.red[800],
          ),
        ),
        subtitle: Text('${result.steps.length} steps completed'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.error != null) ...[
                  Text(
                    'Error:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(result.error!),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Result:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(result.result),
                ),
                if (result.metadata?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Metadata:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _buildMetadata(result.metadata!),
                ],
                const SizedBox(height: 16),
                Text(
                  'Execution Steps:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStepsList(result.steps),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildErrorView(Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Execution Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: metadata.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStepsList(List<agent_types.AgentStep> steps) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return _StepItem(step: step, index: index);
      },
    );
  }

  void _executeGoal() {
    final notifier = ref.read(agentExecutionProvider.notifier);

    Map<String, dynamic>? parameters;
    try {
      if (_parametersController.text.trim().isNotEmpty) {
        parameters = Map<String, dynamic>.from(
          _parseJson(_parametersController.text),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid JSON in parameters: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    notifier.executeGoal(
      goal: _goalController.text.trim(),
      agentId: widget.agentId,
      context: _contextController.text.trim().isEmpty
          ? null
          : _contextController.text.trim(),
      parameters: parameters,
    );
  }

  void _showLastResult() {
    if (_lastResult == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Last Execution Result'),
        content: SingleChildScrollView(
          child: _buildResultView(_lastResult),
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

  void _showAgentCreationDialog(BuildContext context) {
    // Implementation for agent creation dialog
  }

  void _showAgentList(BuildContext context) {
    // Implementation for agent list dialog
  }

  Map<String, dynamic> _parseJson(String json) {
    // Simple JSON parsing - replace with proper implementation
    return {};
  }
}

/// Loading view widget
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Executing agent...'),
          ],
        ),
        const SizedBox(height: 16),
        Consumer(
          builder: (context, ref, child) {
            final stepsAsync = ref.watch(
              agentStepsProvider('default'),
            );

            return switch (stepsAsync) {
              AsyncData(:final value) => _buildStepProgress(context, value),
              AsyncError(:final error) => Text(
                  'Error loading steps: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              AsyncLoading() => const SizedBox.shrink(),
            };
          },
        ),
      ],
    );
  }

  Widget _buildStepProgress(
      BuildContext context, List<agent_types.AgentStep> steps) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress: ${steps.length} steps',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: steps.last.type == agent_types.AgentStepType.finalization
              ? 1.0
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          steps.last.description,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Step item widget
class _StepItem extends StatelessWidget {
  final agent_types.AgentStep step;
  final int index;

  const _StepItem({
    required this.step,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.type) {
      agent_types.AgentStepType.planning => (Icons.calendar_today, Colors.blue),
      agent_types.AgentStepType.reasoning => (Icons.lightbulb, Colors.purple),
      agent_types.AgentStepType.toolExecution => (Icons.build, Colors.orange),
      agent_types.AgentStepType.toolUse => (
          Icons.construction,
          Colors.deepOrange
        ),
      agent_types.AgentStepType.reflection => (Icons.visibility, Colors.green),
      agent_types.AgentStepType.finalization => (Icons.flag, Colors.teal),
      agent_types.AgentStepType.errorRecovery => (Icons.healing, Colors.red),
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          'Step ${index + 1}: ${step.type.name}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${step.description} • ${step.duration.inMilliseconds}ms',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          '${step.timestamp.hour}:${step.timestamp.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Tool selector widget
class _ToolSelector extends StatelessWidget {
  final List<dynamic> tools;

  const _ToolSelector({required this.tools});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Tools',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.map((tool) {
            final toolName =
                tool is Map ? tool['name'] ?? 'Unknown' : tool.toString();
            return InputChip(
              label: Text(toolName),
              onPressed: () => _showToolInfo(context, tool),
              avatar: const Icon(Icons.build, size: 16),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showToolInfo(BuildContext context, dynamic tool) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tool is Map
            ? (tool as Map<String, dynamic>)['name'] ?? 'Tool Info'
            : 'Tool Info'),
        content: SingleChildScrollView(
          child: Text(
            tool is Map
                ? _formatToolInfo(tool as Map<String, dynamic>)
                : 'Tool: ${tool.toString()}',
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

  String _formatToolInfo(Map<String, dynamic> tool) {
    final buffer = StringBuffer();

    if (tool['description'] != null) {
      buffer.writeln('Description: ${tool['description']}');
      buffer.writeln();
    }

    if (tool['parameters'] != null) {
      buffer.writeln('Parameters:');
      final params = tool['parameters'];
      if (params is Map) {
        params.forEach((key, value) {
          buffer.writeln('  $key: $value');
        });
      }
    }

    return buffer.toString();
  }
}
