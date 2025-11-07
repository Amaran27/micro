import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_discovery.dart';
import 'package:micro/infrastructure/ai/agent/agent_delegation.dart';

/// Widget for agent-to-agent delegation and device communication
class AgentDelegationWidget extends ConsumerStatefulWidget {
  final String? sourceAgentId;
  final VoidCallback? onDelegationComplete;

  const AgentDelegationWidget({
    super.key,
    this.sourceAgentId,
    this.onDelegationComplete,
  });

  @override
  ConsumerState<AgentDelegationWidget> createState() =>
      _AgentDelegationWidgetState();
}

class _AgentDelegationWidgetState extends ConsumerState<AgentDelegationWidget> {
  final _discoveryService = AgentDiscoveryService();
  late final _delegationService =
      AgentDelegationService(deviceId: 'local-device');

  List<DiscoveredAgent> _discoveredAgents = [];
  List<String> _nearbyDevices = [];
  bool _isDiscovering = false;
  bool _isDelegating = false;
  DiscoveredAgent? _selectedAgent;
  String _delegationGoal = '';
  Map<String, dynamic> _delegationContext = {};

  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
  }

  @override
  void dispose() {
    _discoveryService.stopDiscovery();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    await _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    setState(() => _isDiscovering = true);

    try {
      // Discover local agents
      final agents = await _discoveryService.discoverAgents();

      // Discover nearby devices
      final devices = await _discoveryService.discoverNearbyDevices();

      if (mounted) {
        setState(() {
          _discoveredAgents = agents;
          _nearbyDevices = devices;
          _isDiscovering = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDiscovering = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discovery failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _delegateTask() async {
    if (_selectedAgent == null || _delegationGoal.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an agent and enter a goal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isDelegating = true);

    try {
      // Connect to target agent first
      await _delegationService.connectToDevice(
        targetDeviceId: _selectedAgent!.deviceId,
        targetAgentId: _selectedAgent!.id,
      );

      // Delegate task
      final result = await _delegationService.delegateTask(
        targetDeviceId: _selectedAgent!.deviceId,
        targetAgentId: _selectedAgent!.id,
        task: _delegationGoal.trim(),
        parameters: _delegationContext.isEmpty ? null : _delegationContext,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task delegated successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Reset form
          setState(() {
            _selectedAgent = null;
            _delegationGoal = '';
            _delegationContext = {};
          });

          widget.onDelegationComplete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delegation failed: ${result.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delegation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDelegating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Agent Delegation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isDiscovering ? null : _startDiscovery,
                      icon: Icon(_isDiscovering ? Icons.stop : Icons.refresh),
                      tooltip: 'Refresh Discovery',
                    ),
                    const SizedBox(width: 8),
                    if (_isDiscovering)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildDiscoverySection(),
            const SizedBox(height: 24),
            _buildDelegationForm(),
            const SizedBox(height: 16),
            _buildDelegationActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Agents',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_isDiscovering)
          const Center(
            child: Column(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(height: 8),
                Text('Discovering agents and devices...'),
              ],
            ),
          )
        else if (_discoveredAgents.isEmpty)
          const Text('No agents discovered')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _discoveredAgents.length,
            itemBuilder: (context, index) {
              final agent = _discoveredAgents[index];
              return _AgentTile(
                agent: agent,
                isSelected: _selectedAgent?.id == agent.id,
                onTap: () => setState(() => _selectedAgent = agent),
              );
            },
          ),
        if (_nearbyDevices.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Nearby Devices',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _nearbyDevices.map((device) {
              return Chip(
                label: Text(device),
                avatar: const Icon(Icons.devices, size: 16),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDelegationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Delegation',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_selectedAgent != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Agent',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        _selectedAgent!.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedAgent!.capabilities.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Capabilities: ${_selectedAgent!.capabilities.join(", ")}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Task Goal',
            hintText: 'What should the delegated agent accomplish?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (value) => setState(() => _delegationGoal = value),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showContextDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Context'),
        ),
      ],
    );
  }

  Widget _buildDelegationActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _selectedAgent = null;
                _delegationGoal = '';
                _delegationContext = {};
              });
            },
            child: const Text('Clear'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isDelegating ? null : _delegateTask,
            icon: _isDelegating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(_isDelegating ? 'Delegating...' : 'Delegate Task'),
          ),
        ),
      ],
    );
  }

  void _showContextDialog() {
    final keyController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Context'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Key',
                hintText: 'context_key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'Context value',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (keyController.text.trim().isNotEmpty) {
                setState(() {
                  _delegationContext[keyController.text.trim()] =
                      valueController.text.trim().isEmpty
                          ? null
                          : valueController.text.trim();
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

/// Agent tile widget
class _AgentTile extends StatelessWidget {
  final DiscoveredAgent agent;
  final bool isSelected;
  final VoidCallback onTap;

  const _AgentTile({
    required this.agent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: agent.isLocal ? Colors.green : Colors.blue,
          child: Icon(
            agent.isLocal ? Icons.devices : Icons.cloud,
            color: Colors.white,
          ),
        ),
        title: Text(agent.name),
        subtitle: Text(
          '${agent.type} • ${agent.isLocal ? "Local" : "Remote"}',
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
        onTap: onTap,
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
