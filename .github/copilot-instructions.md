# Copilot Instructions for Micro AI Chat

## 1. Architecture Overview

### Clean Architecture Pattern
- **Domain Layer** (`lib/domain/`): Entities, use cases, repository interfaces
- **Infrastructure Layer** (`lib/infrastructure/`): Provider adapters, data sources, external integrations
- **Presentation Layer** (`lib/presentation/`, `lib/features/*/presentation/`): UI pages, widgets, Riverpod providers
- **Feature-Based Modules** (`lib/features/chat/`, `lib/features/settings/`, `lib/features/tools/`): Self-contained functionality

### Data Flow (Critical to Understand)
```
UI (enhanced_ai_chat_page.dart)
  ↓ user action
ChatNotifier (chat_provider.dart) - Riverpod StateNotifier
  ↓ ref.read(aiProvidersProvider)
ProviderAdapter Interface (zhipuai_adapter.dart, chat_google_adapter.dart)
  ↓ converts Micro ↔ LangChain messages
LangChain ChatModel
  ↓ HTTP request via Dio
AI Provider API (Z.AI, OpenAI, Google, etc.)
  ↓ response
Back up the chain with state updates triggering ref.listen
  ↓
UI reactive update via flutter_gen_ai_chat_ui
```

### State Management (Riverpod Patterns)
- **StateNotifier**: Complex state with methods (ChatNotifier, ModelSelectionService)
- **FutureProvider**: Async data loading (aiProvidersProvider, availableModelsProvider)
- **StateProvider**: Simple reactive values (currentSelectedModelProvider)
- **ref.listen**: React to state changes in UI (e.g., `ref.listen<ChatState>(chatProvider, ...)`)

## 2. Critical Files and Their Roles

### Core Chat Functionality
- **`lib/features/chat/presentation/providers/chat_provider.dart`** (441 lines)
  - Central chat state management via ChatNotifier
  - Converts between Micro and LangChain message formats
  - **Known Issue**: Line 153 - `_handleSendMessage()` doesn't check `isLoading` before sending (causes double streaming bug)
  
- **`lib/presentation/pages/enhanced_ai_chat_page.dart`** (1113 lines)
  - Main chat UI using flutter_gen_ai_chat_ui package
  - Uses ref.listen to add messages to _messagesController
  - UI package handles streaming animation (not provider-level streaming)

### AI Provider Infrastructure
- **`lib/infrastructure/ai/adapters/zhipuai_adapter.dart`** (233 lines)
  - Implements ProviderAdapter interface for Z.AI
  - Uses non-streaming `invoke()` method (NOT true streaming at adapter level)
  - Maps Z.AI error codes to user-friendly messages
  
- **`lib/infrastructure/ai/model_selection_service.dart`** (833 lines)
  - Dynamic model discovery from provider APIs
  - Per-provider active model persistence
  - **Known Issue**: Provider alias normalization (zhipuai/z_ai/zhipu-ai) causes storage inconsistencies

- **`lib/config/ai_provider_constants.dart`**
  - Centralized provider configuration
  - API endpoints (general vs coding for Z.AI)
  - Default models, documentation URLs

- **`lib/infrastructure/ai/provider_config_model.dart`**
  - Immutable data model for provider configs
  - Custom models feature (users can add unlisted models)
  - JSON serialization to FlutterSecureStorage

## 3. Development Principles (MUST FOLLOW)

### Evidence-Based Development
1. **Understand Cause and Effect**: Before fixing, analyze the complete code flow
2. **Verify Root Cause**: Use print statements, logs, debugger to confirm hypothesis
3. **No Assumption-Based Fixes**: If you don't know, research the code path first
4. **Document Your Analysis**: Explain WHY a bug occurs, not just HOW to fix it

### Design Principles
- **KISS (Keep It Simple, Stupid)**: Prefer simple solutions over complex abstractions
- **SOLID**:
  - Single Responsibility: Each class has one reason to change
  - Open/Closed: Extend behavior via interfaces (ProviderAdapter), not modification
  - Liskov Substitution: All adapters must be interchangeable
  - Interface Segregation: ProviderAdapter interface is minimal
  - Dependency Inversion: Depend on interfaces, not concrete implementations
