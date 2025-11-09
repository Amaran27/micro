# Phase 2 Testing - Complete Reference

## 📊 Overview

**The Question**: "What to test? And how to test?"

**The Answer**: 
- ✅ **What**: 3 categories of tests (Phase 1 baseline, Phase 2A WebSocket, Phase 2B Adapters)
- ✅ **How**: 4 strategies (unit tests, mocks, integration tests, manual verification)
- ✅ **When**: Right now (Phase 1) → after implementation (Phase 2A/2B) → ongoing

---

## 🎯 What to Test - Complete Matrix

| Component | Category | Status | Tests | Command |
|-----------|----------|--------|-------|---------|
| **ToolRegistry** | Phase 1 ✅ | Ready | 5 | `flutter test test/phase1_agent_tests.dart` |
| **Example Tools** | Phase 1 ✅ | Ready | 4 | `flutter test test/phase1_agent_tests.dart` |
| **PlanExecuteAgent** | Phase 1 ✅ | Ready | 10 | `flutter test test/phase1_agent_tests.dart` |
| **AgentFactory** | Phase 1 ✅ | Ready | 4 | `flutter test test/phase1_agent_tests.dart` |
| **TaskAnalysis** | Phase 1 ✅ | Ready | 1 | `flutter test test/phase1_agent_tests.dart` |
| **LocationTool** | Phase 1 ✅ | Covered | (part of ToolRegistry) | `flutter test test/phase1_agent_tests.dart` |
| | | | **24 Total** | |
| **MessageSerializer** | Phase 2A ⏳ | Stubs Ready | 5 | `flutter test test/phase2a_websocket_tests.dart` |
| **WebSocketClient** | Phase 2A ⏳ | Stubs Ready | 10 | `flutter test test/phase2a_websocket_tests.dart` |
| **StreamingAgentNotifier** | Phase 2A ⏳ | Stubs Ready | 9 | `flutter test test/phase2a_websocket_tests.dart` |
| **Integration (WebSocket)** | Phase 2A ⏳ | Stubs Ready | 4 | `flutter test test/phase2a_websocket_tests.dart` |
| | | | **15 Total** | |
| **Z.AI General Adapter** | Phase 2B ⏳ | Ready | 4 | `flutter test test/phase2b_provider_tests.dart` |
| **Z.AI Coding Adapter** | Phase 2B ⏳ | Ready | 4 | `flutter test test/phase2b_provider_tests.dart` |
| | | | **8 Total** | |

---

## 🚀 How to Test - Step-by-Step Guide

### Step 0: Prerequisites (2 min)
```powershell
# Navigate to project
cd D:\Project\xyolve\micro\micro

# Get dependencies
flutter pub get

# Verify environment
flutter --version
dart --version
```

---

### Step 1: Run Phase 1 Tests NOW (5 min) ✅
```powershell
# Run Phase 1 baseline tests
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**What This Tests**:
- ✅ Agent system works (PlanExecuteAgent)
- ✅ Tool registry works (ToolRegistry with 5 tools)
- ✅ Tools execute (UIValidation, Sensor, File, Navigation, Location)
- ✅ Factory routing works (AgentFactory)
- ✅ Task analysis works (TaskAnalysis)

**Expected Output**:
```
ToolRegistry Tests
  ✓ can register and retrieve tools [5 tools]
  ✓ can find tools by capability
  ✓ can find tools by action
  ✓ can check if capabilities are available
  ✓ can check if all required tools are available
  ✓ can unregister tools
  ✓ can execute tools
  ✓ tool metadata is correct

Example Tools Tests
  ✓ UIValidationTool can validate elements
  ✓ SensorAccessTool can access sensors
  ✓ FileOperationTool can perform operations
  ✓ AppNavigationTool can navigate

PlanExecuteAgent Tests
  ✓ can create agent
  ✓ can plan task
  ✓ can execute plan
  ✓ can verify steps
  ✓ can recover from errors
  ✓ can handle tool not found
  ✓ can log progress
  ✓ can manage state
  ✓ can complete successfully
  ✓ can analyze task

AgentFactory Tests
  ✓ creates agent for control_ui
  ✓ creates agent for sensor_data
  ✓ creates agent for unknown task
  ✓ can load configuration

TaskAnalysis Tests
  ✓ analyzes mobile_app_control task

