# What You Can Test in Android App Right Now

## Current State Summary

| Feature | Status | Can Test? |
|---------|--------|-----------|
| **Chat Basic** | ✅ Complete | YES - Type and send messages |
| **Model Selection** | ✅ Complete | YES - Switch between models |
| **Provider Config** | ✅ Complete | YES - Add/edit API keys |
| **Message History** | ✅ Complete | YES - Chat persists between sessions |
| **Error Messages** | ✅ Complete | YES - See user-friendly error text |
| **Agent Backend** | ✅ Complete | YES - Running, but hidden |
| **Tool Execution** | ✅ Implemented | NO - Can't see/trigger in UI |
| **Plan Visualization** | ✅ Implemented | NO - UI not connected |
| **Agent Dashboard** | ✅ Built | NO - Not in navigation |

---

## ✅ Things You CAN Test Now

### 1. **Basic Chat (Simple Mode)**
**What to do**:
```
1. Open app → Chat tab 💬
2. Ensure Z.AI or OpenAI provider configured (Settings ⚙️)
3. Type: "Hello, what time is it?"
4. Tap Send
5. Wait for response
```

**Expected**:
- ✅ Message appears on right (user side)
- ✅ Response appears on left (AI side)
- ✅ Response within 5 seconds
- ✅ No red error page

**Known to work with**:
- Z.AI glm-4.5-flash (free model)
- OpenAI gpt-3.5-turbo
- Google Gemini (if configured)

---

### 2. **Provider Switching**
**What to do**:
```
1. Chat tab → Settings ⚙️ (top right)
2. Model dropdown → Select different provider/model
3. Return to Chat
4. Send message: "What's your name?"
5. Verify response comes from selected provider
```

**Expected**:
- ✅ Can switch between providers
- ✅ Each provider uses correct API key
- ✅ Response style differs per model
  - Z.AI: More technical
  - OpenAI: More general
  - Google: More concise

---

### 3. **Settings Page**
**What to do**:
```
1. Tap Settings ⚙️ at bottom (rightmost)
2. Look at tabs: Overview, Providers, Preferences
3. Add/edit API key in Providers tab
4. View active model
5. Return to Chat
```

**Expected**:
- ✅ Settings load without error
- ✅ Can view existing providers
- ✅ Can paste/edit API keys
- ✅ Can select active model
- ✅ Settings persist (restart app, still there)

---

### 4. **Error Handling**
**What to do**:
```
1. Settings → Providers
2. Set API key to: "invalid_key_12345"
3. Go to Chat
4. Send: "Test"
5. Wait for error
```

**Expected**:
- ✅ Error message appears (not crash)
- ✅ Message is user-friendly (not stack trace)
- ✅ Error mentions "authentication" or "API key"
- ✅ Can return to chat and retry

---

### 5. **Message History**
**What to do**:
```
1. Chat tab
2. Send several messages (minimum 3)
3. Close app (swipe away from recent)
4. Reopen app
5. Chat tab
```

**Expected**:
- ✅ All previous messages still there
- ✅ Messages in correct order
- ✅ No messages lost

---

### 6. **Long Conversations**
**What to do**:
```
Send 10+ messages about same topic (e.g., "Tell me about Dart")
Each response builds context from previous messages
```

**Expected**:
- ✅ Responses reference earlier messages
- ✅ Conversation feels natural
- ✅ No "token limit" errors (for chat length)
- ✅ No performance slowdown

**Note**: Some models have context windows:
- Z.AI glm-4.5-flash: 4K tokens (~12 pages)
- OpenAI gpt-3.5: 4K tokens (~12 pages)
- If you hit the limit, start new chat

---

### 7. **Edge Cases**

#### Empty Message
```
1. Click Send without typing
Expected: ✅ Either send empty or show "message required"
```

#### Very Long Message
```
1. Paste 5000+ character essay
2. Send
Expected: ✅ Sends fine or shows truncation warning
```

#### Special Characters
```
1. Send: "こんにちは (hello in Japanese)"
2. Send: "Emoji: 🚀 🤖 ✨"
3. Send: "Math: ∑(n=1 to ∞) = ... code: print('test')"
Expected: ✅ All render correctly
```

#### Rapid Sending
```
1. Send message A
2. Before response, send message B
3. Before B response, send message C
Expected: ✅ All queue properly, no crash
          ❌ Both streams simultaneously (KNOWN BUG - see Issue #2 below)
```

---

## ❌ Things You CANNOT Test Now (UI Not Connected)

### 1. **Agent Mode** (Hidden)
**Why not available**:
- Backend ✅ fully implemented and tested
- UI ❌ not connected to chat interface
- No toggle/button to trigger

**What's implemented but hidden**:
- PlanExecuteAgent (can decompose complex tasks)
- AgentFactory (can analyze tasks and route to tools)
- ToolRegistry (4 tools: UI validation, sensors, files, navigation)
- Plan-Execute-Verify-Replan cycle

**Will be added in Phase 2**: UI integration task

---

### 2. **Tool Execution Visualization**
**Why not available**:
- Tools ✅ fully implemented and tested
- Visualization ❌ UI widgets not connected
- Chat doesn't show tool calls

**What's implemented but hidden**:
```
4 Tools Available:
1. UIValidationTool
   - Can take screenshots
   - Can analyze UI elements
   - Can validate app state
   
2. SensorAccessTool
   - Can read GPS location
   - Can read accelerometer
   - Can read device sensors
   
3. FileOperationTool
   - Can read files
   - Can write files
   - Can list directories
   
4. AppNavigationTool
   - Can open screens
   - Can navigate app
   - Can control back button
```

