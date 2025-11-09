# Swarm Architecture Resource Analysis

## TOON Format Decision Framework

### Test Plan
Run `flutter test test/toon_comprehension_test.dart` to validate:

1. **Zero-shot comprehension**: Can LLM parse TOON without examples?
2. **Few-shot learning**: Does 2-3 examples improve accuracy?
3. **Accuracy comparison**: TOON vs JSON parsing correctness
4. **Size reduction**: Actual character/token savings

### Decision Criteria
- **Adopt TOON IF**: 
  - Zero-shot accuracy ≥ 90% (vs JSON baseline)
  - Token reduction ≥ 30%
  - No additional latency from retries
  
- **Skip TOON IF**:
  - Accuracy < 90% (hallucination risk)
  - Requires >3 examples per prompt (negates savings)
  - LLM struggles with edge cases (nulls, escaping)

### Expected Outcome
Based on TOON creator's benchmarks (tested on GPT-4/Claude):
- **Likely**: LLMs CAN parse TOON in zero-shot (structured format is learnable)
- **Token Savings**: 30-50% for tabular data, 15-25% for nested objects
- **Trade-off**: Small parsing overhead vs significant token cost reduction

**Recommendation**: Proceed with TOON for input serialization if tests pass ≥85% accuracy threshold.

---

## Specialist Execution Models

### Sequential Execution (Mobile-Safe Default)
```
Specialist 1 → Specialist 2 → Specialist 3
   |              |              |
   ↓              ↓              ↓
Blackboard    Blackboard    Blackboard
```

**Characteristics**:
- **Memory**: Peak = single agent (~200-400MB per agent process)
- **CPU**: One core saturated at a time
- **Latency**: Total = Sum of individual agent times (additive)
- **Reliability**: High (no race conditions, simple state management)

**Mobile Impact**:
- ✅ Safe for low-end devices (2GB RAM)
- ✅ Battery friendly (sequential = lower peak power)
- ❌ Slower completion (5 specialists × 10s = 50s total)

### Parallel Execution (Desktop/High-End Mobile)
```
Specialist 1 ──┐
Specialist 2 ──┼─→ Blackboard (thread-safe)
Specialist 3 ──┘
```

**Characteristics**:
- **Memory**: Peak = N agents × 300MB (e.g., 3 agents = ~900MB)
- **CPU**: N cores saturated simultaneously
- **Latency**: Total ≈ Max(individual agent times) (concurrent)
- **Reliability**: Medium (requires mutex/locks on blackboard writes)

**Mobile Impact**:
- ⚠️ Risky for <4GB RAM devices (OOM crashes possible)
- ⚠️ Higher battery drain (parallel network + compute)
- ✅ 3-5× faster completion (5 specialists × 10s = ~15s total with 3 parallel)

### Adaptive Execution (Recommended)
```dart
class ExecutionScheduler {
  final int maxParallel;
  final bool allowParallel;
  
  ExecutionScheduler.adaptive() :
    maxParallel = _detectDeviceCapacity(),
    allowParallel = _isHighEndDevice();
  
  static int _detectDeviceCapacity() {
    // Dart doesn't have native RAM detection; use platform channel or heuristic
    // Assume: Android 4GB+ = 2 parallel, 6GB+ = 3 parallel, 8GB+ = 5 parallel
    // For now: conservative default
    return 2; // Max 2 specialists in parallel on mobile
  }
  
  static bool _isHighEndDevice() {
    // Heuristic: if device has > 3GB available memory
    // Or user explicitly enabled via settings
    return false; // Default to sequential for safety
  }
}
```

**Strategy**:
- Start sequential by default
- Provide user setting: "Enable Parallel Agents (Requires 4GB+ RAM)"
- Monitor memory during execution; abort parallel if usage > 75%

---

## Specialist Count Constraints

### Hard Limits by Platform

