# Micro Agent System - Technical Specification

**Document Version**: 1.0  
**Created**: November 2, 2025  
**Audience**: Developers, Architects, DevOps  
**Status**: Active Implementation

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Data Models](#data-models)
3. [Component Specifications](#component-specifications)
4. [Protocol Specifications](#protocol-specifications)
5. [Tool Interface Specification](#tool-interface-specification)
6. [API Endpoints (Phase 1)](#api-endpoints-phase-1)
7. [Error Codes & Handling](#error-codes--handling)
8. [Performance Requirements](#performance-requirements)
9. [Security Considerations](#security-considerations)

---

## System Overview

### Architecture Components

```
┌─────────────────────────────────────────┐
│ Mobile (Flutter/Dart)                   │
├─────────────────────────────────────────┤
│ ChatUI                                  │
│   └─ AgentFactory (Task Analysis)       │
│       └─ PlanExecuteAgent (Local exec)  │
│           └─ ToolRegistry (Local tools) │
│               ├─ UIValidationTool       │
│               ├─ SensorTool             │
│               └─ FileOperationTool      │
│                                         │
│ Communication Layer (HTTP/WS/MCP)       │
└─────────────────────────────────────────┘
        ↕ (Phase 1: REST HTTP)
        ↕ (Phase 2: WebSocket)
        ↕ (Phase 3: MCP)
┌─────────────────────────────────────────┐
│ Desktop (Python/FastAPI)                │
├─────────────────────────────────────────┤
│ DesktopAgentFactory                     │
│   └─ PlanExecuteAgent (Remote exec)     │
│       └─ ToolRegistry (Desktop tools)   │
│           ├─ CodeGeneratorTool          │
│           ├─ CodeExecutorTool           │
│           ├─ TestRunnerTool             │
│           └─ FileOperationTool          │
│                                         │
│ LangChain Integration                   │
│   └─ LLM Providers (Claude/GPT/ZhipuAI) │
└─────────────────────────────────────────┘
```

### Execution Flow (Detailed Sequence)

```
1. USER INPUT
   "Generate Flutter login form"
   
2. MOBILE LAYER
   ChatUI → ChatProvider (Riverpod)
   
3. TASK ROUTING
   AgentFactory.createAgentForTask()
   - LLM: "Analyze task requirements"
   - Extract: capabilities = [CODE_GENERATION, COMPILATION, TESTING]
   - Can mobile do this? NO (needs Dart SDK)
   - Decision: DELEGATE TO DESKTOP
   
4. MOBILE → DESKTOP COMMUNICATION
   POST /api/v1/agent/task
   Body: { task: "Generate Flutter login form", context: {} }
   
5. DESKTOP AGENT CREATION
   DesktopAgentFactory.create_agent_for_task()
   - Complexity analysis: "complex" (multi-step code + testing)
   - [MVP Phase 1: Single agent]
   - Get all tools
   - Create system prompt
   
6. PLANNING PHASE
   LLM Prompt: "Create step-by-step plan for: Generate Flutter login form"
   
   LLM Response:
   {
     "steps": [
       {"step": 1, "objective": "Generate form widgets", "tools": ["code_generator"]},
       {"step": 2, "objective": "Add validation logic", "tools": ["code_generator"]},
       {"step": 3, "objective": "Test form", "tools": ["test_runner"]},
     ]
   }
   
   Result: AgentPlan created
   
7. EXECUTION PHASE
   For each step in plan:
     a) Get tools for step
     b) Execute tools
     c) Collect output
     d) Stream to mobile (Phase 2: token-by-token)
   
   Step 1 Output: [Flutter code snippet]
   Step 2 Output: [Validation code]
   Step 3 Output: [Test results]
   
8. VERIFICATION PHASE
   LLM Prompt: "Is task complete?"
   LLM Response: "Yes, generated working login form"
   
   Verification result: SUCCESS
   
9. RETURN RESULT
   HTTP 200 + AgentResult
   
10. MOBILE DISPLAY
    ChatUI displays result with syntax highlighting
```

---

## Data Models

### Core Entity Models

#### AgentPlan
```dart
@freezed
class AgentPlan with _$AgentPlan {
  const factory AgentPlan({
    required String taskDescription,
    required List<PlanStep> steps,
    required Map<int, List<int>> stepDependencies,
    @Default(DateTime.now) DateTime createdAt,
    @Default(1) int version,
  }) = _AgentPlan;
  
  factory AgentPlan.fromJson(Map<String, dynamic> json) =>
      _$AgentPlanFromJson(json);
}

@freezed
class PlanStep with _$PlanStep {
  const factory PlanStep({
    required int stepIndex,
    required String objective,
    required List<String> toolNames,
    required String reasoning,
    @Default([]) List<int> dependsOnSteps,
  }) = _PlanStep;
}
```

#### Execution Result Models
```dart
@freezed
class StepResult with _$StepResult {
  const factory StepResult({
    required int stepIndex,
    required ExecutionStatus status,
    required Map<String, dynamic> toolOutputs,
    String? errorMessage,
    @Default(DateTime.now) DateTime completedAt,
    @Default(0) int retryCount,
  }) = _StepResult;
}

@freezed
class Verification with _$Verification {
  const factory Verification({
    required bool taskComplete,
    required String reasoning,
    List<int>? remainingSteps,
    @Default(false) bool shouldReplan,
  }) = _Verification;
}

@freezed
class AgentResult with _$AgentResult {
  const factory AgentResult({
    required String taskDescription,
    required bool success,
    required String response,
    required List<StepResult> executedSteps,
    @Default(0) Duration executionTime,
    @Default(0) int replans,
    String? finalError,
  }) = _AgentResult;
}

enum ExecutionStatus { pending, running, completed, failed, skipped, timeout }
```

#### Tool Metadata
```dart
@freezed
class ToolMetadata with _$ToolMetadata {
  const factory ToolMetadata({
    required String name,
    required String description,
    required Set<String> capabilities,
    required String domain, // e.g., "ui_testing", "code_gen"
    required Map<String, dynamic> jsonSchema,
    @Default(Duration(minutes: 5)) Duration timeout,
    @Default(3) int maxRetries,
  }) = _ToolMetadata;
}

@freezed
class TaskCapabilities with _$TaskCapabilities {
  const factory TaskCapabilities({
    required List<String> requiredCapabilities,
    required String primaryDomain,
    @Default(false) bool requiresRemoteExecution,
    @Default(false) bool requiresCompilation,
    @Default(false) bool requiresPersistence,
  }) = _TaskCapabilities;
}
```

### Python Models

```python
@dataclass
class PlanStep:
    step_index: int
    objective: str
    tool_names: List[str]
    reasoning: str
    depends_on_steps: List[int] = field(default_factory=list)
    timeout: float = 300.0  # seconds

@dataclass
class AgentPlan:
    task_description: str
    steps: List[PlanStep]
    created_at: datetime = field(default_factory=datetime.now)
    complexity: str = "simple"  # simple, moderate, complex
    estimated_duration: float = 0.0  # seconds

@dataclass
class StepResult:
    step_index: int
    status: str  # completed, failed, skipped, timeout
    tool_outputs: Dict[str, Any]
    error_message: Optional[str] = None
    completed_at: datetime = field(default_factory=datetime.now)
    execution_time: float = 0.0

@dataclass
class AgentResult:
    task_description: str
    success: bool
    response: str
    executed_steps: List[StepResult]
    execution_time: float
    replans: int = 0
    final_error: Optional[str] = None
```

---

## Component Specifications

### Mobile: PlanExecuteAgent

**Location**: `lib/infrastructure/ai/agent/plan_execute_agent.dart`

#### Responsibilities
1. Create execution plan from task
2. Execute steps with tool calling
3. Verify progress
4. Replan on failure (max 2 attempts)

#### Interface
```dart
abstract class Agent {
  Future<AgentResult> execute(String task);
  Future<AgentPlan> createPlan(String task);
  Future<List<StepResult>> executeSteps(AgentPlan plan);
  Future<Verification> verifyProgress(List<StepResult> results);
}

class PlanExecuteAgent implements Agent {
  final List<Tool> tools;
  final String systemPrompt;
  final ChatModel llm;
  
  Future<AgentResult> execute(String task) { ... }
  Future<AgentPlan> _createPlan(String task) { ... }
  Future<List<StepResult>> _executeSteps(AgentPlan plan) { ... }
  Future<Verification> _verifyProgress(List<StepResult> results) { ... }
  Future<AgentResult> _replan(...) { ... }
}
```

#### Lifecycle
```
1. CREATE: PlanExecuteAgent(tools, systemPrompt, llm)
2. PLAN: _createPlan(task) → AgentPlan
3. EXECUTE: _executeSteps(plan) → List<StepResult>
4. VERIFY: _verifyProgress(results) → Verification
5. REPLAN: If verification.shouldReplan (max 2 times)
6. RETURN: AgentResult
```

#### Timeouts
- Plan creation: 10s
- Per-step execution: 30s
- Verification: 5s
- Total execution: 300s (5 min)

### Mobile: AgentFactory

**Location**: `lib/infrastructure/ai/agent/agent_factory.dart`

#### Responsibilities
1. Analyze task requirements (LLM-based)
2. Decide local vs remote execution
3. Select appropriate tools
4. Generate specialized system prompt
5. Create agent instance

#### Interface
```dart
class AgentFactory {
  Future<Agent> createAgentForTask(String task) async {
    // Task analysis
    final capabilities = await _analyzeTaskRequirements(task);
    
    // Tool selection
    final tools = _toolRegistry.getToolsForCapabilities(
      capabilities.requiredCapabilities
    );
    
    // Routing decision
    if (capabilities.requiresRemoteExecution) {
      return RemoteAgentProxy(desktopAddress);
    }
    
    // Local agent creation
    final prompt = _generateSystemPrompt(task, capabilities);
    return PlanExecuteAgent(tools, prompt, llm);
  }
}
```

#### Task Analysis LLM Prompt
```
Analyze this task and determine:
1. Required capabilities (list of strings)
2. Primary domain (ui_testing, code_gen, etc.)
3. Can it be done locally? (yes/no)

Task: {task}

Required format:
{
  "capabilities": ["UI_VALIDATION", "SCREENSHOT"],
  "domain": "ui_testing",
  "requires_remote": false
}
```

### Mobile: ToolRegistry

**Location**: `lib/infrastructure/ai/tools/tool_registry.dart`

#### Responsibilities
1. Register tools with metadata
2. Discover tools by capabilities
3. Discover tools by domain
4. Validate tool availability

#### Interface
```dart
class ToolRegistry {
  void registerTool(
    Tool tool,
    Set<String> capabilities,
    String domain,
  ) { ... }
  
  List<Tool> getToolsForCapabilities(List<String> caps) { ... }
  List<Tool> getToolsForDomain(String domain) { ... }
  Tool? getTool(String toolName) { ... }
}
```

#### Registry Initialization
```dart
final registry = ToolRegistry();

// Register at app startup
registry.registerTool(
  UIValidatorTool(),
  {"UI_VALIDATION", "ELEMENT_INSPECTION", "SCREENSHOT"},
  "ui_testing",
);

registry.registerTool(
  ScreenshotTool(),
  {"SCREENSHOT", "VISION_ANALYSIS"},
  "ui_testing",
);

registry.registerTool(
  FileOperationTool(),
  {"FILE_READ", "FILE_WRITE", "FILE_DELETE"},
  "file_operations",
);

registry.registerTool(
  SensorAccessTool(),
  {"SENSOR_READ", "GPS_LOCATION", "ACCELEROMETER"},
  "sensors",
);
```

### Desktop: PlanExecuteAgent (Python)

**Location**: `backend/infrastructure/agents/plan_execute_agent.py`

#### Responsibilities
- Same as mobile but with desktop-specific tools
- Uses LangChain for tool orchestration

#### Interface
```python
class PlanExecuteAgent:
    def __init__(
        self,
        task: str,
        tools: List[Tool],
        system_prompt: str,
        llm: ChatModel,
    ):
        self.task = task
        self.tools = tools
        self.system_prompt = system_prompt
        self.llm = llm
        self.max_replans = 2
    
    async def execute(self) -> AgentResult: ...
    async def _create_plan(self) -> AgentPlan: ...
    async def _execute_steps(self, plan: AgentPlan) -> List[StepResult]: ...
    async def _verify_progress(self, results: List[StepResult]) -> Verification: ...
```

### Desktop: DesktopAgentFactory (Python)

**Location**: `backend/infrastructure/agents/agent_factory.py`

#### Responsibilities (Phase 1)
1. Analyze task
2. Create single agent
3. Collect all tools

#### Future (Phase 2)
- Complexity analysis
- Multi-agent swarm creation
- Domain-based specialization

#### Interface
```python
class DesktopAgentFactory:
    async def create_agent_for_task(self, task: str) -> PlanExecuteAgent:
        # Phase 1: Always single agent
        tools = self.tool_registry.all_tools()
        
        system_prompt = f"Execute: {task}\nTools: {[t.name for t in tools]}"
        
        return PlanExecuteAgent(task, tools, system_prompt, self.llm)
    
    # Phase 2 methods (placeholder)
    async def _analyze_complexity(self, task: str) -> str: ...
    async def _create_single_agent(self, task: str): ...
    async def _create_agent_swarm(self, task: str): ...
```

### Desktop: ToolRegistry (Python)

**Location**: `backend/infrastructure/tools/tool_registry.py`

```python
class ToolRegistry:
    def register_tool(
        self,
        tool: Tool,
        capabilities: Set[str],
        domain: str,
    ) -> None: ...
    
    def get_tools_for_capabilities(
        self,
        required_capabilities: List[str],
    ) -> List[Tool]: ...
    
    def get_tools_for_domain(self, domain: str) -> List[Tool]: ...
    
    def all_tools(self) -> List[Tool]: ...
```

---

## Protocol Specifications

### Phase 1: REST HTTP

#### Request/Response Format

**Request**:
```
POST /api/v1/agent/task HTTP/1.1
Host: localhost:8000
Content-Type: application/json

{
  "task": "Generate Flutter login form",
  "context": {
    "project_type": "flutter",
    "framework": "riverpod",
    "style": "material3"
  }
}
```

**Response (Success)**:
```
HTTP/1.1 200 OK
Content-Type: application/json

{
  "success": true,
  "result": {
    "task_description": "Generate Flutter login form",
    "success": true,
    "response": "Generated login form with email validation...",
    "executed_steps": [
      {
        "step_index": 0,
        "status": "completed",
        "tool_outputs": {
          "code_generator": "class LoginForm extends StatefulWidget { ... }"
        }
      },
      ...
    ],
    "execution_time": 3.5,
    "replans": 0
  }
}
```

**Response (Error)**:
```
HTTP/1.1 500 Internal Server Error
Content-Type: application/json

{
  "success": false,
  "error": {
    "code": "PLANNING_FAILED",
    "message": "Could not create valid execution plan",
    "details": "LLM returned invalid JSON"
  }
}
```

#### REST Endpoints (Phase 1)

```
POST /api/v1/agent/task
  - Execute agent task
  - Request: { task: string, context?: object }
  - Response: { success: bool, result?: AgentResult, error?: ErrorDetail }

GET /api/v1/tools
  - List available tools
  - Response: { tools: Array<ToolMetadata> }

GET /api/v1/health
  - Health check
  - Response: { status: string, timestamp: string }
```

### Phase 2: WebSocket

#### Message Format
```json
{
  "id": "msg-123",
  "type": "task_request|stream_token|progress_update|error|result",
  "payload": { ... }
}
```

#### Message Types

**task_request**:
```json
{
  "type": "task_request",
  "payload": {
    "task": "Generate code",
    "stream_responses": true
  }
}
```

**stream_token**:
```json
{
  "type": "stream_token",
  "payload": {
    "token": "Generated",
    "step_index": 1,
    "phase": "execution"
  }
}
```

**progress_update**:
```json
{
  "type": "progress_update",
  "payload": {
    "current_step": 2,
    "total_steps": 4,
    "status": "executing",
    "percent": 50
  }
}
```

**result**:
```json
{
  "type": "result",
  "payload": { AgentResult object }
}
```

### Phase 3: MCP Protocol

Reference: [modelcontextprotocol.io](https://modelcontextprotocol.io)

**MCP Resources**:
- `tool://code_generator` - Code generation capability
- `tool://test_runner` - Test execution capability

**MCP Tools**: Each tool mapped to MCP tool definition

---

## Tool Interface Specification

### Tool Base Class

```dart
abstract class Tool {
  /// Tool metadata
  String get name;
  String get description;
  Set<String> get capabilities;
  String get domain;
  
  /// Execution
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
  
  /// Validation
  Map<String, dynamic> get jsonSchema;
}
```

### Tool Implementation Example

```dart
class UIValidatorTool implements Tool {
  @override
  String get name => "ui_validator";
  
  @override
  String get description => "Validate UI elements and interactions";
  
  @override
  Set<String> get capabilities => {
    "UI_VALIDATION",
    "ELEMENT_INSPECTION",
    "INTERACTION_TESTING",
  };
  
  @override
  String get domain => "ui_testing";
  
  @override
  Map<String, dynamic> get jsonSchema => {
    "type": "object",
    "properties": {
      "screen": {"type": "string"},
      "validate_elements": {"type": "array", "items": {"type": "string"}},
    },
    "required": ["screen"],
  };
  
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final screen = args["screen"] as String;
    final validateElements = args["validate_elements"] as List? ?? [];
    
    // Implementation
    return {
      "valid": true,
      "elements_found": validateElements.length,
      "issues": [],
    };
  }
}
```

### Python Tool Implementation

```python
class CodeGeneratorTool(Tool):
    name = "code_generator"
    description = "Generate Dart/Flutter code"
    capabilities = {"CODE_GENERATION", "TEMPLATE_FILLING"}
    domain = "code_gen"
    
    async def execute(self, args: Dict[str, Any]) -> Dict[str, Any]:
        requirement = args.get("requirement", "")
        language = args.get("language", "dart")
        
        # Use LLM to generate code
        code = await self._generate_code(requirement, language)
        
        return {
            "code": code,
            "language": language,
            "lines_of_code": len(code.split("\n")),
        }
    
    async def _generate_code(self, requirement: str, language: str) -> str:
        # Implementation using LLM
        pass
```

---

## API Endpoints (Phase 1)

### Task Execution Endpoint

```
POST /api/v1/agent/task
```

**Purpose**: Execute an agent task

**Request Schema**:
```dart
class TaskRequest {
  final String task;
  final Map<String, dynamic>? context;
  final bool? streamResponses; // Phase 2
  
  TaskRequest({
    required this.task,
    this.context,
    this.streamResponses = false,
  });
}
```

**Response Schema**:
```dart
class TaskResponse {
  final bool success;
  final AgentResult? result;
  final TaskError? error;
  
  TaskResponse({
    required this.success,
    this.result,
    this.error,
  });
}
```

### Tool Discovery Endpoint

```
GET /api/v1/tools
```

**Response**:
```json
{
  "tools": [
    {
      "name": "code_generator",
      "description": "Generate Dart/Flutter code",
      "capabilities": ["CODE_GENERATION", "TEMPLATE_FILLING"],
      "domain": "code_gen",
      "schema": { ... }
    },
    ...
  ]
}
```

### Health Check Endpoint

```
GET /api/v1/health
```

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-11-02T10:30:00Z",
  "services": {
    "llm": "connected",
    "tool_registry": "ready",
    "database": "ok"
  }
}
```

---

## Error Codes & Handling

### Error Code Hierarchy

```
AGENT_ERRORS
├── PLANNING_ERRORS
│   ├── INVALID_PLAN (400)
│   ├── PLANNING_TIMEOUT (504)
│   └── WEAK_MODEL (400)
├── EXECUTION_ERRORS
│   ├── TOOL_NOT_FOUND (400)
│   ├── TOOL_FAILED (500)
│   ├── EXECUTION_TIMEOUT (504)
│   └── INSUFFICIENT_RESOURCES (429)
├── VERIFICATION_ERRORS
│   ├── VERIFICATION_FAILED (500)
│   └── VERIFICATION_TIMEOUT (504)
├── NETWORK_ERRORS
│   ├── CONNECTION_REFUSED (503)
│   ├── REQUEST_TIMEOUT (504)
│   └── INVALID_RESPONSE (502)
└── RESOURCE_ERRORS
    ├── OUT_OF_MEMORY (500)
    ├── RATE_LIMITED (429)
    └── MAX_RETRIES_EXCEEDED (500)
```

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "TOOL_NOT_FOUND",
    "message": "Tool 'code_analyzer' not available",
    "http_status": 400,
    "details": {
      "requested_tool": "code_analyzer",
      "available_tools": ["code_generator", "test_runner"]
    },
    "trace_id": "req-abc123",
    "timestamp": "2025-11-02T10:30:00Z"
  }
}
```

### Recovery Strategies

| Error | Strategy | Retry | Max Retries |
|-------|----------|-------|------------|
| PLANNING_ERRORS | Simplify task → retry | Yes | 1 |
| TOOL_FAILED | Skip step → continue | No | 0 |
| EXECUTION_TIMEOUT | Fail gracefully | No | 0 |
| CONNECTION_REFUSED | Exponential backoff | Yes | 3 |
| RATE_LIMITED | Exponential backoff | Yes | 5 |

---

## Performance Requirements

### Latency Targets

| Operation | Target | Acceptable |
|-----------|--------|-----------|
| Plan creation | < 500ms | < 1s |
| Step execution (simple) | < 1s | < 5s |
| Step execution (complex) | < 5s | < 30s |
| Total task (simple) | < 5s | < 30s |
| Total task (complex) | < 30s | < 300s |
| Verification | < 500ms | < 2s |
| Replan | < 1s | < 5s |

### Throughput Requirements

- Single task: 1 agent per second (MVP)
- Multiple users: 10 concurrent tasks (future)

### Resource Requirements

**Mobile**:
- Memory: < 200MB per agent
- CPU: < 50% per agent
- Storage: < 100MB cache

**Desktop**:
- Memory: < 1GB per agent
- CPU: < 80% per agent
- Disk: < 1GB logs/cache

---

## Security Considerations

### Authentication & Authorization

**Phase 1 (MVP)**: No authentication (local development)

**Phase 2+**:
- API key authentication for desktop endpoint
- JWT token for mobile-to-desktop
- HTTPS/WSS for transport security

### Input Validation

```dart
class TaskValidator {
  static bool validate(TaskRequest request) {
    // Task length: 1-1000 characters
    if (request.task.isEmpty || request.task.length > 1000) return false;
    
    // No dangerous characters
    if (request.task.contains("<script>")) return false;
    
    // Valid context (if provided)
    if (request.context != null) {
      // Validate context size (< 1MB)
      // Validate context types
    }
    
    return true;
  }
}
```

### Tool Sandboxing

- Code execution in isolated environment
- File operations restricted to app directories
- Network requests monitored/rate-limited
- Resource limits enforced (memory, CPU, timeout)

### Data Privacy

- No sensitive data in logs
- Execution results encrypted at rest (Phase 2)
- Audit trail for all agent executions (Phase 2)
- Clear deletion policy for agent history (Phase 2)

---

## Appendix: Testing Specifications

### Unit Test Coverage

- PlanExecuteAgent: 80%+ coverage
- ToolRegistry: 90%+ coverage
- AgentFactory: 75%+ coverage

### Integration Test Scenarios

1. **Local task execution** (UI testing)
2. **Remote task delegation** (code generation)
3. **Multi-step execution** (planning + execution + verification)
4. **Replanning on failure** (verify fallback logic)
5. **Network failure recovery** (connection interruption)
6. **Streaming responses** (WebSocket Phase 2)
7. **Tool discovery** (registry functionality)
8. **Error handling** (graceful degradation)

### Performance Benchmarks

- Plan creation: 50-500ms (typical)
- Tool discovery: 10-50ms
- Tool execution: 500-5000ms (varies by tool)
- Verification: 50-500ms

---

**Version History**:
- v1.0 (2025-11-02): Initial specification

**Next Update**: After Phase 0 completion (Day 5)

