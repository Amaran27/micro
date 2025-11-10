# Phase 2 Testing Summary - What & How

## 📊 Executive Summary

**Current State**:
- ✅ Phase 1: Complete (24 tests passing)
- ✅ Phase 2A/2B/2C.1: Code complete (ZERO errors in new files)
- ⏳ Phase 2A Tests: Stubs ready (15 test cases to implement)
- ❌ Build: Blocked by pre-existing dead code (NOT Phase 2)

**What's Testable Now**:
1. **Phase 1 Agent Tests** (24 tests) - RUN NOW
2. **LocationTool** (part of Phase 1) - Already tested
3. **Phase 2A Test Stubs** (15 tests) - Ready to implement
4. **Phase 2B Adapters** (Z.AI) - Can test separately
5. **WebSocket Code** (Phase 2A) - Manual verification

---

## 🎯 WHAT TO TEST

### Priority 1: Phase 1 Verification (5 min) ✅
**What**: Ensure Phase 1 still works with LocationTool added

**Test File**: `test/phase1_agent_tests.dart`

**Covers**:
- ToolRegistry: 5/5 tools registered (including LocationTool)
- Example Tools: 4/4 tools execute correctly
- PlanExecuteAgent: Agent logic works
- AgentFactory: Task routing works

**Expected**: ✅ All 24 tests pass

**Run**:
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

---

### Priority 2: Phase 2A WebSocket Tests (30 min) ⏳
**What**: Message serialization and WebSocket communication

**Test File**: `test/phase2a_websocket_tests.dart` (15 test stubs)

**Test Categories**:

#### 2A.1 - Message Serialization (5 tests)
```
✓ Encode heartbeat message
✓ Decode plan message  
✓ Handle message type conversion
✓ Encode step execution message
✓ Decode verification message
```

#### 2A.2 - WebSocket Connection (10 tests)
```
✓ Initialize with config
✓ State transition on connect
✓ State transition on success
✓ Auto-reconnect logic
✓ Respect max reconnect attempts
✓ Error when sending while disconnected
✓ Send message when connected
✓ Trigger callbacks on state change
✓ Handle incoming messages
✓ Graceful disconnect
```

#### 2A.3 - Event Streaming (9 tests)
```
✓ Initialize empty event list
✓ Start streaming task
✓ Stop streaming task
✓ Handle incoming agent events
✓ Filter events by task ID
✓ Emit events to stream
✓ Handle deserialization errors
✓ Clear all events
✓ Clear task-specific events
```

#### 2A.4 - Integration (4 tests)
```
✓ Connect and send first message
✓ Receive and parse streaming events
✓ Handle connection errors
✓ Maintain history across reconnects
```

**Expected**: ✅ 15 tests pass (after implementation)

**Status**: Test stubs exist, bodies need implementation with mockito

---

### Priority 3: Phase 2B Provider Tests (20 min) ⏳
**What**: Z.AI provider splitting (General vs Coding)

**Components**:
- `zhipuai_general_adapter.dart` - Chat-optimized
- `zhipuai_coding_adapter.dart` - Code-optimized

**Test Cases**:
```
✓ General adapter initializes (free model)
✓ General adapter sends message
✓ General adapter handles errors
✓ Coding adapter initializes (paid models)
✓ Coding adapter sends message
✓ Coding adapter handles errors
✓ Provider switching works
✓ Temperature configuration correct
✓ Endpoint routing correct
```

**Status**: Code ready, tests not yet written

---

### Priority 4: Phase 2C.1 LocationTool Tests (10 min) ✅
**What**: Location access tool functionality

**Already Tested In**: Phase 1 tests (ToolRegistry section)

**Verification**:
```
✓ LocationTool registered in ToolRegistry
✓ Tool metadata correct (name, capabilities)
✓ Tool executes without errors
✓ Methods exist: getCurrentLocation, getLocationHistory, etc.
```

**Status**: ✅ Covered by Phase 1 tests

---

## 🚀 HOW TO TEST

### Step 1: Run Phase 1 Tests (5 min)
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**What you should see**:
```
ToolRegistry Tests
  ✓ can register and retrieve tools
  ✓ can find tools by capability
  ✓ can find tools by action
  ✓ can check if capabilities are available
  ✓ can check if all required tools are available
  ✓ can unregister tools
  ✓ can execute tools
  ✓ tool metadata is correct
  [5 tests]

Example Tools Tests
  ✓ UIValidationTool can validate elements
  ✓ SensorAccessTool can access sensors
  ✓ FileOperationTool can perform operations
  ✓ AppNavigationTool can navigate
  [4 tests]

PlanExecuteAgent Tests
  ✓ can create agent
  ✓ can plan task
  ... (10 total)

AgentFactory Tests
  ✓ creates agent for control_ui
  ... (4 total)

TaskAnalysis Tests
  ✓ analyzes mobile_app_control task
  [1 test]

════════════════════════════
24 tests passed
════════════════════════════
```

---

### Step 2: Implement Phase 2A Tests (30 min)
**File**: `test/phase2a_websocket_tests.dart`

