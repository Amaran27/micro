# Detailed Fix Steps for Phase 1 Agent Tests

**Status**: Two blocking issues preventing test execution
**Target**: Make tests compilable and passing
**Estimated Time**: 20-30 minutes

---

## Background Context

**Current Situation**:
- Branch: `copilot/enhance-project-documentation` 
- Build fixed: Removed ~400KB stale analysis files (95 errors from deleted code)
- Current codebase: 127 Dart files, 100% syntactically correct
- Blocking test run: `flutter test test/phase1_agent_tests.dart`

**Two Blocking Issues**:
1. **Freezed Code Generation Bug** - mixin definitions incomplete
2. **Test Import Error** - `BaseChatModel` not found

**Project Structure**:
```
micro/
  lib/
    infrastructure/ai/agent/
      models/
        agent_models.dart (181 lines, 11 @freezed models)
        agent_models.freezed.dart (4553 lines - GENERATED, incomplete)
        agent_models.g.dart (GENERATED, not reached in compilation)
  test/
    phase1_agent_tests.dart (228 lines, 24 test cases)
  pubspec.yaml (dependencies specified below)
```

**Key Dependencies**:
```yaml
dependencies:
  langchain: ^0.8.0
  langchain_core: any
  langchain_openai: any
  freezed_annotation: ^3.0.0

dev_dependencies:
  freezed: ^3.2.3
  build_runner: ^2.7.1
  mockito: ^5.4.4
```

---

## ISSUE #1: Fix Freezed Code Generation Bug

### Root Cause Analysis
- **Problem**: `freezed 3.2.3` + `freezed_annotation 3.0.0` generates incomplete mixins
- **Symptom**: Generated `mixin _$PlanStep` at line 16 only has abstract getters, no implementations
- **Result**: Dart compiler error: `'PlanStep' is missing implementations for _$PlanStep.action, _$PlanStep.dependencies...`
- **Affected Models** (11 total):
  1. PlanStep
  2. StepResult
  3. Verification
  4. AgentPlan
  5. AgentResult
  6. ToolMetadata
  7. TaskCapabilities
  8. PlanningContext
  9. TaskAnalysis
  10. (Two additional models - same pattern)

### Solution Strategy

**Option A: Version Update (Preferred - Maintains Quality)**
- Update freezed to a compatible version that generates correct code
- Check pub.dev for latest stable: freezed 3.2.3 (current) → try 3.1.5 (downgrade) or wait for fix

**Option B: Workaround (Quick but Lower Quality)**
- Replace `@freezed` with `@JsonSerializable`
- Remove mixin pattern: `class PlanStep with _$PlanStep` → `class PlanStep`
- Keep field definitions, manually add constructor

### Detailed Fix Steps for Option A

#### Step 1.1: Investigate Freezed Versions
**Commands to run** (in terminal, directory: `d:\Project\xyolve\micro\micro`):
```bash
# Check what versions of freezed are available
dart pub cache list
# Or check pub.dev package info (might need web search)
# Known issue: freezed 3.2.3 broken for this pattern
# Try downgrading to 3.1.5 which is known stable
```

**Expected Output**: List of cached packages, or error if not available

#### Step 1.2: Update pubspec.yaml
**File**: `micro/pubspec.yaml`
**Line 106**: Change freezed version

**Current**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_gen_runner: ^5.3.0
  json_serializable: ^6.7.1
  freezed: ^3.2.3
  build_runner: ^2.7.1
```

**New** (try one of these in order):
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  flutter_gen_runner: ^5.3.0
  json_serializable: ^6.7.1
  freezed: ^3.1.5
  build_runner: ^2.7.1
```

**Action**: Update the line `freezed: ^3.2.3` to `freezed: ^3.1.5`

#### Step 1.3: Clean Build Environment
**Commands** (sequential):
```bash
# Kill any running processes
taskkill /f /im dart.exe /fi "status eq running" 2>nul
taskkill /f /im flutter.exe /fi "status eq running" 2>nul

# Delete all generated code and cache
cd d:\Project\xyolve\micro\micro
Remove-Item -Force .dart_tool -Recurse -ErrorAction SilentlyContinue
Remove-Item -Force build -Recurse -ErrorAction SilentlyContinue

# Clean Flutter
flutter clean

# Get fresh dependencies with new freezed version
flutter pub get
```

**Expected Output**: 
- No processes running
- `.dart_tool` and `build/` directories deleted
- `flutter clean` completes
- `flutter pub get` downloads freezed 3.1.5 and dependencies

