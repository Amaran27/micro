# Micro Agent System - Developer Quick Reference

**Document Version**: 1.0  
**Created**: November 2, 2025  
**Audience**: Developers implementing the agent system  
**Maintenance**: Updated weekly during implementation

---

## Quick Navigation

📋 **Main Documents**:
- [AGENT_IMPLEMENTATION_PHASES.md](./AGENT_IMPLEMENTATION_PHASES.md) - Detailed phase breakdown (8-9 weeks)
- [AGENT_ARCHITECTURE_DECISIONS.md](./AGENT_ARCHITECTURE_DECISIONS.md) - Architecture decisions & rationale (ADR-001 to ADR-008)
- [AGENT_TECHNICAL_SPECIFICATION.md](./AGENT_TECHNICAL_SPECIFICATION.md) - Technical specs, data models, APIs

---

## Core Concepts (TL;DR)

### What is the Agent?

```
PlanExecuteAgent: A task executor that:
  1. PLAN: LLM creates step-by-step plan
  2. EXECUTE: Run steps with tools
  3. VERIFY: Check if goal met
  4. REPLAN: Fix if failed (max 2 attempts)
```

### Why Not ReAct?

ReAct does: Think → Act → Observe → Think → Act (slow, wasteful)  
PlanExecute does: Plan → Execute → Verify → Done (efficient, progress tracked)

### Why Dynamic Tools?

```
WRONG: Create LoginTestAgent, CodeGenAgent, DataAnalysisAgent classes
RIGHT: Register tools once → agents created dynamically at runtime
```

---

## Key Components at a Glance

### Mobile (Dart/Flutter)

| Component | File | Purpose |
|-----------|------|---------|
| **PlanExecuteAgent** | `lib/infrastructure/ai/agent/plan_execute_agent.dart` | Core agent: plan → execute → verify → replan |
| **AgentFactory** | `lib/infrastructure/ai/agent/agent_factory.dart` | Creates agents dynamically, decides local vs remote |
| **ToolRegistry** | `lib/infrastructure/ai/tools/tool_registry.dart` | Registers tools, discovers by capability |
| **HTTPClient** | `lib/infrastructure/ai/communication/http_client.dart` | REST communication to desktop (Phase 1) |

**Initialization**:
```dart
// At app startup
final registry = ToolRegistry();
registry.registerTool(UIValidatorTool(), {...}, "ui_testing");
registry.registerTool(SensorTool(), {...}, "sensors");

final factory = AgentFactory(registry, llm);

// When user sends message
final agent = await factory.createAgentForTask(userMessage);
final result = await agent.execute(userMessage);
```

### Desktop (Python/FastAPI)

| Component | File | Purpose |
|-----------|------|---------|
| **PlanExecuteAgent** | `backend/infrastructure/agents/plan_execute_agent.py` | Same as mobile but with desktop tools |
| **DesktopAgentFactory** | `backend/infrastructure/agents/agent_factory.py` | Creates agents, analyzes complexity |
| **ToolRegistry** | `backend/infrastructure/tools/tool_registry.py` | Desktop tools (code gen, execution, etc.) |
| **FastAPI Server** | `backend/main.py` | REST endpoints (Phase 1) |

**Initialization**:
```python
# At startup
registry = ToolRegistry()
registry.register_tool(CodeGeneratorTool(), {...}, "code_gen")
registry.register_tool(TestRunnerTool(), {...}, "testing")

factory = DesktopAgentFactory(registry, llm)

# FastAPI endpoint
@app.post("/api/v1/agent/task")
async def execute_task(request: TaskRequest):
    agent = await factory.create_agent_for_task(request.task)
    return await agent.execute()
```

---

## Common Workflows

### Workflow 1: Adding a New Tool

**Step 1: Create Tool Class**
```dart
class MyNewTool implements Tool {
  @override
  String get name => "my_tool";
  
  @override
  Set<String> get capabilities => {"CAPABILITY_A", "CAPABILITY_B"};
  
  @override
  String get domain => "my_domain";
  
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    // Implementation
    return {"result": "value"};
  }
}
```

**Step 2: Register at Startup**
```dart
registry.registerTool(
  MyNewTool(),
  {"CAPABILITY_A", "CAPABILITY_B"},
  "my_domain",
);
```