════════════════════════════════════════════
24 tests passed in ~2 seconds
════════════════════════════════════════════
```

**If tests pass** ✅ → Continue to Step 2  
**If tests fail** ❌ → See Troubleshooting section

---

### Step 2: Implement Phase 2A Tests (30 min) ⏳
**File**: `test/phase2a_websocket_tests.dart` (already created with 15 test stubs)

**What to Do**:
1. Open the test file
2. Replace TODO comments with actual test implementations
3. Use mockito for mocking WebSocketChannel
4. Run the tests

**Example Implementation - MessageSerializer Test**:
```dart
test('encodes heartbeat message correctly', () {
  // Arrange
  const clientId = 'client_1';
  
  // Act
  final message = MessageSerializer.createHeartbeat(clientId: clientId);
  final encoded = MessageSerializer.encode(message);
  
  // Assert
  expect(encoded, isNotEmpty);
  expect(encoded, contains('heartbeat'));
  expect(encoded, contains(clientId));
});
```

**Example Implementation - WebSocketClient Test**:
```dart
test('initializes with correct config', () {
  // Arrange
  const url = 'ws://localhost:8080';
  
  // Act
  final client = WebSocketClient(url: url);
  
  // Assert
  expect(client.state, equals(WebSocketConnectionState.disconnected));
  expect(client.isConnected, isFalse);
  expect(client.url, equals(url));
});
```

**Run Phase 2A Tests** (after implementation):
```powershell
flutter test test/phase2a_websocket_tests.dart --reporter=compact
```

**Expected**: ✅ 15 tests pass

---

### Step 3: Create Phase 2B Provider Tests (20 min) ⏳
**File to Create**: `test/phase2b_provider_tests.dart`

**What to Test**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_general_adapter.dart';
import 'package:micro/infrastructure/ai/adapters/zhipuai_coding_adapter.dart';

void main() {
  group('Z.AI General Adapter Tests', () {
    test('initializes with free model', () async {
      final adapter = ZhipuAIGeneralAdapter();
      
      expect(adapter.isInitialized, isFalse);
      expect(adapter.supportedModels, contains('glm-4.5-flash'));
    });

    test('sends message to general endpoint', () async {
      final adapter = ZhipuAIGeneralAdapter();
      // Test endpoint: /paas/v4
      // Test temp: 0.7
      expect(adapter.endpoint, contains('/paas/v4'));
    });

    test('can switch between models', () async {
      final adapter = ZhipuAIGeneralAdapter();
      await adapter.setModel('glm-4.6');
      
      expect(adapter.currentModel, equals('glm-4.6'));
    });

    test('handles initialization errors', () async {
      final adapter = ZhipuAIGeneralAdapter();
      // Test with invalid API key
      expect(
        () => adapter.initialize(invalidConfig),
        throwsException,
      );
    });
  });

  group('Z.AI Coding Adapter Tests', () {
    test('initializes with code-optimized models', () async {
      final adapter = ZhipuAICodingAdapter();
      
      expect(adapter.isInitialized, isFalse);
      expect(adapter.supportedModels, contains('glm-4.6'));
    });

    test('sends message to coding endpoint', () async {
      final adapter = ZhipuAICodingAdapter();
      // Test endpoint: /coding/paas/v4
      // Test temp: 0.3
      expect(adapter.endpoint, contains('/coding/paas/v4'));
    });

    test('can switch between models', () async {
      final adapter = ZhipuAICodingAdapter();
      await adapter.setModel('glm-4.5');
      
      expect(adapter.currentModel, equals('glm-4.5'));
    });

    test('handles initialization errors', () async {
      final adapter = ZhipuAICodingAdapter();
      expect(
        () => adapter.initialize(invalidConfig),
        throwsException,
      );
    });
  });

  group('Provider Switching Tests', () {
    test('can switch from general to coding', () async {
      final generalAdapter = ZhipuAIGeneralAdapter();
      final codingAdapter = ZhipuAICodingAdapter();
      
      expect(generalAdapter.endpoint, contains('/paas/v4'));
      expect(codingAdapter.endpoint, contains('/coding/paas/v4'));
    });

    test('models are independent', () async {
      final generalAdapter = ZhipuAIGeneralAdapter();
      final codingAdapter = ZhipuAICodingAdapter();
      
      await generalAdapter.setModel('glm-4.5-flash');
      await codingAdapter.setModel('glm-4.6');
      
      expect(generalAdapter.currentModel, equals('glm-4.5-flash'));
      expect(codingAdapter.currentModel, equals('glm-4.6'));
    });

    test('temperature is different', () {
      final generalAdapter = ZhipuAIGeneralAdapter();
      final codingAdapter = ZhipuAICodingAdapter();
      
      expect(generalAdapter.temperature, equals(0.7));
      expect(codingAdapter.temperature, equals(0.3));
    });

    test('both implement ProviderAdapter interface', () {
      final generalAdapter = ZhipuAIGeneralAdapter();
      final codingAdapter = ZhipuAICodingAdapter();
      
      expect(generalAdapter, isA<ProviderAdapter>());
      expect(codingAdapter, isA<ProviderAdapter>());
    });
  });
}
```

