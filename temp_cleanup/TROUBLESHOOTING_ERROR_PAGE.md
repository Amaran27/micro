# Troubleshooting: "Error Occurred" Page

## Problem
You see "Error occurred" page on Android app startup or when navigating.

## Root Causes & Solutions

### Issue #1: No API Key Configured (Most Common)

**Symptoms**:
- "Error occurred" on startup
- Chat tab shows error
- Settings page shows "No provider"

**Fix**:
```
1. Get free API key:
   - Z.AI (glm-4.5-flash model free):
     → Go to https://z.ai
     → Sign up (no credit card needed)
     → Copy API key from dashboard
   
   OR
   
   - OpenAI:
     → Go to https://platform.openai.com/account/api-keys
     → Create new key
     → Note: Requires credit card

2. Add to app:
   ✅ Open app
   ✅ Tap Settings ⚙️ icon at bottom
   ✅ Tap "Providers" or "AI Providers"
   ✅ Select "Z.AI" or your provider
   ✅ Paste API key in text field
   ✅ Tap Save
   ✅ Return to Chat 💬 tab
   ✅ Type message and send

3. Verify:
   ✅ Message sends
   ✅ Response appears within 5 seconds
   ✅ No error message
```

---

### Issue #2: Invalid API Key Format

**Symptoms**:
- "Invalid API key" error message
- "Authentication failed" after sending message
- "401 Unauthorized" in logs

**Fix**:
```
1. Double-check key format:
   ✅ No spaces at start/end
   ✅ Full key copied (not truncated)
   ✅ Key is still active in provider account
   ✅ Not expired or revoked

2. Verify key works:
   - Z.AI: Use their web chat first
   - OpenAI: Use their ChatGPT UI first
   - If works there → copy key again carefully

3. Update in app:
   ✅ Settings → Providers
   ✅ Clear current key (select all, delete)
   ✅ Paste fresh copy
   ✅ Save and retry
```

---

### Issue #3: Network Error

**Symptoms**:
- "Connection timeout"
- "Network unreachable"
- "Failed to connect to provider"
- Happens after 10+ seconds of waiting

**Fix**:
```
1. Check connectivity:
   ✅ Phone has WiFi enabled
   ✅ WiFi shows connected (not just available)
   ✅ Can access websites in browser
   ✅ No VPN blocking provider

2. Restart connection:
   ✅ Disable WiFi → Enable WiFi → Retry
   ✅ Disable Bluetooth → Retry
   ✅ Airplane mode OFF → Retry

3. Verify provider is online:
   ✅ Visit provider website in browser first
   ✅ If website loads → provider is up
   ✅ If not → provider might be down

4. Try different network:
   ✅ Switch to cellular data (use hotspot from computer)
   ✅ Use different WiFi network
```

---

### Issue #4: Model Selection Error

**Symptoms**:
- "Model not found"
- "Selected model unavailable"
- Error after changing model

**Fix**:
```
1. Reset to default model:
   ✅ Settings → Providers → [Your Provider]
   ✅ Tap "Reset to Default"
   ✅ Select "glm-4.5-flash" (Z.AI) or "gpt-3.5-turbo" (OpenAI)
   ✅ Save

2. Verify model exists:
   ✅ Login to provider website
   ✅ Check available models in your account
   ✅ Check account tier (some models need paid plan)
   ✅ Ensure model hasn't been deprecated

3. Return to app:
   ✅ Close and reopen Chat tab
   ✅ Send test message
```

---

### Issue #5: Provider Service Down

**Symptoms**:
- All requests fail (even with working key)
- Error persists across network changes
- Status page shows incident

**Fix**:
```
1. Check provider status:
   - Z.AI: https://status.z.ai (if available)
   - OpenAI: https://status.openai.com
   - Google: https://status.cloud.google.com

2. If service is down:
   ✅ Wait for provider to recover
   ✅ Check status page for ETA

3. If status page says OK but still failing:
   ✅ Clear app cache:
     - Settings → Apps → [Micro] → Storage → Clear Cache
     - DON'T Clear Data (that deletes settings)
   ✅ Restart app
```

---

### Issue #6: App Bug/Crash

**Symptoms**:
- Red error page with stack trace
- Crash/close happens unexpectedly
- Same error every time

