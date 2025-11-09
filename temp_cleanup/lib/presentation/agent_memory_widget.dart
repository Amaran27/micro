import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart' as agent_types;
import 'package:micro/infrastructure/ai/agent/agent_providers.dart';

/// Widget for viewing and managing agent memory
class AgentMemoryWidget extends ConsumerStatefulWidget {
  final String? agentId;
  final bool allowSearch;
  final bool allowExport;
  final bool allowAddMemory;

  const AgentMemoryWidget({
    super.key,
    this.agentId,
    this.allowSearch = true,
    this.allowExport = true,
    this.allowAddMemory = true,
  });

  @override
  ConsumerState<AgentMemoryWidget> createState() => _AgentMemoryWidgetState();
}

class _AgentMemoryWidgetState extends ConsumerState<AgentMemoryWidget> {
  final _searchController = TextEditingController();
  final _memoryContentController = TextEditingController();
  String _searchQuery = '';
  agent_types.AgentMemoryType? _selectedType;
  bool _showAddMemory = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    _memoryContentController.dispose();
    super.dispose();
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
                  'Agent Memory',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.allowAddMemory)
                  IconButton(
                    onPressed: () =>
                        setState(() => _showAddMemory = !_showAddMemory),
                    icon: Icon(_showAddMemory ? Icons.close : Icons.add),
                    tooltip: 'Add Memory',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_showAddMemory && widget.allowAddMemory) ...[
              _buildAddMemorySection(),
              const SizedBox(height: 16),
            ],
            if (widget.allowSearch) ...[
              _buildSearchSection(),
              const SizedBox(height: 16),
            ],
            _buildMemoryFilter(),
            const SizedBox(height: 16),
            _buildMemoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMemorySection() {
    return Consumer(
      builder: (context, ref, child) {
        final capabilitiesAsync = ref.watch(agentCapabilitiesProvider);

        return switch (capabilitiesAsync) {
          AsyncData() => Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Custom Memory',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<agent_types.AgentMemoryType>(
                      initialValue:
                          _selectedType ?? agent_types.AgentMemoryType.working,
                      items: [
                        ...agent_types.AgentMemoryType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getMemoryTypeLabel(type)),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedType = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Memory Type',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _memoryContentController,
                      decoration: const InputDecoration(
                        labelText: 'Memory Content',
                        hintText: 'Enter the memory content...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _addMemory,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Add Memory'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => setState(() {
                            _showAddMemory = false;
                            _memoryContentController.clear();
                            _selectedType = null;
                          }),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
          AsyncError(:final error) => Text(
              'Error loading memory types: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          AsyncLoading() => const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        };
      },
    );
  }

  Widget _buildSearchSection() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search memories...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        if (widget.allowExport) ...[
          const SizedBox(width: 8),
          IconButton.outlined(
            onPressed: _exportMemories,
            icon: const Icon(Icons.download),
            tooltip: 'Export Memories',
          ),
        ],
      ],
    );
  }

  Widget _buildMemoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Types'),
            selected: _selectedType == null,
            onSelected: (selected) {
              setState(() => _selectedType =
                  selected ? null : agent_types.AgentMemoryType.working);
            },
          ),
          const SizedBox(width: 8),
          ...agent_types.AgentMemoryType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_getMemoryTypeLabel(type)),
                selected: _selectedType == type,
                onSelected: (selected) {
                  setState(() => _selectedType = selected ? type : null);
                },
                avatar: Icon(
                  _getMemoryTypeIcon(type),
                  size: 16,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMemoryList() {
    return Consumer(
      builder: (context, ref, child) {
        if (_searchQuery.isNotEmpty) {
          // Search memories - create a future for the search
          final searchFuture =
              ref.watch(agentManagementProvider.notifier).searchMemories(
                    query: _searchQuery,
                    agentId: widget.agentId,
                    types: _selectedType != null ? [_selectedType!] : null,
                  );

          return FutureBuilder<List<agent_types.AgentMemoryEntry>>(
            future: searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error searching memories: ${snapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                );
              } else if (snapshot.hasData) {
                return _buildMemoryContent(snapshot.data!);
              } else {
                return const Center(
                  child: Text('No search results'),
                );
              }
            },
          );
        } else {
          // Show recent memories
          return const Center(
            child: Text('Enter a search query to find memories'),
          );
        }
      },
    );
  }

  Widget _buildMemoryContent(List<agent_types.AgentMemoryEntry> memories) {
    if (memories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No memories found',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return _MemoryTile(
          memory: memory,
          onTap: () => _showMemoryDetails(context, memory),
        );
      },
    );
  }

  Future<void> _addMemory() async {
    if (_memoryContentController.text.trim().isEmpty || _selectedType == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(agentManagementProvider.notifier);

      await notifier.addMemory(
        type: _selectedType!,
        content: _memoryContentController.text.trim(),
        metadata: {
          'source': 'manual',
          'timestamp': DateTime.now().toIso8601String(),
        },
        agentId: widget.agentId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory added successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        setState(() {
          _showAddMemory = false;
          _memoryContentController.clear();
          _selectedType = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add memory: $e'),
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

  Future<void> _exportMemories() async {
    // Implementation for exporting memories
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memory export functionality coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showMemoryDetails(
      BuildContext context, agent_types.AgentMemoryEntry memory) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getMemoryTypeIcon(memory.type),
                          color: _getMemoryTypeColor(memory.type),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getMemoryTypeLabel(memory.type),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  memory.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (memory.metadata.isNotEmpty) ...[
                  Text(
                    'Metadata',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildMetadataView(memory.metadata),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(memory.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.trending_up, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Relevance: ${memory.relevance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataView(Map<String, dynamic> metadata) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
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

  String _getMemoryTypeLabel(agent_types.AgentMemoryType type) {
    switch (type) {
      case agent_types.AgentMemoryType.conversation:
        return 'Conversation';
      case agent_types.AgentMemoryType.episodic:
        return 'Episodic';
      case agent_types.AgentMemoryType.semantic:
        return 'Semantic';
      case agent_types.AgentMemoryType.working:
        return 'Working';
    }
  }

  IconData _getMemoryTypeIcon(agent_types.AgentMemoryType type) {
    switch (type) {
      case agent_types.AgentMemoryType.conversation:
        return Icons.chat;
      case agent_types.AgentMemoryType.episodic:
        return Icons.timeline;
      case agent_types.AgentMemoryType.semantic:
        return Icons.psychology;
      case agent_types.AgentMemoryType.working:
        return Icons.workspaces;
    }
  }

  Color _getMemoryTypeColor(agent_types.AgentMemoryType type) {
    switch (type) {
      case agent_types.AgentMemoryType.conversation:
        return Colors.green;
      case agent_types.AgentMemoryType.episodic:
        return Colors.purple;
      case agent_types.AgentMemoryType.semantic:
        return Colors.orange;
      case agent_types.AgentMemoryType.working:
        return Colors.blue;
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

/// Memory tile widget
class _MemoryTile extends StatelessWidget {
  final agent_types.AgentMemoryEntry memory;
  final VoidCallback onTap;

  const _MemoryTile({
    required this.memory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _getMemoryTypeColor(memory.type).withValues(alpha: 0.2),
          child: Icon(
            _getMemoryTypeIcon(memory.type),
            color: _getMemoryTypeColor(memory.type),
            size: 20,
          ),
        ),
        title: Text(
          memory.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              _formatTimestamp(memory.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Icon(Icons.trending_up, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              memory.relevance.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (100 * memory.hashCode).ms);
  }

  Color _getMemoryTypeColor(agent_types.AgentMemoryType type) {
    switch (type) {
      case agent_types.AgentMemoryType.conversation:
        return Colors.green;
      case agent_types.AgentMemoryType.episodic:
        return Colors.purple;
      case agent_types.AgentMemoryType.semantic:
        return Colors.orange;
      case agent_types.AgentMemoryType.working:
        return Colors.blue;
    }
  }

  IconData _getMemoryTypeIcon(agent_types.AgentMemoryType type) {
    switch (type) {
      case agent_types.AgentMemoryType.conversation:
        return Icons.chat;
      case agent_types.AgentMemoryType.episodic:
        return Icons.timeline;
      case agent_types.AgentMemoryType.semantic:
        return Icons.psychology;
      case agent_types.AgentMemoryType.working:
        return Icons.workspaces;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
