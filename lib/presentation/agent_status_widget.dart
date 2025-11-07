import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'package:micro/infrastructure/ai/agent/agent_providers.dart';

/// Widget for displaying agent status and metrics
class AgentStatusWidget extends ConsumerWidget {
  final String agentId;
  final bool showMetrics;
  final bool showHistory;
  final VoidCallback? onRefresh;

  const AgentStatusWidget({
    super.key,
    required this.agentId,
    this.showMetrics = true,
    this.showHistory = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentStatusAsync = ref.watch(defaultAgentStatusProvider);
    final agentHistoryAsync = ref.watch(agentHistoryProvider);
    final agentManagementAsync = ref.watch(agentManagementProvider);

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
                  'Agent Status: $agentId',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (onRefresh != null)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                  ),
              ],
            ),
            const Divider(),
            _buildStatusIndicator(context, agentStatusAsync),
            if (showMetrics) ...[
              const SizedBox(height: 16),
              _buildMetricsSection(context, ref, agentManagementAsync),
            ],
            if (showHistory) ...[
              const SizedBox(height: 16),
              _buildHistorySection(context, agentHistoryAsync),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    AsyncValue<agent_types.AgentStatus> agentStatusAsync,
  ) {
    return switch (agentStatusAsync) {
      AsyncData(:final value) => _StatusIndicator(status: value),
      AsyncError(:final error) => Text(
          'Error: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      AsyncLoading() => const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Loading status...'),
          ],
        ),
    };
  }

  Widget _buildMetricsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, dynamic>> agentManagementAsync,
  ) {
    return agentManagementAsync.when(
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Metrics',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Status',
                  value: value['status']?.toString() ?? 'Unknown',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricCard(
                  title: 'Active Agent',
                  value: value['activeAgent']?.toString() ?? 'None',
                  icon: Icons.smart_toy,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Available Agents',
                  value: '${(value['agents'] as List?)?.length ?? 0}',
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
      error: (error, stack) => Text(
        'Error loading metrics: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    AsyncValue<List<agent_types.AgentExecution>> agentHistoryAsync,
  ) {
    return switch (agentHistoryAsync) {
      AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${value.length} executions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (value.isEmpty)
              const Text('No recent activity')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: value.length.clamp(0, 5),
                itemBuilder: (context, index) {
                  final execution = value[index];
                  return _ExecutionTile(execution: execution);
                },
              ),
          ],
        ),
      AsyncError(:final error) => Text(
          'Error loading history: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      AsyncLoading() => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
    };
  }
}

/// Status indicator widget
class _StatusIndicator extends StatelessWidget {
  final agent_types.AgentStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      agent_types.AgentStatus.idle => (Icons.pause_circle, Colors.grey, 'Idle'),
      agent_types.AgentStatus.planning => (
          Icons.calendar_today,
          Colors.blue,
          'Planning'
        ),
      agent_types.AgentStatus.executing => (
          Icons.play_circle,
          Colors.green,
          'Executing'
        ),
      agent_types.AgentStatus.reasoning => (
          Icons.lightbulb,
          Colors.purple,
          'Reasoning'
        ),
      agent_types.AgentStatus.waiting => (
          Icons.hourglass_empty,
          Colors.orange,
          'Waiting'
        ),
      agent_types.AgentStatus.completed => (
          Icons.check_circle,
          Colors.green,
          'Completed'
        ),
      agent_types.AgentStatus.failed => (Icons.error, Colors.red, 'Failed'),
      agent_types.AgentStatus.cancelled => (
          Icons.cancel,
          Colors.orange,
          'Cancelled'
        ),
    };

    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (status == agent_types.AgentStatus.planning ||
            status == agent_types.AgentStatus.executing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

/// Metric card widget
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Execution tile widget
class _ExecutionTile extends StatelessWidget {
  final agent_types.AgentExecution execution;

  const _ExecutionTile({required this.execution});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          execution.result.success ? Icons.check_circle : Icons.error,
          color: execution.result.success ? Colors.green : Colors.red,
        ),
        title: Text(
          execution.goal,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${execution.result.steps.length} steps • ${_formatDuration(execution.duration)}',
        ),
        trailing: Text(
          _formatTimestamp(execution.startTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _showExecutionDetails(context, execution),
      ),
    );
  }

  void _showExecutionDetails(
      BuildContext context, agent_types.AgentExecution execution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(execution.goal),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: execution.result.steps.length,
            itemBuilder: (context, index) {
              final step = execution.result.steps[index];
              return _StepExpansionTile(step: step);
            },
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

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Step expansion tile widget
class _StepExpansionTile extends StatelessWidget {
  final agent_types.AgentStep step;

  const _StepExpansionTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.type) {
      agent_types.AgentStepType.planning => (Icons.calendar_today, Colors.blue),
      agent_types.AgentStepType.reasoning => (Icons.lightbulb, Colors.purple),
      agent_types.AgentStepType.toolExecution => (Icons.build, Colors.orange),
      agent_types.AgentStepType.reflection => (Icons.visibility, Colors.green),
      agent_types.AgentStepType.finalization => (Icons.flag, Colors.teal),
      agent_types.AgentStepType.errorRecovery => (Icons.healing, Colors.red),
    };

    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(step.description),
      subtitle: Text(
        '${_formatDuration(step.duration)} • ${_formatTimestamp(step.timestamp)}',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.input != null) ...[
                const Text('Input:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatMap(step.input!)),
                ),
                const SizedBox(height: 8),
              ],
              if (step.output != null) ...[
                const Text('Output:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(_formatMap(step.output!)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(1)}s';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final hour = timestamp.hour;
    final minute = timestamp.minute;
    return '${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatMap(Map<String, dynamic> map) {
    return map.entries.map((entry) {
      final value = entry.value is Map
          ? _formatMap(entry.value as Map<String, dynamic>)
          : entry.value.toString();
      return '${entry.key}: $value';
    }).join('\n');
  }
}