**Fix**:
```
1. Capture error details:
   ✅ Take screenshot of error
   ✅ Note exact error message
   ✅ Note what you were doing

2. View detailed logs:
   ✅ Connect Android phone via USB
   ✅ Open terminal/cmd where Flutter is installed
   ✅ Run: flutter logs
   ✅ Wait for error
   ✅ Screenshot the ERROR line(s)

3. Report with:
   - Error screenshot
   - Log screenshot
   - Steps to reproduce
   - Device: [Model, Android version]
```

---

## Debug Logging

### View App Logs

**Option A: Simple (Android Studio)**
```
1. Connect phone via USB
2. Open Android Studio
3. View → Tool Windows → Logcat
4. Select your device
5. Search for "ERROR" or "Exception"
```

**Option B: Terminal**
```bash
# Connect phone, then:
flutter logs

# Or with filtering:
flutter logs | grep -i error
flutter logs | grep -i "micro\|chat\|provider"
```

**Option C: Device Logs**
```
1. Settings → Developer Options
2. Enable USB Debugging (if not already)
3. Connect to computer
4. Use Android Device Monitor or ADB Logcat
```

### What to Look For

```
🔴 ERROR patterns:
  "SocketException" → Network issue
  "401 Unauthorized" → API key wrong
  "404 Not Found" → Provider endpoint wrong
  "TimeoutException" → Connection too slow
  "JSON decode error" → Bad response format
  
🟠 WARNING patterns:
  "Null safety violation" → Code bug
  "Unhandled exception" → Crash coming
  
🟢 INFO patterns:
  "Provider initialized" → Working
  "Model selected" → Ready
```

---

## Common Error Messages & Meanings

| Error | Cause | Solution |
|-------|-------|----------|
| "Error occurred" (no detail) | Provider not set up | Add API key in Settings |
| "Connection refused" | Can't reach provider | Check internet, try different network |
| "401 Unauthorized" | Bad API key | Copy key again, verify format |
| "Connection timeout" | Too slow | Wait longer or check network |
| "Model not found" | Model doesn't exist | Select from available models list |
| "Rate limit exceeded" | Too many requests | Wait a few seconds, try again |
| "Invalid request" | Bad parameters | Update app to latest version |
| "Service unavailable" | Provider down | Check status page, wait |

---

## Quick Diagnostic Checklist

Copy this and fill it out:

```
[ ] Internet connection: ✅ WiFi / 🌐 Mobile / ❌ None
[ ] API key obtained: ✅ Yes / ❌ No
[ ] API key added to app: ✅ Yes / ❌ No
[ ] Key format verified: ✅ No spaces / ❌ Has spaces
[ ] Provider online: ✅ Yes / ❌ No
[ ] Model selected: ✅ [Model name] / ❌ None
[ ] Chat screen loading: ✅ Yes / ❌ Stuck/Error
[ ] Can type message: ✅ Yes / ❌ No
[ ] Message sends: ✅ Yes / ❌ Error: ___
[ ] Response appears: ✅ Yes / ❌ No

Error message (if any): _________________
```

---

## If All Else Fails

**Contact Support with**:
1. ✅ Filled checklist (above)
2. ✅ Screenshot of error
3. ✅ 5-10 lines from `flutter logs` showing ERROR
4. ✅ Your device model and Android version
5. ✅ Exact steps you took before error occurred

---

## Prevention Tips

```
✅ Always verify API key works:
   → Try it in provider's web interface first
   → Then copy to app

✅ Test basic chat before complex tasks:
   → "Hello" or "What time is it?" first
   → Complex tasks later

✅ Keep API key secure:
   → Never share in messages
   → Use strong passwords for provider account
   → Rotate keys periodically

✅ Monitor provider status:
   → Follow their status page
   → Check before reporting bugs
```

---

## Next Steps

1. **Try fixes above**
2. **If working**: Go to ANDROID_UI_TESTING_GUIDE.md for what to test
3. **If still error**: Run `flutter logs` and share output
4. **If logs show specific error**: Use error table above to fix

Need more help? Check:
- `ANDROID_APP_STATUS.md` - Overview of what works
- `PHASE_2_ROADMAP.md` - Future features
