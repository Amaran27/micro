import 'package:go_router/go_router.dart';

import '../pages/home_page.dart';
import '../pages/enhanced_chat_page.dart';

/// Minimal enhanced AI app router
class MinimalEnhancedAIRouter {
  static final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/minimal-enhanced-ai',
        name: 'minimal-enhanced-ai',
        builder: (context, state) => const EnhancedChatPage(),
      ),
    ],
  );
}
