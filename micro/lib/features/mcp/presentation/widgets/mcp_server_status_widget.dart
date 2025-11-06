import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';

/// Widget showing status of a single MCP server with expandable tool list
class MCPServerStatusWidget extends ConsumerStatefulWidget {
  final MCPServerConfig config;
  final MCPServerState state;
  final VoidCallback? onDisconnect;

  const MCPServerStatusWidget({
    super.key,
    required this.config,
    required this.state,
    this.onDisconnect,
  });

  @override
  ConsumerState<MCPServerStatusWidget> createState() =>
      _MCPServerStatusWidgetState();
}

class _MCPServerStatusWidgetState
    extends ConsumerState<MCPServerStatusWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.state.status);
    final statusText = _getStatusText(widget.state.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dns,
                color: statusColor,
                size: 20,
              ),
            ),
            title: Text(
              widget.config.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.state.availableTools.isNotEmpty)
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
                      '${widget.state.availableTools.length} tools',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.state.status == MCPConnectionStatus.connected &&
                    widget.onDisconnect != null)
                  IconButton(
                    icon: const Icon(Icons.link_off, size: 18),
                    tooltip: 'Disconnect',
                    onPressed: widget.onDisconnect,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() => _isExpanded = !_isExpanded);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Transport', widget.config.transportType.name.toUpperCase()),
                  if (widget.config.url != null)
                    _buildInfoRow('URL', widget.config.url!),
                  if (widget.state.lastConnected != null)
                    _buildInfoRow(
                      'Last Connected',
                      _formatTime(widget.state.lastConnected!),
                    ),
                  if (widget.state.lastActivity != null)
                    _buildInfoRow(
                      'Last Activity',
                      _formatTime(widget.state.lastActivity!),
                    ),
                  _buildInfoRow(
                    'Tool Calls',
                    widget.state.toolCallCount.toString(),
                  ),
                  if (widget.state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.state.errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (widget.state.availableTools.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Available Tools:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: widget.state.availableTools
                          .map((tool) => Chip(
                                label: Text(
                                  tool.name,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11),
            ),
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
        return 'Connecting';
      case MCPConnectionStatus.error:
        return 'Error';
      case MCPConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}
