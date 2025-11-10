# Quick Reference: Agent Frameworks for Micro

## TL;DR Recommendation

**For your Flutter chat app seeking a desktop agent:**

```
🏆 PRIMARY: LangChain (Python) + MCP
🥈 ALTERNATIVE: Roo Code (VS Code extension)
❌ AVOID: Kilo Code (abandoned), OpenAI Codex (commercial)
```

---

## One-Sentence Summary

| Framework | Summary |
|-----------|---------|
| **Roo Code** | VS Code extension with autonomous AI agents in 5 specialized modes |
| **Kilo Code** | Abandoned fork of Roo Code - not recommended |
| **MCP** | Open standard for AI ↔ system communication (like USB-C for AI) |
| **LangChain** | Python framework for building complex multi-step agent workflows with tools |
| **OpenAI Codex** | Commercial hosted code execution API - not open source |

---

## Recommended Stack for Micro

### MVP (Phase 1: 2-3 weeks)
```
Flutter Mobile App
    ↓ HTTP REST
Desktop Backend (Python)
    ├─ FastAPI (web framework)
    └─ LangChain (agent logic)
        ├─ Tools: File ops, code generation
        └─ LLM: Claude/GPT/ZhipuAI
```

### Production (Phase 2: 4-6 weeks)
```
Flutter Mobile App
    ↓ WebSocket + HTTP
Desktop Backend (Python)
    ├─ FastAPI (web framework)
    ├─ MCP Server (standardized protocol)
    └─ LangChain Agent
        ├─ Tools with MCP discovery
        └─ Streaming responses
```

---

## Decision Matrix

### Which framework for YOUR use case?

**Q1: Do you want to integrate existing coding tools (Git, LSP, etc.)?**
- YES → **Roo Code** (already integrates many)
- NO → **LangChain** (build what you need)

**Q2: Do you want maximum customization of agent logic?**
- YES → **LangChain** (full control)
- NO → **Roo Code** (predefined modes)

**Q3: Do you want to run on desktop without VS Code?**
- YES → **LangChain** (standalone backend)
- MAYBE → **Roo Code** (requires VS Code)

**Q4: Do you want multi-agent interoperability?**
- YES → **MCP** (standardized protocol)
- NO → Custom REST API is fine

### Your Answers → Recommendation
- Customization + Multi-agent + Open-source → **LangChain + MCP** ✅
- Quick integration + Mode-based → **Roo Code** ⚠️
- Code execution verification → **Code Interpreter** (supplementary only)

---

## Integration Effort Comparison

| Aspect | Roo Code | LangChain | MCP |
|--------|----------|-----------|-----|
| **Setup Time** | 1-2 hours (if VS Code available) | 4-6 hours | 2-3 hours |
| **Learning Curve** | Medium (understanding modes) | High (agent concepts) | Low (JSON-RPC) |
| **Dependencies** | VS Code extension | Python 3.8+, pip packages | Minimal, language-agnostic |
| **Mobile Integration Effort** | High (Roomote Control complex) | Low (simple REST API) | Medium (HTTP + MCP) |
| **Customization Effort** | Medium (mode system) | Low (just write code) | Low (define tools) |

---

## Technology Stack Decision

### Language
| Consideration | Language | Why |
|---------------|----------|-----|
| **Existing code** | Python | LangChain ecosystem, mature |
| **Performance** | Rust/Go | More scalable, not needed for MVP |
| **Simplicity** | Python | Fastest to prototype |

**Decision**: Python (FastAPI backend)

### API Protocol
| Use Case | Protocol | Why |
|----------|----------|-----|
| **Simple requests** | REST HTTP | Mobile app familiarity |
| **Real-time streaming** | WebSocket | Low latency token updates |
| **Tool discovery** | MCP | Standardized, future-proof |

**Decision**: REST (Phase 1) → REST + WebSocket (Phase 2) → Add MCP layer (Phase 3)

### Licensing
| Framework | License | Commercial OK? |
|-----------|---------|-----------------|
| LangChain | MIT | ✅ Yes |
| MCP | MIT/Apache 2.0 | ✅ Yes |
| Roo Code | Apache 2.0 | ✅ Yes |
| FastAPI | MIT | ✅ Yes |
| OpenAI Codex | Proprietary | ⚠️ Vendor lock-in |

**Decision**: MIT/Apache 2.0 only (zero vendor lock-in)

---

## Key Implementation Patterns

### Pattern 1: Tool Definition (LangChain)
```python
from langchain.tools import tool

@tool
def generate_flutter_code(prompt: str) -> str:
    """Generate Flutter widget code from description."""
    # Call LLM with Flutter-specific prompt
    return llm.invoke(f"Generate Flutter code: {prompt}")

# Register tool with agent
agent.tools.append(generate_flutter_code)
```

### Pattern 2: MCP Server (Exposing tools)
```typescript
// Desktop MCP server
class MicroAgentServer implements MCPServer {
  resources = {
    "project://flutter" → Project structure
    "tool://analyze" → Run flutter analyze
  };
  
  tools = {
    "generate_code" → LLM-powered code generation
    "run_tests" → Execute tests
  };
}
```

### Pattern 3: Mobile Integration (Dart)
```dart
// Flutter mobile app
final response = await http.post(
  Uri.parse('http://localhost:8000/agent/task'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'task': 'refactor_widget', 'code': selectedCode}),
);
```

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| MCP protocol instability | Low | High | Start with REST, add MCP later |
| LangChain API changes | Low | Medium | Pin versions, monitor updates |
| Desktop ↔ Mobile latency | Medium | Medium | Use WebSocket + caching |
| LLM cost overruns | Medium | High | Implement rate limiting, cost tracking |
| Offline capability gap | High | Low | Graceful fallback to mobile-only |

---

## Success Criteria (Phase 1)

- [ ] Desktop agent generates valid Dart/Flutter code
- [ ] Mobile app receives code in < 2 seconds
- [ ] Agent can refactor existing code with > 80% correctness
- [ ] Works offline (cached models) or with multiple LLM providers
- [ ] Zero proprietary dependencies
- [ ] Extensible tool system (easy to add new tasks)

---

## Next Steps

1. **Week 1**: Set up LangChain + FastAPI backend locally
2. **Week 2**: Implement Flutter code generation + refactoring tools
3. **Week 3**: Integrate REST API endpoint with mobile app
4. **Week 4+**: Add WebSocket streaming, MCP layer, production features

**Effort Estimate**: 80-120 hours to production MVP

---

## References

- **MCP Spec**: https://modelcontextprotocol.io
- **LangChain Docs**: https://docs.langchain.com/oss/python/langchain
- **FastAPI**: https://fastapi.tiangolo.com
- **Roo Code**: https://github.com/RooCodeInc/Roo-Code

---

**Last Updated**: November 1, 2025
