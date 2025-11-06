# Autonomous Agent Implementation Plan

## Current Status Assessment (FACTUAL)

### ✅ WHAT EXISTS (Backend Infrastructure)
1. **Agent Core**: `autonomous_agent.dart` - Complete planning/execution engine
2. **Agent Service**: `agent_service.dart` - Agent lifecycle management 
3. **Agent Types**: Models, enums, configurations
4. **Memory System**: Full episodic/semantic/conversation memory
5. **Delegation Framework**: `agent_delegation.dart` (needs review)
6. **MCP Models**: Server configs, tool definitions, state tracking
7. **MCP Service**: Server management, connection handling (STUB implementations)
8. **Provider MCP Binding**: Tool format translation (exists but incomplete)

### ❌ WHAT'S MISSING (Critical Gaps)

#### 1. MCP Service - Real Implementation
**File**: `lib/infrastructure/ai/mcp/mcp_service.dart`
**Issue**: Methods are TODOs/stubs - no actual JSON-RPC calls
**Needs**:
- Actual HTTP/SSE/stdio transport implementation
- Real `callTool()` with JSON-RPC 2.0 protocol
- Server connection/disconnect with handshake
- Tool discovery from servers
- Error handling and retry logic

#### 2. Agent Service - Model Creation
**File**: `lib/infrastructure/ai/agent/agent_service.dart` 
**Issue**: Line 340 throws `UnimplementedError` - cannot create LLM models
**Needs**:
- Add `langchain_openai` dependency to pubspec.yaml
- Implement `_createModel()` to return actual ChatOpenAI/ChatAnthropic/etc.
- Wire to user's provider configuration from settings

#### 3. Chat Page - Agent Integration
**File**: `lib/presentation/pages/enhanced_ai_chat_page.dart`
**Issue**: `_agentMode` is just a boolean - no AgentService integration
**Needs**:
- Import and inject AgentService
- When `_agentMode == true`: call `agentService.executeGoal()` instead of direct chat
- Display agent steps in real-time via `stepStream`
- Show tool executions with visual feedback
- Handle agent errors gracefully

#### 4. Tools Page - Tool Enable/Disable Persistence & Integration
**File**: `lib/presentation/pages/tools_page.dart`
**Issue**: `_enabledTools` map is local state only - not persisted or used by agents
**Needs**:
- Save enabled tools to FlutterSecureStorage
- Create Riverpod provider for enabled tools state
- Wire to Agent Service - only pass enabled tools to agent
- Update reactively when user toggles tools

#### 5. MCP Tool Integration with Agent
**Files**: Multiple
**Issue**: Agent can't actually call MCP tools
**Needs**:
- Update `autonomous_agent.dart` line 306: `_executeTool()` to call MCP
- Create `MCPToolExecutor` service 
- Bridge: Tool name → find MCP server → call via MCPService → return result
- Handle tool failures and timeouts

#### 6. Provider Integration
**Issue**: MCP settings in provider config not actually used
**Needs**:
- When creating agent, read provider's `mcpEnabled` and `mcpServerIds`
- Only load tools from those specific servers
- Pass provider's LLM to agent

#### 7. Sub-agent (Microbot) Delegation
**File**: `lib/infrastructure/ai/agent/agent_delegation.dart` (exists but unused)
**Needs**:
- Review and complete delegation logic
- Desktop: Spawn sub-agents as separate isolates
- Mobile: Sequential execution (no true parallelism)
- Communication channel between agents
- Cleanup on task completion

## Implementation Phases (Priority Order)

### Phase A: Foundation (Critical Path)
1. Add `langchain_openai` to pubspec.yaml
2. Fix AgentService model creation
3. Implement real MCP JSON-RPC calls in MCPService
4. Create MCPToolExecutor bridge

### Phase B: Agent-Chat Integration
1. Wire AgentService to chat page
2. Display agent steps in UI
3. Show tool executions
4. Error handling and retry

### Phase C: Tool Management
1. Persist enabled tools
2. Create tools provider
3. Wire to agent service
4. Reactive updates

### Phase D: Provider Integration
1. Read MCP config from provider settings
2. Filter tools by selected servers
3. Use provider's LLM for agent

### Phase E: Sub-agent Delegation (Advanced)
1. Complete delegation framework
2. Isolate spawning (desktop)
3. Sequential fallback (mobile)
4. Agent communication protocol

### Phase F: Build Verification
1. Generate code: `flutter pub run build_runner build`
2. Analyze: `flutter analyze`
3. Build Android: `flutter build apk`
4. Build Desktop: `flutter build windows/linux/macos`
5. Test on device

## Success Criteria

### Functional
- [ ] User enables agent mode in chat
- [ ] Agent receives message and creates plan
- [ ] Agent identifies which MCP tools are needed
- [ ] Agent calls MCP tools through servers
- [ ] Tools execute and return results
- [ ] Agent uses results to reason and respond
- [ ] User sees agent thinking process in UI
- [ ] Tool executions visible in real-time
- [ ] Sub-agents can be delegated to (desktop)
- [ ] Everything works on mobile (sequential mode)

### Technical
- [ ] App builds without errors on all platforms
- [ ] No runtime exceptions
- [ ] State management is reactive
- [ ] Tool enable/disable persists across restarts
- [ ] Agent memory accumulates learnings
- [ ] Performance is acceptable (< 30s for typical tasks)

## Estimated Timeline
- Phase A: 2-3 hours
- Phase B: 1-2 hours  
- Phase C: 1 hour
- Phase D: 1 hour
- Phase E: 2-3 hours
- Phase F: 1-2 hours
- **Total**: 8-12 hours of focused implementation

## Current Commit Strategy
- Commit after each phase
- Include factual evidence of implementation
- Build and test iteratively
- No "done" claims without proof
