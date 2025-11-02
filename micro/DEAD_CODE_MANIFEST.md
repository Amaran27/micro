# Dead Code Organization Plan
# Generated: 11/01/2025 22:53:31

## Files to be removed (experimental/incomplete):
### UI Pages (incomplete implementations)
- lib/presentation/pages/permissions_settings_page.dart
- lib/presentation/pages/tool_detail_page.dart
- lib/presentation/pages/simple_enhanced_chat_page.dart (has unused variables)

### Routers (legacy/experimental)
- lib/presentation/routes/simple_app_router.dart
- lib/presentation/routes/minimal_enhanced_router.dart

### Providers (legacy)
- lib/presentation/providers/chat_provider.dart (legacy, has type issues)

### AI Infrastructure (experimental/incomplete)
- lib/infrastructure/ai/providers/zhipuai_chat_model.dart (uses LangChain, incomplete)
- lib/infrastructure/ai/state/active_request_notifier.dart (unused experimental StateNotifier)
- lib/infrastructure/ai/model_selection_notifier.dart (unused, has dead code)

### Autonomous/MCP (experimental)
- lib/infrastructure/mcp/** (entire MCP adapter - experimental)
- lib/infrastructure/autonomous/** (autonomous framework - experimental)

### Already flagged dead code variants
- lib/presentation/pages/unified_provider_settings_new.dart
- lib/presentation/pages/unified_provider_settings_clean.dart

## Status
- These files should be moved to lib/_to_be_removed/
- After testing confirms they're not needed, delete them
- After deletion, remove from analysis_options.yaml exclusions
