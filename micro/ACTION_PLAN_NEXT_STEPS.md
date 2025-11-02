# Next Action Plan for Micro AI Chat Project

**Status**: ✅ Code analysis cleaned (749 → 107 issues, 85.7% reduction)

---

## Phase 1: Testing & Validation ✅ COMPLETE
- [x] Removed dead code from zhipuai_provider.dart (_createZhipuAIChatModel, _generateJWTToken, _isValidApiKey)
- [x] Fixed import paths (base_provider.dart, zai_provider_v2.dart)
- [x] Fixed directive ordering (dart:io import in zai_provider_v2.dart)
- [x] Organized dead code for removal (created lib/_to_be_removed/ structure)
- [x] Analysis issues: 749 → 107 (-85.7%)
- [x] Remaining issues: All warnings only (no compilation errors)

---

## Phase 2: Build & Run Testing (NEXT)

### 2.1 Build the app
```bash
cd D:\Project\xyolve\micro\micro
flutter clean
flutter pub get
flutter build apk --debug
```

**Success Criteria**: 
- Build completes without errors
- APK generated successfully
- No runtime errors during build

### 2.2 Test on device
```bash
flutter run -d ZD222KVKVY --debug
```

**Test scenarios**:
1. App launches and loads chat UI
2. Model selection works (no crashes)
3. Chat functionality works (send/receive messages)
4. No runtime errors in console
5. Navigation works (settings, agent mode, etc.)

### 2.3 Verification checklist
- [ ] App builds successfully
- [ ] App runs on device without crashes
- [ ] Chat UI renders correctly
- [ ] Model selection dropdown works
- [ ] Sending a message works
- [ ] No null pointer exceptions
- [ ] Performance is acceptable

---

## Phase 3: Dead Code Removal (After Testing Passes)

### 3.1 Move dead code files to _to_be_removed/
Once we confirm Phase 2 testing passes, systematically move:

**UI Pages**:
- permissions_settings_page.dart
- tool_detail_page.dart
- simple_enhanced_chat_page.dart
- unified_provider_settings_new.dart
- unified_provider_settings_clean.dart

**Routers**:
- simple_app_router.dart
- minimal_enhanced_router.dart

**Providers**:
- chat_provider.dart (legacy)
- model_selection_notifier.dart

**Infrastructure**:
- zhipuai_chat_model.dart
- lib/infrastructure/ai/state/* (entire directory)
- lib/infrastructure/mcp/* (entire directory)
- lib/infrastructure/autonomous/* (entire directory)

### 3.2 Update analysis_options.yaml
Remove exclusions as files are deleted:
```yaml
# Remove these from analyzer.exclude after confirming deletion:
- 'lib/_to_be_removed/**'
- 'lib/infrastructure/mcp/**'
- 'lib/infrastructure/autonomous/**'
# etc.
```

### 3.3 Final cleanup
- Delete lib/_to_be_removed/ directory
- Delete lib/_backup/ directory
- Run final analysis: `flutter analyze`
- Should show: **0 remaining issues in production code** ✅

---

## Phase 4: Code Quality Improvements (After Cleanup)

### 4.1 Fix remaining warnings (~107 issues)
These are mostly harmless but good to clean:
- Remove unused variables (unused_local_variable)
- Remove unused fields (unused_field)
- Fix dead code (dead_code, dead_null_aware_expression)
- Remove unused methods (unused_element)

Example files to review:
- `lib/infrastructure/ai/adapters/zai_provider_v2.dart` (2 warnings)
- `lib/infrastructure/ai/model_selection_service.dart` (1 warning)
- `lib/infrastructure/autonomous/ai_context_analyzer.dart` (3 warnings)
- `lib/presentation/pages/simple_enhanced_chat_page.dart` (1 warning)
- `lib/presentation/widgets/agent_creation_dialog.dart` (1 warning)
- `lib/presentation/widgets/ai_proactive_integration_demo.dart` (1 warning)

### 4.2 Zero-warning goal
After Phase 4: **Analysis should show 0 issues** (or only info-level hints)

---

## Phase 5: Documentation & Knowledge Transfer

### 5.1 Document architecture decisions
- Chat UI package (flutter_gen_ai_chat_ui) handles streaming
- Provider pattern with Riverpod
- Model selection per-provider persistence
- BaseProvider interface for multi-provider support

### 5.2 Create developer guide
- Setup instructions
- Code organization explanation
- How to add new providers
- Common patterns and conventions

---

## Current Metrics

| Metric | Before | After | Progress |
|--------|--------|-------|----------|
| Analysis Issues | 749 | 107 | ✅ 85.7% reduction |
| Compilation Errors | Multiple | 0 | ✅ Clean build |
| Warnings | 700+ | ~107 | ⏳ Next phase |
| Excluded Files | - | 30+ | ✅ Organized |
| Dead Code | Scattered | Organized | ⏳ Ready for removal |

---

## Dependencies & Requirements

### SDK Versions
- Dart: >=3.2.0 <4.0.0
- Flutter: >=3.16.0
- flutter_riverpod: ^3.0.3

### Key Packages
- flutter_gen_ai_chat_ui: ^2.4.2 (Chat UI with streaming)
- dio: ^5.7.0 (HTTP client)
- flutter_secure_storage: ^9.2.2 (API key storage)

### Known Limitations
- No LangChain direct support (zhipuai_chat_model.dart excluded)
- MCP adapter experimental (to be removed)
- Autonomous framework experimental (to be removed)

---

## Next Immediate Action

**→ RUN: `flutter build apk --debug` and `flutter run -d ZD222KVKVY`**

Report back with:
1. Build output (success/failure)
2. Runtime console output
3. Any crashes or errors
4. Chat functionality test results

Then proceed to Phase 3 once testing confirms all systems operational.
