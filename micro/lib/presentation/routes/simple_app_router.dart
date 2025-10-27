import 'package:go_router/go_router.dart';

import '../pages/home_page.dart';
import '../pages/dashboard_page.dart';
import '../pages/simple_chat_page.dart';
import '../pages/simple_enhanced_chat_page.dart';
import '../pages/tools_page.dart';
import '../pages/settings_page.dart';

/// Simple app router
class SimpleAppRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/simple-chat',
        name: 'simple-chat',
        builder: (context, state) => const SimpleChatPage(),
      ),
      GoRoute(
        path: '/enhanced-chat',
        name: 'enhanced-chat',
        builder: (context, state) => const SimpleEnhancedChatPage(),
      ),
      GoRoute(
        path: '/simple-tools',
        name: 'simple-tools',
        builder: (context, state) => const ToolsPage(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
