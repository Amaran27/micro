# Architecture Decision Records (ADRs) - Micro Agent System

**Document Version**: 1.0  
**Created**: November 2, 2025  
**Status**: Active  
**Format**: Based on [Lightweight ADRs](https://adr.github.io/) template

---

## ADR-001: Plan-Execute Agent Pattern

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
The Micro system requires autonomous agents capable of multi-step reasoning and task execution. The team evaluated several agent patterns:

1. **ReAct (Reasoning + Acting)**
   - Agent loops: Think → Act → Observe → Loop
   - Pros: Simple, proven pattern
   - Cons: Trial-and-error, no upfront planning, wasteful of LLM calls

2. **Chain-of-Thought**
   - Agent: Explains reasoning step-by-step
   - Pros: Interpretable
   - Cons: Linear only, no tool orchestration

3. **Plan-Execute**
   - Agent: Plan → Execute → Verify → Replan (if needed)
   - Pros: Multi-step planning, progress tracking, deterministic
   - Cons: Slightly more complex, requires good LLM planning ability

4. **AutoGen (Agent Communication)**
   - Multi-agent coordination
   - Pros: Powerful for complex tasks
   - Cons: Overkill for MVP, operational complexity

5. **LangGraph (Graph-Based Execution)**
   - Directed graph of agent nodes
   - Pros: Explicit workflow definition
   - Cons: Python-only (mobile incompatible), steeper learning curve

### Decision
**Adopt Plan-Execute Agent Pattern** for both mobile (Dart) and desktop (Python).

### Rationale

1. **Efficiency**: Plan upfront → fewer LLM calls than ReAct trial-and-error
2. **Predictability**: Planned steps allow progress tracking and ETA estimates
3. **Replanning**: Built-in failure recovery without infinite loops (max 2 replans)
4. **Resource Efficiency**: Critical for mobile devices (battery, bandwidth)
5. **Clarity**: Easy to debug (can inspect intermediate plans and results)
6. **Simplicity**: Balanced complexity (not too simple like chain-of-thought, not too complex like LangGraph)

### Implementation
- **Phase 1**: Basic Plan → Execute → Verify cycle
- **Phase 2**: Add streaming during execution (token-by-token)
- **Phase 3**: Optional: Multi-agent swarm with supervisor (extending Plan-Execute)

### Consequences

**Positive**:
- ✅ Mobile agents remain lightweight and responsive
- ✅ Deterministic execution order (good for debugging)
- ✅ Built-in progress tracking in UI
- ✅ Extensible to multi-agent swarms
- ✅ Works across Dart (mobile) and Python (desktop)

**Negative**:
- ⚠️ Requires good LLM model (weak models may fail at planning)
- ⚠️ More complex than simple chain-of-thought
- ⚠️ Replanning adds latency (max 2 attempts)

### Alternatives Rejected

**ReAct**: Too wasteful of LLM calls, creates UX of "stuttering" (agent keeps stopping and starting)  
**LangGraph**: Python-only, cannot use on mobile without custom re-implementation  
**AutoGen**: Adds multi-agent complexity not needed for MVP  

### References
- [ReAct: Synergizing Reasoning and Acting in Language Models](https://arxiv.org/abs/2210.03629)
- [Chain-of-Thought Prompting](https://arxiv.org/abs/2201.11903)
- [Agentic Reasoning in LangChain](https://docs.langchain.com/oss/python/langchain)

---

## ADR-002: Dynamic ToolRegistry (Zero Hardcoding)

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
The team considered two approaches to agent specialization:

**Approach A: Hardcoded Agent Classes**
```dart
class LoginTestAgent extends PlanExecuteAgent { ... }
class CodeGeneratorAgent extends PlanExecuteAgent { ... }
class DataAnalysisAgent extends PlanExecuteAgent { ... }
```
Pros: Simple, predictable  
Cons: Not scalable, brittle, requires code changes for each new task

**Approach B: Dynamic Agent Creation via ToolRegistry**
```dart
// No hardcoded classes
// Agents created at runtime based on task + available tools
final agent = await agentFactory.createAgentForTask(task);
```
Pros: Highly extensible, no code changes needed for new tasks  
Cons: Slightly more complex, requires good LLM task analysis

### Decision
**Adopt Dynamic ToolRegistry Pattern** (Approach B) - Zero hardcoded agent specializations.

### Rationale

1. **Extensibility**: Add new tool → automatically available to agents (no code change)
2. **Scalability**: System grows gracefully with new tools, not new agent classes
3. **Maintainability**: Behavior centralized in tool implementations, not scattered across agent classes
4. **Flexibility**: Same agent class handles infinite task variations
5. **Testing**: Test agent once, trust it works with any tool combination
6. **Future-Proof**: MCP protocol will leverage this design for tool discovery

### Implementation

**Registry Structure**:
```dart
class ToolRegistry {
  Map<String, Tool> _tools;
  Map<String, Set<String>> _toolCapabilities; // tool → capabilities
  Map<String, String> _toolDomains; // tool → domain
  
  void registerTool(Tool tool, Set<String> capabilities, String domain) { ... }
  List<Tool> getToolsForCapabilities(List<String> capabilities) { ... }
}
```

**Agent Creation Flow**:
```
Task: "Test login UI"
  ↓
Task Analyzer (LLM): "Needs capabilities: [UI_VALIDATION, SCREENSHOT, REPORTING]"
  ↓
ToolRegistry.getToolsForCapabilities([UI_VALIDATION, SCREENSHOT, REPORTING])
  → Returns: [validateUITool, screenshotTool, reportTool]
  ↓
Agent created with these tools only
  ↓
System prompt: "You are specialized in: ui_validation, testing, reporting"
  ↓
Agent executes
```

### Consequences

**Positive**:
- ✅ No hardcoded agent classes - pure dynamic behavior
- ✅ Adding new capability is trivial (register tool, it works immediately)
- ✅ Clear separation: Agent logic vs Tool implementations
- ✅ Enables MCP tool discovery (Phase 3)
- ✅ Fits MCP model exactly (resources → tools)

**Negative**:
- ⚠️ Task analysis (LLM) must be accurate
- ⚠️ Tool metadata must be complete and correct
- ⚠️ Debugging requires understanding capability matching

### Alternatives Rejected

**Hardcoded Classes**: Creates technical debt, not scalable, brittleness increases with each new agent type.

### References
- [Registry Pattern](https://refactoring.guru/design-patterns/registry)
- [Dependency Injection](https://en.wikipedia.org/wiki/Dependency_injection)
- [MCP Tool Discovery](https://modelcontextprotocol.io)

---

## ADR-003: REST → WebSocket → MCP Evolution

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
The team needed to choose a communication protocol between mobile and desktop agents. Options evaluated:

**Option 1: REST API (HTTP)**
- Pros: Simple, language-agnostic, stateless, well-understood
- Cons: Polling for responses, no streaming, firewall issues possible

**Option 2: WebSocket (Persistent Connection)**
- Pros: Real-time, bi-directional, streaming support
- Cons: More complex, state management, connection lifecycle

**Option 3: gRPC (High-Performance RPC)**
- Pros: High throughput, type-safe, streaming
- Cons: Overkill for MVP, additional infrastructure, harder debugging

**Option 4: MCP (Model Context Protocol)**
- Pros: Standardized, tool discovery, future-proof
- Cons: Emerging standard, less mature tooling, learning curve

**Option 5: Message Queue (RabbitMQ, Redis)**
- Pros: Decoupled, async, reliable
- Cons: Operational complexity, overkill for mobile-desktop

### Decision
**Phased Evolution: REST (Phase 1) → WebSocket (Phase 2) → MCP (Phase 3)**

### Rationale

1. **MVP Velocity**: REST is fastest to implement, ships working product quickly
2. **Future-Proof**: Evolution path leads to standardized MCP protocol
3. **No Breaking Changes**: Each phase compatible with previous (backward-compatible)
4. **Incremental Complexity**: Add only what's needed per phase
5. **Industry Alignment**: Follows pattern used by major projects (Anthropic MCP roadmap)

### Phases

#### Phase 1: REST API (Days 6-19)
```
Mobile → HTTP POST → Desktop Agent
         ← HTTP 200 + JSON ← 
```
- Simple JSON request/response
- Polling for long tasks
- Good for MVP validation

#### Phase 2: WebSocket (Days 20-30)
```
Mobile ←→ WebSocket ←→ Desktop Agent
(persistent connection, real-time streaming)
```
- Token-by-token response streaming
- Progress updates in real-time
- Chat-like UX (tokens appear as they're generated)

#### Phase 3: MCP Protocol (Days 31-42)
```
Mobile (MCP Client) ← REST/WS → Desktop (MCP Server)
                     ↓
                Tool Registry (discoverable)
```
- Standardized tool discovery
- JSON-RPC messages
- Future compatibility with Claude, other LLMs

### Implementation Guardrails

**Phase 1 → Phase 2**:
- REST endpoints remain functional (backward compat)
- New WebSocket endpoints added in parallel
- Clients can choose protocol

**Phase 2 → Phase 3**:
- MCP wraps existing agent and tools
- Tool registry mapped to MCP resources
- No agent logic changes

### Consequences

**Positive**:
- ✅ Fast MVP (REST is simple)
- ✅ Future-proof (leads to MCP)
- ✅ Incremental complexity
- ✅ No breaking changes
- ✅ Aligns with industry trends

**Negative**:
- ⚠️ Must be careful about backward compatibility
- ⚠️ Three implementations to maintain (REST, WS, MCP)
- ⚠️ Learning curve for MCP (Phase 3)

### Alternatives Rejected

**gRPC Only**: Overkill, steeper learning curve, harder to debug.  
**MCP From Day 1**: Slower MVP, premature standardization.  
**Message Queue Only**: Operational complexity, not suitable for mobile.

### References
- [Model Context Protocol](https://modelcontextprotocol.io)
- [REST vs WebSocket vs gRPC](https://martinfowler.com/articles/microservices.html)
- [WebSocket Protocol (RFC 6455)](https://tools.ietf.org/html/rfc6455)

---

## ADR-004: LangChain for Desktop Backend

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
The team evaluated frameworks for the desktop Python agent:

**Option 1: LangChain**
- Python agent framework with tool orchestration
- 119k GitHub stars, mature ecosystem
- MIT license, commercial-friendly

**Option 2: Roo Code**
- VS Code extension with agentic reasoning
- 20.5k stars, active development
- Apache 2.0 license

**Option 3: AutoGen (Microsoft)**
- Multi-agent communication framework
- 28k stars, research-backed
- MIT license

**Option 4: LangGraph (LangChain's graph system)**
- Directed graph execution
- Newer, high complexity
- Part of LangChain ecosystem

**Option 5: Custom Agent (Build from Scratch)**
- Maximum control
- Cons: Massive time investment, many edge cases

### Decision
**Use LangChain + FastAPI** for desktop backend. Roo Code as reference for architecture patterns only.

### Rationale

1. **Mature Ecosystem**: 119k GitHub stars, 272k+ dependents, proven in production
2. **Tool System**: Excellent built-in tool orchestration (perfect for our ToolRegistry)
3. **Streaming**: Native support for token-by-token streaming
4. **Extensibility**: Easy to wrap as REST API or MCP server
5. **Learning Curve**: Well-documented, large community
6. **Licensing**: MIT (most permissive)
7. **Mobile Integration**: REST/WebSocket easily exposed via FastAPI

### Implementation

**Architecture**:
```
FastAPI (HTTP Server)
    ↓
DesktopAgentFactory (agent creation)
    ↓
PlanExecuteAgent (our pattern)
    ↓
LangChain Tools (tool orchestration)
    ↓
LLM Providers (Claude, GPT, etc.)
```

**Tool Integration**:
```python
from langchain.tools import Tool
from langchain.agents import initialize_agent

def code_generator_tool(...) -> str:
    # Implementation
    return code

tools = [
    Tool(
        name="code_generator",
        func=code_generator_tool,
        description="Generate Flutter code"
    ),
    # ... more tools
]

agent = initialize_agent(tools, llm, agent="zero-shot-react-description")
```

### Consequences

**Positive**:
- ✅ Massive community (easy to find help)
- ✅ Production-proven framework
- ✅ Tool system perfectly suited to our ToolRegistry
- ✅ MIT license (commercial-friendly)
- ✅ Easy REST/MCP wrapping
- ✅ Streaming support out-of-the-box

**Negative**:
- ⚠️ Python-only (mobile can't use directly)
- ⚠️ Learning curve for LangChain concepts
- ⚠️ Dependency on LangChain stability
- ⚠️ More overhead than minimal agent (we only need planning + tool calling)

### Why Not Roo Code?

**Pros of Roo Code**:
- Battle-tested architecture patterns
- Excellent mode system for task specialization
- VS Code integration powerful for local testing

**Cons of Roo Code**:
- Tightly coupled to VS Code extension model
- Not designed as standalone agent service
- Roomote Control (distributed execution) is cloud-based
- Would require significant custom wrapping for REST API
- Not designed for mobile integration

**How We Use Roo Code**:
- Study its architecture patterns (mode system, tool orchestration)
- Reference implementation for streaming response handling
- Optional: Integrate as advanced feature (Phase 3+)

### Alternatives Rejected

**AutoGen**: Multi-agent framework, more complex than needed for MVP.  
**Custom Build**: Massive time investment, many edge cases, reinventing the wheel.  
**Roo Code as Primary**: Too tightly coupled to VS Code, not suitable for REST API.

### References
- [LangChain Documentation](https://docs.langchain.com)
- [LangChain GitHub](https://github.com/langchain-ai/langchain)
- [Tool Use in LangChain](https://docs.langchain.com/oss/python/langchain/modules/agents/tools)
- [Roo Code Architecture](https://github.com/RooCodeInc/Roo-Code)

---

## ADR-005: Mobile Agent Capabilities (Local vs Remote)

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
Mobile devices have limited capabilities compared to desktop. The team needed to decide which tasks execute locally vs delegate to desktop.

**Local Capabilities** (Mobile can do):
- UI testing & validation
- Sensor access (camera, GPS, accelerometer)
- File operations (read/write local storage)
- Simple transformations (JSON parsing, string processing)
- Offline tasks (no network required)

**Remote Capabilities** (Desktop can do):
- Code generation & analysis
- Complex computations
- Testing & compilation
- Database operations
- Long-running tasks (> 30 seconds)
- Tasks requiring specialized tools (Dart SDK, compilers)

### Decision
**Hybrid Model: Mobile decides locally, delegates intelligently**

Local execution decision criteria:
1. Task requires only mobile-available tools
2. Task completes in < 30 seconds
3. Task works offline
4. Device has sufficient resources

Remote delegation criteria:
1. Task needs desktop tools (compilers, analyzers)
2. Task exceeds 30-second timeout
3. Task requires persistent state (database)
4. Device is low on memory/battery

### Implementation

**Mobile AgentFactory**:
```dart
Future<PlanExecuteAgent> createAgentForTask(String task) async {
  // 1. Analyze task
  final requirements = await _analyzeRequirements(task);
  
  // 2. Check if local execution is possible
  if (_canExecuteLocally(requirements)) {
    // Local agent with local tools
    return PlanExecuteAgent(
      tools: _getLocalTools(),
      systemPrompt: prompt,
    );
  } else {
    // Remote delegation
    return RemoteAgentProxy(desktopClient);
  }
}
```

### Consequences

**Positive**:
- ✅ Optimal resource usage (local for simple tasks)
- ✅ Works offline for local tasks
- ✅ Delegates complex work to powerful desktop
- ✅ Flexible (can adjust delegation threshold)

**Negative**:
- ⚠️ Decision logic must be accurate (incorrect delegation wastes resources)
- ⚠️ Network dependency for complex tasks
- ⚠️ Different behavior on mobile vs desktop (potential consistency issues)

### Trade-offs Accepted

1. **Offline Limitation**: Complex tasks require network (acceptable - they're rare)
2. **Consistency**: Same task might execute locally vs remote (acceptable - results are deterministic)
3. **Latency**: Network delay for remote tasks (acceptable - complex tasks are worth waiting for)

### References
- [Mobile App Architecture Patterns](https://developer.android.com/guide/app-architecture)
- [Offline-First Architecture](https://www.w3.org/TR/cache-api/)

---

## ADR-006: Streaming Strategy (Token-by-Token vs Chunked)

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
LLM responses can be streamed in different ways:

**Option 1: Token-by-Token Streaming**
- Each token sent individually
- Pros: Real-time display, interactive feel
- Cons: Many messages, network overhead

**Option 2: Chunked Streaming (e.g., every 5 tokens)**
- Multiple tokens per message
- Pros: Fewer messages, more efficient
- Cons: Less interactive, chunkier display

**Option 3: Full Response**
- Complete response at once
- Pros: Simple, no streaming logic
- Cons: User waits for full response (poor UX)

### Decision
**Token-by-Token Streaming via WebSocket (Phase 2)**

### Rationale

1. **UX**: Users see response appearing in real-time (modern chat experience)
2. **Responsiveness**: Immediate feedback vs waiting for completion
3. **Interactivity**: Users can interrupt or refine mid-response
4. **Compatibility**: Works with flutter_gen_ai_chat_ui widget

### Implementation

**Backend (Python)**:
```python
async def stream_task(task: str):
    agent = await agent_factory.create_agent_for_task(task)
    async for token in agent.stream_execute():
        yield token

@app.websocket("/ws/stream")
async def websocket_endpoint(websocket):
    async for message in websocket:
        async for token in stream_task(message):
            await websocket.send_text(token)
```

**Frontend (Dart)**:
```dart
websocket.onMessage = (message) {
  setState(() {
    response += message; // Append token to response
  });
};
```

### Consequences

**Positive**:
- ✅ Modern UX (tokens appear in real-time)
- ✅ User perceives faster response (psychological)
- ✅ Can interrupt during streaming

**Negative**:
- ⚠️ More complex implementation
- ⚠️ Network overhead if not batched appropriately
- ⚠️ Requires WebSocket (Phase 2)

### Buffering Strategy

To balance efficiency and responsiveness:
- Collect tokens into 50-100ms buffers
- Send batch of tokens together
- Results in ~10-20 messages/second (good balance)

### References
- [Streaming LLM Responses](https://platform.openai.com/docs/guides/streaming)
- [Real-Time Communication](https://en.wikipedia.org/wiki/Real-time_computing)

---

## ADR-007: Error Handling & Graceful Degradation

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
Agents can fail at multiple points:
- Planning fails (LLM can't create valid plan)
- Tool execution fails (tool throws exception)
- Verification fails (LLM can't assess progress)
- Network fails (no connection to desktop)

The team needed a robust error handling strategy.

### Decision
**Layered Error Handling with Graceful Degradation**

### Strategy

```
Layer 1: Planning Errors
├─ Attempt 1: Full planning
├─ Attempt 2: Simplified planning (fewer steps)
└─ Fail: Return error, suggest manual input

Layer 2: Execution Errors
├─ Per-step error handling
├─ Skip failed step + continue
├─ Use alternative tool if available
└─ Fail: Return partial results

Layer 3: Verification Errors
├─ Attempt 1: Full verification
├─ Attempt 2: Simple verification ("Is response helpful?")
└─ Fail: Assume task incomplete, offer manual verification

Layer 4: Network Errors
├─ Queue request for retry
├─ Exponential backoff (1s, 2s, 4s, 8s, max 30s)
├─ Fallback to local execution if possible
└─ Fail: Tell user "desktop unavailable, try local mode"

Layer 5: Resource Errors
├─ Timeout: Kill execution after 30s
├─ Memory: Switch to streaming mode
├─ Rate limit: Queue and retry with backoff
└─ Fail: Return "Resource limit exceeded"
```

### Implementation

**Exception Hierarchy**:
```dart
abstract class AgentException implements Exception {}
class PlanningException extends AgentException {}
class ExecutionException extends AgentException {}
class VerificationException extends AgentException {}
class NetworkException extends AgentException {}
class ResourceException extends AgentException {}
```

### Consequences

**Positive**:
- ✅ System doesn't crash on errors
- ✅ Partial results better than no results
- ✅ User always gets feedback
- ✅ Logging enables debugging

**Negative**:
- ⚠️ Complex error handling logic
- ⚠️ May hide underlying issues if not monitored
- ⚠️ Requires good logging/telemetry

### Logging Strategy
- Log all errors with context (task, step, error message)
- Track error rates (metrics for monitoring)
- Include reproducible stack traces
- Enable DEBUG level logging for troubleshooting

### References
- [Error Handling Best Practices](https://www.baeldung.com/cs/error-handling-strategies)
- [Graceful Degradation](https://developer.mozilla.org/en-US/docs/Glossary/Graceful_degradation)

---

## ADR-008: State Persistence (MVP: Ephemeral)

### Status
**ACCEPTED** | Decision Date: November 2, 2025

### Context
The team needed to decide how much state to persist:

**Option 1: Ephemeral** (All in-memory)
- State lost on app restart
- Simpler implementation
- Suitable for MVP

**Option 2: Session Persistence**
- State survives app restart
- Can resume interrupted tasks
- Moderate complexity

**Option 3: Full Persistence (SQLite)**
- Complete agent history
- Can replay tasks
- Higher complexity

### Decision
**MVP: Ephemeral State (Phase 1)**

Rationale: Fast MVP, no database overhead. Sessions rarely interrupted in practice.

**Future: Phase 2+ will add SQLite checkpointing** for reliability.

### Consequences

**Positive**:
- ✅ Simpler implementation (MVP focus)
- ✅ No database dependencies
- ✅ Faster execution

**Negative**:
- ⚠️ Tasks lost on app crash
- ⚠️ No task history
- ⚠️ Can't resume interrupted tasks

### Phase 2+ Upgrade Path

- Add SQLite for agent execution checkpoints
- Checkpoint after each step (enables resume)
- Implement history browser
- Enable task replay for debugging

---

## Decision Summary Table

| # | Decision | Chosen | Phase | Priority |
|---|----------|--------|-------|----------|
| ADR-001 | Agent Pattern | Plan-Execute | 1 | Critical |
| ADR-002 | Tool Management | Dynamic Registry | 1 | Critical |
| ADR-003 | Communication | REST→WS→MCP | 1,2,3 | Critical |
| ADR-004 | Desktop Framework | LangChain | 1 | Critical |
| ADR-005 | Mobile Delegation | Hybrid (Local+Remote) | 1 | Critical |
| ADR-006 | Streaming | Token-by-Token WS | 2 | High |
| ADR-007 | Error Handling | Layered Degradation | 1 | High |
| ADR-008 | State Persistence | Ephemeral (MVP) | 1 | Medium |

---

## Review & Approval

| Role | Name | Approved | Date |
|------|------|----------|------|
| Architecture Lead | [TBD] | [ ] | |
| Backend Lead | [TBD] | [ ] | |
| Mobile Lead | [TBD] | [ ] | |
| Tech Lead | [TBD] | [ ] | |

---

## Change Log

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2025-11-02 | Initial ADRs (ADR-001 through ADR-008) | Architecture Team |

---

**Next ADR Session**: Week 2 (after Phase 0 completion)  
**Document Ownership**: Architecture Team  
**Review Frequency**: Bi-weekly or as needed