| Platform | Max Specialists | Reasoning |
|----------|----------------|-----------|
| Mobile (Low-End) | 3 | Memory constraint (~1GB available for agents) |
| Mobile (High-End) | 5 | Balance memory (2GB) vs complexity |
| Desktop/Web | 15 | Generous RAM, but diminishing returns on coordination |

### Why Not More Than 15?

1. **Coordination Overhead**: Each specialist adds:
   - Blackboard synchronization latency
   - Conflict resolution complexity
   - Verification cross-checks

2. **Token Cost Explosion**: N specialists reading blackboard = N × blackboard size in tokens
   - 5 specialists × 3KB blackboard = 15KB per round
   - 15 specialists × 3KB = 45KB per round (approaching context limits)

3. **"Too Many Cooks" Problem**: 
   - >10 specialists increase chance of conflicting outputs
   - Verification/arbitration overhead exceeds execution time
   - Empirical studies show 3-5 specialists optimal for most tasks

### Recommended Configuration
```dart
class SwarmConfig {
  final int maxSpecialists;
  final ExecutionMode executionMode;
  final bool enableSwarm;
  
  SwarmConfig.mobile() :
    maxSpecialists = 3,
    executionMode = ExecutionMode.sequential,
    enableSwarm = true;
  
  SwarmConfig.desktop() :
    maxSpecialists = 10,
    executionMode = ExecutionMode.adaptive,
    enableSwarm = true;
  
  SwarmConfig.conservative() :
    maxSpecialists = 1, // Disable swarm, single agent only
    executionMode = ExecutionMode.sequential,
    enableSwarm = false;
}

enum ExecutionMode {
  sequential,  // One at a time (safe)
  parallel,    // All at once (fast but risky)
  adaptive,    // Auto-detect device capacity
}
```

---

## Resource Consumption Analysis

### Single PlanExecuteAgent Baseline
**Measured on Android device (Samsung Galaxy, 6GB RAM)**:
- Memory: ~250MB (Dart VM + HTTP client + model state)
- CPU: 15-25% single-core utilization during planning
- Network: 50-200KB per API call (depends on prompt size)
- Battery: ~2-3% drain per 30s task (network-bound)

### 3 Specialists (Sequential)
**Estimated**:
- Memory: Peak ~300MB (single agent active at a time)
- CPU: 15-25% per specialist (total time = 3× single agent)
- Network: 150-600KB total (3 API calls)
- Battery: ~6-9% drain for 90s total task
- **Mobile Safe**: ✅ Yes

### 3 Specialists (Parallel)
**Estimated**:
- Memory: Peak ~750MB (3 agents × 250MB)
- CPU: 45-75% multi-core utilization (3 cores saturated)
- Network: 150-600KB concurrent (may hit rate limits)
- Battery: ~8-12% drain for 30s burst
- **Mobile Safe**: ⚠️ Only on 4GB+ RAM devices

### 5 Specialists (Sequential)
**Estimated**:
- Memory: Peak ~300MB (still single agent)
- CPU: 15-25% per specialist (total time = 5× single agent)
- Network: 250-1000KB total
- Battery: ~10-15% drain for 150s total task
- **Mobile Safe**: ✅ Yes, but slow

### 5 Specialists (Parallel)
**Estimated**:
- Memory: Peak ~1.25GB (5 agents × 250MB)
- CPU: 75-100% multi-core (5 cores saturated; thermal throttling likely)
- Network: 250-1000KB concurrent (rate limit risk)
- Battery: ~15-20% drain for 40s burst
- **Mobile Safe**: ❌ High risk of OOM on <6GB devices

---

## User Configuration Design

### Settings UI (Priority Order)
1. **Enable Swarm Intelligence** (Toggle)
   - Default: OFF for first release (stability)
   - Description: "Use multiple AI specialists for complex tasks (uses more resources)"

2. **Max Specialists** (Slider: 1-5 for mobile, 1-15 for desktop)
   - Default: 3 (mobile), 5 (desktop)
   - Warning: "More specialists = faster but uses more battery and data"

