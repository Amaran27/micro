# Quick Testing Commands

## 🚀 Run Phase 1 Tests Now

```powershell
# Navigate to project
cd D:\Project\xyolve\micro\micro

# Run Phase 1 tests
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected Output**:
```
ToolRegistry Tests: 5 tests
Example Tools Tests: 4 tests
PlanExecuteAgent Tests: 10 tests
AgentFactory Tests: 4 tests
TaskAnalysis Tests: 1 test

════════════════════════════
24 tests passed
════════════════════════════
```

---

## 🔍 What Each Section Tests

### ToolRegistry (5 tests)
✅ Registers 5 tools (added LocationTool)
✅ Finds tools by capability
✅ Finds tools by action
✅ Checks if capabilities available
✅ Checks if all required tools available
⚠️ Unregister test (removes UI tool, expect 4 tools)
✅ Execute tools
✅ Metadata validation

### Example Tools (4 tests)
✅ UIValidationTool.execute()
✅ SensorAccessTool.execute()
✅ FileOperationTool.execute()
✅ AppNavigationTool.execute()
(LocationTool registered in setUp but not directly tested - covered by ToolRegistry)

### PlanExecuteAgent (10 tests)
✅ Creates agent
✅ Plans task
✅ Executes plan
✅ Verifies steps
✅ Recovers from errors
✅ Handles tool not found
✅ Logs progress
✅ Manages state
✅ Completes successfully
✅ Task analysis

### AgentFactory (4 tests)
✅ Creates agents for different tasks
✅ Routes to correct adapter
✅ Handles unknown tasks
✅ Configuration loading

### TaskAnalysis (1 test)
✅ Analyzes mobile app control task

---

## 📊 File Structure

```
micro/
├── test/
│   └── phase1_agent_tests.dart         # ← Run this: 24 tests
│       ├── ToolRegistry Tests (5)
│       ├── Example Tools Tests (4)
│       ├── PlanExecuteAgent Tests (10)
│       ├── AgentFactory Tests (4)
│       └── TaskAnalysis Tests (1)
│
└── lib/
    └── infrastructure/
        └── ai/
            ├── agent/
            │   ├── plan_execute_agent.dart
            │   ├── agent_factory.dart
            │   └── tools/
            │       ├── tool_registry.dart
            │       └── example_mobile_tools.dart (←← LocationTool here)
```

---

## ✨ New in Phase 2

### Files NOT included in these tests yet:
- `lib/infrastructure/communication/websocket_client.dart` (Phase 2A)
- `lib/infrastructure/communication/websocket_provider.dart` (Phase 2A)
- `lib/infrastructure/communication/message_serializer.dart` (Phase 2A)
- `lib/features/agent/providers/streaming_agent_provider.dart` (Phase 2A)
- `lib/infrastructure/ai/adapters/zhipuai_general_adapter.dart` (Phase 2B)
- `lib/infrastructure/ai/adapters/zhipuai_coding_adapter.dart` (Phase 2B)

**Next steps after Phase 1 verification**:
1. ✅ Verify Phase 1 tests pass
2. ⏳ Implement Phase 2A test cases (test/phase2a_websocket_tests.dart)
3. ⏳ Test Phase 2B adapters separately
4. ⏳ Test LocationTool in isolation

---

## 🎯 Success Criteria

**Phase 1 Baseline** ✅
```
MUST HAVE:
- All 24 tests pass
- LocationTool registered (toolCount = 5)
- No compilation errors in test files
- No runtime errors
```

**Phase 2A (After Implementation)**
```
SHOULD HAVE:
- 15 additional tests pass
- WebSocket tests cover connection, reconnection, messages
- Message serialization tests verify encode/decode
- Event streaming tests verify filtering
```

**Phase 2B (After Implementation)**
```
SHOULD HAVE:
- General adapter tests pass
- Coding adapter tests pass
- Provider switching tested
- Error handling verified
```

---

## 🐛 If Tests Fail

### Problem: `flutter: command not found`
**Solution**: 
```powershell
# Add Flutter to PATH or use full path
"$env:USERPROFILE\flutter\bin\flutter" test test/phase1_agent_tests.dart
```

### Problem: `Package not found: micro`
**Solution**:
```powershell
# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean
flutter pub get
```

### Problem: Test file not found
**Solution**:
```powershell
# Verify you're in correct directory
cd D:\Project\xyolve\micro\micro
dir test/phase1_agent_tests.dart  # Should exist

# If not found, check path
ls test/
```

### Problem: Tests timeout
**Solution**:
```powershell
# Run with longer timeout
flutter test test/phase1_agent_tests.dart --timeout=60s
```

---

## 📈 Progress Tracking

```
Phase 1 (Baseline)
├── ✅ ToolRegistry (5 tools registered)
├── ✅ PlanExecuteAgent (agent logic)
├── ✅ AgentFactory (task routing)
├── ✅ Example Tools (UI, Sensor, File, Navigation, Location)
└── ✅ Tests (24 passing)

Phase 2A (WebSocket)
├── ⏳ MessageSerializer
├── ⏳ WebSocketClient
├── ⏳ StreamingAgentProvider
└── ⏳ Tests (15 to implement)

Phase 2B (Providers)
├── ✅ ZhipuAI General Adapter
├── ✅ ZhipuAI Coding Adapter
└── ⏳ Tests (pending)

Phase 2C.1 (Location)
├── ✅ LocationTool (4 methods)
└── ✅ Registered in ToolRegistry

Phase 2C.2 (Camera) - Planned
├── ⏳ CameraTool (takePhoto, scanQRCode, detectObjects)
└── ⏳ Tests

Phase 2UI (Chat Integration) - Planned
├── ⏳ UI streaming implementation
└── ⏳ E2E tests
```

---

## 🚦 Next Steps

### Right Now (5 minutes)
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

### If All Tests Pass ✅
Continue to Phase 2A test implementation:
1. Open `test/phase2a_websocket_tests.dart`
2. Implement test bodies (use mockito for mocking)
3. Run tests: `flutter test test/phase2a_websocket_tests.dart`

### If Tests Fail ❌
1. Read error message carefully
2. Check if it's a Phase 1 issue or environment issue
3. Verify dependencies: `flutter pub get`
4. Clean and retry: `flutter clean && flutter pub get`

---

## 💾 Command Reference

| Command | Purpose |
|---------|---------|
| `flutter test test/phase1_agent_tests.dart` | Run Phase 1 tests |
| `flutter test --reporter=compact` | Run all tests (compact output) |
| `flutter test -k "ToolRegistry"` | Run only ToolRegistry tests |
| `flutter test --watch test/phase1_agent_tests.dart` | Watch mode (rerun on change) |
| `flutter test --coverage` | Run with coverage report |
| `flutter pub get` | Get dependencies |
| `flutter clean` | Clean build |

---

**Ready? Run:**
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected**: ✅ 24 tests pass 🎯