**That's it!** Agent automatically discovers this tool for future tasks.

### Workflow 2: Task Routing (Local vs Remote)

**Flow**:
```
User: "Generate Flutter code"
  ↓
AgentFactory.createAgentForTask()
  ↓
Task Analysis (LLM):
  "This task needs: [CODE_GENERATION, COMPILATION]"
  "Can mobile do this? No (needs Dart SDK)"
  ↓
Decision: DELEGATE TO DESKTOP
  ↓
Create RemoteAgentProxy
```

**Code**:
```dart
// lib/infrastructure/ai/agent/agent_factory.dart
Future<PlanExecuteAgent> createAgentForTask(String task) async {
  final caps = await _analyzeTaskRequirements(task);
  
  if (caps.requiresRemoteExecution) {
    return RemoteAgentProxy(desktopClient); // Delegate
  } else {
    final tools = _toolRegistry.getToolsForCapabilities(caps.requiredCapabilities);
    return PlanExecuteAgent(tools, systemPrompt, llm); // Local
  }
}
```

### Workflow 3: Streaming Responses (Phase 2)

**Mobile Side**:
```dart
websocket.onMessage = (token) {
  setState(() {
    response += token; // Append token to response
  });
};

websocket.connect('ws://localhost:8000/ws/stream');
```

**Desktop Side**:
```python
@app.websocket("/ws/stream")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    async for token in agent.stream_execute():
        await websocket.send_text(token)
```

---

## File Structure

### Mobile Project

```
lib/
├── domain/
│   ├── entities/
│   │   ├── agent.dart              ← Models: Plan, Step, Result
│   │   ├── tool.dart               ← Tool interface
│   │   └── task_analysis.dart      ← Capability models
│   └── repositories/
│       └── agent_repository.dart   ← Repository interface
│
├── infrastructure/
│   └── ai/
│       ├── agent/
│       │   ├── plan_execute_agent.dart ← Core agent
│       │   ├── agent_factory.dart      ← Dynamic creation
│       │   └── task_analyzer.dart      ← Task analysis
│       ├── tools/
│       │   ├── tool_registry.dart      ← Tool registry
│       │   ├── ui_validation_tool.dart ← Example tool
│       │   ├── sensor_tool.dart        ← Example tool
│       │   └── file_operation_tool.dart
│       └── communication/
│           ├── http_client.dart        ← REST (Phase 1)
│           ├── websocket_client.dart   ← WebSocket (Phase 2)
│           └── mcp_client.dart         ← MCP (Phase 3)
│
└── features/
    └── agent_chat/
        ├── presentation/
        │   └── providers/
        │       └── agent_provider.dart ← Riverpod state
        └── data/
            └── datasources/
                └── remote_agent_source.dart
```

### Desktop Project

```
backend/
├── main.py                        ← FastAPI entry point
├── config/
│   ├── settings.py               ← Configuration
│   └── logging.py                ← Logging
├── domain/
│   ├── entities.py               ← Data models
│   └── repositories.py           ← Repository interfaces
├── infrastructure/
│   ├── agents/
│   │   ├── plan_execute_agent.py ← Core agent
│   │   ├── agent_factory.py      ← Factory
│   │   └── task_analyzer.py      ← Analysis
│   ├── tools/
│   │   ├── tool_registry.py      ← Registry
│   │   ├── code_generator.py     ← Example tool
│   │   ├── code_executor.py
│   │   └── test_runner.py
│   ├── llm/
│   │   ├── provider_manager.py   ← LLM selection
│   │   └── stream_handler.py     ← Response streaming
│   └── communication/
│       ├── rest_router.py        ← HTTP (Phase 1)
│       ├── websocket_handler.py  ← WebSocket (Phase 2)
│       └── mcp_server.py         ← MCP (Phase 3)
├── presentation/
│   └── api/
│       └── routes.py             ← Route definitions
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
└── requirements.txt              ← Dependencies
```

---

## Common Commands

### Development Setup

**Mobile (Dart)**:
```bash
cd micro
pub get
dart run build_runner build  # Generate models
flutter run -d <device>
```

**Desktop (Python)**:
```bash
cd backend
python -m venv venv
venv\Scripts\activate  # Windows
pip install -r requirements.txt
python main.py
```

### Running Tests

