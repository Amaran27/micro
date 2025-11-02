# Post-Fix: What's Next (Phase 2 Planning)

Once the Phase 1 agent tests pass (estimated 20 min), here's the planned roadmap:

---

## Current State (After Phase 1 Fixes)

✅ **Complete**:
- PlanStep/StepResult/Verification models (freezed, immutable)
- PlanExecuteAgent (491 lines, Plan-Execute-Verify-Replan cycle)
- AgentFactory (280+ lines, task analysis & routing)
- ToolRegistry (180+ lines, dynamic tool management)
- 4 Example Mobile Tools (UIValidation, SensorAccess, FileOperation, AppNavigation)
- 24 Comprehensive Test Cases
- Riverpod integration ready

✅ **Tested & Working**:
- LangChain integration (langchain 0.8.0)
- JSON serialization (freezed/json_serializable)
- Mock-based unit testing (mockito)

---

## Phase 2: Agent Communication Architecture

### Phase 2A: WebSocket Streaming (Priority: HIGH)

**What**: Real-time streaming responses from mobile agent to desktop UI

**Why**: Current REST is blocking. WebSocket enables:
- Live streaming of plan steps as they execute
- Real-time verification results
- Immediate user feedback without polling
- Streaming LLM responses (token-by-token)

**Files to Create**:
```
lib/infrastructure/communication/
  websocket_client.dart      (200 lines - handles WS connection)
  websocket_provider.dart    (150 lines - Riverpod integration)
  message_serializer.dart    (100 lines - encode/decode messages)
  
lib/features/agent/providers/
  streaming_agent_provider.dart (250 lines - streaming state management)
  streaming_results_handler.dart (150 lines - process stream events)
```

**Key Classes**:
- `WebSocketClient` - manages connection lifecycle
- `StreamingAgentNotifier` - extends ChatNotifier with stream support
- `AgentStreamEvent` - union type for different event types

**Expected Completion**: 3-4 hours

---

### Phase 2B: Provider Configuration Splitting (Priority: MEDIUM)

**What**: Split Z.AI into separate general and coding endpoints

**Why**: Currently single Z.AI provider. Users should choose:
- `zai-general`: Chat optimized (glm-4.5-flash free)
- `zai-coding`: Code optimized (better code analysis)

**Current Setup**:
```
lib/infrastructure/ai/adapters/zhipuai_adapter.dart (single endpoint)
  → Uses: https://api.z.ai/api/paas/v4 (general)
  → Has: coding endpoint URL but not used
```

**New Setup**:
```
lib/infrastructure/ai/adapters/
  zhipuai_general_adapter.dart   (chat optimized)
  zhipuai_coding_adapter.dart    (code optimized)
  
lib/infrastructure/ai/config/
  provider_registry.dart (register both variants)
```

**Model Selection UI Impact**:
```
Before:
Provider: [Z.AI]
Model: [glm-4.5-flash] [glm-4.6] [glm-4.5]

After:
Provider: [Z.AI General] [Z.AI Coding] [OpenAI] [Google]
Model: [glm-4.5-flash] [glm-4.6] [glm-4.5]
```

**Expected Completion**: 1-2 hours

---

### Phase 2C: Additional Mobile Tools (Priority: MEDIUM)

**Current Tools** (4):
1. UIValidationTool - Inspect UI elements
2. SensorAccessTool - Read device sensors
3. FileOperationTool - Read/write files
4. AppNavigationTool - Navigate to screens

**New Tools to Add** (recommended order):

#### Tool #5: LocationTool (HIGH value)
```dart
class LocationTool extends MobileTool {
  Future<Map<String, dynamic>> getCurrentLocation()
  Future<List<Map<String, dynamic>>> getLocationHistory()
  Future<void> startLocationTracking()
  Future<void> stopLocationTracking()
}
```
- Uses: `geolocator` (already in pubspec)
- Capabilities: ['location-access', 'gps-tracking', 'geocoding']
- Example: "Where am I?" → Get coordinates → Agent decides action

#### Tool #6: CameraTool (MEDIUM value)
```dart
class CameraTool extends MobileTool {
  Future<String> takePhoto()  // Returns base64 image
  Future<String> scanQRCode()
  Future<List<String>> detectObjects(String imagePath)  // Via LLM
}
```
- Uses: `image_picker`, `camera` packages (need to add)
- Capabilities: ['camera-capture', 'qr-scanning', 'image-analysis']

#### Tool #7: AccessibilityTool (MEDIUM value)
```dart
class AccessibilityTool extends MobileTool {
  Future<String> readScreenContent()     // OCR via camera
  Future<void> speakText(String text)    // Text-to-speech
  Future<String> listenForSpeech()       // Speech-to-text
}
```
- Uses: `flutter_tts`, `speech_to_text` packages (need to add)
- Capabilities: ['text-to-speech', 'speech-to-text', 'screen-reader']

#### Tool #8: AppManagementTool (LOW value, Phase 3)
```dart
class AppManagementTool extends MobileTool {
  Future<List<AppInfo>> getInstalledApps()
  Future<void> launchApp(String packageName)
  Future<void> uninstallApp(String packageName)
}
```
- Uses: `device_apps` package (need to add)
- Capabilities: ['app-management', 'app-launcher']