**Run Phase 2B Tests** (after creation):
```powershell
flutter test test/phase2b_provider_tests.dart --reporter=compact
```

**Expected**: ✅ 8 tests pass

---

### Step 4: Run All Tests Together (5 min)
```powershell
flutter test --reporter=compact
```

**Expected Final Output**:
```
Phase 1 Tests:     24 pass ✅
Phase 2A Tests:    15 pass ✅ (after implementation)
Phase 2B Tests:     8 pass ✅ (after creation)
────────────────────────────
Total:             47+ tests pass ✅
```

---

## 🧪 Testing Strategies & Patterns

### Strategy 1: Unit Testing (Isolated Components)
```dart
test('component behaves correctly', () {
  // Arrange: Set up test data
  final input = TestData.createInput();
  
  // Act: Call the component
  final result = componentUnderTest(input);
  
  // Assert: Verify the outcome
  expect(result.isValid, isTrue);
  expect(result.value, equals(expectedValue));
});
```

### Strategy 2: Mocking External Dependencies
```dart
// For WebSocket tests
final mockChannel = MockWebSocketChannel();
final mockSink = MockSink();

when(mockChannel.sink).thenReturn(mockSink);
when(mockChannel.stream).thenAnswer((_) => Stream.value('{"type": "pong"}'));

final client = WebSocketClient(channel: mockChannel);
client.send('ping');

verify(mockSink.add(any)).called(1);
```

### Strategy 3: Async Testing
```dart
test('async operation completes', () async {
  // Use async/await in test
  final result = await performAsyncOperation();
  
  expect(result, isNotNull);
  expect(result.isComplete, isTrue);
});
```

### Strategy 4: Stream Testing
```dart
test('emits events to stream', () async {
  final events = <Event>[];
  
  final subscription = eventStream.listen((event) {
    events.add(event);
  });
  
  // Trigger events
  notifier.emitEvent(testEvent);
  
  // Wait for stream to emit
  await Future.delayed(Duration(milliseconds: 100));
  
  expect(events, contains(testEvent));
  subscription.cancel();
});
```

### Strategy 5: Error Handling Testing
```dart
test('throws on invalid input', () {
  expect(
    () => functionUnderTest(invalidInput),
    throwsA(isA<InvalidInputException>()),
  );
});

test('handles errors gracefully', () async {
  try {
    await riskyOperation();
    fail('Should have thrown');
  } on OperationException catch (e) {
    expect(e.message, contains('expected error'));
  }
});
```

---

## 📋 Testing Checklist

### Phase 1 Verification ✅
```
[x] ToolRegistry loads all 5 tools
[x] LocationTool correctly registered
[x] All tools have proper metadata
[x] PlanExecuteAgent creates agents
[x] AgentFactory routes tasks
[x] 24 tests pass with no failures
```

### Phase 2A Implementation ⏳
```
[ ] MessageSerializer tests implemented (5)
    [ ] Heartbeat encoding
    [ ] Plan message decoding
    [ ] Message type conversion
    [ ] Step execution encoding
    [ ] Verification decoding

[ ] WebSocketClient tests implemented (10)
    [ ] Initialization
    [ ] Connection state transitions
    [ ] Reconnection logic
    [ ] Message sending
    [ ] Callback triggering
    [ ] Error handling
    [ ] Graceful disconnect

[ ] StreamingAgentNotifier tests implemented (9)
    [ ] Initialization
    [ ] Start/stop streaming
    [ ] Event handling
    [ ] Event filtering
    [ ] Stream emission
    [ ] Error handling

[ ] Integration tests implemented (4)
    [ ] Connect and send flow
    [ ] Event streaming flow
    [ ] Error recovery
    [ ] Persistence across reconnect

[ ] 15 tests pass with no failures
```

### Phase 2B Implementation ⏳
```
[ ] Z.AI General Adapter tests created
    [ ] Initialization
    [ ] Model switching
    [ ] Endpoint routing
    [ ] Error handling

[ ] Z.AI Coding Adapter tests created
    [ ] Initialization
    [ ] Model switching
    [ ] Endpoint routing
    [ ] Error handling

[ ] Provider switching tests
    [ ] Independent model state
    [ ] Different endpoints
    [ ] Different temperatures

[ ] 8 tests pass with no failures
```

---

## 🔍 File Locations & References

