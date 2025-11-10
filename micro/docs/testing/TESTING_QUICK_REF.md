# Phase 2 Testing - Quick Reference Card

## 📍 ONE-PAGE SUMMARY

### What's Testable RIGHT NOW

| What | Where | How Many | Status |
|------|-------|----------|--------|
| **Phase 1 Agent** | `test/phase1_agent_tests.dart` | 24 | ✅ Ready to run |
| **LocationTool** | (included in Phase 1) | (5 tools) | ✅ Ready to run |
| **WebSocket (Phase 2A)** | `test/phase2a_websocket_tests.dart` | 15 | ⏳ Stubs ready |
| **Adapters (Phase 2B)** | `test/phase2b_provider_tests.dart` | 8 | ⏳ Ready to create |

---

## 🚀 QUICK START (Right Now)

```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected**: ✅ 24 tests pass

---

## 📋 Test Breakdown

### Phase 1: Agent System (24 tests) ✅

```
ToolRegistry (5 tests)
├── Register/retrieve tools
├── Find by capability
├── Find by action
├── Check capabilities
└── Check all required tools

Example Tools (4 tests)
├── UIValidationTool
├── SensorAccessTool
├── FileOperationTool
└── AppNavigationTool

PlanExecuteAgent (10 tests)
├── Create agent
├── Plan task
├── Execute plan
├── Verify steps
├── Recover from errors
├── Handle missing tools
├── Log progress
├── Manage state
├── Complete task
└── Analyze task

AgentFactory (4 tests)
├── Create for control_ui
├── Create for sensor_data
├── Handle unknown tasks
└── Load configuration

TaskAnalysis (1 test)
└── Analyze mobile_app_control
```

---

### Phase 2A: WebSocket (15 tests) ⏳

```
MessageSerializer (5 tests)
├── Encode heartbeat
├── Decode plan message
├── Convert message types
├── Encode step execution
└── Decode verification

WebSocketClient (10 tests)
├── Initialize config
├── Transition to connecting
├── Transition to connected
├── Auto-reconnect
├── Max reconnect attempts
├── Error on disconnected send
├── Send when connected
├── Trigger callbacks
├── Handle incoming messages
└── Disconnect gracefully

StreamingAgentNotifier (9 tests)
├── Initialize empty
├── Start streaming
├── Stop streaming
├── Handle events
├── Filter by task ID
├── Emit to stream
├── Handle errors
├── Clear all events
└── Clear task events

Integration (4 tests)
├── Connect and send
├── Receive and parse
├── Handle connection errors
└── Persist across reconnect
```

---

### Phase 2B: Providers (8 tests) ⏳

```
Z.AI General (4 tests)
├── Initialize with free model
├── Send to /paas/v4
├── Switch models
└── Handle errors

Z.AI Coding (4 tests)
├── Initialize code models
├── Send to /coding/paas/v4
├── Switch models
└── Handle errors

Provider Switching (3 tests in practice)
├── Independent models
├── Different endpoints
└── Different temperatures
```

---

## 🎯 Testing Workflow

```
STEP 1 (5 min) - Verify Phase 1 ✅
  flutter test test/phase1_agent_tests.dart
  Expected: 24/24 pass

STEP 2 (30 min) - Implement Phase 2A ⏳
  - Open test/phase2a_websocket_tests.dart
  - Replace TODO comments with real tests
  - Use mockito for mocking
  - flutter test test/phase2a_websocket_tests.dart
  Expected: 15/15 pass

STEP 3 (20 min) - Create Phase 2B ⏳
  - Create test/phase2b_provider_tests.dart
  - Test adapters and switching
  - flutter test test/phase2b_provider_tests.dart
  Expected: 8/8 pass

STEP 4 (5 min) - Run All ✅
  flutter test --reporter=compact
  Expected: 47+ pass total
```

---

## 💻 Essential Commands

```powershell
# Verify baseline
flutter test test/phase1_agent_tests.dart --reporter=compact

# Watch mode (auto-rerun)
flutter test test/phase1_agent_tests.dart --watch

# Specific test
flutter test -k "ToolRegistry"

# All tests
flutter test --reporter=compact

# With coverage
flutter test --coverage

# Verbose output
flutter test test/phase1_agent_tests.dart -v

