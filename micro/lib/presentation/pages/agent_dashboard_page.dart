import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:micro/infrastructure/ai/agent/agent_types.dart';
import 'package:micro/infrastructure/ai/agent/agent_providers.dart';
import 'package:micro/presentation/widgets/agent_status_widget.dart';
import 'package:micro/presentation/widgets/agent_execution_widget.dart';
import 'package:micro/presentation/widgets/agent_memory_widget.dart';
import 'package:micro/presentation/widgets/agent_creation_dialog.dart';
import 'package:micro/infrastructure/ai/mcp/mcp_providers.dart';
import 'package:micro/infrastructure/ai/mcp/models/mcp_models.dart';
import 'package:micro/features/mcp/presentation/widgets/mcp_server_status_widget.dart';
import 'package:micro/features/mcp/presentation/widgets/mcp_activity_log_item.dart';

/// Main dashboard page for autonomous agent management
class AgentDashboardPage extends ConsumerStatefulWidget {
  const AgentDashboardPage({super.key});

  @override
  ConsumerState<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends ConsumerState<AgentDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedAgentId = 'default';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autonomous Agent Dashboard'),
        actions: [
          IconButton(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh All',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create Agent'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Execute'),
            Tab(text: 'Memory'),
            Tab(text: 'MCP', icon: Icon(Icons.dns, size: 16)),
          ],
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final agentsAsync = ref.watch(agentManagementProvider);

          return switch (agentsAsync) {
            AsyncData(:final value) => _buildTabContent(value),
            AsyncError(:final error) => _buildErrorView(error),
            AsyncLoading() => const _LoadingView(),
          };
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAgentCreationDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Agent'),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> agentData) {
    return Column(
      children: [
        _buildAgentSelector(agentData),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildExecuteTab(),
              _buildMemoryTab(),
              _buildMCPTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAgentSelector(Map<String, dynamic> agentData) {
    final agents = List<String>.from(agentData['agents'] ?? []);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.smart_toy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<String>(
                value: _selectedAgentId,
                isExpanded: true,
                underline: Container(),
                items: [
                  const DropdownMenuItem(
                    value: 'default',
                    child: Text('Default Agent'),
                  ),
                  ...agents.map((agentId) => DropdownMenuItem(
                        value: agentId,
                        child: Text('Agent: $agentId'),
                      )),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAgentId = value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${agents.length + 1} agents',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAgentStatusSection(),
          const SizedBox(height: 24),
          _buildQuickActionsSection(),
          const SizedBox(height: 24),
          _buildRecentActivitySection(),
          const SizedBox(height: 24),
          _buildPerformanceSection(),
        ],
      ),
    );
  }

  Widget _buildExecuteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentExecutionWidget(
            agentId: _selectedAgentId,
            onExecutionComplete: _refreshAll,
          ),
          const SizedBox(height: 24),
          _buildExecutionHistorySection(),
        ],
      ),
    );
  }

  Widget _buildMemoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AgentMemoryWidget(
            agentId: _selectedAgentId,
            allowSearch: true,
            allowExport: true,
            allowAddMemory: true,
          ),
          const SizedBox(height: 24),
          _buildMemoryStatsSection(),
        ],
      ),
    );
  }

  Widget _buildAgentStatusSection() {
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
                  'Agent Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _refreshAgentStatus,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AgentStatusWidget(
              agentId: _selectedAgentId,
              showMetrics: true,
              showHistory: false,
              onRefresh: _refreshAgentStatus,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
              children: [
                _QuickActionButton(
                  icon: Icons.search,
                  label: 'Research',
                  onPressed: () => _executeQuickAction('research'),
                  color: Colors.blue,
                ),
                _QuickActionButton(
                  icon: Icons.analytics,
                  label: 'Analyze',
                  onPressed: () => _executeQuickAction('analyze'),
                  color: Colors.purple,
                ),
                _QuickActionButton(
                  icon: Icons.checklist,
                  label: 'Plan',
                  onPressed: () => _executeQuickAction('plan'),
                  color: Colors.green,
                ),
                _QuickActionButton(
                  icon: Icons.play_arrow,
                  label: 'Execute',
                  onPressed: () => _executeQuickAction('execute'),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildRecentActivitySection() {
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
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.go('/agents/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AgentStatusWidget(
              agentId: _selectedAgentId,
              showMetrics: false,
              showHistory: true,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildPerformanceSection() {
    return Consumer(
      builder: (context, ref, child) {
        final managementAsync = ref.watch(agentManagementProvider);

        return managementAsync.when(
          data: (managementData) {
            // Build performance content with placeholder data for now
            return _buildPerformanceContent({
              'memory_statistics': {'entries': 0, 'types': {}},
              'execution_count': 0,
              'success_rate': 0.0,
              'average_steps': 0.0,
            });
          },
          error: (error, stack) => Text(
            'Error loading performance: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildPerformanceContent(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Analytics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildPerformanceChart(stats),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 300.ms);
  }

  Widget _buildPerformanceChart(Map<String, dynamic> stats) {
    final successRate = (stats['success_rate'] as double) * 100;
    final averageSteps = stats['average_steps'] as double;
    final executionCount = stats['execution_count'] as int;

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Success Rate Gauge
          Expanded(
            child: Column(
              children: [
                Text(
                  'Success Rate',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: successRate / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            successRate > 80
                                ? Colors.green
                                : successRate > 60
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      Text(
                        '${successRate.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats Column
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PerformanceStat(
                  label: 'Total Executions',
                  value: '$executionCount',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                _PerformanceStat(
                  label: 'Average Steps',
                  value: averageSteps.toStringAsFixed(1),
                  color: Colors.purple,
                ),
                const SizedBox(height: 16),
                _PerformanceStat(
                  label: 'Memory Entries',
                  value: '${stats['memory_statistics']?['total_entries'] ?? 0}',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionHistorySection() {
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
                  'Execution History',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  onPressed: _clearExecutionHistory,
                  icon: const Icon(Icons.clear_all),
                  tooltip: 'Clear History',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer(
              builder: (context, ref, child) {
                final historyAsync = ref.watch(agentHistoryProvider);

                return switch (historyAsync) {
                  AsyncData(:final value) => _buildHistoryList(value),
                  AsyncError(:final error) => Text(
                      'Error loading history: $error',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  AsyncLoading() => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                };
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<AgentExecution> history) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('No execution history yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final execution = history[index];
        return _ExecutionHistoryItem(execution: execution);
      },
    );
  }

  Widget _buildMemoryStatsSection() {
    return Consumer(
      builder: (context, ref, child) {
        final managementAsync = ref.watch(agentManagementProvider);

        return managementAsync.when(
          data: (managementData) {
            // Build memory stats content with placeholder data for now
            return _buildMemoryStatsContent({
              'total_entries': 0,
              'episodic': 0,
              'semantic': 0,
              'procedural': 0,
              'working': 0,
            });
          },
          error: (error, stack) => Text(
            'Error loading memory stats: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }

  Widget _buildMemoryStatsContent(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Memory Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Total Memories',
                    value: '${stats['total_entries'] ?? 0}',
                    icon: Icons.memory,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'High Relevance',
                    value: '${stats['high_relevance_count'] ?? 0}',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Recent Memories',
                    value: '${stats['recent_memories_count'] ?? 0}',
                    icon: Icons.access_time,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MemoryStatCard(
                    label: 'Pruned Memories',
                    value: '${stats['pruned_memories_count'] ?? 0}',
                    icon: Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCPTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MCP Integration',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor and manage Model Context Protocol server connections',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          _buildMCPConnectionsSection(),
          const SizedBox(height: 24),
          _buildMCPActivitySection(),
          const SizedBox(height: 24),
          _buildMCPStatisticsSection(),
        ],
      ),
    );
  }

  Widget _buildMCPConnectionsSection() {
    final serverConfigsAsync = ref.watch(mcpServerConfigsProvider);
    final serverStatesAsync = ref.watch(mcpServerStatesProvider);

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
                  'Connected Servers',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to MCP settings
                    context.push('/settings/mcp');
                  },
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            serverConfigsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Error: $error'),
                    ],
                  ),
                ),
              ),
              data: (configs) {
                if (configs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.dns_outlined,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No MCP servers configured',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add MCP servers to extend agent capabilities',
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/settings/mcp'),
                            icon: const Icon(Icons.add),
                            label: const Text('Add MCP Server'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return serverStatesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      _buildServerList(configs, []),
                  data: (states) => _buildServerList(configs, states),
                );
              },
            ),
          ],
        ),
      ),
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

        return MCPServerStatusWidget(
          config: config,
          state: state,
          onDisconnect: () async {
            await ref.read(mcpOperationsProvider.notifier).disconnectServer(config.id);
          },
        );
      }).toList(),
    );
  }

  Widget _buildMCPActivitySection() {
    // Mock activity data for now - will be replaced with real data
    final mockActivities = <MCPActivityLogEntry>[
      MCPActivityLogEntry(
        id: '1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        serverName: 'Filesystem',
        toolName: 'read_file',
        status: MCPActivityStatus.success,
        parameters: {'path': '/home/user/document.txt'},
        result: 'File content here...',
        durationMs: 125,
      ),
      MCPActivityLogEntry(
        id: '2',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        serverName: 'GitHub',
        toolName: 'search_repos',
        status: MCPActivityStatus.success,
        parameters: {'query': 'flutter mcp'},
        result: {'repos': ['repo1', 'repo2']},
        durationMs: 523,
      ),
      MCPActivityLogEntry(
        id: '3',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        serverName: 'Brave Search',
        toolName: 'web_search',
        status: MCPActivityStatus.failed,
        parameters: {'query': 'test query'},
        error: 'Connection timeout',
        durationMs: 5000,
      ),
    ];

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
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Clear activity log
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (mockActivities.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No activity yet',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tool calls will appear here',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: mockActivities
                    .map((activity) => MCPActivityLogItem(entry: activity))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCPStatisticsSection() {
    // Mock statistics - will be replaced with real data
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Tool Calls',
                    value: '3',
                    icon: Icons.build,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Success Rate',
                    value: '67%',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Avg Duration',
                    value: '1.2s',
                    icon: Icons.speed,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    label: 'Active Servers',
                    value: '2',
                    icon: Icons.dns,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Agents',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _refreshAll() {
    ref.invalidate(agentManagementProvider);
    ref.invalidate(agentHistoryProvider);
    ref.invalidate(agentServiceProvider);
  }

  void _refreshAgentStatus() {
    ref.invalidate(defaultAgentStatusProvider);
  }

  void _executeQuickAction(String action) {
    _tabController.animateTo(1); // Switch to Execute tab
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (action) {
        case 'research':
        case 'analyze':
        case 'plan':
        case 'execute':
          // Quick action execution would go here
          break;
        default:
          // Default action
          break;
      }
      // You would need to pass this goal to the execution widget
    });
  }

  void _showAgentCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => AgentCreationDialog(
        onAgentCreated: _refreshAll,
      ),
    );
  }

  void _clearExecutionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Execution History'),
        content: const Text(
            'Are you sure you want to clear all execution history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Clear history implementation
              Navigator.of(context).pop();
              _refreshAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String value) {
    switch (value) {
      case 'create':
        _showAgentCreationDialog();
        break;
      case 'settings':
        context.go('/agents/settings');
        break;
      case 'help':
        context.go('/agents/help');
        break;
    }
  }
}

/// Quick action button widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}

/// Performance stat widget
class _PerformanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PerformanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Memory stat card widget
class _MemoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MemoryStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Execution history item widget
class _ExecutionHistoryItem extends StatelessWidget {
  final AgentExecution execution;

  const _ExecutionHistoryItem({required this.execution});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          execution.result.success ? Icons.check_circle : Icons.error,
          color: execution.result.success ? Colors.green : Colors.red,
        ),
        title: Text(
          execution.goal,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text('${execution.result.steps.length} steps'),
            const SizedBox(width: 8),
            Text('•'),
            const SizedBox(width: 8),
            Text(_formatDuration(execution.duration)),
          ],
        ),
        trailing: Text(
          _formatTimestamp(execution.startTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: () => _showExecutionDetails(context, execution),
      ),
    );
  }

  void _showExecutionDetails(BuildContext context, AgentExecution execution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(execution.goal),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: execution.result.steps.length,
            itemBuilder: (context, index) {
              final step = execution.result.steps[index];
              return _StepExpansionTile(step: step);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
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

/// Step expansion tile widget
class _StepExpansionTile extends StatelessWidget {
  final AgentStep step;

  const _StepExpansionTile({required this.step});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (step.type) {
      AgentStepType.planning => (Icons.map, Colors.blue),
      AgentStepType.reasoning => (Icons.lightbulb, Colors.purple),
      AgentStepType.toolExecution => (Icons.build, Colors.orange),
      AgentStepType.reflection => (Icons.auto_graph, Colors.green),
      AgentStepType.finalization => (Icons.flag, Colors.teal),
      AgentStepType.errorRecovery => (Icons.error, Colors.red),
    };

    return ExpansionTile(
      leading: Icon(icon, color: color),
      title: Text(step.description),
      subtitle: Text('${step.duration.inMilliseconds}ms'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (step.input != null) ...[
                const Text('Input:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(step.input.toString()),
                const SizedBox(height: 8),
              ],
              if (step.output != null) ...[
                const Text('Output:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(step.output.toString()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Loading view widget
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text('Loading agents...'),
        ],
      ),
    );
  }
}
