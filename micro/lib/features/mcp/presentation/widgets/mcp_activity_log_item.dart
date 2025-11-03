import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Model for MCP activity log entry
class MCPActivityLogEntry {
  final String id;
  final DateTime timestamp;
  final String serverName;
  final String toolName;
  final MCPActivityStatus status;
  final Map<String, dynamic>? parameters;
  final dynamic result;
  final String? error;
  final int? durationMs;

  const MCPActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.serverName,
    required this.toolName,
    required this.status,
    this.parameters,
    this.result,
    this.error,
    this.durationMs,
  });
}

/// Status of MCP activity
enum MCPActivityStatus {
  pending,
  running,
  success,
  failed,
}

/// Widget for displaying a single MCP activity log entry
class MCPActivityLogItem extends StatefulWidget {
  final MCPActivityLogEntry entry;

  const MCPActivityLogItem({
    super.key,
    required this.entry,
  });

  @override
  State<MCPActivityLogItem> createState() => _MCPActivityLogItemState();
}

class _MCPActivityLogItemState extends State<MCPActivityLogItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(widget.entry.status);
    final icon = _getStatusIcon(widget.entry.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.entry.toolName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (widget.entry.durationMs != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${widget.entry.durationMs}ms',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.dns, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.entry.serverName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(widget.entry.timestamp),
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 20,
              ),
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parameters
                  if (widget.entry.parameters != null &&
                      widget.entry.parameters!.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Parameters:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => _copyToClipboard(
                            widget.entry.parameters.toString(),
                          ),
                          tooltip: 'Copy parameters',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatJson(widget.entry.parameters!),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Result or Error
                  if (widget.entry.status == MCPActivityStatus.success &&
                      widget.entry.result != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Result:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => _copyToClipboard(
                            widget.entry.result.toString(),
                          ),
                          tooltip: 'Copy result',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.entry.result.toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],

                  if (widget.entry.status == MCPActivityStatus.failed &&
                      widget.entry.error != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Error:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () => _copyToClipboard(
                            widget.entry.error!,
                          ),
                          tooltip: 'Copy error',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.entry.error!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontFamily: 'monospace',
                        ),
                      ),
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

  Color _getStatusColor(MCPActivityStatus status) {
    switch (status) {
      case MCPActivityStatus.pending:
        return Colors.grey;
      case MCPActivityStatus.running:
        return Colors.orange;
      case MCPActivityStatus.success:
        return Colors.green;
      case MCPActivityStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(MCPActivityStatus status) {
    switch (status) {
      case MCPActivityStatus.pending:
        return Icons.schedule;
      case MCPActivityStatus.running:
        return Icons.refresh;
      case MCPActivityStatus.success:
        return Icons.check_circle;
      case MCPActivityStatus.failed:
        return Icons.error;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    return json.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
