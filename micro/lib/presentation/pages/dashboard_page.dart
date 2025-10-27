import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

              // Stats Cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
              ),

              const SizedBox(height: 24),

              // Recent Activity Section
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
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
                  ],
                ),
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