**Mobile**:
```bash
flutter test lib/domain/entities/agent.dart
flutter test lib/infrastructure/ai/agent/
```

**Desktop**:
```bash
pytest backend/tests/unit/test_agent.py
pytest backend/tests/integration/
```

### Building for Deployment

**Mobile**:
```bash
flutter build apk --release
```

**Desktop**:
```bash
# Docker container (Phase 2)
docker build -t micro-agent-backend .
docker run -p 8000:8000 micro-agent-backend
```

---

## Debugging Guide

### How to Debug Agent Execution

**1. Enable Debug Logging**:
```dart
// Add to agent_factory.dart
logger.d("Task: $task");
logger.d("Required capabilities: ${capabilities.requiredCapabilities}");
logger.d("Selected tools: ${tools.map((t) => t.name).toList()}");
```

**2. Inspect Agent Plan**:
```dart
// After plan creation
logger.d("Plan steps: ${plan.steps.length}");
plan.steps.forEach((step) {
  logger.d("  Step ${step.stepIndex}: ${step.objective}");
  logger.d("    Tools: ${step.toolNames}");
});
```

**3. Check Tool Output**:
```dart
// After step execution
results.forEach((result) {
  logger.d("Step ${result.stepIndex}: ${result.status}");
  logger.d("  Output: ${result.toolOutputs}");
  if (result.errorMessage != null) {
    logger.e("  Error: ${result.errorMessage}");
  }
});
```

**4. Verify Progress**:
```dart
// After verification
logger.d("Task complete: ${verification.taskComplete}");
logger.d("Reasoning: ${verification.reasoning}");
if (verification.shouldReplan) {
  logger.d("Replanning needed. Remaining: ${verification.remainingSteps}");
}
```

### Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| Agent returns empty response | LLM planning failed | Check LLM logs, try simpler task |
| Tool not found | Registry not initialized | Call `registerTool()` at app startup |
| Desktop agent not responding | Server not running | Start FastAPI: `python main.py` |
| Streaming broken (Phase 2) | WebSocket connection failed | Check firewall, verify URL |
| Tool timeout | Tool takes too long | Increase timeout in ToolMetadata |

---

## Testing Checklist

### Unit Test Template

```dart
void main() {
  group('PlanExecuteAgent', () {
    late PlanExecuteAgent agent;
    late MockTool mockTool;
    late MockChatModel mockLlm;
    
    setUp(() {
      mockTool = MockTool();
      mockLlm = MockChatModel();
      agent = PlanExecuteAgent([mockTool], "prompt", mockLlm);
    });
    
    test('creates valid plan', () async {
      // When
      final plan = await agent._createPlan("test task");
      
      // Then
      expect(plan.steps, isNotEmpty);
      expect(plan.taskDescription, "test task");
    });
    
    test('executes steps in order', () async {
      // Given
      final plan = AgentPlan(
        taskDescription: "test",
        steps: [
          PlanStep(stepIndex: 0, objective: "do A", toolNames: ["tool1"], reasoning: ""),
          PlanStep(stepIndex: 1, objective: "do B", toolNames: ["tool1"], reasoning: ""),
        ],
        stepDependencies: {},
      );
      
      // When
      final results = await agent._executeSteps(plan);
      
      // Then
      expect(results.length, 2);
      expect(results[0].status, ExecutionStatus.completed);
    });
  });
}
```

### Integration Test Template

```dart
void main() {
  group('Agent End-to-End', () {
    late PlanExecuteAgent agent;
    late RealTool realTool;
    
    setUp(() async {
      realTool = RealTool();
      // Use real LLM (MockLlm for testing)
      agent = PlanExecuteAgent([realTool], "prompt", mockLlm);
    });
    
    test('executes complete task', () async {
      // When
      final result = await agent.execute("Generate hello world in Dart");
      
      // Then
      expect(result.success, true);
      expect(result.response, isNotEmpty);
      expect(result.executedSteps, isNotEmpty);
    });
  });
}
```

---

## Performance Tips

### Mobile Optimization

1. **Cache tool registry** - Don't recreate every time
2. **Lazy load tools** - Only load tools needed for task
3. **Set reasonable timeouts** - 30s max per step
4. **Use streaming** - Don't wait for complete response

### Desktop Optimization