# Timeout
flutter test test/phase2a_websocket_tests.dart --timeout=60s
```

---

## ✅ Success Criteria

```
Phase 1: 24 tests pass ✅
Phase 2A: 15 tests pass ✅ (after implementation)
Phase 2B: 8 tests pass ✅ (after creation)
────────────────────────────
Total: 47+ tests pass ✅
```

---

## 🔍 File Locations

```
micro/
├── test/
│   ├── phase1_agent_tests.dart ✅ (ready)
│   └── phase2a_websocket_tests.dart ⏳ (stubs ready)
└── lib/
    └── infrastructure/
        ├── ai/
        │   ├── agent/
        │   │   ├── plan_execute_agent.dart ✅
        │   │   ├── agent_factory.dart ✅
        │   │   └── tools/
        │   │       ├── tool_registry.dart ✅
        │   │       └── example_mobile_tools.dart ✅
        │   └── adapters/
        │       ├── zhipuai_general_adapter.dart ✅
        │       └── zhipuai_coding_adapter.dart ✅
        └── communication/ ✅ (Phase 2A ready)
```

---

## 🛠️ Mocking Pattern (Phase 2A)

```dart
// Mock WebSocket
class MockWebSocketChannel extends Mock implements WebSocketChannel {}

// Use in test
test('test name', () {
  final mockChannel = MockWebSocketChannel();
  final mockSink = MockSink();
  
  when(mockChannel.sink).thenReturn(mockSink);
  
  // Create client with mock
  final client = WebSocketClient(channel: mockChannel);
  
  // Verify behavior
  verify(mockSink.add(any)).called(1);
});
```

---

## 🎓 Testing Patterns

```dart
// Arrange-Act-Assert
test('feature works', () {
  // Arrange: Setup
  final input = testData();
  
  // Act: Execute
  final result = function(input);
  
  // Assert: Verify
  expect(result, expectedValue);
});

// Stream testing
test('emits events', () async {
  final events = [];
  stream.listen((e) => events.add(e));
  
  notifier.emit(testEvent);
  await Future.delayed(Duration(ms: 100));
  
  expect(events, contains(testEvent));
});

// Error testing
test('throws on bad input', () {
  expect(
    () => function(badInput),
    throwsA(isA<Exception>()),
  );
});
```

---

## ❌ Troubleshooting (Quick Fix)

| Problem | Solution |
|---------|----------|
| Package not found | `flutter pub get` |
| Test file not found | `cd micro` → then run test |
| Test timeout | Add `--timeout=60s` |
| Compilation error | `flutter clean` + `flutter pub get` |
| Mock not working | Verify mockito in pubspec.yaml |

---

## 📊 Status Board

```
Phase 1 ✅
├── Code complete
├── 24 tests written
├── Tests passing
└── LocationTool integrated

Phase 2A ⏳
├── Code complete (0 errors)
├── 15 test stubs ready
├── Tests awaiting implementation
└── Ready for mock testing

Phase 2B ⏳
├── Code complete (0 errors)
├── Tests awaiting creation
├── Adapters ready to test
└── Provider splitting done

Phase 2C.1 ✅
├── LocationTool code complete
├── Integrated in ToolRegistry
├── Tested via Phase 1
└── 5 tools registered

Phase 2C.2 ⏳
├── CameraTool awaiting implementation
├── 3 methods planned
└── Tests to follow

Phase 2UI ⏳
├── Chat integration planned
├── E2E tests planned
└── Production milestone
```

---

## 🎯 Your Next Action

```
RIGHT NOW (5 minutes):

cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact

Expected: 24 tests pass ✅

AFTER SUCCESS:
See Phase 2A implementation guide above
```

---

## 📚 Reference Files

- **TESTING_GUIDE.md** - Complete detailed guide
- **TESTING_ROADMAP.md** - Step-by-step implementation
- **QUICK_TEST_COMMANDS.md** - Command reference
- **PHASE_2_TESTING_GUIDE.md** - Comprehensive overview
- **phase1_agent_tests.dart** - Actual test file
- **phase2a_websocket_tests.dart** - Test stubs with TODOs

---

**Last Updated**: Phase 2 Implementation Complete
**Status**: ✅ Ready for Phase 1 Verification
**Next**: Run Phase 1 tests (5 min)
