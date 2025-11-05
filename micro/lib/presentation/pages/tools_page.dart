import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../infrastructure/ai/mcp/mcp_providers.dart';
import '../../infrastructure/ai/mcp/models/mcp_models.dart';
import '../../infrastructure/ai/mcp/recommended_servers.dart';

/// Tools Page - Manages MCP Servers and Tools per Micro 2.0 spec
/// Tab 1: Servers (discovery + management)
/// Tab 2: Tools (per-server tool enable/disable)
class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key});

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  Set<String> _platformFilters = {'All'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_circle,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'MCP Tools',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage servers and configure tools for Micro',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimaryContainer
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.dns), text: 'Servers'),
                Tab(icon: Icon(Icons.extension), text: 'Tools'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ServersTab(
                  searchQuery: _searchQuery,
                  platformFilters: _platformFilters,
                  onSearchChanged: (query) => setState(() => _searchQuery = query),
                  onFiltersChanged: (filters) => setState(() => _platformFilters = filters),
                ),
                const _ToolsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Servers Tab - Discovery + Management combined
class _ServersTab extends ConsumerWidget {
  final String searchQuery;
  final Set<String> platformFilters;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Set<String>> onFiltersChanged;

  const _ServersTab({
    required this.searchQuery,
    required this.platformFilters,
    required this.onSearchChanged,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(mcpServerConfigsProvider);
    final statesAsync = ref.watch(mcpServerStatesProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mcpServerConfigsProvider);
        ref.invalidate(mcpServerStatesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search and Filters
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search servers...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 12),
          
          // Platform Filters
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: platformFilters.contains('All'),
                onSelected: (selected) {
                  if (selected) {
                    onFiltersChanged({'All'});
                  }
                },
              ),
              FilterChip(
                label: const Text('Desktop'),
                selected: platformFilters.contains('Desktop'),
                onSelected: (selected) {
                  final newFilters = Set<String>.from(platformFilters)..remove('All');
                  if (selected) {
                    newFilters.add('Desktop');
                  } else {
                    newFilters.remove('Desktop');
                  }
                  if (newFilters.isEmpty) newFilters.add('All');
                  onFiltersChanged(newFilters);
                },
              ),
              FilterChip(
                label: const Text('Mobile'),
                selected: platformFilters.contains('Mobile'),
                onSelected: (selected) {
                  final newFilters = Set<String>.from(platformFilters)..remove('All');
                  if (selected) {
                    newFilters.add('Mobile');
                  } else {
                    newFilters.remove('Mobile');
                  }
                  if (newFilters.isEmpty) newFilters.add('All');
                  onFiltersChanged(newFilters);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Discover Section
          Text(
            'Discover MCP Servers',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildDiscoveryGrid(context, ref),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Configured Servers Section
          configsAsync.when(
            data: (configs) {
              if (configs.isEmpty) {
                return _buildEmptyConfigured(context);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Configured Servers (${configs.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text Chip(
                        label: Text('${_getConnectedCount(ref, configs)} connected'),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        labelStyle: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...configs.map((config) => _buildServerCard(context, ref, config)),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryGrid(BuildContext context, WidgetRef ref) {
    // Filter recommended servers
    var servers = getRecommendedServers();
    
    if (!platformFilters.contains('All')) {
      servers = servers.where((s) {
        if (platformFilters.contains('Desktop') && s.platform == MCPServerPlatform.desktop) return true;
        if (platformFilters.contains('Mobile') && s.platform == MCPServerPlatform.mobile) return true;
        if (platformFilters.contains('Desktop') && platformFilters.contains('Mobile') && s.platform == MCPServerPlatform.both) return true;
        return false;
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      servers = servers.where((s) =>
        s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        s.description.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showServerDetails(context, ref, server),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dns, color: Theme.of(context).colorScheme.primary),
                      const Spacer(),
                      _buildPlatformBadge(context, server.platform),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    server.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    server.description,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _configureServer(context, ref, server),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add', style: TextStyle(fontSize: 12)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlatformBadge(BuildContext context, MCPServerPlatform platform) {
    String label;
    Color color;
    
    switch (platform) {
      case MCPServerPlatform.desktop:
        label = 'Desktop';
        color = Colors.blue;
        break;
      case MCPServerPlatform.mobile:
        label = 'Mobile';
        color = Colors.green;
        break;
      case MCPServerPlatform.both:
        label = 'Both';
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyConfigured(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.dns_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Servers Configured',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add servers from the discovery section above',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerCard(BuildContext context, WidgetRef ref, MCPServerConfig config) {
    final statesAsync = ref.watch(mcpServerStatesProvider);
    final state = statesAsync.value?.firstWhere(
      (s) => s.serverId == config.id,
      orElse: () => MCPServerState(
        serverId: config.id,
        status: MCPConnectionStatus.disconnected,
        availableTools: [],
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildStatusIndicator(state?.status ?? MCPConnectionStatus.disconnected),
        title: Text(config.name),
        subtitle: Text(
          '${config.transportType.toString().split('.').last.toUpperCase()} • '
          '${state?.availableTools.length ?? 0} tools',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state?.status == MCPConnectionStatus.connected)
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.red),
                onPressed: () => _disconnectServer(ref, config.id),
                tooltip: 'Disconnect',
              )
            else
              IconButton(
                icon: const Icon(Icons.power_settings_new, color: Colors.green),
                onPressed: () => _connectServer(ref, config.id),
                tooltip: 'Connect',
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'test', child: Text('Test Connection')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editServer(context, ref, config);
                    break;
                  case 'test':
                    _testServer(ref, config.id);
                    break;
                  case 'delete':
                    _deleteServer(context, ref, config.id);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(MCPConnectionStatus status) {
    Color color;
    switch (status) {
      case MCPConnectionStatus.connected:
        color = Colors.green;
        break;
      case MCPConnectionStatus.connecting:
        color = Colors.orange;
        break;
      case MCPConnectionStatus.error:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: status == MCPConnectionStatus.connected
            ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4, spreadRadius: 1)]
            : null,
      ),
    );
  }

  int _getConnectedCount(WidgetRef ref, List<MCPServerConfig> configs) {
    final states = ref.watch(mcpServerStatesProvider).value ?? [];
    return states.where((s) => s.status == MCPConnectionStatus.connected).length;
  }

  void _showServerDetails(BuildContext context, WidgetRef ref, RecommendedMCPServer server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(server.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(server.description),
            const SizedBox(height: 16),
            Text('Transport: ${server.transportType.toString().split('.').last.toUpperCase()}'),
            Text('Platform: ${server.platform.toString().split('.').last}'),
            if (server.docUrl != null) ...[
              const SizedBox(height: 8),
              Text('Documentation: ${server.docUrl}', style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _configureServer(context, ref, server);
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _configureServer(BuildContext context, WidgetRef ref, RecommendedMCPServer server) {
    context.push('/settings/mcp'); // Navigate to MCP settings to add server
  }

  void _connectServer(WidgetRef ref, String serverId) {
    ref.read(mcpOperationsProvider.notifier).connect(serverId);
  }

  void _disconnectServer(WidgetRef ref, String serverId) {
    ref.read(mcpOperationsProvider.notifier).disconnect(serverId);
  }

  void _editServer(BuildContext context, WidgetRef ref, MCPServerConfig config) {
    context.push('/settings/mcp'); // Navigate to edit
  }

  void _testServer(WidgetRef ref, String serverId) {
    ref.read(mcpOperationsProvider.notifier).testConnection(serverId);
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
          FilledButton(
            onPressed: () {
              ref.read(mcpOperationsProvider.notifier).removeServer(serverId);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Tools Tab - Per-server tool enable/disable
class _ToolsTab extends ConsumerStatefulWidget {
  const _ToolsTab();

  @override
  ConsumerState<_ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends ConsumerState<_ToolsTab> {
  String? _selectedServerId;
  final Map<String, Set<String>> _enabledTools = {}; // serverId -> Set of tool IDs

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(mcpServerConfigsProvider);
    final statesAsync = ref.watch(mcpServerStatesProvider);

    return configsAsync.when(
      data: (configs) {
        if (configs.isEmpty) {
          return _buildEmptyState(context);
        }

        return statesAsync.when(
          data: (states) {
            return Column(
              children: [
                // Filter dropdown
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<String>(
                    value: _selectedServerId,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Server',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.filter_list),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Servers')),
                      ...configs.map((config) => DropdownMenuItem(
                        value: config.id,
                        child: Text(config.name),
                      )),
                    ],
                    onChanged: (value) => setState(() => _selectedServerId = value),
                  ),
                ),

                // Tools list
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: configs.where((config) =>
                      _selectedServerId == null || _selectedServerId == config.id
                    ).map((config) {
                      final state = states.firstWhere(
                        (s) => s.serverId == config.id,
                        orElse: () => MCPServerState(
                          serverId: config.id,
                          status: MCPConnectionStatus.disconnected,
                          availableTools: [],
                        ),
                      );
                      return _buildServerToolsSection(context, config, state);
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Tools Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure MCP servers in the Servers tab to see their tools here',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerToolsSection(
    BuildContext context,
    MCPServerConfig config,
    MCPServerState state,
  ) {
    final tools = state.availableTools;
    final isConnected = state.status == MCPConnectionStatus.connected;
    
    // Initialize enabled tools for this server if not present
    if (!_enabledTools.containsKey(config.id)) {
      _enabledTools[config.id] = tools.map((t) => t.name).toSet();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          Icons.dns,
          color: isConnected ? Colors.green : Colors.grey,
        ),
        title: Text(config.name),
        subtitle: Text(
          isConnected
              ? '${tools.length} tools available'
              : 'Disconnected - Connect to see tools',
        ),
        trailing: isConnected
            ? Text(
                '${_enabledTools[config.id]?.length ?? 0}/${tools.length} enabled',
                style: Theme.of(context).textTheme.bodySmall,
              )
            : null,
        children: [
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Connect this server in the Servers tab to manage its tools',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tools available from this server',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...tools.map((tool) => CheckboxListTile(
              title: Text(tool.name),
              subtitle: tool.description != null
                  ? Text(tool.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                  : null,
              value: _enabledTools[config.id]?.contains(tool.name) ?? false,
              onChanged: (enabled) {
                setState(() {
                  if (enabled == true) {
                    _enabledTools[config.id]?.add(tool.name);
                  } else {
                    _enabledTools[config.id]?.remove(tool.name);
                  }
                });
                // TODO: Persist enabled tools state
              },
            )),
        ],
      ),
    );
  }
}
