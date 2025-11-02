# Cloud LLM - Work Instructions Index

## 📋 Current Situation

**Project**: Micro AI Chat (Flutter mobile + desktop agent system)
**Status**: Phase 1 implementation blocked by 2 compilation issues
**Branch**: `copilot/enhance-project-documentation`
**Location**: `d:\Project\xyolve\micro\micro\`

---

## 🎯 Your Mission

Fix 2 blocking compilation issues so Phase 1 agent tests can run and pass.

**Estimated Time**: 15-20 minutes total

---

## 📚 Documentation Created (FOR YOU)

### 1. **DETAILED_FIX_STEPS.md** (PRIMARY - Use This)
📄 **What**: Step-by-step fix instructions with full context
📍 **Location**: `d:\Project\xyolve\micro\DETAILED_FIX_STEPS.md`
✅ **Contains**: 
- Root cause analysis for both issues
- Exact commands to run (copy-paste ready)
- Expected outputs at each step
- Troubleshooting guide
- Fallback Option B (if freezed fails)

**👉 START HERE - Read this first, it has everything**

---

### 2. **QUICK_FIX_REFERENCE.md** (QUICK LOOKUP)
📄 **What**: TL;DR version, commands only
📍 **Location**: `d:\Project\xyolve\micro\QUICK_FIX_REFERENCE.md`
✅ **Contains**:
- Sequential command blocks (copy-paste entire section)
- File changes required (exact line numbers)
- Success signs to look for
- Quick debug commands

**👉 Use this while executing, copy entire command blocks**

---

### 3. **PHASE_2_ROADMAP.md** (PLANNING - After Tests Pass)
📄 **What**: What comes after Phase 1 fixes
📍 **Location**: `d:\Project\xyolve\micro\PHASE_2_ROADMAP.md`
✅ **Contains**:
- 3 Phase 2 components (WebSocket, Provider Split, New Tools)
- Detailed implementation plan for each
- Timeline and success metrics
- Architecture diagrams

**👉 Reference this after tests pass to plan next work**

---

## 🚀 Quick Start

### Option A: Detailed Step-by-Step (Recommended)
1. Open: `DETAILED_FIX_STEPS.md`
2. Follow sections in order:
   - ISSUE #1: Fix Freezed Code Generation (Steps 1.1-1.5)
   - ISSUE #2: Fix Test Import (Steps 2.1-2.3)
   - VERIFICATION: Run Tests (Steps 3.1-3.2)
3. Expected result: All 24 tests pass

### Option B: Quick Command Execution (If Experienced)
1. Open: `QUICK_FIX_REFERENCE.md`
2. Copy command blocks and run sequentially
3. Check success signs
4. Run final test command

---

## 🔴 The Two Issues

### Issue #1: Freezed Code Generation Bug (90% of errors)
```
Error: The non-abstract class 'PlanStep' is missing implementations 
for these members: _$PlanStep.action, _$PlanStep.dependencies...
```

**Root Cause**: `freezed 3.2.3` + `freezed_annotation 3.0.0` incompatible
**Solution**: Update to `freezed 3.1.5` (stable version)
**Files Affected**: 11 models (PlanStep, StepResult, Verification, etc.)

**What You'll Do**:
1. Change 1 line in `pubspec.yaml`
2. Run `flutter clean`
3. Run `flutter pub get` 
4. Run `dart run build_runner build --delete-conflicting-outputs`
5. Verify compilation succeeds

---

### Issue #2: Test Import Error (10% of errors)
```
Error: Type 'BaseChatModel' not found.
class MockChatModel extends Mock implements BaseChatModel {}
```

**Root Cause**: Missing imports in test file
**Solution**: Add 2 import lines
**File**: `test/phase1_agent_tests.dart`

**What You'll Do**:
1. Open test file
2. Add 2 import lines after line 10:
   - `import 'package:langchain_core/language_models/language_model.dart';`
   - `import 'package:langchain_core/language_models/chat_model.dart';`
3. Save file

---

## ✅ Success Criteria

**After all fixes**, this command should show all green:

```bash
cd d:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

Expected output:
```
00:00 +0: loading test/phase1_agent_tests.dart
...
00:15 +24: All tests passed!

24 tests passed
```

**Exit Code**: 0 (zero)

---