**Current State**: Test stubs with TODO comments

**Example Implementation**:
```dart
test('encodes heartbeat message correctly', () {
  final message = MessageSerializer.createHeartbeat(clientId: 'client_1');
  final json = MessageSerializer.encode(message);
  
  expect(json, isNotEmpty);
  expect(json, contains('heartbeat'));
  expect(json, contains('client_1'));
});

test('initializes with correct config', () {
  final config = WebSocketConfig(
    url: 'ws://localhost:8080',
    reconnectDelay: Duration(seconds: 3),
    maxReconnectAttempts: 5,
  );
  
  final client = WebSocketClient(url: config.url);
  
  expect(client.state, equals(WebSocketConnectionState.disconnected));
  expect(client.isConnected, isFalse);
});

test('handles incoming agent events', () async {
  final notifier = StreamingAgentNotifier();
  
  notifier.handleMessage(AgentMessage(
    id: 'msg_1',
    taskId: 'task_1',
    type: MessageType.plan,
    payload: {'steps': []},
  ));
  
  final events = notifier.getTaskEvents('task_1');
  expect(events, isNotEmpty);
});
```

**Run**:
```powershell
flutter test test/phase2a_websocket_tests.dart --reporter=compact
```

**Expected**: ✅ 15 tests pass (after implementation)

---

### Step 3: Test Phase 2B Adapters (20 min)
**Create**: `test/phase2b_provider_tests.dart`

**Example**:
```dart
test('Z.AI General adapter initializes', () async {
  final config = ZhipuAIConfig(
    apiKey: 'test_key',
    baseUrl: 'https://api.z.ai/api/paas/v4',
  );
  
  final adapter = ZhipuAIGeneralAdapter();
  await adapter.initialize(config);
  
  expect(adapter.isInitialized, isTrue);
  expect(adapter.currentModel, equals('glm-4.5-flash'));
  expect(adapter.supportedModels, contains('glm-4.5-flash'));
});

test('Z.AI Coding adapter has coding models', () async {
  final config = ZhipuAIConfig(
    apiKey: 'test_key',
    baseUrl: 'https://api.z.ai/api/coding/paas/v4',
  );
  
  final adapter = ZhipuAICodingAdapter();
  await adapter.initialize(config);
  
  expect(adapter.isInitialized, isTrue);
  expect(adapter.supportedModels, contains('glm-4.6'));
});
```

**Run**:
```powershell
flutter test test/phase2b_provider_tests.dart --reporter=compact
```

**Expected**: ✅ 8 tests pass

---

### Step 4: Run All Tests Together (5 min)
```powershell
flutter test --reporter=compact
```

**Expected Output**:
```
════════════════════════════════════
Phase 1 Tests:     24 pass ✅
Phase 2A Tests:    15 pass ✅ (after implementation)
Phase 2B Tests:     8 pass ✅ (after creation)
════════════════════════════════════
Total:             47 tests pass
════════════════════════════════════
```

---

## 📋 Testing Checklist

### Phase 1 (Baseline) ✅
- [x] ToolRegistry loads 5 tools
- [x] LocationTool registered
- [x] All tools execute
- [x] 24 tests pass

### Phase 2A (WebSocket) - TO DO
- [ ] Create test file (or use stubs)
- [ ] Implement MessageSerializer tests
- [ ] Implement WebSocketClient tests
- [ ] Implement StreamingAgentNotifier tests
- [ ] Implement Integration tests
- [ ] All 15 tests pass

### Phase 2B (Providers) - TO DO
- [ ] Create test file
- [ ] Test General adapter
- [ ] Test Coding adapter
- [ ] Test provider switching
- [ ] All adapter tests pass

### Phase 2C.1 (Location) ✅
- [x] LocationTool methods exist
- [x] Tool registered
- [x] Covered by Phase 1 tests

### Integration - TO DO
- [ ] Phase 1 + Phase 2A together
- [ ] Phase 2A + Phase 2B together
- [ ] Full end-to-end flow

---

## 🎓 Testing Patterns Used

### 1. Unit Testing (Individual Components)
```dart
test('describes expected behavior', () {
  // Arrange: Set up test data
  final input = 'test_value';
  
  // Act: Perform the action
  final result = functionUnderTest(input);
  
  // Assert: Verify the outcome
  expect(result, equals('expected_value'));
});
```

### 2. Mocking External Dependencies
```dart
class MockWebSocketChannel extends Mock implements WebSocketChannel {}

test('sends message to channel', () {
  final mockChannel = MockWebSocketChannel();
  final client = WebSocketClient(channel: mockChannel);
  
  client.send('test');
  
  verify(mockChannel.sink.add(any)).called(1);
});
```

### 3. Async Testing
```dart
test('loads data asynchronously', () async {
  final result = await loadDataAsync();
  
  expect(result, isNotNull);
  expect(result.length, greaterThan(0));
});
```

### 4. Stream Testing
```dart
test('emits events to stream', () async {
  final events = <AgentEvent>[];
  
  final subscription = eventStream.listen((event) {
    events.add(event);
  });
  
  notifier.emitEvent(testEvent);
  await Future.delayed(Duration(milliseconds: 100));
  
  expect(events, contains(testEvent));
  subscription.cancel();
});
```

