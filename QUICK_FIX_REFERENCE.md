# Quick Command Reference - Phase 1 Test Fix

## TL;DR - Sequential Commands

```bash
# ========== ISSUE #1: FIX FREEZED ==========

# 1. Kill processes
taskkill /f /im dart.exe /fi "status eq running" 2>nul
taskkill /f /im flutter.exe /fi "status eq running" 2>nul

# 2. Clean build
cd d:\Project\xyolve\micro\micro
Remove-Item -Force .dart_tool -Recurse -ErrorAction SilentlyContinue
Remove-Item -Force build -Recurse -ErrorAction SilentlyContinue
flutter clean

# 3. Get new freezed version
flutter pub get
# Note: First update pubspec.yaml line 106: freezed: ^3.2.3 → freezed: ^3.1.5

# 4. Regenerate code
dart run build_runner build --delete-conflicting-outputs

# 5. Verify
dart analyze lib/infrastructure/ai/agent/models/agent_models.dart

# ========== ISSUE #2: FIX TEST IMPORTS ==========

# 6. Add imports to test file
# File: micro/test/phase1_agent_tests.dart
# Add after line 10:
# import 'package:langchain_core/language_models/language_model.dart';
# import 'package:langchain_core/language_models/chat_model.dart';

# ========== RUN TESTS ==========

# 7. Execute tests
flutter test test/phase1_agent_tests.dart --reporter=compact

# Expected: All 24 tests pass, exit code 0
```

---

## File Changes Required

### 1. pubspec.yaml (1 line change)

**Location**: Line 106 in `micro/pubspec.yaml`

**From**:
```yaml
  freezed: ^3.2.3
```

**To**:
```yaml
  freezed: ^3.1.5
```

---

### 2. test/phase1_agent_tests.dart (2 lines added)

**Location**: After line 10, before line 11 (`// Mock implementations`)

**Add these two import lines**:
```dart
// LangChain imports
import 'package:langchain_core/language_models/language_model.dart';
import 'package:langchain_core/language_models/chat_model.dart';
```

---

## What Each Fix Does

### Fix #1: Update Freezed Version
- **Problem**: freezed 3.2.3 generates incomplete mixins
- **Solution**: Downgrade to freezed 3.1.5 (stable version)
- **Result**: Generated code will have proper implementations, not just abstract getters

### Fix #2: Add Missing Imports  
- **Problem**: Test mocks reference `LanguageModel` and `BaseChatModel` classes that aren't imported
- **Solution**: Import from langchain_core
- **Result**: Test file will compile without "Type not found" errors

---

## Success Signs

### After Fix #1:
```bash
$ dart analyze lib/infrastructure/ai/agent/models/agent_models.dart
No issues found!
```

### After Fix #2:
```bash
$ dart analyze test/phase1_agent_tests.dart
No issues found!
```

### After Both Fixes:
```bash
$ flutter test test/phase1_agent_tests.dart --reporter=compact
...
24 tests passed
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `Still getting freezed errors after update` | Check that build_runner finished completely. Run `dart run build_runner build --delete-conflicting-outputs` again |
| `BaseChatModel still not found` | Verify imports were added correctly to top of test file. Check for typos |
| `Tests compile but fail at runtime` | Check test output - likely issues with mock implementations. Focus on first failing test |
| `.dart_tool` won't delete (in use) | Kill Dart/Flutter processes with `taskkill` command first |
| `flutter pub get` hangs` | Try `flutter pub cache repair` then `flutter pub get` again |

---

## Debug Commands

```bash
# Check if freezed version updated
grep "freezed:" micro/pubspec.yaml

# View first 50 lines of generated freezed file
type micro/lib/infrastructure/ai/agent/models/agent_models.freezed.dart | select -first 50

# See what test imports exist
type micro/test/phase1_agent_tests.dart | select -first 20

# Run build_runner with verbose output
dart run build_runner build -v

# Run just one test
flutter test test/phase1_agent_tests.dart -n "can register and retrieve tools"
```

---

## Timeline

- **5 min**: Update pubspec.yaml
- **3 min**: Clean and get dependencies  
- **5 min**: Regenerate code with build_runner
- **2 min**: Verify freezed fix
- **3 min**: Add test imports
- **5 min**: Run full test suite

**Total: ~20 minutes**