1. **Batch tool registration** - Register all at startup, not per-task
2. **Connection pooling** - Reuse LLM connections
3. **Implement caching** - Cache generated code, test results
4. **Monitor resources** - Track memory/CPU per agent

---

## Code Examples

### Example 1: Create Custom Tool

```dart
// my_custom_tool.dart
class MyCustomTool implements Tool {
  @override
  String get name => "my_custom_tool";
  
  @override
  String get description => "Does something useful";
  
  @override
  Set<String> get capabilities => {
    "MY_CAPABILITY_A",
    "MY_CAPABILITY_B",
  };
  
  @override
  String get domain => "custom_domain";
  
  @override
  Map<String, dynamic> get jsonSchema => {
    "type": "object",
    "properties": {
      "input": {"type": "string"},
    },
    "required": ["input"],
  };
  
  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args) async {
    final input = args["input"] as String;
    
    // Do work
    final output = "Processed: $input";
    
    return {
      "output": output,
      "status": "success",
    };
  }
}

// main.dart
void main() {
  final registry = ToolRegistry();
  registry.registerTool(
    MyCustomTool(),
    {"MY_CAPABILITY_A", "MY_CAPABILITY_B"},
    "custom_domain",
  );
}
```

### Example 2: Use Factory to Create Agent

```dart
Future<void> executeTask(String task) async {
  // Create factory
  final factory = AgentFactory(toolRegistry, llm);
  
  // Create agent dynamically for this task
  final agent = await factory.createAgentForTask(task);
  
  // Execute
  final result = await agent.execute(task);
  
  // Handle result
  if (result.success) {
    print("Task completed: ${result.response}");
  } else {
    print("Task failed: ${result.finalError}");
  }
}
```

### Example 3: Stream Results (Phase 2)

```dart
// With WebSocket
websocket.onMessage = (token) {
  setState(() {
    _response += token;
  });
};

websocket.connect('ws://localhost:8000/ws/stream');
websocket.send(jsonEncode({
  "type": "task_request",
  "payload": {"task": userMessage},
}));
```

---

## Phase Timeline

| Phase | Duration | Deliverable | Status |
|-------|----------|-------------|--------|
| 0 | Day 1-5 | Project structure, models, docs | **STARTING** |
| 1 | Day 6-19 | PlanExecuteAgent, REST API, MVP | Planned |
| 2 | Day 20-30 | WebSocket, streaming, production | Planned |
| 3 | Day 31-42 | MCP protocol, standardization | Planned |

---

## Key Contacts & Resources

### Team Leads
- **Mobile**: [TBD]
- **Backend**: [TBD]
- **DevOps**: [TBD]
- **QA**: [TBD]

### Documentation
- Main: [AGENT_IMPLEMENTATION_PHASES.md](./AGENT_IMPLEMENTATION_PHASES.md)
- Decisions: [AGENT_ARCHITECTURE_DECISIONS.md](./AGENT_ARCHITECTURE_DECISIONS.md)
- Specs: [AGENT_TECHNICAL_SPECIFICATION.md](./AGENT_TECHNICAL_SPECIFICATION.md)

### Resources
- [LangChain Docs](https://docs.langchain.com)
- [FastAPI Docs](https://fastapi.tiangolo.com)
- [MCP Spec](https://modelcontextprotocol.io)
- [Riverpod Guide](https://riverpod.dev)

---

## FAQ

**Q: Why Plan-Execute and not ReAct?**  
A: Plan-Execute is more efficient (fewer LLM calls), better progress tracking, and deterministic.

**Q: How do I add a new agent capability?**  
A: Create a new Tool class, register it in ToolRegistry. Agent discovers it automatically.

**Q: What if a tool fails during execution?**  
A: Agent catches error, logs it, skips step, continues with remaining steps.

**Q: Can I use the system offline?**  
A: Yes! Local tasks execute on mobile without network. Remote tasks need desktop connection.

**Q: How do I test my tool?**  
A: Write unit test that mocks tool.execute(), integration test with real tool.

**Q: What's the max task execution time?**  
A: 5 minutes total (300s) per task by default. Configurable in PlanExecuteAgent.

---

**Document Status**: Ready for Implementation  
**Last Updated**: November 2, 2025  
**Next Review**: November 7, 2025 (end of Phase 0)

