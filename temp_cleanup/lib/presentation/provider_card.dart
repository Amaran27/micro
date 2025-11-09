import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:micro/infrastructure/ai/provider_config_model.dart';
import 'package:micro/infrastructure/ai/provider_registry.dart';
import 'package:micro/presentation/providers/provider_config_providers.dart';
import 'package:micro/presentation/dialogs/edit_provider_dialog.dart';

/// Widget displaying a configured AI provider with status, models, and quick actions
class ProviderCard extends ConsumerStatefulWidget {
  final ProviderConfig config;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ProviderCard({
    super.key,
    required this.config,
    this.onEdit,
    this.onDelete,
  });

  @override
  ConsumerState<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends ConsumerState<ProviderCard> {
  /// Get status badge color based on provider state
  Color _getStatusColor() {
    if (!widget.config.isEnabled) {
      return Colors.grey;
    }
    if (!widget.config.isConfigured) {
      return Colors.orange;
    }
    if (!widget.config.testPassed) {
      return Colors.orange;
    }
    return Colors.green;
  }

  /// Get status badge text
  String _getStatusText() {
    if (!widget.config.isEnabled) {
      return 'Disabled';
    }
    if (!widget.config.isConfigured) {
      return 'Not Configured';
    }
    if (!widget.config.testPassed) {
      return 'Test Failed';
    }
    return 'Active';
  }

  /// Get status icon
  IconData _getStatusIcon() {
    if (!widget.config.isEnabled) {
      return Icons.block;
    }
    if (!widget.config.testPassed) {
      return Icons.warning;
    }
    return Icons.check_circle;
  }

  Future<void> _showEditDialog() async {
    showDialog(
      context: context,
      builder: (context) => EditProviderDialog(config: widget.config),
    );
    widget.onEdit?.call();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Provider?'),
        content: Text(
          'Are you sure you want to delete this provider configuration? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(providerStorageServiceProvider)
          .deleteConfig(widget.config.id);
      ref.invalidate(providersConfigProvider);
      widget.onDelete?.call();
    }
  }

  Future<void> _toggleProvider() async {
    await ref.read(providersNotifierProvider).toggleConfig(widget.config.id);
  }

  @override
  Widget build(BuildContext context) {
    final metadata = ProviderRegistry().getProvider(widget.config.providerId);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Provider name + status badge
            Row(
              children: [
                // Provider icon
                if (metadata != null)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: metadata.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        metadata.icon,
                        color: metadata.color,
                        size: 24,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                // Name and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metadata?.name ?? widget.config.providerId,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu button
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        await _showEditDialog();
                        break;
                      case 'delete':
                        await _confirmDelete();
                        break;
                      case 'toggle':
                        await _toggleProvider();
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: const [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            widget.config.isEnabled
                                ? Icons.toggle_on
                                : Icons.toggle_off,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(widget.config.isEnabled ? 'Disable' : 'Enable'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: const [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Provider description
            if (metadata?.description != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  metadata!.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Favorite models
            if (widget.config.favoriteModels.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Favorite Models (${widget.config.favoriteModels.length})',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.config.favoriteModels
                    .take(3) // Show only first 3
                    .map((model) => Chip(
                          label: Text(
                            model,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: metadata?.color.withOpacity(0.1),
                          side: BorderSide(
                            color: metadata?.color ?? Colors.grey,
                            width: 0.5,
                          ),
                        ))
                    .toList(),
              ),
              if (widget.config.favoriteModels.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '+${widget.config.favoriteModels.length - 3} more',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // MCP Integration status
            if (widget.config.mcpEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.dns,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'MCP Integration',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                    ),
                  ],
                ),
              ),
              if (widget.config.mcpServerIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.config.mcpServerIds
                      .map((serverId) => Chip(
                            avatar: Icon(Icons.check_circle, size: 16, color: Colors.green),
                            label: Text(
                              serverId,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            side: BorderSide(
                              color: Colors.blue.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ))
                      .toList(),
                )
              else
                Text(
                  'No MCP servers configured',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                ),
              const SizedBox(height: 12),
            ],

            // Last tested info
            if (widget.config.lastTestedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Tested: ${_formatDate(widget.config.lastTestedAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

            // Quick actions
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showEditDialog,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _toggleProvider,
                      icon: Icon(
                        widget.config.isEnabled
                            ? Icons.toggle_on
                            : Icons.toggle_off,
                        size: 16,
                      ),
                      label:
                          Text(widget.config.isEnabled ? 'Disable' : 'Enable'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
