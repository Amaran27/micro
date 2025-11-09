# Swarm Streaming & HIL (Human-in-the-Loop) Plan

This document outlines a lightweight, event-driven streaming architecture for the Swarm Orchestrator, enabling real-time UI updates, human approvals at key checkpoints, and token-efficient operation.

## Goals
- Real-time visibility of swarm phases (routing, planning, specialist execution, evaluation)
- Optional human approvals: pause → ask → resume at safe points
- Preserve token efficiency (avoid redundant model calls)
- Backward-compatible with current non-streaming flow

## Event Model

Introduce a `SwarmEvent` sealed class (or union types) emitted during execution:
- RoutingStarted, RoutingCompleted
- ClarificationNeeded(questions, reason)
- PlanningStarted, PlanningCompleted(teamSize)
- SpecialistStarted(id, role)
- TokenChunk(id, role, text) [optional if adapters support streaming]
- SpecialistCompleted(id, role, factsWritten, durationMs)
- EvaluationStarted, EvaluationCompleted(approved, feedback)
- SwarmCompleted(converged, totals)
- ErrorOccurred(context, message)

Transport options:
- Dart Stream<SwarmEvent> from Orchestrator to AgentService to UI
- Maintain current `SWARM_METRIC` logs for text-based observability

## API Sketch

```dart
class SwarmOrchestrator {
  Stream<SwarmEvent> executeStream(String goal, {...});
}

sealed class SwarmEvent { ... }
```

The existing `execute(...)` remains as a convenience method that internally collects events and returns a final `SwarmResult`.

## Human-in-the-Loop (HIL)

- Clarification checkpoint: emit ClarificationNeeded; orchestrator pauses until UI supplies answers or user cancels.
- Optional Specialist-level approvals: emit ProposedAction(role, planSummary) → wait for Approve/Reject.
- Resume semantics: orchestrator maintains coroutine state; on resume injects user responses into blackboard.

## UI Integration (flutter_gen_ai_chat_ui)

- Map events to incremental messages/indicators:
  - Show planning spinner; update with team size
  - For ClarificationNeeded: render questions as a prompt with quick-reply inputs
  - SpecialistStarted/Completed: timeline chips
  - TokenChunk: live text stream (when adapter supports)
  - EvaluationCompleted: final badge (approved/rejected)

## Token Efficiency

- Event emissions are metadata-only; no extra LLM calls except:
  - Clarification detector (already implemented, compact prompt)
  - Optional evaluator (already compact)
- For streaming model support, use provider adapters' streaming APIs to avoid double calls.

## Phased Rollout

1. Event stream without HIL: emit phase markers, durations, and per-specialist updates.
2. Clarification HIL: wire ClarificationNeeded → UI prompt → resume.
3. Token streaming: plumb provider `sendMessageStream` into specialist execution.
4. Approval gates for high-risk actions (filesystem/network tools).

## Telemetry

- Continue `SWARM_METRIC` lines with structured key=value pairs
- Add counters: specialists_started, specialists_failed, evaluation_approved
- Emit correlation IDs for goal runs for cross-log aggregation

## Safety Considerations

- Approval gates before executing side-effecting tools
- Prompt injection mitigations (tool descriptions sanitized; goal/blackboard scoped)
- Network and filesystem sandboxing (future)

## Backward Compatibility

- `execute()` uses the same code path but collects events internally
- No breaking changes to AgentService or ChatProvider until streaming UI is adopted
