import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';

/// Widget for configuring MCP integration in provider settings
class MCPProviderConfigWidget extends ConsumerStatefulWidget {
  final bool mcpEnabled;
  final List<String> mcpServerIds;
  final Function(bool enabled, List<String> serverIds) onChanged;

  const MCPProviderConfigWidget({
    super.key,
    required this.mcpEnabled,
    required this.mcpServerIds,
    required this.onChanged,
  });

  @override
  ConsumerState<MCPProviderConfigWidget> createState() =>
      _MCPProviderConfigWidgetState();
}

class _MCPProviderConfigWidgetState
    extends ConsumerState<MCPProviderConfigWidget> {
  late bool _mcpEnabled;
  late Set<String> _selectedServerIds;

  @override
  void initState() {
    super.initState();
    _mcpEnabled = widget.mcpEnabled;
    _selectedServerIds = Set.from(widget.mcpServerIds);
  }

  void _toggleMCP(bool value) {
    setState(() {
      _mcpEnabled = value;
      if (!value) {
        _selectedServerIds.clear();
      }
    });
    widget.onChanged(_mcpEnabled, _selectedServerIds.toList());
  }

  void _toggleServer(String serverId, bool selected) {
    setState(() {
      if (selected) {
        _selectedServerIds.add(serverId);
      } else {
        _selectedServerIds.remove(serverId);
      }
    });
    widget.onChanged(_mcpEnabled, _selectedServerIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final serverConfigsAsync = ref.watch(mcpServerConfigsProvider);
    final serverStatesAsync = ref.watch(mcpServerStatesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Text(
          'Advanced Configuration',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enable Model Context Protocol integration to extend this provider with additional tools and capabilities',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),

        // MCP Enable toggle
        SwitchListTile(
          title: const Text('Enable MCP Integration'),
          subtitle: const Text('Allow this provider to use tools from MCP servers'),
          value: _mcpEnabled,
          onChanged: _toggleMCP,
          secondary: const Icon(Icons.dns),
        ),

        // MCP Server selection (only if enabled)
        if (_mcpEnabled) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Select MCP Servers',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which MCP servers this provider can use for tool execution',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),

          serverConfigsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading MCP servers: $error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (configs) {
              if (configs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(height: 8),
                      const Text(
                        'No MCP servers configured',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Go to Settings → MCP Servers to add servers',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to MCP settings
                          Navigator.pushNamed(context, '/settings/mcp');
                        },
                        icon: const Icon(Icons.settings),
                        label: const Text('Configure MCP Servers'),
                      ),
                    ],
                  ),
                );
              }

              return serverStatesAsync.when(
                loading: () => _buildServerList(configs, []),
                error: (error, stack) => _buildServerList(configs, []),
                data: (states) => _buildServerList(configs, states),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildServerList(
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

        final isSelected = _selectedServerIds.contains(config.id);
        final isConnected = state.status == MCPConnectionStatus.connected;
        final toolCount = state.availableTools.length;

        return CheckboxListTile(
          title: Text(config.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.description),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tool count
                  if (toolCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$toolCount tools',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          value: isSelected,
          onChanged: (bool? value) {
            if (value != null) {
              _toggleServer(config.id, value);
            }
          },
          secondary: Icon(
            Icons.dns,
            color: isConnected ? Colors.green : Colors.grey,
          ),
        );
      }).toList(),
    );
  }
}