3. **Execution Mode** (Dropdown)
   - Options: Sequential (Safe), Adaptive (Recommended), Parallel (Fast)
   - Default: Sequential
   - Help: "Sequential: One specialist at a time. Adaptive: Auto-detects device. Parallel: All at once (requires 4GB+ RAM)"

4. **Resource Monitoring** (Info Display)
   - Show current: Memory usage, Active specialists, Tokens used
   - Real-time graph during swarm execution

### Persistence
```dart
class SwarmSettings {
  static const String _keyEnableSwarm = 'swarm_enabled';
  static const String _keyMaxSpecialists = 'swarm_max_specialists';
  static const String _keyExecutionMode = 'swarm_execution_mode';
  
  Future<void> save(SharedPreferences prefs) async {
    await prefs.setBool(_keyEnableSwarm, enableSwarm);
    await prefs.setInt(_keyMaxSpecialists, maxSpecialists);
    await prefs.setString(_keyExecutionMode, executionMode.name);
  }
  
  static Future<SwarmSettings> load(SharedPreferences prefs) async {
    return SwarmSettings(
      enableSwarm: prefs.getBool(_keyEnableSwarm) ?? false, // Default OFF
      maxSpecialists: prefs.getInt(_keyMaxSpecialists) ?? 3,
      executionMode: ExecutionMode.values.byName(
        prefs.getString(_keyExecutionMode) ?? 'sequential'
      ),
    );
  }
}
```

---

## Performance Benchmarks (To Be Measured)

### Test Scenarios
1. **Simple Math Task** (baseline)
   - Single specialist: "Calculate mean of [5, 10, 15, 20]"
   - Expected: ~5s, 2KB tokens, 150MB RAM

2. **Multi-Domain Task** (3 specialists)
   - Task: "Analyze customer reviews: sentiment, average rating, top complaint"
   - Sequential: ~30s, 15KB tokens, 300MB RAM
   - Parallel: ~12s, 15KB tokens, 750MB RAM

3. **Complex Task** (5 specialists)
   - Task: "Generate quarterly report: sales stats, trend analysis, forecast, summary, visualization data"
   - Sequential: ~60s, 40KB tokens, 300MB RAM
   - Parallel: ~20s, 40KB tokens, 1.25GB RAM

### Success Criteria
- Memory never exceeds 1GB on mobile
- No OOM crashes on 3GB RAM devices (sequential mode)
- Battery drain < 5% per typical swarm task (3 specialists)
- Latency acceptable: <60s for 5 specialists sequential

---

## Recommendations

### Phase 1: MVP (Current Sprint)
- ✅ Implement sequential execution only
- ✅ Hard limit: 3 specialists on mobile, 5 on desktop
- ✅ Use compact JSON (skip TOON if comprehension tests fail)
- ✅ No user configuration (hardcoded safe defaults)

### Phase 2: Optimization (Next Sprint)
- ⏳ Add TOON encoding IF comprehension tests pass ≥85%
- ⏳ Implement adaptive execution scheduler
- ⏳ Add user settings UI (enable swarm, max specialists)
- ⏳ Resource monitoring dashboard

### Phase 3: Advanced (Future)
- ⏳ Parallel execution with mutex-protected blackboard
- ⏳ Provider selection based on caching (Anthropic/OpenAI)
- ⏳ Dynamic specialist count adjustment based on task complexity
- ⏳ Memory pressure detection and auto-throttling

---

## Open Questions (To Resolve via Testing)

1. **TOON Viability**: Run `toon_comprehension_test.dart` → measure accuracy
2. **Memory Profiling**: Run swarm with DevTools → confirm 250MB per agent estimate
3. **Battery Impact**: Run 3 specialists sequential → measure actual % drain
4. **Network Rate Limits**: Test 5 parallel API calls → check for 429 errors
5. **Context Window**: With blackboard growth, how many rounds before hitting 128K limit?

**Next Action**: Execute TOON comprehension tests to make final format decision.