**Implementation Order**:
1. LocationTool (uses existing `geolocator` dependency)
2. CameraTool (add `image_picker`, `camera`)
3. AccessibilityTool (add `flutter_tts`, `speech_to_text`)
4. AppManagementTool (Phase 3)

**Expected Completion**: 2-3 hours for all 3

---

## Prioritized Phase 2 Roadmap

### Week 1 (After Phase 1 Pass):
```
Mon: WebSocket Streaming (Phase 2A) - 3-4 hours
     → Desktop agent can receive real-time updates
     
Tue: Provider Splitting (Phase 2B) - 1-2 hours
     → UI shows z.ai-general and z.ai-coding separately
     
Wed: LocationTool (Phase 2C.1) - 1 hour
     → Agent knows device location, can reference it in decisions
```

### Week 2:
```
Thu: CameraTool (Phase 2C.2) - 1.5 hours
     → Agent can take photos, analyze images
     
Fri: AccessibilityTool (Phase 2C.3) - 1.5 hours
     → Agent can read screen content, communicate via voice
     
Weekend: Integration testing, bug fixes
```

---

## Success Metrics for Phase 2

| Milestone | Success Criteria |
|-----------|------------------|
| Phase 2A Complete | Desktop UI receives streaming plan steps in real-time |
| Phase 2B Complete | User can select between Z.AI General and Coding providers |
| Phase 2C Complete | Agent can use location + camera + voice communication |
| Full Phase 2 | Mobile agent 80% feature-complete for MVP |

---

## Phase 3 Planning (After Phase 2)

### Phase 3A: Dead Code Cleanup
Remove ~15 deprecated files:
```
lib/presentation/pages/
  main_*.dart (5 files)
  *_old.dart (3 files)
  *_backup.dart (2 files)
  *.disabled (2 files)
  
lib/infrastructure/ai/providers/
  *_backup.dart (3 files)
```

### Phase 3B: MCP Client Integration
Implement Model Context Protocol client:
```
lib/infrastructure/mcp/
  mcp_client.dart (300 lines)
  mcp_protocol_handler.dart (200 lines)
  mcp_tools_adapter.dart (150 lines)
```

### Phase 3C: Desktop Agent Implementation
Parallel desktop agent using same architecture:
```
lib/infrastructure/ai/agent/
  desktop_agent.dart
  desktop_tools.dart (file system, network, process management)
  desktop_agent_provider.dart
```

---

## Current Blockers (Phase 1 Only)

After Phase 1 tests pass, there are NO blockers for Phase 2.

**Dependencies Already in pubspec.yaml**:
✅ websocket_channel
✅ riverpod (for state management)
✅ geolocator (for location)
✅ dio (for HTTP)

**Dependencies to Add for Full Phase 2C**:
- `image_picker` (camera/gallery)
- `camera` (camera streams)
- `flutter_tts` (text-to-speech)
- `speech_to_text` (speech-to-text)
- `device_apps` (app management, Phase 3)

---

## How Phase 2 Fits into Overall Architecture

```
Current State (Phase 1):
  Mobile Agent ←[REST]→ Tests Only
  (can plan, execute, verify)

After Phase 2A (WebSocket):
  Mobile Agent ←[WebSocket]→ Desktop UI
  (real-time streaming)

After Phase 2B (Provider Splitting):
  Mobile Agent ←[Multiple Providers]→ Desktop UI
  (flexible AI backend selection)

After Phase 2C (New Tools):
  Mobile Agent ←[WebSocket]→ Desktop UI
  (with location, camera, voice)
  ↓ (can access)
  Device: Location, Camera, Sensors, Files, Apps

After Phase 3 (MCP + Desktop):
  Mobile Agent ←→ Desktop Agent
  (bidirectional communication)
  ↓ (can access)
  Mobile: Location, Camera, Sensors, Files
  Desktop: Filesystem, Network, Processes, Databases
```

---

## Questions to Answer Before Phase 2

1. **WebSocket Priority**: How important is real-time streaming vs polling?
2. **Tool Priority**: Location or Camera first?
3. **Desktop Ready**: Is desktop agent development needed in parallel or after mobile?
4. **Testing**: Should Phase 2 maintain same test coverage (24+ tests)?
5. **Deployment**: Mobile-only MVP or desktop co-release?

---

## Estimated Total Time for Phase 2

| Component | Time | Priority |
|-----------|------|----------|
| Phase 2A: WebSocket | 3-4 hrs | HIGH |
| Phase 2B: Provider Split | 1-2 hrs | MEDIUM |
| Phase 2C.1: Location | 1 hr | MEDIUM |
| Phase 2C.2: Camera | 1.5 hrs | MEDIUM |
| Phase 2C.3: Accessibility | 1.5 hrs | MEDIUM |
| Integration + Testing | 2-3 hrs | HIGH |
| **Total** | **10-13 hrs** | - |

**Timeline**: 2-3 days of focused development (assuming 8-10 hour work days)

---

## Next Command After Phase 1 Tests Pass

```bash
# Once flutter test returns: "24 tests passed"
# Run this to see what's next:

echo "Phase 1 Complete! Starting Phase 2..."
echo "1. Choose priority: WebSocket (2A), Provider Split (2B), or Tools (2C)"
echo "2. Create feature branch: git checkout -b feature/phase2-<component>"
echo "3. Proceed with implementation"
```
