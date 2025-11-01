import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor your activity and insights',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              // Stats Cards (Non-scrollable)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Conversations Card
                  _StatCard(
                    icon: Icons.chat,
                    title: 'Conversations',
                    value: '12',
                    subtitle: 'This week',
                    color: Colors.blue,
                  ),

                  // Tools Used Card
                  _StatCard(
                    icon: Icons.build,
                    title: 'Tools Used',
                    value: '8',
                    subtitle: 'This week',
                    color: Colors.orange,
                  ),

                  // Workflows Card
                  _StatCard(
                    icon: Icons.account_tree,
                    title: 'Workflows',
                    value: '3',
                    subtitle: 'Active',
                    color: Colors.purple,
                  ),

                  // Tasks Completed Card
                  _StatCard(
                    icon: Icons.check_circle,
                    title: 'Tasks',
                    value: '24',
                    subtitle: 'Completed',
                    color: Colors.green,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Activity Section Header
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Recent Activity List (Scrollable)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ActivityItem(
                        icon: Icons.chat,
                        title: 'Chat with AI Assistant',
                        subtitle: '2 hours ago',
                        color: Colors.blue,
                      ),
                      _ActivityItem(
                        icon: Icons.build,
                        title: 'Used Weather Tool',
                        subtitle: '5 hours ago',
                        color: Colors.orange,
                      ),
                      _ActivityItem(
                        icon: Icons.account_tree,
                        title: 'Ran Daily Workflow',
                        subtitle: '1 day ago',
                        color: Colors.purple,
                      ),
                      _ActivityItem(
                        icon: Icons.settings,
                        title: 'Updated Settings',
                        subtitle: '2 days ago',
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 24),

                      // Quick Actions Section (Launcher from Home)
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _QuickActionCard(
                            icon: Icons.chat,
                            title: 'Chat',
                            subtitle: 'Talk with Micro',
                            color: Colors.blue,
                            onTap: () => context.go('/chat'),
                          ),
                          _QuickActionCard(
                            icon: Icons.build,
                            title: 'Tools',
                            subtitle: 'Manage tools',
                            color: Colors.orange,
                            onTap: () => context.go('/simple-tools'),
                          ),
                          _QuickActionCard(
                            icon: Icons.smart_toy,
                            title: 'Agents',
                            subtitle: 'Manage agents',
                            color: Colors.purple,
                            onTap: () => context.go('/agents'),
                          ),
                          _QuickActionCard(
                            icon: Icons.account_tree,
                            title: 'Workflows',
                            subtitle: 'Automate tasks',
                            color: Colors.teal,
                            onTap: () => context.go('/workflows'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(
          icon,
          color: color,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