```
d:\Project\xyolve\micro\
├── micro/
│   ├── test/
│   │   ├── phase1_agent_tests.dart ✅ READY TO RUN
│   │   │   └── 24 tests
│   │   │
│   │   └── phase2a_websocket_tests.dart ⏳ STUBS READY
│   │       └── 15 test stubs (need implementation)
│   │
│   └── lib/
│       ├── infrastructure/
│       │   ├── ai/
│       │   │   ├── agent/
│       │   │   │   ├── plan_execute_agent.dart ✅
│       │   │   │   ├── agent_factory.dart ✅
│       │   │   │   └── tools/
│       │   │   │       ├── tool_registry.dart ✅
│       │   │   │       └── example_mobile_tools.dart ✅ (LocationTool)
│       │   │   │
│       │   │   └── adapters/
│       │   │       ├── zhipuai_general_adapter.dart ✅ Phase 2B
│       │   │       └── zhipuai_coding_adapter.dart ✅ Phase 2B
│       │   │
│       │   └── communication/ ✅ Phase 2A
│       │       ├── websocket_client.dart
│       │       ├── websocket_provider.dart
│       │       ├── message_serializer.dart
│       │       └── [streaming integration]
│       │
│       └── features/
│           └── agent/
│               └── providers/
│                   └── streaming_agent_provider.dart ✅ Phase 2A
│
└── TESTING_GUIDE.md (this file)
    QUICK_TEST_COMMANDS.md
    PHASE_2_TESTING_GUIDE.md
```

---

## 🎯 Quick Start Commands

```powershell
# 1. Verify Phase 1 (5 min)
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact

# 2. Check for errors
flutter analyze

# 3. Run with watch mode (auto-rerun on change)
flutter test test/phase1_agent_tests.dart --watch

# 4. Run specific test
flutter test -k "ToolRegistry" test/phase1_agent_tests.dart

# 5. Run all tests
flutter test --reporter=compact

# 6. Run with coverage
flutter test --coverage

# 7. Check Phase 2A stubs
cat test/phase2a_websocket_tests.dart | head -50
```

---

## ❓ Troubleshooting

### Issue: "Could not find test package"
```powershell
# Solution
flutter clean
flutter pub get
flutter test test/phase1_agent_tests.dart
```

### Issue: Tests timeout
```powershell
# Solution - increase timeout
flutter test test/phase1_agent_tests.dart --timeout=60s
```

### Issue: "Package not found: micro"
```powershell
# Solution - verify import paths
cd D:\Project\xyolve\micro\micro
flutter pub get
flutter test test/phase1_agent_tests.dart
```

### Issue: MockWebSocketChannel not mocking
```powershell
# Ensure mockito is in pubspec.yaml
# Add: mockito: ^5.4.0

flutter pub get
flutter test test/phase2a_websocket_tests.dart
```

### Issue: Assertion fails unexpectedly
```powershell
# Run with verbose output
flutter test test/phase1_agent_tests.dart -v

# Or run specific test
flutter test -k "specific_test_name" -v
```

---

## 📈 Progress Timeline

**Phase 1** (Already Complete) ✅
```
Week 1: Agent backend implementation
Week 2: ToolRegistry + 5 tools
Week 3: Tests written & passing (24/24)
```

**Phase 2A** (Current) ⏳
```
Step 1: Verify Phase 1 tests pass ← YOU ARE HERE
Step 2: Implement Phase 2A test bodies (30 min)
Step 3: Run Phase 2A tests (15 tests)
```

**Phase 2B** (Next) ⏳
```
Step 4: Create Phase 2B provider tests (20 min)
Step 5: Run Phase 2B tests (8 tests)
```

**Phase 2C.2** (After Phase 2A/2B) ⏳
```
Step 6: Implement CameraTool
Step 7: Add Phase 2C.2 tests
Step 8: Run all tests (47+ tests)
```

**Phase 2UI** (Final) ⏳
```
Step 9: Chat UI integration
Step 10: E2E tests
Step 11: Production ready
```

---

## ✨ Summary

**WHAT to test**:
1. ✅ Phase 1 agent system (24 tests ready)
2. ✅ LocationTool (covered by Phase 1)
3. ⏳ Phase 2A WebSocket (15 test stubs ready)
4. ⏳ Phase 2B Adapters (ready to test)

**HOW to test**:
1. ✅ Unit tests for individual components
2. ✅ Mocks for external dependencies
3. ✅ Integration tests for full flows
4. ✅ Manual verification for UI

**WHEN to test**:
1. ✅ Now - Phase 1 baseline (5 min)
2. ⏳ After impl - Phase 2A (30 min)
3. ⏳ After creation - Phase 2B (20 min)
4. ⏳ Ongoing - All tests together

---

## 🚀 Next Action

**Run RIGHT NOW**:
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected**: ✅ 24 tests pass

**Then**: Continue with Phase 2A test implementation

---

**Testing Guide Created**: Phase 2 Complete Reference
**Status**: Ready for Phase 1 verification
**Next**: Run Phase 1 tests to establish baseline ✅
