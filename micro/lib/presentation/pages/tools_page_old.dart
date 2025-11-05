import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../infrastructure/ai/mcp/mcp_providers.dart';
import '../../infrastructure/ai/mcp/models/mcp_models.dart';
import '../../features/mcp/presentation/pages/mcp_server_discovery_page.dart';

/// Tools Page - Central hub for MCP servers and tool management
class ToolsPage extends ConsumerStatefulWidget {
  const ToolsPage({super.key});

  @override
  ConsumerState<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends ConsumerState<ToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          // Header Section
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
                  'Manage MCP servers and discover tools',
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
                Tab(
                  icon: Icon(Icons.dns),
                  text: 'My Servers',
                ),
                Tab(
                  icon: Icon(Icons.explore),
                  text: 'Discover',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MyServersTab(),
                const MCPServerDiscoveryPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/settings/mcp');
        },
        icon: const Icon(Icons.settings),
        label: const Text('Manage Servers'),
      ),
    );
  }
}

class _MyServersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(mcpServerConfigsProvider);
    final statesAsync = ref.watch(mcpServerStatesProvider);

    return configsAsync.when(
      data: (configs) {
        if (configs.isEmpty) {
          return _EmptyServersState();
        }

        return statesAsync.when(
          data: (states) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(mcpServerConfigsProvider);
                ref.invalidate(mcpServerStatesProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Statistics Card
                  _StatisticsCard(
                    totalServers: configs.length,
                    connectedServers: states
                        .where((s) => s.status == MCPConnectionStatus.connected)
                        .length,
                    totalTools: states.fold<int>(
                      0,
                      (sum, state) => sum + state.availableTools.length,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Servers List
                  Text(
                    'Configured Servers',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...configs.map((config) {
                    final state = states.firstWhere(
                      (s) => s.serverId == config.id,
                      orElse: () => MCPServerState(
                        serverId: config.id,
                        status: MCPConnectionStatus.disconnected,
                        availableTools: [],
                      ),
                    );
                    return _ServerCard(config: config, state: state);
                  }),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorState(error: error.toString()),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _ErrorState(error: error.toString()),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final int totalServers;
  final int connectedServers;
  final int totalTools;

  const _StatisticsCard({
    required this.totalServers,
    required this.connectedServers,
    required this.totalTools,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.dns,
              label: 'Servers',
              value: '$connectedServers/$totalServers',
              color: Colors.blue,
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _StatItem(
              icon: Icons.build,
              label: 'Tools',
              value: '$totalTools',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ServerCard extends ConsumerWidget {
  final MCPServerConfig config;
  final MCPServerState state;

  const _ServerCard({
    required this.config,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(state.status);
    final statusText = _getStatusText(state.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          _showServerDetails(context, ref);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      config.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    side: BorderSide.none,
                  ),
                ],
              ),
              if (config.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  config.description!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    _getTransportIcon(config.transportType),
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTransportText(config.transportType),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.build,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.availableTools.length} tools',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showServerDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return _ServerDetailsSheet(
            config: config,
            state: state,
            scrollController: scrollController,
          );
        },
      ),
    );
  }

  Color _getStatusColor(MCPConnectionStatus status) {
    switch (status) {
      case MCPConnectionStatus.connected:
        return Colors.green;
      case MCPConnectionStatus.connecting:
        return Colors.orange;
      case MCPConnectionStatus.disconnected:
        return Colors.grey;
      case MCPConnectionStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(MCPConnectionStatus status) {
    switch (status) {
      case MCPConnectionStatus.connected:
        return 'Connected';
      case MCPConnectionStatus.connecting:
        return 'Connecting';
      case MCPConnectionStatus.disconnected:
        return 'Disconnected';
      case MCPConnectionStatus.error:
        return 'Error';
    }
  }

  IconData _getTransportIcon(MCPTransportType type) {
    switch (type) {
      case MCPTransportType.stdio:
        return Icons.computer;
      case MCPTransportType.http:
        return Icons.http;
      case MCPTransportType.sse:
        return Icons.stream;
    }
  }

  String _getTransportText(MCPTransportType type) {
    switch (type) {
      case MCPTransportType.stdio:
        return 'stdio';
      case MCPTransportType.http:
        return 'HTTP';
      case MCPTransportType.sse:
        return 'SSE';
    }
  }
}

class _ServerDetailsSheet extends ConsumerWidget {
  final MCPServerConfig config;
  final MCPServerState state;
  final ScrollController scrollController;

  const _ServerDetailsSheet({
    required this.config,
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  config.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Available Tools
          Text(
            'Available Tools (${state.availableTools.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          if (state.availableTools.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No tools available'),
              ),
            )
          else
            ...state.availableTools.map((tool) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.build),
                  title: Text(tool.name),
                  subtitle: Text(tool.description ?? 'No description'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            }),
          const SizedBox(height: 24),

          // Actions
          if (state.status == MCPConnectionStatus.disconnected)
            FilledButton.icon(
              onPressed: () async {
                await ref.read(mcpOperationsProvider.notifier).connectServer(config.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.power),
              label: const Text('Connect'),
            )
          else if (state.status == MCPConnectionStatus.connected)
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(mcpOperationsProvider.notifier).disconnectServer(config.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.power_off),
              label: const Text('Disconnect'),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings/mcp');
            },
            icon: const Icon(Icons.settings),
            label: const Text('Manage Server'),
          ),
        ],
      ),
    );
  }
}

class _EmptyServersState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No MCP Servers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first MCP server to start using tools',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                context.push('/settings/mcp');
              },
              icon: const Icon(Icons.add),
              label: const Text('Add MCP Server'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Servers',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
