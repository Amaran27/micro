import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/minimal_enhanced_router.dart';

/// Working enhanced AI app with comprehensive LLM provider
void main() {
  runApp(
    ProviderScope(
      child: MaterialApp.router(
        router: MinimalEnhancedAIRouter.router,
        title: '🤖 Enhanced AI Chat - Comprehensive LLM System',
        debugShowCheckedModeBanner: true,
      ),
    ),
  );
}