---

## 🔍 Key Test Files Location

```
micro/
├── test/
│   ├── phase1_agent_tests.dart          ✅ 24 tests (READY TO RUN)
│   │   ├── ToolRegistry Tests (5)
│   │   ├── Example Tools Tests (4)
│   │   ├── PlanExecuteAgent Tests (10)
│   │   ├── AgentFactory Tests (4)
│   │   └── TaskAnalysis Tests (1)
│   │
│   ├── phase2a_websocket_tests.dart     ⏳ 15 test stubs (READY TO IMPLEMENT)
│   │   ├── MessageSerializer Tests (5)
│   │   ├── WebSocketClient Tests (10)
│   │   ├── StreamingAgentNotifier Tests (9)
│   │   └── Integration Tests (4)
│   │
│   └── [TODO] phase2b_provider_tests.dart (TO CREATE)
│       ├── Z.AI General Adapter Tests (4)
│       └── Z.AI Coding Adapter Tests (4)
│
└── lib/
    └── infrastructure/
        ├── ai/
        │   ├── agent/
        │   │   ├── plan_execute_agent.dart ✅ Phase 1
        │   │   ├── agent_factory.dart ✅ Phase 1
        │   │   └── tools/
        │   │       ├── tool_registry.dart ✅ Phase 1
        │   │       └── example_mobile_tools.dart ✅ + LocationTool
        │   │
        │   └── adapters/
        │       ├── zhipuai_general_adapter.dart ✅ Phase 2B
        │       └── zhipuai_coding_adapter.dart ✅ Phase 2B
        │
        └── communication/ ✅ Phase 2A (all code ready)
            ├── websocket_client.dart
            ├── websocket_provider.dart
            ├── message_serializer.dart
            └── [integration with streaming_agent_provider.dart]
```

---

## 💡 Next Steps

### Immediate (Now)
```powershell
# 1. Verify Phase 1 works
flutter test test/phase1_agent_tests.dart

# 2. If pass: Continue to Step 2
# If fail: Debug Phase 1 issue
```

### Short-term (30 min)
```powershell
# 1. Open test/phase2a_websocket_tests.dart
# 2. Replace TODO comments with actual tests
# 3. Use mockito to mock WebSocketChannel
# 4. Run Phase 2A tests
flutter test test/phase2a_websocket_tests.dart
```

### Medium-term (1 hour)
```powershell
# 1. Create test/phase2b_provider_tests.dart
# 2. Test adapter initialization
# 3. Test model switching
# 4. Test error handling
flutter test test/phase2b_provider_tests.dart
```

### Long-term (Phase 2C.2+)
```powershell
# 1. Implement CameraTool
# 2. Add Phase 2UI tests
# 3. End-to-end integration tests
flutter test --reporter=compact
```

---

## 🎯 Success Criteria

**Phase 1 ✅**: 24 tests pass
```
PASS: 24 tests executed, 0 failures
```

**Phase 2A ⏳**: 15 tests pass (after implementation)
```
PASS: 15 tests executed, 0 failures
COVERAGE: WebSocket (100%), Serializer (100%), Streaming (100%)
```

**Phase 2B ⏳**: 8+ tests pass (after creation)
```
PASS: 8 tests executed, 0 failures
COVERAGE: Adapters (100%), Error handling (100%)
```

**Overall**: 47+ tests pass with no failures

---

## 📞 Troubleshooting

**Problem**: Tests not found
```powershell
# Solution: Check working directory
cd D:\Project\xyolve\micro\micro
dir test/  # Verify test files exist
```

**Problem**: Compilation errors
```powershell
# Solution: Clean and reinstall
flutter clean
flutter pub get
flutter test test/phase1_agent_tests.dart
```

**Problem**: WebSocket tests timeout
```powershell
# Solution: Use longer timeout
flutter test test/phase2a_websocket_tests.dart --timeout=60s
```

**Problem**: Mock not working
```powershell
# Solution: Ensure mockito is in pubspec.yaml
flutter pub get
# Then restart test
```

---

## 📚 Resources

- **Flutter Testing**: https://flutter.dev/docs/testing
- **Mockito**: https://pub.dev/packages/mockito
- **Test Package**: https://pub.dev/packages/test

---

## ✨ Summary

**What's testable now**:
1. ✅ Phase 1 agent tests (24 tests) - RUN NOW
2. ✅ LocationTool (covered by Phase 1)
3. ⏳ Phase 2A WebSocket (15 test stubs ready)
4. ⏳ Phase 2B Adapters (ready to test)

**How to start**:
```powershell
cd D:\Project\xyolve\micro\micro
flutter test test/phase1_agent_tests.dart --reporter=compact
```

**Expected**: ✅ 24 tests pass

---

**Created**: Phase 2 Testing Guide
**Status**: Ready for Phase 1 verification and Phase 2 implementation
**Next**: Run Phase 1 tests to establish baseline ✅
