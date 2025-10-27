import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../config/app_config.dart';
import '../pages/home_page.dart';
import '../pages/enhanced_ai_chat_page.dart';
import '../pages/dashboard_page.dart';
import '../widgets/simple_tools_page.dart';
import '../pages/settings_page.dart';
import '../pages/workflows_page.dart';
import '../pages/onboarding_page.dart';
import '../pages/unified_provider_settings.dart';
import '../providers/app_providers.dart';

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
          // Home
          GoRoute(
            path: RouteConstants.home,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),

          // Chat
          GoRoute(
            path: RouteConstants.chat,
            name: 'chat',
            builder: (context, state) => const EnhancedAIChatPage(),
          ),

          // Dashboard
          GoRoute(
            path: RouteConstants.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
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
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
      route: RouteConstants.home,
    ),
    NavigationItem(
      icon: Icons.chat_outlined,
      selectedIcon: Icons.chat,
      label: 'Chat',
      route: RouteConstants.chat,
    ),
    NavigationItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: RouteConstants.dashboard,
    ),
    NavigationItem(
      icon: Icons.build_outlined,
      selectedIcon: Icons.build,
      label: 'Tools',
      route: RouteConstants.tools,
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
