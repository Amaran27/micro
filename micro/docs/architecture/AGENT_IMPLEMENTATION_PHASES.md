# Autonomous Agent Implementation Plan (Phase 0-3)
## Micro AI Chat - Desktop + Mobile Agent Architecture

**Document Version**: 1.0  
**Created**: November 2, 2025  
**Last Updated**: November 2, 2025  
**Status**: Active Implementation  
**Prepared By**: Architecture & Engineering Team

---

## Executive Summary

This document outlines the comprehensive implementation strategy for integrating autonomous agents into the Micro AI Chat application. The system follows a **hybrid architecture** with:

- **Mobile Agent (Flutter/Dart)**: Plan-Execute agent with local autonomy for UI/sensor tasks
- **Desktop Agent (Python/LangChain)**: Multi-agent swarm capable of complex reasoning and code generation
- **Communication**: REST (Phase 1) → WebSocket (Phase 2) → MCP (Phase 3)

**Key Principle**: All agent specialization is **dynamic and data-driven**, zero hardcoded agent classes.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Phase 0: Foundation & Setup](#phase-0-foundation--setup)
3. [Phase 1: MVP - REST Communication](#phase-1-mvp--rest-communication)
4. [Phase 2: Production - Real-Time Streaming](#phase-2-production--real-time-streaming)
5. [Phase 3: Advanced - MCP Protocol](#phase-3-advanced--mcp-protocol)
6. [Technical Specifications](#technical-specifications)
7. [Testing Strategy](#testing-strategy)
8. [Documentation & Runbooks](#documentation--runbooks)
9. [Success Metrics](#success-metrics)

---

## Architecture Overview

### System Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                        MICRO ECOSYSTEM                            │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────┐          ┌──────────────────────────────┐
│   MOBILE (Flutter)      │          │  DESKTOP (Python)            │
├─────────────────────────┤          ├──────────────────────────────┤
│                         │          │                              │
│ ┌─────────────────────┐ │          │ ┌──────────────────────────┐ │
│ │  Chat UI (Riverpod) │ │          │ │  FastAPI Server          │ │
│ └──────────┬──────────┘ │          │ └──────────┬───────────────┘ │
│            │            │          │            │                 │
│ ┌──────────▼──────────┐ │          │ ┌──────────▼───────────────┐ │
│ │ AgentFactory        │ │◄────────►│ │ DesktopAgentFactory     │ │
│ │ (Plan-Execute)      │ │  HTTP    │ │ (Complexity Analysis)   │ │
│ └──────────┬──────────┘ │  REST    │ └──────────┬───────────────┘ │
│            │            │  Phase1  │            │                 │
│            │            │  WS      │ ┌──────────▼───────────────┐ │
│ ┌──────────▼──────────┐ │  Phase2  │ │ LangChain Agent         │ │
│ │ ToolRegistry        │ │◄────────►│ │ (Tool Orchestration)    │ │
│ │ (Dynamic Tool Sel)  │ │  MCP     │ └──────────┬───────────────┘ │
│ └─────────────────────┘ │  Phase3  │            │                 │
│                         │          │ ┌──────────▼───────────────┐ │
│ Tools:                  │          │ │ Tool Registry           │ │
│ - UI Validation         │          │ │ (Metadata-Driven)       │ │
│ - Sensor Access         │          │ └──────────┬───────────────┘ │
│ - File Operations       │          │            │                 │
│ - Local Execution       │          │ ┌──────────▼───────────────┐ │
│                         │          │ │ Tools:                  │ │
└─────────────────────────┘          │ │ - Code Generation       │ │
                                     │ │ - Code Analysis         │ │
                                     │ │ - Testing/Execution     │ │
                                     │ │ - File Operations       │ │
                                     │ │ - Remote Execution      │ │
                                     │ └─────────────────────────┘ │
                                     │                              │
                                     │ LLM Providers:              │
                                     │ - ZhipuAI, OpenAI, Google   │
                                     │                              │
                                     └──────────────────────────────┘
```

### Data Flow (Example: "Test Login UI")

```
Mobile User: "Test the login UI"
  ↓
ChatProvider (Riverpod) → AgentFactory.createAgentForTask()
  ↓
Task Analysis: "Test login UI"
  → LLM analyzes → Required capabilities: [UI_VALIDATION, TESTING, SCREENSHOT]
  ↓
ToolRegistry.getToolsForCapabilities([UI_VALIDATION, TESTING, SCREENSHOT])
  → Returns: [validateUITool, takeScreenshotTool, reportTool]
  ↓
System Prompt Generated: "You are specialized in ui_validation and testing..."
  ↓
PlanExecuteAgent created with tools & prompt
  ↓
Agent Flow:
  1. PLAN: "I will take screenshot → validate UI elements → test interactions"
  2. EXECUTE: Run 3 steps with tools
  3. VERIFY: Check test results
  4. If failed → REPLAN
  ↓
Result sent to Desktop? NO (local execution)
  ↓
Mobile displays result in chat

---

Alternative Flow: "Generate Flutter code for authentication"
Mobile User: "Generate Flutter code for authentication"
  ↓
AgentFactory analyzes task → Capabilities: [CODE_GENERATION, COMPILATION, TESTING]
  → Can mobile tools satisfy? NO (compilation requires Dart SDK)
  ↓
Decision: Delegate to Desktop Agent
  ↓
Mobile Agent sends to Desktop:
  POST /agent/task with {task, context, preferences}
  ↓
Desktop AgentFactory.create_agent_for_task()
  → Complexity Analysis: "complex" (code gen + testing)
  ↓
Create Multi-Agent Swarm:
  - code_generation_agent (specialization: flutter/dart)
  - testing_agent (specialization: unit_tests)
  → Agents coordinate via LangGraph supervisor
  ↓
Desktop executes:
  1. Code generation agent generates code
  2. Testing agent writes/runs tests
  3. Refactoring agent optimizes
  ↓
Result sent back to Mobile via HTTP response
  ↓
Mobile displays result in chat
```

---

## Core Concepts

### 1. Plan-Execute Agent Pattern

The agent follows a **predictable 4-step cycle**:

```
┌─────────────────────────────────────────────────────────┐
│ 1. PLANNING: LLM creates step-by-step plan             │
│    Input: Task + Available tools                       │
│    Output: AgentPlan(steps, dependencies)              │
├─────────────────────────────────────────────────────────┤
│ 2. EXECUTION: Execute each step with tool calls        │
│    Input: Plan, step index                             │
│    Output: StepResult (tool outputs, status)           │
├─────────────────────────────────────────────────────────┤
│ 3. VERIFICATION: Check progress against goal           │
│    Input: Completed steps, original goal               │
│    Output: Verification(complete, remaining)           │
├─────────────────────────────────────────────────────────┤
│ 4. REPLANNING (Optional): If verification fails        │
│    Input: Failures, observations                       │
│    Output: Updated AgentPlan OR fail gracefully        │
└─────────────────────────────────────────────────────────┘
```

**Advantages over ReAct**:
- ✅ Multi-step planning reduces trial-and-error
- ✅ Clear progress tracking
- ✅ Built-in failure recovery
- ✅ Better for constrained resources (mobile)

### 2. ToolRegistry Pattern (Zero Hardcoding)

```
Registration (at app startup):
  registry.registerTool(
    tool: UIValidatorTool(),
    capabilities: [VALIDATE_UI, ELEMENT_INSPECTION],
    domain: "ui_testing"
  )
  
  registry.registerTool(
    tool: CodeGeneratorTool(),
    capabilities: [CODE_GENERATION, TEMPLATE_FILLING],
    domain: "code_gen"
  )

Runtime Tool Selection:
  task_capabilities = analyzer.analyze_task("Generate login page")
  // Returns: [CODE_GENERATION, UI_ELEMENTS, RESPONSIVE_DESIGN]
  
  tools = registry.get_tools_for_capabilities(task_capabilities)
  // Returns: [CodeGeneratorTool, UIElementTool]
  
  // Agent created with ONLY the tools it needs
  agent = AgentFactory.create(task, tools, prompt)
```

**Key Benefit**: No agent class called `LoginPageAgent` - behavior emerges from task + tools.

### 3. Dynamic Agent Creation

```dart
// Mobile: Runtime agent creation
class AgentFactory {
  Future<PlanExecuteAgent> createAgentForTask(String task) async {
    // 1. Analyze what this task needs
    final capabilities = await _analyzeTaskRequirements(task);
    
    // 2. Get tools that support those capabilities
    final tools = _toolRegistry.getToolsForCapabilities(capabilities);
    
    // 3. Check if we can handle locally
    if (_canHandleLocally(capabilities)) {
      // 4. Create agent with LOCAL tools only
      final systemPrompt = _generateSystemPrompt(task, capabilities);
      return PlanExecuteAgent(
        task: task,
        tools: tools,
        systemPrompt: systemPrompt,
      );
    } else {
      // Delegate to desktop
      return RemoteAgent(desktopAddress);
    }
  }
}
```

```python
# Desktop: Complexity-aware agent creation
class DesktopAgentFactory:
  async def create_agent_for_task(self, task: str):
    # 1. Analyze task complexity
    complexity = await self._analyze_complexity(task)
    
    if complexity == "simple":
      # Single agent for simple tasks
      return await self._create_single_agent(task)
    else:
      # Multi-agent swarm for complex tasks
      return await self._create_agent_swarm(task)
  
  async def _create_agent_swarm(self, task: str):
    # 1. Identify domains needed (code_gen, testing, refactoring)
    domains = await self._determine_domains(task)
    
    # 2. Create specialized agent per domain
    agents = {
      domain: self._create_domain_agent(domain, task)
      for domain in domains
    }
    
    # 3. Coordinate via LangGraph supervisor
    return SupervisorAgent(agents)
```

---

## Phase 0: Foundation & Setup

### Objectives
- ✅ Establish project structure for mobile + desktop
- ✅ Create core data models (Agent, Plan, Tool)
- ✅ Setup communication infrastructure (HTTP, WebSocket stubs)
- ✅ Create comprehensive documentation

### Duration
**1 week** (Days 1-5)

### Deliverables

#### 0.1 Mobile Project Structure
```
lib/
├── domain/
│   ├── entities/
│   │   ├── agent.dart              # Agent, PlanStep, StepResult models
│   │   ├── tool.dart               # Tool interface & metadata
│   │   └── task_analysis.dart      # TaskCapabilities, TaskComplexity
│   └── repositories/
│       └── agent_repository.dart   # Repository interface
│
├── infrastructure/
│   ├── ai/
│   │   ├── agent/
│   │   │   ├── plan_execute_agent.dart      # Core agent implementation
│   │   │   ├── agent_factory.dart           # Dynamic creation
│   │   │   └── task_analyzer.dart           # Task analysis (LLM)
│   │   ├── tools/
│   │   │   ├── tool_registry.dart           # Tool registry pattern
│   │   │   ├── ui_validation_tool.dart      # Example tool
│   │   │   ├── sensor_tool.dart             # Example tool
│   │   │   └── file_operation_tool.dart     # Example tool
│   │   └── communication/
│   │       ├── http_client.dart             # REST client (Phase 1)
│   │       ├── websocket_client.dart        # WS client (Phase 2)
│   │       └── mcp_client.dart              # MCP client (Phase 3)
│
├── features/
│   └── agent_chat/
│       ├── presentation/
│       │   └── providers/
│       │       └── agent_provider.dart      # Riverpod agent state
│       └── data/
│           └── datasources/
│               └── remote_agent_source.dart # Desktop delegation
```

#### 0.2 Desktop Project Structure
```
backend/
├── main.py                         # FastAPI entry point
├── config/
│   ├── settings.py                 # Configuration
│   └── logging.py                  # Logging setup
├── domain/
│   ├── entities.py                 # Agent, Plan, Tool models
│   └── repositories.py             # Repository interfaces
├── infrastructure/
│   ├── agents/
│   │   ├── plan_execute_agent.py   # Core agent
│   │   ├── agent_factory.py        # Dynamic creation
│   │   └── task_analyzer.py        # Task analysis
│   ├── tools/
│   │   ├── tool_registry.py        # Tool registry
│   │   ├── code_generator.py       # Example tool
│   │   ├── code_executor.py        # Example tool
│   │   └── test_runner.py          # Example tool
│   ├── llm/
│   │   ├── provider_manager.py     # LLM provider selection
│   │   └── stream_handler.py       # Response streaming
│   └── communication/
│       ├── rest_router.py          # HTTP endpoints (Phase 1)
│       ├── websocket_handler.py    # WS handler (Phase 2)
│       └── mcp_server.py           # MCP server (Phase 3)
├── presentation/
│   └── api/
│       └── routes.py               # API route definitions
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
└── requirements.txt                # Python dependencies
```

#### 0.3 Core Data Models (Dart)

**File**: `lib/domain/entities/agent.dart`
```dart
// Plan-Execute Agent data models
@freezed
class AgentPlan with _$AgentPlan {
  const factory AgentPlan({
    required String taskDescription,
    required List<PlanStep> steps,
    required Map<int, List<int>> stepDependencies, // step_index -> [prereq_indices]
    required DateTime createdAt,
  }) = _AgentPlan;
}

@freezed
class PlanStep with _$PlanStep {
  const factory PlanStep({
    required int stepIndex,
    required String objective,
    required List<String> toolNames,
    required String reasoning,
  }) = _PlanStep;
}

@freezed
class StepResult with _$StepResult {
  const factory StepResult({
    required int stepIndex,
    required ExecutionStatus status, // pending, running, completed, failed
    required Map<String, dynamic> toolOutputs,
    required String? errorMessage,
    required DateTime completedAt,
  }) = _StepResult;
}

@freezed
class Verification with _$Verification {
  const factory Verification({
    required bool taskComplete,
    required String reasoning,
    required List<int>? remainingSteps,
    required bool shouldReplan,
  }) = _Verification;
}

@freezed
class AgentResult with _$AgentResult {
  const factory AgentResult({
    required String taskDescription,
    required bool success,
    required String response,
    required List<StepResult> executedSteps,
    required Duration executionTime,
    required int replans,
  }) = _AgentResult;
}

enum ExecutionStatus { pending, running, completed, failed, skipped }
```

**File**: `lib/domain/entities/tool.dart`
```dart
// Tool interface and metadata
abstract class Tool {
  String get name;
  String get description;
  Set<String> get capabilities; // Metadata for discovery
  String get domain; // ui_testing, code_gen, file_ops, etc.
  
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
}

@freezed
class ToolMetadata with _$ToolMetadata {
  const factory ToolMetadata({
    required String name,
    required String description,
    required Set<String> capabilities,
    required String domain,
    required Map<String, dynamic> schema, // JSON schema for args
    required Duration timeout,
  }) = _ToolMetadata;
}

@freezed
class TaskCapabilities with _$TaskCapabilities {
  const factory TaskCapabilities({
    required List<String> requiredCapabilities,
    required String primaryDomain,
    required bool requiresRemoteExecution,
  }) = _TaskCapabilities;
}
```

#### 0.4 Core Data Models (Python)

**File**: `backend/domain/entities.py`
```python
from dataclasses import dataclass, field
from datetime import datetime
from typing import List, Dict, Any, Optional
from enum import Enum

class ExecutionStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"

class AgentComplexity(Enum):
    SIMPLE = "simple"
    MODERATE = "moderate"
    COMPLEX = "complex"

@dataclass
class PlanStep:
    step_index: int
    objective: str
    tool_names: List[str]
    reasoning: str
    dependencies: List[int] = field(default_factory=list)

@dataclass
class AgentPlan:
    task_description: str
    steps: List[PlanStep]
    created_at: datetime = field(default_factory=datetime.now)
    complexity: AgentComplexity = AgentComplexity.SIMPLE

@dataclass
class StepResult:
    step_index: int
    status: ExecutionStatus
    tool_outputs: Dict[str, Any]
    error_message: Optional[str] = None
    completed_at: datetime = field(default_factory=datetime.now)

@dataclass
class Verification:
    task_complete: bool
    reasoning: str
    remaining_steps: Optional[List[int]] = None
    should_replan: bool = False

@dataclass
class AgentResult:
    task_description: str
    success: bool
    response: str
    executed_steps: List[StepResult]
    execution_time: float  # seconds
    replans: int = 0
```

#### 0.5 Documentation Requirements

**File**: `AGENT_ARCHITECTURE_DECISION_RECORDS.md` (ADRs)
- ADR-001: Why Plan-Execute over ReAct
- ADR-002: Dynamic ToolRegistry vs Hardcoded Agents
- ADR-003: LangChain for Desktop vs Roo Code
- ADR-004: REST → WebSocket → MCP Evolution

**File**: `AGENT_DEVELOPER_GUIDE.md`
- How to add new tools
- How to extend agent capabilities
- Debugging agent execution
- Common patterns and anti-patterns

**File**: `AGENT_TESTING_GUIDE.md`
- Unit testing Plan-Execute agent
- Integration testing mobile ↔ desktop
- Performance benchmarking
- Error scenario testing

#### 0.6 Communication Stubs (Phase 1 REST)

**File**: `lib/infrastructure/ai/communication/http_client.dart`
```dart
class AgentHttpClient {
  final String desktopAddress;
  final Dio _dio;
  
  Future<AgentResult> sendTaskToDesktop(String task) async {
    // Phase 1: Basic HTTP POST
    final response = await _dio.post(
      '$desktopAddress/api/v1/agent/task',
      data: {'task': task},
    );
    
    return AgentResult.fromJson(response.data);
  }
}
```

**File**: `backend/infrastructure/communication/rest_router.py`
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

class TaskRequest(BaseModel):
    task: str
    context: Optional[Dict] = None

@app.post("/api/v1/agent/task")
async def execute_task(request: TaskRequest):
    """Phase 1: Simple REST endpoint"""
    try:
        result = await agent_factory.create_agent_for_task(request.task)
        return {"success": True, "result": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/tools")
async def list_tools():
    """Tool discovery endpoint"""
    return {
        "tools": [tool.to_dict() for tool in tool_registry.all_tools()]
    }
```

### Phase 0 Milestones

- [ ] **Day 1-2**: Project structures created, base models defined
- [ ] **Day 3**: Communication stubs implemented
- [ ] **Day 4**: Core data models complete with serialization
- [ ] **Day 5**: Documentation complete, architecture decisions documented
- [ ] **Day 5 EOD**: Team review & sign-off

### Success Criteria for Phase 0

- ✅ All project directories created and organized
- ✅ Core data models compile and serialize correctly
- ✅ Communication stubs load without errors
- ✅ ADRs document all architectural decisions
- ✅ Developer guide explains agent patterns clearly
- ✅ No compilation errors in Dart or Python

---

## Phase 1: MVP - REST Communication

### Objectives
- ✅ Implement Plan-Execute Agent (Dart & Python)
- ✅ Implement ToolRegistry (Dart & Python)
- ✅ Implement AgentFactory (Dart & Python)
- ✅ REST API endpoints functional
- ✅ Single agent execution for both simple tasks

### Duration
**2 weeks** (Days 6-19)

### Deliverables

#### 1.1 Mobile Plan-Execute Agent

**File**: `lib/infrastructure/ai/agent/plan_execute_agent.dart`

Key Methods:
```dart
class PlanExecuteAgent {
  Future<AgentResult> execute(String task) async {
    // 1. Create plan
    final plan = await _createPlan(task);
    
    // 2. Execute steps
    final results = await _executeSteps(plan);
    
    // 3. Verify progress
    final verification = await _verifyProgress(results);
    
    // 4. Replan if needed
    if (verification.shouldReplan) {
      return _replan(task, results, verification);
    }
    
    return _compileFinalResult(results);
  }
  
  Future<AgentPlan> _createPlan(String task) async {
    // Use LLM to generate step-by-step plan
    // Input: task description + available tools
    // Output: AgentPlan with ordered steps
  }
  
  Future<List<StepResult>> _executeSteps(AgentPlan plan) async {
    // Execute each step with dependency tracking
    // Multi-tool calls per step
    // Error handling per step
  }
  
  Future<Verification> _verifyProgress(List<StepResult> results) async {
    // Use LLM to verify: "Is goal met? Any gaps?"
    // Returns: complete or list of remaining work
  }
  
  Future<AgentResult> _replan(
    String task,
    List<StepResult> results,
    Verification verification,
  ) async {
    // Adjust plan based on failures + feedback
    // Max 2 replans to avoid infinite loops
  }
}
```

#### 1.2 Mobile ToolRegistry

**File**: `lib/infrastructure/ai/tools/tool_registry.dart`

```dart
class ToolRegistry {
  final Map<String, Tool> _tools = {};
  final Map<String, Set<String>> _toolCapabilities = {};
  final Map<String, String> _toolDomains = {};
  
  void registerTool(
    Tool tool,
    Set<String> capabilities,
    String domain,
  ) {
    _tools[tool.name] = tool;
    _toolCapabilities[tool.name] = capabilities;
    _toolDomains[tool.name] = domain;
  }
  
  List<Tool> getToolsForCapabilities(List<String> capabilities) {
    // Return tools that support the required capabilities
    final capabilitySet = capabilities.toSet();
    return _tools.values.where((tool) {
      return _toolCapabilities[tool.name]
          ?.intersection(capabilitySet)
          .isNotEmpty ?? false;
    }).toList();
  }
  
  List<Tool> getToolsForDomain(String domain) {
    return _tools.values.where((tool) {
      return _toolDomains[tool.name] == domain;
    }).toList();
  }
}
```

#### 1.3 Mobile AgentFactory

**File**: `lib/infrastructure/ai/agent/agent_factory.dart`

```dart
class AgentFactory {
  final ToolRegistry _toolRegistry;
  final ChatModel _llm;
  
  Future<PlanExecuteAgent> createAgentForTask(String task) async {
    // 1. Analyze task to determine capabilities needed
    final taskCapabilities = await _analyzeTaskRequirements(task);
    
    // 2. Get tools that support those capabilities
    final tools = _toolRegistry
        .getToolsForCapabilities(taskCapabilities.requiredCapabilities);
    
    // 3. Check if we can handle locally
    if (!taskCapabilities.requiresRemoteExecution) {
      // 4. Create local agent
      final systemPrompt = _generateSystemPrompt(task, taskCapabilities);
      return PlanExecuteAgent(
        task: task,
        tools: tools,
        systemPrompt: systemPrompt,
        llm: _llm,
      );
    } else {
      // Delegate to desktop
      return RemoteAgentProxy(desktopClient);
    }
  }
  
  Future<TaskCapabilities> _analyzeTaskRequirements(String task) async {
    // LLM analyzes task to extract:
    // - Required capabilities
    // - Primary domain
    // - Whether it needs remote execution
    
    final analysisPrompt = '''
    Analyze this task and determine:
    1. What capabilities are needed?
    2. What domain does it belong to?
    3. Can it be done locally (UI testing, file ops, sensors)?
    
    Task: $task
    ''';
    
    final response = await _llm.invoke(analysisPrompt);
    return _parseCapabilitiesFromResponse(response);
  }
  
  String _generateSystemPrompt(
    String task,
    TaskCapabilities capabilities,
  ) {
    return '''
    You are a specialized autonomous agent for the following task:
    Task: $task
    
    You have expertise in: ${capabilities.requiredCapabilities.join(', ')}
    Domain: ${capabilities.primaryDomain}
    
    Your approach:
    1. Plan: Create a step-by-step plan
    2. Execute: Run each step with available tools
    3. Verify: Check if goal is met
    4. Replan if needed
    
    Available tools: [will be injected]
    ''';
  }
}
```

#### 1.4 Desktop Plan-Execute Agent

**File**: `backend/infrastructure/agents/plan_execute_agent.py`

```python
class PlanExecuteAgent:
    def __init__(self, task: str, tools: List[Tool], system_prompt: str, llm: ChatModel):
        self.task = task
        self.tools = tools
        self.system_prompt = system_prompt
        self.llm = llm
        self.max_replans = 2
    
    async def execute(self) -> AgentResult:
        try:
            # 1. Create plan
            plan = await self._create_plan()
            
            # 2. Execute steps
            results = await self._execute_steps(plan)
            
            # 3. Verify progress
            verification = await self._verify_progress(results)
            
            # 4. Replan if needed
            if verification.should_replan:
                results = await self._replan(plan, results, verification)
            
            return self._compile_final_result(results)
        except Exception as e:
            return AgentResult(
                task_description=self.task,
                success=False,
                response=f"Agent failed: {str(e)}",
                executed_steps=[],
                execution_time=0,
            )
    
    async def _create_plan(self) -> AgentPlan:
        """Use LLM to create step-by-step plan"""
        planning_prompt = f"""
        Create a detailed step-by-step plan for this task:
        {self.task}
        
        Available tools: {[t.name for t in self.tools]}
        
        Return a JSON plan with:
        - steps: List of PlanStep objects
        - reasoning: Why this approach
        """
        
        response = await self.llm.ainvoke(planning_prompt)
        return self._parse_plan(response)
    
    async def _execute_steps(self, plan: AgentPlan) -> List[StepResult]:
        """Execute plan steps with tool calls"""
        results = []
        for step in plan.steps:
            result = await self._execute_step(step)
            results.append(result)
        return results
    
    async def _execute_step(self, step: PlanStep) -> StepResult:
        """Execute a single step with multiple tool calls"""
        try:
            tool_outputs = {}
            for tool_name in step.tool_names:
                tool = next((t for t in self.tools if t.name == tool_name), None)
                if tool:
                    output = await tool.execute({})
                    tool_outputs[tool_name] = output
            
            return StepResult(
                step_index=step.step_index,
                status=ExecutionStatus.COMPLETED,
                tool_outputs=tool_outputs,
            )
        except Exception as e:
            return StepResult(
                step_index=step.step_index,
                status=ExecutionStatus.FAILED,
                tool_outputs={},
                error_message=str(e),
            )
    
    async def _verify_progress(self, results: List[StepResult]) -> Verification:
        """Check if goal is met"""
        verification_prompt = f"""
        Original task: {self.task}
        Executed steps: {len(results)}
        Step results: {[r.status for r in results]}
        
        Is the task complete? What remains?
        """
        
        response = await self.llm.ainvoke(verification_prompt)
        return self._parse_verification(response)
```

#### 1.5 Desktop ToolRegistry

**File**: `backend/infrastructure/tools/tool_registry.py`

```python
class ToolRegistry:
    def __init__(self):
        self._tools: Dict[str, Tool] = {}
        self._capabilities: Dict[str, Set[str]] = {}
        self._domains: Dict[str, str] = {}
    
    def register_tool(
        self,
        tool: Tool,
        capabilities: Set[str],
        domain: str,
    ):
        self._tools[tool.name] = tool
        self._capabilities[tool.name] = capabilities
        self._domains[tool.name] = domain
    
    def get_tools_for_capabilities(
        self,
        required_capabilities: List[str],
    ) -> List[Tool]:
        capability_set = set(required_capabilities)
        matching_tools = []
        
        for tool_name, tool in self._tools.items():
            if self._capabilities[tool_name].intersection(capability_set):
                matching_tools.append(tool)
        
        return matching_tools
    
    def get_tools_for_domain(self, domain: str) -> List[Tool]:
        return [
            tool for tool_name, tool in self._tools.items()
            if self._domains[tool_name] == domain
        ]
    
    def all_tools(self) -> List[Tool]:
        return list(self._tools.values())
```

#### 1.6 Desktop AgentFactory

**File**: `backend/infrastructure/agents/agent_factory.py`

```python
class DesktopAgentFactory:
    def __init__(self, tool_registry: ToolRegistry, llm: ChatModel):
        self.tool_registry = tool_registry
        self.llm = llm
    
    async def create_agent_for_task(self, task: str) -> PlanExecuteAgent:
        # Analyze complexity
        complexity = await self._analyze_complexity(task)
        
        # For MVP Phase 1: Single agent only
        # Phase 2 will add multi-agent swarm
        return await self._create_single_agent(task)
    
    async def _analyze_complexity(self, task: str) -> AgentComplexity:
        """Determine if task is simple or complex"""
        analysis_prompt = f"""
        Rate this task complexity (simple/moderate/complex):
        {task}
        
        Simple: Single domain, straightforward
        Moderate: Multiple domains, but clear steps
        Complex: Multiple domains with interdependencies, optimization needed
        """
        
        response = await self.llm.ainvoke(analysis_prompt)
        # Parse response to return complexity
        return AgentComplexity.SIMPLE  # MVP: default to simple
    
    async def _create_single_agent(self, task: str) -> PlanExecuteAgent:
        """Create single agent for MVP"""
        # Get all tools for this task
        tools = self.tool_registry.all_tools()
        
        system_prompt = f"""
        You are an autonomous agent designed to complete tasks.
        
        Task: {task}
        
        Approach:
        1. Plan: Create a step-by-step plan
        2. Execute: Run each step with available tools
        3. Verify: Check if goal is met
        4. Replan if needed
        """
        
        return PlanExecuteAgent(
            task=task,
            tools=tools,
            system_prompt=system_prompt,
            llm=self.llm,
        )
```

#### 1.7 REST API Endpoints

**File**: `backend/presentation/api/routes.py`

```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Micro Agent Backend", version="1.0.0")

class TaskRequest(BaseModel):
    task: str
    context: Optional[Dict] = None

class TaskResponse(BaseModel):
    success: bool
    result: Optional[Dict] = None
    error: Optional[str] = None

@app.post("/api/v1/agent/task")
async def execute_task(request: TaskRequest) -> TaskResponse:
    """Execute a task on desktop agent"""
    try:
        agent = await agent_factory.create_agent_for_task(request.task)
        result = await agent.execute()
        
        return TaskResponse(
            success=result.success,
            result=result.to_dict(),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/tools")
async def list_tools() -> Dict:
    """List all available tools"""
    return {
        "tools": [
            {
                "name": tool.name,
                "description": tool.description,
                "capabilities": list(tool.capabilities),
            }
            for tool in tool_registry.all_tools()
        ]
    }

@app.get("/api/v1/health")
async def health_check() -> Dict:
    """Health check endpoint"""
    return {"status": "healthy"}
```

#### 1.8 Mobile Riverpod Integration

**File**: `lib/features/agent_chat/presentation/providers/agent_provider.dart`

```dart
// Integration with existing chat provider
final agentFactoryProvider = Provider((ref) {
  return AgentFactory(
    toolRegistry: ref.watch(toolRegistryProvider),
    llm: ref.watch(aiProvidersProvider),
  );
});

final localAgentProvider = FutureProvider<AgentResult>((ref) async {
  final agentFactory = ref.watch(agentFactoryProvider);
  final userMessage = ref.watch(userMessageProvider);
  
  return agentFactory.createAgentForTask(userMessage).then((agent) {
    return agent.execute(userMessage);
  });
});
```

#### 1.9 Tool Implementations (Examples)

**File**: `backend/infrastructure/tools/code_generator.py`

```python
class CodeGeneratorTool(Tool):
    name = "code_generator"
    description = "Generate Flutter/Dart code"
    capabilities = {"CODE_GENERATION", "TEMPLATE_FILLING"}
    domain = "code_gen"
    
    async def execute(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Generate code based on requirements"""
        requirement = args.get("requirement", "")
        
        # Use LLM to generate code
        # This is a skeleton - actual implementation uses langchain
        return {
            "code": "// Generated code here",
            "language": "dart",
            "complexity": "medium",
        }

class CodeExecutorTool(Tool):
    name = "code_executor"
    description = "Execute/compile code"
    capabilities = {"CODE_EXECUTION", "COMPILATION", "TESTING"}
    domain = "code_gen"
    
    async def execute(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute code safely"""
        code = args.get("code", "")
        
        # Execute in sandbox (Phase 1: mock, Phase 2+: real execution)
        return {
            "output": "Code executed successfully",
            "errors": [],
            "warnings": [],
        }
```

### Phase 1 Testing

**File**: `lib/domain/entities/agent.dart` - Unit tests
```dart
void main() {
  group('PlanExecuteAgent', () {
    test('creates valid plan from task', () async {
      // Mock LLM, tools
      // Verify agent creates AgentPlan with steps
    });
    
    test('executes steps in order with dependencies', () async {
      // Mock step execution
      // Verify order and dependency handling
    });
    
    test('verifies progress correctly', () async {
      // Mock verification LLM call
      // Verify completion detection
    });
    
    test('replans on failure', () async {
      // Mock failure scenario
      // Verify replan is triggered
      // Verify max replans limit (2)
    });
  });
}
```

**File**: `backend/tests/test_agent.py` - Python tests
```python
@pytest.mark.asyncio
async def test_plan_execute_agent_creates_plan():
    agent = PlanExecuteAgent(task="test", tools=[], system_prompt="", llm=mock_llm)
    plan = await agent._create_plan()
    assert isinstance(plan, AgentPlan)
    assert len(plan.steps) > 0

@pytest.mark.asyncio
async def test_agent_executes_steps():
    # Mock tools, verify step execution
    pass

@pytest.mark.asyncio
async def test_tool_registry_dynamic_discovery():
    registry = ToolRegistry()
    registry.register_tool(MockTool(), {"CAPABILITY_A", "CAPABILITY_B"}, "test_domain")
    
    tools = registry.get_tools_for_capabilities(["CAPABILITY_A"])
    assert len(tools) == 1
    assert tools[0].name == "mock_tool"
```

### Phase 1 Milestones

- [ ] **Day 6-8**: Plan-Execute agent implemented (Dart + Python)
- [ ] **Day 9**: ToolRegistry and tools implemented
- [ ] **Day 10-11**: AgentFactory implemented
- [ ] **Day 12-14**: REST API endpoints functional, integration tested
- [ ] **Day 15-16**: Error handling, edge cases
- [ ] **Day 17-19**: Testing complete, documentation updated

### Phase 1 Success Criteria

- ✅ Simple task execution works (local)
- ✅ Desktop task delegation works (HTTP)
- ✅ Tool discovery dynamic (no hardcoding)
- ✅ Plan-Execute cycle completes successfully
- ✅ REST API responds correctly
- ✅ 80% unit test coverage
- ✅ Zero hardcoded agent specializations

---

## Phase 2: Production - Real-Time Streaming

### Objectives
- ✅ WebSocket support for real-time responses
- ✅ Token-by-token streaming (LLM responses)
- ✅ Streaming verification & plan updates
- ✅ Server-Sent Events fallback
- ✅ Production-grade error handling

### Duration
**1.5 weeks** (Days 20-30)

### Key Deliverables

#### 2.1 WebSocket Communication Layer

**File**: `lib/infrastructure/ai/communication/websocket_client.dart`
- Persistent connection management
- Reconnection logic with exponential backoff
- Message queuing for offline scenarios
- Token stream aggregation

**File**: `backend/infrastructure/communication/websocket_handler.py`
- WebSocket connection lifecycle
- Streaming response handling
- Graceful disconnect recovery
- Broadcast capability (multi-client support)

#### 2.2 Real-Time Streaming Integration

**File**: `lib/infrastructure/ai/agent/streaming_agent.dart`
- Stream-based plan execution
- Token-by-token callback
- Progress updates in real-time
- Interactive replanning during execution

**File**: `backend/infrastructure/agents/streaming_agent.py`
- Async streaming with `async yield`
- Token buffering and flushing
- Rate limiting for client consumption

#### 2.3 Production Error Handling

- Network failure recovery
- Partial result recovery
- Timeout management
- Resource cleanup

### Phase 2 Success Criteria

- ✅ Streaming responses work end-to-end
- ✅ WebSocket reconnection automatic
- ✅ SSE fallback functional
- ✅ Token-by-token response time < 100ms
- ✅ No data loss on network failures
- ✅ Chat UI displays streamed tokens smoothly

---

## Phase 3: Advanced - MCP Protocol

### Objectives
- ✅ Implement Model Context Protocol (MCP) server
- ✅ Tool discovery via MCP
- ✅ Standardized request/response format
- ✅ MCP client in Flutter
- ✅ Future-proof architecture

### Duration
**1.5 weeks** (Days 31-42)

### Key Deliverables

#### 3.1 MCP Server Implementation

**File**: `backend/infrastructure/communication/mcp_server.py`
- MCP resource definitions
- MCP tool definitions
- MCP prompt definitions
- JSON-RPC handler

#### 3.2 MCP Client Integration (Dart)

**File**: `lib/infrastructure/ai/communication/mcp_client.dart`
- MCP client for Dart
- Tool discovery via MCP resources
- Standardized MCP message format

#### 3.3 MCP Tool Discovery

- Dynamic tool loading
- Capability mapping to MCP schema
- Runtime tool registration

### Phase 3 Success Criteria

- ✅ MCP server exposes all tools
- ✅ Mobile discovers tools via MCP
- ✅ Standardized message format
- ✅ Compatible with MCP ecosystem
- ✅ Zero regression from Phase 2

---

## Technical Specifications

### Agent Execution Flow (Detailed)

```
1. USER INPUT: "Generate and test login form"
   ↓
2. TASK ROUTING:
   - Local capable? → Execute locally
   - Remote needed? → Delegate to desktop
   ↓
3. AGENT CREATION:
   - Analyze task capabilities
   - Select tools
   - Generate system prompt
   ↓
4. PLANNING PHASE:
   LLM: "Here's my plan:
     Step 1: Generate login form code (code_generator)
     Step 2: Add validation logic (code_generator)
     Step 3: Create tests (test_generator)
     Step 4: Run tests (test_executor)
   "
   ↓
5. EXECUTION PHASE:
   FOR EACH STEP:
     a) Execute tools
     b) Collect outputs
     c) Stream progress to UI
     ↓
6. VERIFICATION PHASE:
   LLM: "Did we complete the goal?"
   → YES: Return result
   → NO: Return remaining work
   ↓
7. REPLAN PHASE (if needed):
   LLM: "We failed at step 3. Revise plan."
   → Go to EXECUTION PHASE with new plan
   → Max 2 replans
   ↓
8. RESULT:
   Return AgentResult with all execution details
```

### Tool Interface Standard

```dart
// All tools implement this interface
abstract class Tool {
  // Metadata
  String get name;
  String get description;
  Set<String> get capabilities;
  String get domain;
  
  // Execution
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args);
  
  // Validation
  Map<String, dynamic> get jsonSchema; // For validation
}
```

### Error Handling Strategy

```
Exception Types:
├── PlanningError
│   └── LLM couldn't create valid plan
├── ExecutionError
│   ├── ToolNotFound
│   ├── ToolExecutionFailed
│   └── TimeoutError
├── VerificationError
│   └── LLM couldn't verify progress
├── NetworkError
│   ├── ConnectionLost
│   ├── Timeout
│   └── InvalidResponse
└── ResourceError
    ├── InsufficientMemory
    └── RateLimit

Recovery Strategies:
├── PlanningError → Retry with simplified task
├── ExecutionError → Skip step or use alternative tool
├── VerificationError → Assume task incomplete, replan
├── NetworkError → Queue and retry
└── ResourceError → Fail gracefully
```

---

## Testing Strategy

### Unit Tests (40% of effort)

**Dart Tests**:
- PlanExecuteAgent: Plan creation, execution, verification, replanning
- ToolRegistry: Registration, discovery, filtering
- AgentFactory: Task analysis, tool selection, agent creation
- Communication: HTTP, WebSocket parsing

**Python Tests**:
- Agent: Same as Dart
- LangChain integration: Tool calling, streaming
- FastAPI routes: Request/response handling

### Integration Tests (35% of effort)

**End-to-End Scenarios**:
1. Local task execution (UI validation)
2. Remote task delegation (code generation)
3. Multi-step task with replanning
4. Network failure recovery
5. Streaming response end-to-end
6. Tool discovery and validation

### Performance Tests (15% of effort)

**Benchmarks**:
- Plan creation latency (< 500ms)
- Step execution latency (< 2s)
- Token streaming rate (> 50 tokens/sec)
- Tool discovery (< 100ms)
- Memory usage (< 200MB mobile, < 1GB desktop)

### Stress Tests (10% of effort)

- Concurrent task execution (10+ tasks)
- Long-running tasks (30+ min)
- Large output handling (1MB+)
- Network instability simulation

---

## Documentation & Runbooks

### Developer Documentation

1. **Agent Architecture Guide** (`AGENT_ARCHITECTURE.md`)
   - System design overview
   - Data flow diagrams
   - Pattern explanations

2. **Developer Getting Started** (`AGENT_DEV_SETUP.md`)
   - Environment setup (Dart + Python)
   - Running the system locally
   - Common debugging techniques

3. **Tool Developer Guide** (`HOW_TO_CREATE_TOOLS.md`)
   - Tool interface definition
   - Step-by-step tool creation
   - Tool testing patterns
   - Integration checklist

4. **Agent Extension Guide** (`HOW_TO_EXTEND_AGENTS.md`)
   - Custom agent creation
   - Multi-agent coordination
   - Domain specialization

### Operational Runbooks

1. **Deployment Guide** (`AGENT_DEPLOYMENT.md`)
   - Backend deployment (FastAPI)
   - Mobile integration
   - Configuration management

2. **Troubleshooting Guide** (`AGENT_TROUBLESHOOTING.md`)
   - Agent not executing
   - WebSocket disconnections
   - Tool execution failures
   - Performance issues

3. **Monitoring Guide** (`AGENT_MONITORING.md`)
   - Metrics to track
   - Alert thresholds
   - Log analysis

### Architecture Decision Records (ADRs)

1. `ADR-001-plan-execute-pattern.md`
2. `ADR-002-dynamic-tool-registry.md`
3. `ADR-003-rest-websocket-mcp-evolution.md`
4. `ADR-004-langchain-vs-roo-code.md`

---

## Success Metrics

### Functional Metrics

- [ ] Agent execution success rate > 95%
- [ ] Plan validity (LLM creates executable plans) > 90%
- [ ] Tool discovery accuracy > 99%
- [ ] Zero hardcoded agent specializations
- [ ] Tool extensibility (add new tool in < 30 min)

### Performance Metrics

- [ ] Plan creation latency < 500ms
- [ ] Step execution latency < 2s
- [ ] Token streaming rate > 50 tokens/sec
- [ ] WebSocket reconnection < 2s
- [ ] Memory footprint < 200MB (mobile), < 1GB (desktop)

### Quality Metrics

- [ ] Unit test coverage > 80%
- [ ] Integration test coverage > 70%
- [ ] Zero critical bugs in Phase 1
- [ ] Response time (p95) < 5s for simple tasks
- [ ] Documentation completeness > 90%

### Developer Metrics

- [ ] New tool creation time < 30 minutes
- [ ] Onboarding time for new developer < 4 hours
- [ ] Architecture decision clarity score > 8/10
- [ ] Code review feedback positive > 85%

---

## Timeline Summary

| Phase | Duration | Key Deliverables | Status |
|-------|----------|------------------|--------|
| **Phase 0** | Days 1-5 (1 week) | Project structure, core models, documentation | Planned |
| **Phase 1** | Days 6-19 (2 weeks) | PlanExecuteAgent, ToolRegistry, REST API, MVP | Planned |
| **Phase 2** | Days 20-30 (1.5 weeks) | WebSocket streaming, production-grade error handling | Planned |
| **Phase 3** | Days 31-42 (1.5 weeks) | MCP protocol, tool discovery, standardization | Planned |
| **Buffer** | Days 43-45 (1 week) | Refinement, final testing, deployment | Planned |

**Total Duration**: ~8-9 weeks to production-ready

---

## Team Responsibilities

### Mobile (Dart/Flutter)
- **Day 1-5**: Setup project structure, define models
- **Day 6-14**: Implement PlanExecuteAgent, ToolRegistry, AgentFactory
- **Day 15-19**: REST integration, testing
- **Day 20-30**: WebSocket integration, streaming UI updates
- **Day 31-42**: MCP client integration

### Backend (Python)
- **Day 1-5**: Setup project structure, define models
- **Day 6-14**: Implement PlanExecuteAgent, ToolRegistry, tools, LangChain integration
- **Day 15-19**: FastAPI REST endpoints, testing
- **Day 20-30**: WebSocket handler, streaming, error handling
- **Day 31-42**: MCP server implementation

### DevOps/Infra
- Day 1-5: Infrastructure setup (Docker, deployment targets)
- Day 20+: Monitoring, logging, performance tracking

### QA
- Day 6+: Test plan development, test case creation
- Day 15+: Integration testing, performance benchmarking
- Day 35+: Production readiness review

---

## Architecture Decisions (Summary)

### ADR-001: Plan-Execute Agent Pattern
**Chosen**: Plan-Execute (over ReAct)
**Reasoning**: 
- Multi-step planning reduces trial-and-error
- Built-in progress tracking and verification
- Better for resource-constrained environments (mobile)
- Enables replanning for failure recovery

### ADR-002: Dynamic ToolRegistry (Zero Hardcoding)
**Chosen**: Runtime tool discovery via capability matching
**Reasoning**:
- No hardcoded agent classes (LoginTestAgent, CodeGenAgent antipattern avoided)
- Tools registered once with metadata
- Agent behavior emerges from task + tools
- Easy extensibility (add tool → automatically available to future agents)

### ADR-003: REST → WebSocket → MCP Evolution
**Chosen**: Phased communication protocol evolution
**Reasoning**:
- REST for MVP (simple, familiar)
- WebSocket for Phase 2 (real-time, efficient)
- MCP for Phase 3 (standardized, future-proof)
- No breaking changes between phases

### ADR-004: LangChain for Desktop Backend
**Chosen**: LangChain + FastAPI (over Roo Code)
**Reasoning**:
- Maximum flexibility for agent design
- Excellent tool/toolkit system
- Easy REST API exposure
- MIT license (commercial-friendly)
- Mature ecosystem (272k+ dependents)
- Better for mobile ↔ desktop integration

---

## Known Constraints & Assumptions

### Constraints
1. Mobile device must operate autonomously (no real-time connection required)
2. Desktop backend is optional (system works mobile-only for local tasks)
3. Agent execution time must be < 30 seconds for user interaction
4. Tool execution must be deterministic (reproducible results)
5. No persistent agent state across sessions (MVP)

### Assumptions
1. LLM providers (OpenAI, Claude, ZhipuAI) are accessible
2. Network connectivity available for desktop tasks
3. Users understand agent limitations (not magic AI)
4. Tool implementations are bug-free (garbage in → garbage out)
5. No sensitive data in agent execution (no PII processing)

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| LLM plan invalid/unexecutable | Medium | High | Max 2 replans, fallback to manual entry |
| Tool execution fails | Medium | Medium | Alternative tool selection, graceful degradation |
| WebSocket disconnect during execution | Medium | Medium | Message queuing, reconnection + resume |
| Performance degradation with many tools | Low | High | Tool registry indexing, lazy loading |
| Agent infinite loop/runaway execution | Low | Critical | Execution timeout, step count limit, cost tracking |

---

## Next Steps (Day 1)

1. **Review & Approval**: Team review of this document
2. **Environment Setup**: Python venv, Dart packages, Git repo
3. **Project Structure**: Create directories per specification
4. **Team Kickoff**: Clarify roles, define daily standups
5. **Start Phase 0**: Begin project structure implementation

---

**Document Status**: Ready for Implementation  
**Next Review Date**: Day 5 (end of Phase 0)  
**Prepared By**: Architecture Team  
**Approved By**: [TBD]