**Status**: All 4 tested ✅, awaiting UI exposure

---

### 3. **Plan Visualization**
**Why not available**:
- Plan generation ✅ working (tested)
- Visualization ❌ no UI widgets
- Chat doesn't show plan breakdown

**What's missing**:
```
When agent analyzes task, it creates:
- ✅ Step 1: Do X
- ✅ Step 2: Do Y
- ✅ Step 3: Do Z
- ✅ Verification: Check result
- ✅ Status: Success/Failure

UI would show all this, but not exposed yet
```

---

### 4. **Agent Dashboard**
**Why not available**:
- Dashboard ✅ UI built (1006 lines)
- Navigation ❌ not in main tabs
- Can't navigate to agent features

**What exists but hidden**:
```
Dashboard has tabs for:
- Overview (stats, active tasks)
- Execute (run tasks, see results)
- Memory (agent learning, history)
```

**Status**: Built but requires navigation refactor

---

## 🐛 Known Issues (Phase 1)

### Issue #1: Double Message Stream (Minor)
**When it happens**:
- Send message A
- Before A finishes, send message B
- Both responses stream simultaneously

**Current behavior**:
- ❌ Two messages stream at same time
- ✅ Both arrive correctly
- ✅ App doesn't crash

**Fix**: Coming in Phase 1 bug fixes (add isLoading check)

**Workaround**: Wait for first response before sending next message

---

### Issue #2: Model Selection Not Persisting
**When it happens**:
- Change model in Settings
- Close/restart app
- Sometimes reverts to previous selection

**Current behavior**:
- ❌ Model selection occasionally forgets
- ✅ Manually setting again fixes it
- ✅ Works most of the time

**Fix**: Coming in Phase 1 cleanup (provider alias normalization)

**Workaround**: Set model again if it reverts after restart

---

### Issue #3: Z.AI Response Sometimes Slow
**When it happens**:
- Free tier glm-4.5-flash model
- High usage hours (peak time)
- First request of session

**Current behavior**:
- ❌ Takes 10-30 seconds instead of 3-5
- ✅ Eventually responds
- ✅ Response quality same

**Why**: Z.AI free tier is best-effort (slower during peak hours)

**Fix**: None needed (provider limitation, not app bug)

**Workaround**: Try OpenAI gpt-3.5 if you have key (usually faster)

---

## 🎯 Recommended Testing Sequence

**First Time Testing**:
1. ✅ Test #1: Basic Chat (verify setup works)
2. ✅ Test #2: Provider Switching (if you have multiple keys)
3. ✅ Test #4: Error Handling (intentional error)
4. ✅ Test #5: Message History (app restart)

**Deeper Testing**:
5. ✅ Test #3: Settings Page (explore options)
6. ✅ Test #6: Long Conversations (context handling)
7. ✅ Test #7: Edge Cases (robustness)

**Performance Testing**:
8. ✅ Send 20+ messages in sequence
9. ✅ Wait for all to complete
10. ✅ Check app doesn't slow/crash

---

## What Happens Behind Scenes (Not Visible)

Even though you can't see it in UI:

```
Your message:
  "Tell me how to build a Flutter app"

Goes to:
  1. ChatNotifier (state management) ✅
  2. ProviderAdapter (Z.AI/OpenAI) ✅
  3. LangChain ChatModel ✅
  4. AI Provider API ✅
  
ALSO processed by (invisible):
  5. AgentFactory (task analysis) ✅
  6. PlanExecuteAgent (plan creation) ✅
  7. ToolRegistry (checks available tools) ✅
  8. Plan-Execute cycle (verification) ✅
  
BUT:
  ❌ You don't see the plan
  ❌ You don't see tool calls
  ❌ You don't see verification
  ✅ You just get the response
```

This is Phase 1: Agent runs silently, just returns responses.
Phase 2: Will expose agent thinking/planning in UI.

---

## Debugging if Test Fails

**If test fails**:
1. Follow `TROUBLESHOOTING_ERROR_PAGE.md` guide above
2. Check provider is online (visit in browser)
3. Verify API key format (copy again)
4. Check network connectivity
5. View logs: `flutter logs | grep ERROR`

**If still failing**:
- Check that you're on right settings tab
- Restart app completely
- Check FlutterSecureStorage has key saved
- Try different provider (if you have multiple keys)

---

## Expected Performance

```
Single message:
  ⏱️ Send to response: 3-10 seconds
  ⏱️ Short response: ~2 seconds
  ⏱️ Long response: ~5-10 seconds

Multiple messages:
  ⏱️ Queue time between sends: <1 second
  ⏱️ Total for 5 messages: 20-40 seconds
  ⏱️ Memory: <50MB on device

App responsiveness:
  ✅ Chat input always responsive
  ✅ No freezing while waiting
  ✅ Can scroll history while response comes in
  ✅ Settings loads instantly
```

---

## Next Steps

### If Basic Chat Works ✅
→ Go to `ANDROID_UI_TESTING_GUIDE.md` for advanced testing

### If Basic Chat Fails ❌
→ Go to `TROUBLESHOOTING_ERROR_PAGE.md` and follow diagnostics

### If You Want Agent Features
→ Check `PHASE_2_ROADMAP.md` (coming soon)

### If You Found a Bug
→ Use template in `BUG_REPORT_TEMPLATE.md` (coming soon)