#### Step 1.4: Regenerate Code
**Commands**:
```bash
cd d:\Project\xyolve\micro\micro
dart run build_runner build --delete-conflicting-outputs
```

**Expected Output**:
```
Building package executable...
[INFO] Precompiling build_runner...
[INFO] Generating build script completed, took 4 seconds...
[INFO] Running build...
[INFO] GeneratedCodeGenerator completed, took 2 seconds
...
[INFO] Succeeded after 10 seconds
```

**Check Generated File**:
```bash
# Verify the mixin now has implementations
type lib\infrastructure\ai\agent\models\agent_models.freezed.dart | findstr /A:2 "mixin _\$PlanStep"
```

**Expected**: Mixin should have proper method bodies, not just abstract getters

#### Step 1.5: Verify Compilation
**Commands**:
```bash
cd d:\Project\xyolve\micro\micro
dart analyze lib/infrastructure/ai/agent/models/agent_models.dart
```

**Expected Output**:
```
No issues found!
```

**If Still Fails**: Try Option B (Workaround)

---

## ISSUE #2: Fix Test Import Error

### Root Cause Analysis
- **Problem**: Test file references `BaseChatModel` without importing it
- **Source**: File `test/phase1_agent_tests.dart` line 13
- **Error**: `Error: Type 'BaseChatModel' not found`
- **Solution**: Import from `langchain_core`

### Detailed Fix Steps

#### Step 2.1: Identify Missing Imports
**File**: `micro/test/phase1_agent_tests.dart`
**Current Content** (lines 1-15):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import 'package:micro/infrastructure/ai/agent/models/agent_models.dart'
    as agent_models;
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';
import 'package:micro/infrastructure/ai/agent/agent_factory.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/example_mobile_tools.dart';

// Mock implementations for testing
class MockLanguageModel extends Mock implements LanguageModel {}

class MockChatModel extends Mock implements BaseChatModel {}
```

**Missing**: 
- `LanguageModel` (from langchain or langchain_core)
- `BaseChatModel` (from langchain_core)

#### Step 2.2: Add Missing Imports
**File**: `micro/test/phase1_agent_tests.dart`

**Action**: Add these imports after line 10 (after the agent imports):

```dart
import 'package:langchain_core/language_models/language_model.dart';
import 'package:langchain_core/language_models/chat_model.dart';
```

**Result** (new lines 11-12):
```dart
import 'package:micro/infrastructure/ai/agent/tools/example_mobile_tools.dart';

// LangChain imports
import 'package:langchain_core/language_models/language_model.dart';
import 'package:langchain_core/language_models/chat_model.dart';

// Mock implementations for testing
class MockLanguageModel extends Mock implements LanguageModel {}
```

#### Step 2.3: Verify File Structure
**File**: `micro/test/phase1_agent_tests.dart`
**Complete Import Section** (should look like):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mockito/mockito.dart';

import 'package:micro/infrastructure/ai/agent/models/agent_models.dart'
    as agent_models;
import 'package:micro/infrastructure/ai/agent/plan_execute_agent.dart';
import 'package:micro/infrastructure/ai/agent/agent_factory.dart';
import 'package:micro/infrastructure/ai/agent/tools/tool_registry.dart';
import 'package:micro/infrastructure/ai/agent/tools/example_mobile_tools.dart';

// LangChain imports
import 'package:langchain_core/language_models/language_model.dart';
import 'package:langchain_core/language_models/chat_model.dart';

// Mock implementations for testing
class MockLanguageModel extends Mock implements LanguageModel {}

class MockChatModel extends Mock implements BaseChatModel {}
```

---

## VERIFICATION: Run Tests

### Step 3.1: Execute Tests
**Command**:
```bash
cd d:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected Output** (success):
```
00:00 +0: loading test/phase1_agent_tests.dart
00:05 +1: ToolRegistry Tests can register and retrieve tools
00:05 +2: ToolRegistry Tests can find tools by capability
00:05 +3: ToolRegistry Tests can find tools by action
00:05 +4: ToolRegistry Tests can check if capabilities are available
...
00:10 +24: All tests passed!

