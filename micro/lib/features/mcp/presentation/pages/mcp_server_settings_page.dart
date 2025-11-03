import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/features/mcp/presentation/widgets/mcp_server_dialog.dart';
import 'package:micro/features/mcp/presentation/pages/mcp_server_discovery_page.dart';

/// MCP Server Settings Page - Manage MCP servers
class MCPServerSettingsPage extends ConsumerWidget {
  const MCPServerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverConfigsAsync = ref.watch(mcpServerConfigsProvider);
    final serverStatesAsync = ref.watch(mcpServerStatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP Servers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Discover Servers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MCPServerDiscoveryPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(mcpServerConfigsProvider);
              ref.invalidate(mcpServerStatesProvider);
            },
          ),
        ],
      ),
      body: serverConfigsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading servers: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(mcpServerConfigsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (configs) {
          if (configs.isEmpty) {
            return _buildEmptyState(context);
          }

          return serverStatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildServerList(context, ref, configs, []),
            data: (states) => _buildServerList(context, ref, configs, states),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddServerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Server'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dns_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No MCP Servers Configured',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add MCP servers to extend your AI assistant\nwith additional tools and capabilities',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MCPServerDiscoveryPage(),
                ),
              );
            },
            icon: const Icon(Icons.explore),
            label: const Text('Discover Servers'),
          ),
        ],
      ),
    );
  }

  Widget _buildServerList(
    BuildContext context,
    WidgetRef ref,
    List<MCPServerConfig> configs,
    List<MCPServerState> states,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        final state = states.firstWhere(
          (s) => s.serverId == config.id,
          orElse: () => MCPServerState(
            serverId: config.id,
            status: MCPConnectionStatus.disconnected,
          ),
        );
        return _buildServerCard(context, ref, config, state);
      },
    );
  }

  Widget _buildServerCard(
    BuildContext context,
    WidgetRef ref,
    MCPServerConfig config,
    MCPServerState state,
  ) {
    final statusColor = _getStatusColor(state.status);
    final statusText = _getStatusText(state.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            boxShadow: state.status == MCPConnectionStatus.connected
                ? [
                    BoxShadow(
                      color: statusColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        title: Text(
          config.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(config.description),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(statusText, statusColor),
                const SizedBox(width: 8),
                _buildBadge(
                  config.transportType.name.toUpperCase(),
                  Colors.blue,
                ),
                if (state.availableTools.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildBadge(
                    '${state.availableTools.length} tools',
                    Colors.purple,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.status == MCPConnectionStatus.connected)
              IconButton(
                icon: const Icon(Icons.link_off, color: Colors.orange),
                tooltip: 'Disconnect',
                onPressed: () => _disconnectServer(ref, config.id),
              )
            else if (state.status == MCPConnectionStatus.error)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                tooltip: 'Retry Connection',
                onPressed: () => _connectServer(ref, config.id),
              )
            else
              IconButton(
                icon: const Icon(Icons.link, color: Colors.green),
                tooltip: 'Connect',
                onPressed: () => _connectServer(ref, config.id),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditServerDialog(context, ref, config);
                    break;
                  case 'test':
                    _testConnection(context, ref, config);
                    break;
                  case 'delete':
                    _deleteServer(context, ref, config.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'test',
                  child: Row(
                    children: [
                      Icon(Icons.science),
                      SizedBox(width: 8),
                      Text('Test Connection'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Transport', config.transportType.name.toUpperCase()),
                if (config.url != null) _buildDetailRow('URL', config.url!),
                if (config.command != null) _buildDetailRow('Command', config.command!),
                if (config.args != null && config.args!.isNotEmpty)
                  _buildDetailRow('Arguments', config.args!.join(' ')),
                if (state.lastConnected != null)
                  _buildDetailRow(
                    'Last Connected',
                    _formatDateTime(state.lastConnected!),
                  ),
                if (state.lastActivity != null)
                  _buildDetailRow(
                    'Last Activity',
                    _formatDateTime(state.lastActivity!),
                  ),
                if (state.toolCallCount > 0)
                  _buildDetailRow('Tool Calls', state.toolCallCount.toString()),
                if (state.errorMessage != null) ...[
                  const Divider(),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                if (state.availableTools.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'Available Tools:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.availableTools
                        .map((tool) => Chip(
                              label: Text(tool.name),
                              avatar: const Icon(Icons.build, size: 16),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(MCPConnectionStatus status) {
    switch (status) {
      case MCPConnectionStatus.connected:
        return Colors.green;
      case MCPConnectionStatus.connecting:
        return Colors.orange;
      case MCPConnectionStatus.error:
        return Colors.red;
      case MCPConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  String _getStatusText(MCPConnectionStatus status) {
    switch (status) {
      case MCPConnectionStatus.connected:
        return 'Connected';
      case MCPConnectionStatus.connecting:
        return 'Connecting...';
      case MCPConnectionStatus.error:
        return 'Error';
      case MCPConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showAddServerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        onSave: (config) async {
          try {
            await ref.read(mcpOperationsProvider.notifier).addServer(config);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server "${config.name}" added')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add server: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditServerDialog(
    BuildContext context,
    WidgetRef ref,
    MCPServerConfig config,
  ) {
    showDialog(
      context: context,
      builder: (context) => MCPServerDialog(
        config: config,
        onSave: (updatedConfig) async {
          try {
            await ref.read(mcpOperationsProvider.notifier).updateServer(updatedConfig);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Server "${updatedConfig.name}" updated')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update server: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _connectServer(WidgetRef ref, String serverId) async {
    await ref.read(mcpOperationsProvider.notifier).connectServer(serverId);
  }

  Future<void> _disconnectServer(WidgetRef ref, String serverId) async {
    await ref.read(mcpOperationsProvider.notifier).disconnectServer(serverId);
  }

  Future<void> _testConnection(
    BuildContext context,
    WidgetRef ref,
    MCPServerConfig config,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing connection...'),
          ],
        ),
      ),
    );

    final success = await ref.read(mcpOperationsProvider.notifier).testConnection(config);

    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Connection test successful!'
                : 'Connection test failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _deleteServer(BuildContext context, WidgetRef ref, String serverId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Server'),
        content: const Text('Are you sure you want to delete this server?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(mcpOperationsProvider.notifier).removeServer(serverId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete server: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