- **DRY (Don't Repeat Yourself)**: Extract common patterns (see Roo Code BaseProvider pattern)
- **ACID (for data persistence)**: Ensure atomic, consistent, isolated, durable storage operations

### Code Review Checklist
Before implementing ANY change:
1. ✅ Did you read the relevant code sections?
2. ✅ Do you understand the data flow?
3. ✅ Have you verified the root cause with evidence?
4. ✅ Is your solution the simplest possible?
5. ✅ Does it follow existing patterns in the codebase?
6. ✅ Will it introduce new bugs or break existing functionality?

## 4. Common Patterns and Conventions

### State Management Patterns
```dart
// ✅ GOOD: Check state before async operations
final chatState = ref.read(chatProvider);
if (chatState.isLoading) {
  // Show user feedback, don't proceed
  return;
}

// ✅ GOOD: Use ref.listen for reactive UI updates
ref.listen<ChatState>(chatProvider, (previous, next) {
  if (next.messages.length > (previous?.messages.length ?? 0)) {
    // Handle new messages
  }
});

// ❌ BAD: Calling async without checking state
await chatNotifier.sendMessage(message); // What if already loading?
```

### Provider Integration Pattern
```dart
// All providers implement ProviderAdapter interface
abstract class ProviderAdapter {
  Future<String> sendMessage(String message, List<ChatMessage> history);
  Future<List<String>> getAvailableModels();
  // ...
}

// Adapters convert between formats: Micro ↔ LangChain ↔ API
final langchainMessages = _convertToLangChainMessages(history);
final response = await chatModel.invoke(langchainMessages);
return _convertToMicroFormat(response);
```

### Error Handling Pattern
```dart
// Map provider-specific errors to user-friendly messages
try {
  final response = await adapter.sendMessage(message, history);
} on DioException catch (e) {
  if (e.response?.data['error']['code'] == '1113') {
    throw Exception('Insufficient balance. Please top up your account.');
  } else if (e.response?.data['error']['code'] == '1000') {
    throw Exception('Authentication failed. Check your API key.');
  }
  rethrow;
}
```

## 5. Known Issues and Workarounds

### Issue 1: Model Selection Not Persisting (Until App Restart)
- **Root Cause**: Provider alias normalization inconsistency (zhipuai vs z_ai vs zhipu-ai)
- **Location**: `ModelSelectionService._normalizeProviderAliases()`
- **Status**: Identified, fix pending
- **Workaround**: Restart app after model selection

### Issue 2: Previous Message Streams When Sending New Message
- **Root Cause**: `enhanced_ai_chat_page.dart` line 153 - no isLoading check in `_handleSendMessage()`
- **Flow**: Both messages complete → both trigger ref.listen → both added to _messagesController → UI streams both
- **Fix**: Add isLoading check before calling `chatNotifier.sendMessage()`
- **Status**: Root cause verified, minimal fix proposed (not yet implemented)

### Issue 3: Extensive Dead Code
- **Problem**: Multiple versions of files (*_old.dart, *_fixed.dart, *_backup.dart, *.disabled)
- **Impact**: Confuses developers and AI agents
- **Location**: `lib/presentation/pages/`, `lib/infrastructure/ai/providers/`, multiple `main_*.dart` files
- **Status**: Catalogued for Phase 3 deletion

## 6. Development Workflows

### Running the App
```powershell
# List connected devices
flutter devices

# Run on specific device (Android example)
flutter run -d ZD222KVKVY

# Hot reload (r in terminal)
# Hot restart (R in terminal)
```

### Model Switching Flow
1. User selects model in UI → `ModelSelectionDialog`
2. `ModelSelectionService.setActiveModel(provider, modelId)`
3. Persisted to FlutterSecureStorage with key format: `provider:model|provider:model`
4. UI reads via `currentSelectedModelProvider` → reactive update

### Provider Configuration
- API keys stored in FlutterSecureStorage (encrypted)
- Provider configs in `provider_config_model.dart` (includes custom models)
- Custom models: Users can add unlisted models via UI (no API validation)

### Debugging Tips
- Look for `DEBUG:` prefix in logs (from ModelSelectionService, adapters)
- Check FlutterSecureStorage keys: `selectedModels`, `{provider}_config`
- Verify provider normalization: zhipuai/z_ai/zhipu-ai should map consistently

## 7. AI Provider Specifics

### Z.AI (ZhipuAI)
- **General Endpoint**: https://api.z.ai/api/paas/v4 (chat-optimized)
- **Coding Endpoint**: https://api.z.ai/api/coding/paas/v4 (code-optimized, not currently used)
- **Free Model**: glm-4.5-flash ($0)
- **Paid Models**: glm-4.6, glm-4.5, glm-4.5-air
- **Authentication**: Bearer token format
- **Error Codes**: 1113 (insufficient balance), 1000 (auth failure)
- **Architectural Decision**: Use separate provider entries (zai-general, zai-coding) instead of toggle

### Other Providers
- Google (Gemini): chat_google_adapter.dart
- OpenAI: chat_openai_adapter.dart
- Anthropic: (stub, Phase 4 implementation)

## 8. Next Steps for Agents

### Before Making Changes
1. Read relevant files completely (use read_file, not assumptions)
2. Use grep_search or semantic_search to find related code
3. Understand the data flow (see Section 1)
4. Verify your hypothesis with evidence (logs, debugger)

### Incremental Development (Phase-by-Phase)
- **Phase 1**: Fix isLoading check in enhanced_ai_chat_page.dart (simple, high-impact)
- **Phase 2**: Split Z.AI providers (zai-general, zai-coding) for clearer UX
- **Phase 3**: Delete dead code (main_*.dart, *_old.dart, *_backup.dart, *.disabled)
- **Phase 4**: Integrate Roo Code patterns (BaseProvider, ApiStream, cost calculation)

### Testing Your Changes
1. Build and run the app: `flutter run -d DEVICE_ID`
2. Test the specific scenario that was broken
3. Test edge cases (e.g., rapid message sending, network errors, empty messages)
4. Check logs for unexpected errors or warnings

## 9. Resources

### Documentation Structure
- **MICRO_DOCUMENTATION/**: Comprehensive project docs
  - `01_ARCHITECTURE/`: Architecture decisions
  - `02_IMPLEMENTATION/`: Implementation details
  - `03_TESTING_QUALITY/`: Testing strategies
  - `04_MOBILE_OPTIMIZATION/`: Mobile-specific optimizations
  - `05_PROCESS/`: Development processes
  - `LEGACY_ARCHIVE/`: Outdated docs (safe to ignore)

### Key Dependencies
- flutter_gen_ai_chat_ui: ^2.4.2 (chat UI with markdown streaming)
- flutter_riverpod: ^3.0.3 (state management)
- langchain: ^0.8.0, langchain_openai (AI provider abstraction)
- dio: ^5.7.0 (HTTP client)
- flutter_secure_storage: ^9.2.2 (encrypted storage)
- sqflite: ^2.4.2 (local database)

### External Patterns to Study
- **Roo Code** (RooCodeInc/Roo-Code): Provider architecture, streaming patterns, error handling
- Use Context7 tools to fetch up-to-date documentation when implementing new providers

---

**Remember**: Fix based on evidence, not assumptions. Understand the cause, then implement the simplest solution that addresses the root cause.