24 tests passed
```

**Expected Exit Code**: 0 (success)

### Step 3.2: If Tests Fail
**Troubleshooting**:
1. **Still getting freezed errors?**
   - Freezed version not compatible
   - Try Option B: Replace @freezed with @JsonSerializable

2. **Other compilation errors?**
   - Check error message carefully
   - Likely missing import or typo

3. **Runtime test failures?**
   - Check logger output
   - Tests might pass compilation but fail execution

---

## OPTION B: Workaround (If Freezed Fails)

If freezed version update doesn't work, use `@JsonSerializable` instead.

### Step B.1: Update Models
**File**: `micro/lib/infrastructure/ai/agent/models/agent_models.dart`

**Current** (example - PlanStep):
```dart
@freezed
class PlanStep with _$PlanStep {
  const factory PlanStep({
    required String id,
    required String description,
    required String action,
    required Map<String, dynamic> parameters,
    required List<String> requiredTools,
    required int estimatedDurationSeconds,
    @Default(ExecutionStatus.pending) ExecutionStatus status,
    @Default([]) List<String> dependencies,
    int? sequenceNumber,
    String? toolName,
  }) = _PlanStep;

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);
}
```

**New** (replace with):
```dart
@JsonSerializable()
class PlanStep {
  final String id;
  final String description;
  final String action;
  final Map<String, dynamic> parameters;
  final List<String> requiredTools;
  final int estimatedDurationSeconds;
  final ExecutionStatus status;
  final List<String> dependencies;
  final int? sequenceNumber;
  final String? toolName;

  const PlanStep({
    required this.id,
    required this.description,
    required this.action,
    required this.parameters,
    required this.requiredTools,
    required this.estimatedDurationSeconds,
    this.status = ExecutionStatus.pending,
    this.dependencies = const [],
    this.sequenceNumber,
    this.toolName,
  });

  factory PlanStep.fromJson(Map<String, dynamic> json) =>
      _$PlanStepFromJson(json);

  Map<String, dynamic> toJson() => _$PlanStepToJson(this);
}
```

**Action**: Apply same pattern to ALL 11 models in the file

### Step B.2: Update pubspec.yaml
**Change**: Remove freezed, keep json_serializable

```yaml
dev_dependencies:
  # REMOVE: freezed: ^3.2.3
  # KEEP: json_serializable: ^6.7.1
  build_runner: ^2.7.1
```

### Step B.3: Regenerate JSON
```bash
cd d:\Project\xyolve\micro\micro
dart run build_runner build --delete-conflicting-outputs
```

---

## Summary Checklist

**Issue #1 - Freezed Fix**:
- [ ] Update `pubspec.yaml`: `freezed: ^3.1.5`
- [ ] Delete `.dart_tool/` and `build/` directories
- [ ] Run `flutter clean`
- [ ] Run `flutter pub get`
- [ ] Run `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify `agent_models.freezed.dart` has proper mixin implementations
- [ ] Run `dart analyze lib/infrastructure/ai/agent/models/agent_models.dart`

**Issue #2 - Test Import Fix**:
- [ ] Add imports to `test/phase1_agent_tests.dart`:
  - `import 'package:langchain_core/language_models/language_model.dart';`
  - `import 'package:langchain_core/language_models/chat_model.dart';`
- [ ] Verify import section compiles

**Final Verification**:
- [ ] Run: `flutter test test/phase1_agent_tests.dart --reporter=compact`
- [ ] Expected: 24 tests passed, exit code 0
- [ ] If failed: Check error message and troubleshoot

---

## Files to Modify

### Primary Changes
1. **`micro/pubspec.yaml`** (Line 106)
   - Change: `freezed: ^3.2.3` → `freezed: ^3.1.5`

2. **`micro/test/phase1_agent_tests.dart`** (Lines 11-12)
   - Add LangChain imports

### Generated Files (Will be Auto-Regenerated)
- `micro/lib/infrastructure/ai/agent/models/agent_models.freezed.dart` (4553 lines)
- `micro/lib/infrastructure/ai/agent/models/agent_models.g.dart`

---

## Expected Timeline

| Step | Task | Time |
|------|------|------|
| 1.1-1.2 | Update freezed version | 2 min |
| 1.3 | Clean environment | 3 min |
| 1.4 | Regenerate code | 5 min |
| 1.5 | Verify compilation | 2 min |
| 2.1-2.3 | Fix test imports | 3 min |
| 3.1 | Run tests | 5 min |
| **Total** | | **20 min** |

---

## Success Criteria

✅ **Step 1 Complete**: No freezed compilation errors
✅ **Step 2 Complete**: No import errors in test file
✅ **Step 3 Complete**: All 24 tests pass

**Next Phase**: Once tests pass, move to Phase 2 work (WebSocket, additional tools, provider splitting)
