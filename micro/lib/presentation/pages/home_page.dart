import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to Micro',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy-first personal assistant',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Chat Button
                  _ActionCard(
                    icon: Icons.chat,
                    title: 'Chat',
                    subtitle: 'Talk with Micro',
                    color: Colors.blue,
                    onTap: () => context.go('/chat'),
                  ),

                  // Dashboard Button
                  _ActionCard(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    subtitle: 'View insights',
                    color: Colors.green,
                    onTap: () => context.go('/dashboard'),
                  ),

                  // Tools Button
                  _ActionCard(
                    icon: Icons.build,
                    title: 'Tools',
                    subtitle: 'Manage tools',
                    color: Colors.orange,
                    onTap: () => context.go('/simple-tools'),
                  ),

                  // Simple Chat Button
                  _ActionCard(
                    icon: Icons.chat,
                    title: 'AI Chat',
                    subtitle: 'Simple AI chat',
                    color: Colors.blue,
                    onTap: () => context.go('/simple-chat'),
                  ),

                  // Workflows Button
                  _ActionCard(
                    icon: Icons.account_tree,
                    title: 'Workflows',
                    subtitle: 'Automate tasks',
                    color: Colors.purple,
                    onTap: () => context.go('/workflows'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
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