## 📂 File Changes Summary

| File | Change | Lines | Type |
|------|--------|-------|------|
| `micro/pubspec.yaml` | `freezed: ^3.2.3` → `freezed: ^3.1.5` | Line 106 | 1 line |
| `micro/test/phase1_agent_tests.dart` | Add langchain imports | After line 10 | 2 lines |
| `agent_models.freezed.dart` | Will be auto-generated | 4553 lines | Auto |
| `agent_models.g.dart` | Will be auto-generated | 1000+ lines | Auto |

**Total Manual Changes**: 3 lines in 2 files

---

## 🛠️ Tools You'll Use

| Tool | Purpose | Command |
|------|---------|---------|
| PowerShell | Run commands | `cd`, `Remove-Item`, etc. |
| Flutter | Build/test framework | `flutter clean`, `flutter pub get` |
| Dart | Code generation | `dart run build_runner build` |
| Text Editor | Edit files | Open `.dart` and `.yaml` files |

---

## ⚠️ Common Pitfalls (Avoid These)

❌ **Don't**: Skip the `flutter clean` step
✅ **Do**: Always clean before `flutter pub get`

❌ **Don't**: Edit the `.freezed.dart` file manually
✅ **Do**: Let build_runner regenerate it

❌ **Don't**: Run commands from wrong directory
✅ **Do**: Stay in `d:\Project\xyolve\micro\micro\`

❌ **Don't**: Copy imports wrong
✅ **Do**: Add exactly 2 lines, check no typos

---

## 📞 If You Get Stuck

### "Freezed still failing after update"
→ See DETAILED_FIX_STEPS.md **"TROUBLESHOOTING"** section
→ Or use **"OPTION B: Workaround"** (replace with @JsonSerializable)

### "Import still not found"
→ Check file was saved
→ Verify exact import line paths
→ Try `flutter pub get` again

### ".dart_tool won't delete"
→ Processes still running
→ Run `taskkill` command from QUICK_FIX_REFERENCE.md

### "Tests compile but fail at runtime"
→ Check test output for specific errors
→ Likely mock setup issue, not compilation
→ See DETAILED_FIX_STEPS.md Step 3.2

---

## 🎓 Learning Resources (Optional)

**Freezed Package**: https://pub.dev/packages/freezed
- Immutable data models with JSON serialization

**LangChain Dart**: https://pub.dev/packages/langchain
- AI provider abstraction, model interfaces

**Flutter Testing**: https://flutter.dev/docs/testing
- Unit testing, mocking, test structure

---

## 📊 Project Context (For Reference)

**What's Phase 1 Testing**:
- Plan-Execute-Verify-Replan agent cycle
- ToolRegistry with dynamic tool management
- 4 mobile tools (UI, Sensors, Files, Navigation)
- 11 immutable data models (with freezed)

**What's Already Working**:
- LangChain integration (0.8.0)
- Riverpod state management
- JSON serialization
- 127 Dart files, all syntactically correct

**What's Been Fixed Recently**:
- Removed 400KB of stale analysis artifacts
- Cleaned up 7 files with deleted references
- Formatted all code (4 files needed minor fixes)

---

## 🔄 Next Steps After Success

Once `flutter test` returns "24 tests passed":

1. **Commit your changes**:
   ```bash
   git add micro/pubspec.yaml micro/test/phase1_agent_tests.dart
   git commit -m "Fix: Freezed version and test imports for Phase 1 tests"
   ```

2. **Read PHASE_2_ROADMAP.md** for next priorities:
   - WebSocket streaming
   - Provider configuration splitting
   - Additional mobile tools

3. **Create feature branch for Phase 2**:
   ```bash
   git checkout -b feature/phase2-websocket
   ```

---

## 📝 Notes for Next Agent

- **Current Directory**: `d:\Project\xyolve\micro\micro\`
- **Current Branch**: `copilot/enhance-project-documentation`
- **Main Issue**: 2 blocking compilation errors (not runtime)
- **Expected Outcome**: Clean compilation + all 24 unit tests pass
- **Difficulty Level**: Low (mostly copy-paste commands + 2-line edit)
- **Time Estimate**: 15-20 minutes including verification

---

**Ready?** Open `DETAILED_FIX_STEPS.md` and start with **Step 1.1**! 🚀
