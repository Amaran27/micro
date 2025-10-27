import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/minimal_enhanced_router.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp.router(
        router: MinimalEnhancedAIRouter.router,
        title: '🤖 Minimal Enhanced AI - Maximum Coverage',
        debugShowCheckedModeBanner: true,
      ),
    ),
  );
}