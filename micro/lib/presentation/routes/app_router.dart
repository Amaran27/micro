import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../config/app_config.dart';
import '../pages/enhanced_ai_chat_page.dart';
import '../pages/dashboard_page.dart';
import '../widgets/simple_tools_page.dart';
import '../pages/settings_page.dart';
import '../pages/workflows_page.dart';
import '../pages/onboarding_page.dart';
import '../pages/unified_provider_settings.dart';
import '../providers/app_providers.dart';
import '../pages/agent_dashboard_page.dart';

class AppRouter {
  static final GoRouter _router = GoRouter(
    initialLocation: RouteConstants.onboarding,
    debugLogDiagnostics: AppConfig.environment == Environment.development,
    routes: [
      // Onboarding
      GoRoute(
        path: RouteConstants.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // Main Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationPage(child: child);
        },
        routes: [
          // Dashboard (Landing page - replaces Home)
          GoRoute(
            path: RouteConstants.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),

          // Chat
          GoRoute(
            path: RouteConstants.chat,
            name: 'chat',
            builder: (context, state) => const EnhancedAIChatPage(),
          ),

          // Tools
          GoRoute(
            path: RouteConstants.tools,
            name: 'tools',
            builder: (context, state) => const SimpleToolsPage(),
          ),

          // Workflows
          GoRoute(
            path: RouteConstants.workflows,
            name: 'workflows',
            builder: (context, state) => const WorkflowsPage(),
          ),

          // Settings
          GoRoute(
            path: RouteConstants.settings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
            routes: [
              // AI Providers
              GoRoute(
                path: 'providers',
                name: 'providers',
                builder: (context, state) => const UnifiedProviderSettings(),
              ),
            ],
          ),

          // Home route kept for backward compatibility (redirects to dashboard)
          GoRoute(
            path: RouteConstants.home,
            name: 'home',
            redirect: (context, state) => RouteConstants.dashboard,
          ),

          // Workflow Detail
          GoRoute(
            path: RouteConstants.workflowDetail,
            name: 'workflow_detail',
            builder: (context, state) {
              final workflowId = state.pathParameters['id']!;
              return WorkflowDetailPage(workflowId: workflowId);
            },
          ),

          // Tool Detail
          GoRoute(
            path: RouteConstants.toolDetail,
            name: 'tool_detail',
            builder: (context, state) {
              final toolId = state.pathParameters['id']!;
              return ToolDetailPage(toolId: toolId);
            },
          ),

          // Audit
          GoRoute(
            path: RouteConstants.audit,
            name: 'audit',
            builder: (context, state) => const AuditPage(),
          ),

          // Agents
          GoRoute(
            path: RouteConstants.agents,
            name: 'agents',
            redirect: (context, state) => RouteConstants.agentDashboard,
          ),

          // Agent Dashboard
          GoRoute(
            path: RouteConstants.agentDashboard,
            name: 'agent_dashboard',
            builder: (context, state) => const AgentDashboardPage(),
          ),

          // Agent Detail
          GoRoute(
            path: RouteConstants.agentDetail,
            name: 'agent_detail',
            builder: (context, state) {
              final agentId = state.pathParameters['id']!;
              return AgentDetailPage(agentId: agentId);
            },
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => ErrorPage(error: state.error),

    // Redirects
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final isOnboardingComplete =
          container.read(onboardingCompleteSyncProvider);
      final currentPath = state.uri.toString();

      // If onboarding is not complete and user is not on onboarding page, redirect to onboarding
      if (!isOnboardingComplete &&
          !currentPath.startsWith(RouteConstants.onboarding)) {
        return RouteConstants.onboarding;
      }

      // If onboarding is complete and user is on onboarding page, redirect to home
      if (isOnboardingComplete &&
          currentPath.startsWith(RouteConstants.onboarding)) {
        return RouteConstants.home;
      }

      return null;
    },
  );

  static GoRouter get router => _router;
}

class MainNavigationPage extends StatefulWidget {
  final Widget child;

  const MainNavigationPage({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: RouteConstants.dashboard,
    ),
    NavigationItem(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      label: 'Chat',
      route: RouteConstants.chat,
    ),
    NavigationItem(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      label: 'Tools',
      route: RouteConstants.tools,
    ),
    NavigationItem(
      icon: Icons.smart_toy_outlined,
      selectedIcon: Icons.smart_toy,
      label: 'Agents',
      route: RouteConstants.agents,
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
      route: RouteConstants.settings,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location.startsWith(_navigationItems[i].route)) {
        setState(() {
          _currentIndex = i;
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current route to determine the index
    final location =
        GoRouter.of(context).routeInformationProvider.value.uri.toString();
    for (int i = 0; i < _navigationItems.length; i++) {
      if (location.startsWith(_navigationItems[i].route)) {
        _currentIndex = i;
        break;
      }
    }

    // Don't show AppBar for chat page as it has its own header
    final showAppBar = !location.startsWith(RouteConstants.chat);

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(_navigationItems[_currentIndex].label),
              elevation: 0,
            )
          : null,
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          final item = _navigationItems[index];
          context.go(item.route);
        },
        destinations: _navigationItems.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

// Placeholder pages for routes that don\'t exist yet
class AgentDetailPage extends StatelessWidget {
  final String agentId;

  const AgentDetailPage({
    super.key,
    required this.agentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Agent: $agentId'),
      ),
      body: Center(
        child: Text('Agent Detail Page\nID: $agentId'),
      ),
    );
  }
}

class WorkflowDetailPage extends StatelessWidget {
  final String workflowId;

  const WorkflowDetailPage({
    super.key,
    required this.workflowId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workflow: $workflowId'),
      ),
      body: Center(
        child: Text('Workflow Detail Page\nID: $workflowId'),
      ),
    );
  }
}

class ToolDetailPage extends StatelessWidget {
  final String toolId;

  const ToolDetailPage({
    super.key,
    required this.toolId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tool: $toolId'),
      ),
      body: Center(
        child: Text('Tool Detail Page\nID: $toolId'),
      ),
    );
  }
}

class AuditPage extends StatelessWidget {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
      ),
      body: const Center(
        child: Text('Audit Log Page'),
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final Exception? error;

  const ErrorPage({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'An error occurred',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(RouteConstants.home),
                child: const Text('Go Home'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
