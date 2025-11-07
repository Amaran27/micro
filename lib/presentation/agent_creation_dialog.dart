import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'package:micro/infrastructure/ai/agent/agent_providers.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';

/// Dialog for creating new autonomous agents
class AgentCreationDialog extends ConsumerStatefulWidget {
  final VoidCallback? onAgentCreated;

  const AgentCreationDialog({
    super.key,
    this.onAgentCreated,
  });

  @override
  ConsumerState<AgentCreationDialog> createState() =>
      _AgentCreationDialogState();
}

class _AgentCreationDialogState extends ConsumerState<AgentCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  agent_types.AgentType _agentType = agent_types.AgentType.general;
  String _selectedModel = 'gpt-4';
  double _temperature = 0.7;
  int _maxSteps = 10;
  bool _enableMemory = true;
  bool _enableReasoning = true;
  bool _enableCollaboration = false;
  final List<String> _selectedTools = [];
  
  // MCP Integration
  bool _enableMCP = false;
  final List<String> _selectedMCPServers = [];

  bool _showAdvanced = false;
  bool _isLoading = false;

  final List<String> _availableModels = [
    'gpt-4',
    'gpt-4-turbo',
    'gpt-3.5-turbo',
    'claude-3-sonnet-20240229',
    'claude-3-opus-20240229',
    'gemini-pro',
    'llama2-70b-chat',
  ];

  final List<String> _specializations = [
    'research',
    'analysis',
    'planning',
    'execution',
    'communication',
    'problem-solving',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create New Agent',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAgentTypeSection(),
                    const SizedBox(height: 24),
                    _buildBasicSettings(),
                    const SizedBox(height: 24),
                    if (_showAdvanced) ...[
                      _buildAdvancedSettings(),
                      const SizedBox(height: 24),
                      _buildToolSelection(),
                      const SizedBox(height: 24),
                      _buildMCPConfiguration(),
                      const SizedBox(height: 24),
                    ],
                    _buildActions(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAgentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Agent Type',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _AgentTypeChip(
              label: 'General Purpose',
              type: agent_types.AgentType.general,
              selectedType: _agentType,
              onTap: (type) => setState(() => _agentType = type),
            ),
            _AgentTypeChip(
              label: 'Specialized',
              type: agent_types.AgentType.specialized,
              selectedType: _agentType,
              onTap: (type) => setState(() => _agentType = type),
            ),
            _AgentTypeChip(
              label: 'Collaborative',
              type: agent_types.AgentType.collaborative,
              selectedType: _agentType,
              onTap: (type) => setState(() => _agentType = type),
            ),
          ],
        ),
        if (_agentType == agent_types.AgentType.specialized) ...[
          const SizedBox(height: 16),
          _buildSpecializationSelector(),
        ],
        if (_agentType == agent_types.AgentType.collaborative) ...[
          const SizedBox(height: 16),
          _buildCollaborationSettings(),
        ],
      ],
    );
  }

  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Agent Name',
            hintText: 'Enter a descriptive name for the agent',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an agent name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedModel,
          items: _availableModels.map((model) {
            return DropdownMenuItem(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedModel = value!);
          },
          decoration: const InputDecoration(
            labelText: 'AI Model',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildSliderSection(
          label: 'Temperature',
          value: _temperature,
          min: 0.0,
          max: 2.0,
          divisions: 20,
          onChanged: (value) => setState(() => _temperature = value),
          description:
              '${_temperature.toStringAsFixed(2)} (${_getTemperatureDescription(_temperature)})',
        ),
        const SizedBox(height: 16),
        _buildSliderSection(
          label: 'Max Steps',
          value: _maxSteps.toDouble(),
          min: 1.0,
          max: 50.0,
          divisions: 49,
          onChanged: (value) => setState(() => _maxSteps = value.toInt()),
          description: '$_maxSteps steps',
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Switch(
              value: _showAdvanced,
              onChanged: (value) => setState(() => _showAdvanced = value),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable Memory System'),
          subtitle: const Text('Allow agent to remember past interactions'),
          value: _enableMemory,
          onChanged: (value) => setState(() => _enableMemory = value),
        ),
        SwitchListTile(
          title: const Text('Enable Advanced Reasoning'),
          subtitle: const Text('Use sophisticated reasoning strategies'),
          value: _enableReasoning,
          onChanged: (value) => setState(() => _enableReasoning = value),
        ),
      ],
    );
  }

  Widget _buildToolSelection() {
    return Consumer(
      builder: (context, ref, child) {
        final toolsAsync = ref.watch(availableToolsProvider);

        return switch (toolsAsync) {
          AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Tools',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${_selectedTools.length} selected',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: value.map((tool) {
                    final toolName = tool is Map
                        ? tool['name'] ?? 'Unknown'
                        : tool.toString();
                    final isSelected = _selectedTools.contains(toolName);
                    return FilterChip(
                      label: Text(toolName),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedTools.add(toolName);
                          } else {
                            _selectedTools.remove(toolName);
                          }
                        });
                      },
                      avatar: Icon(
                        isSelected ? Icons.check : Icons.build,
                        size: 18,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          AsyncError(:final error) => Text(
              'Error loading tools: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          AsyncLoading() => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        };
      },
    );
  }

  Widget _buildMCPConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dns, size: 20),
            const SizedBox(width: 8),
            Text(
              'MCP Integration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enable Model Context Protocol to extend agent with additional tools',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable MCP Tools'),
          subtitle: const Text('Allow agent to use tools from MCP servers'),
          value: _enableMCP,
          onChanged: (value) => setState(() => _enableMCP = value),
          contentPadding: EdgeInsets.zero,
        ),
        if (_enableMCP) ...[
          const SizedBox(height: 16),
          const Text(
            'Select MCP Servers:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, child) {
              final serverConfigsAsync = ref.watch(mcpServerConfigsProvider);
              final serverStatesAsync = ref.watch(mcpServerStatesProvider);

              return serverConfigsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (error, stack) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error loading MCP servers: $error',
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (configs) {
                  if (configs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(height: 8),
                          const Text(
                            'No MCP servers configured',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Configure MCP servers in Settings',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return serverStatesAsync.when(
                    loading: () => _buildServerCheckboxes(configs, []),
                    error: (error, stack) => _buildServerCheckboxes(configs, []),
                    data: (states) => _buildServerCheckboxes(configs, states),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildServerCheckboxes(
    List<MCPServerConfig> configs,
    List<MCPServerState> states,
  ) {
    return Column(
      children: configs.map((config) {
        final state = states.firstWhere(
          (s) => s.serverId == config.id,
          orElse: () => MCPServerState(
            serverId: config.id,
            status: MCPConnectionStatus.disconnected,
          ),
        );

        final isSelected = _selectedMCPServers.contains(config.id);
        final isConnected = state.status == MCPConnectionStatus.connected;

        return CheckboxListTile(
          title: Text(config.name),
          subtitle: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 10,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
              ),
              if (state.availableTools.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${state.availableTools.length} tools',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.purple,
                    ),
                  ),
                ),
              ],
            ],
          ),
          value: isSelected,
          onChanged: (selected) {
            setState(() {
              if (selected == true) {
                _selectedMCPServers.add(config.id);
              } else {
                _selectedMCPServers.remove(config.id);
              }
            });
          },
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _createAgent,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Agent'),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecializationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Specialization'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _specializations.map((specialization) {
            return ChoiceChip(
              label: Text(specialization),
              selected: false, // Add state management for selection
              onSelected: (selected) {
                // Handle specialization selection
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCollaborationSettings() {
    return SwitchListTile(
      title: const Text('Enable Collaboration'),
      subtitle: const Text('Agent can work with other agents'),
      value: _enableCollaboration,
      onChanged: (value) => setState(() => _enableCollaboration = value),
    );
  }

  Widget _buildSliderSection({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(agentManagementProvider.notifier);

      late String agentId;

      if (_agentType == agent_types.AgentType.specialized) {
        // Create specialized agent
        agentId = await notifier.createSpecializedAgent(
          specialization: _specializations.first, // Use selected specialization
          model: _selectedModel,
          requiredTools: _selectedTools.isEmpty ? null : _selectedTools,
        );
      } else {
        // Create general or collaborative agent
        agentId = await notifier.createAgent(
          name: _nameController.text.trim(),
          model: _selectedModel,
          temperature: _temperature,
          maxSteps: _maxSteps,
          enableMemory: _enableMemory,
          enableReasoning: _enableReasoning,
          preferredTools: _selectedTools.isEmpty ? null : _selectedTools,
        );
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Agent "${_nameController.text}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Close dialog
        Navigator.of(context).pop();

        // Call callback
        widget.onAgentCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create agent: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTemperatureDescription(double temperature) {
    if (temperature < 0.3) return 'Very deterministic';
    if (temperature < 0.7) return 'Balanced';
    if (temperature < 1.2) return 'Creative';
    return 'Very creative';
  }
}

/// Agent type chip widget
class _AgentTypeChip extends StatelessWidget {
  final String label;
  final agent_types.AgentType type;
  final agent_types.AgentType selectedType;
  final ValueChanged<agent_types.AgentType> onTap;

  const _AgentTypeChip({
    required this.label,
    required this.type,
    required this.selectedType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = type == selectedType;

    return ActionChip(
      label: Text(label),
      backgroundColor:
          isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : null,
      onPressed: () => onTap(type),
      avatar: isSelected
          ? Icon(Icons.check, size: 18, color: Theme.of(context).primaryColor)
          : null,
    );
  }
}
