# Dig Deeper Diagnostic Guide

## Current Issue

**Symptoms**:
- Dig Deeper tab shows static "Generating questions..." message (no spinner)
- Questions never appear
- Pull-to-refresh not working

**What This Means**:
The view is rendering `noQuestionsYetState` which expects `.onAppear` to trigger question generation, but generation is NOT starting.

---

## Step-by-Step Diagnostic

### Test 1: Check Console Logs on First Load

**Steps**:
1. **Clean build** the app (Cmd+Shift+K, then Cmd+B)
2. **Open Xcode console** (Cmd+Shift+Y to show debug area)
3. **Filter console** for "generation", "questions", or "fetchQuestions"
4. **Launch app** in simulator
5. **Navigate to Journal tab** (should be default)
6. **Wait 2 seconds**, note any logs
7. **Swipe to Dig Deeper tab**
8. **Wait 5 seconds**, note any logs

**Expected Logs** (if working):
```
📥 fetchQuestions() called
   📊 Fetched 0 questions
   ✅ Completed: 0/0
📊 Total completed questions: 0 (first-time user)
✅ fetchQuestions() completed

🆕 Auto-generating INITIAL questions from 1 most recent entry (first-time user)
🆕 Generating INITIAL questions from 1 most recent entries
✅ Generated 3 INITIAL questions
📊 Analyzed 1 entries (from 1 most recent)
🎯 Found X themes
📥 fetchQuestions() called
   📊 Fetched 3 questions
   ✅ Completed: 0/3
✅ fetchQuestions() completed
```

**What to Look For**:
- ❌ Do you see "🆕 Auto-generating INITIAL questions"?
  - NO → `.onAppear` not firing or conditions failing
  - YES → Check if generation completes
- ❌ Do you see any error messages "❌ Error generating questions"?
  - YES → Edge function is failing (network/auth issue)
- ❌ Do you see "⏸️ Skip generation" messages?
  - YES → Conditions are blocking generation

---

### Test 2: Check Auto-Generation Conditions

Add temporary debug logging to understand WHY generation isn't starting.

**File to modify**: `DigDeeperView.swift` (line 80-93)

**Add debug prints**:
```swift
private func autoGenerateQuestionsIfNeeded() {
    // DEBUG: Print all conditions
    print("🔍 DEBUG: Checking auto-generation conditions:")
    print("   - entries.isEmpty: \(entryViewModel.entries.isEmpty) (need FALSE)")
    print("   - currentWeekQuestions.isEmpty: \(questionsViewModel.currentWeekQuestions.isEmpty) (need TRUE)")
    print("   - isLoading: \(questionsViewModel.isLoading) (need FALSE)")
    print("   - isRefreshing: \(questionsViewModel.isRefreshing) (need FALSE)")
    print("   - hasAttemptedGeneration: \(hasAttemptedGeneration) (need FALSE)")

    // Only auto-generate if:
    guard !entryViewModel.entries.isEmpty,
          questionsViewModel.currentWeekQuestions.isEmpty,
          !questionsViewModel.isLoading,
          !questionsViewModel.isRefreshing,
          !hasAttemptedGeneration
    else {
        print("❌ AUTO-GENERATION BLOCKED - conditions not met")
        return
    }

    print("✅ AUTO-GENERATION CONDITIONS MET - proceeding...")
    hasAttemptedGeneration = true

    // ... rest of function
}
```

**Re-run Test 1** and check what prints.

---

### Test 3: Check Pull-to-Refresh

**Steps**:
1. Go to Dig Deeper tab (showing static "Generating questions...")
2. **Pull down** on the screen to trigger refresh
3. **Watch console** for logs

**Expected Logs** (if working):
```
🔄 Pull-to-refresh: Generating INITIAL questions from 1 most recent entry (first-time user)
🆕 Generating INITIAL questions from 1 most recent entries
✅ Generated 3 INITIAL questions
```

**What to Look For**:
- ❌ Do you see "🔄 Pull-to-refresh" log?
  - NO → `.refreshable` modifier not triggering (UI issue)
  - YES → Check if generation completes
- ❌ Do you see generation error "❌ Error generating questions"?
  - YES → Edge function failing (likely network/auth)

---

### Test 4: Check Background Generation After Entry Creation

**Steps**:
1. Create a new journal entry with meaningful text
2. Save the entry
3. **Watch console immediately** for generation logs
4. Wait 5 seconds

**Expected Logs** (if working):
```
✅ Saved entry to Supabase: <UUID>
🔄 Background generation requested
⏸️ Not enough new entries - need 2+, have 1
```

Then create a second entry:

**Expected Logs**:
```
✅ Saved entry to Supabase: <UUID>
🔄 Background generation requested
✅ Generation threshold met - 2 new entries
🚀 BACKGROUND GENERATION STARTED
   Strategy: First-time user (1 most recent entry)
   ✅ Generated 3 questions
📝 Generation recorded
✅ BACKGROUND GENERATION COMPLETE - Questions ready!
```

---

## Common Issues and Fixes

### Issue 1: `.onAppear` Not Firing
**Symptom**: No "🔍 DEBUG" or "🆕 Auto-generating" logs

**Possible Causes**:
- TabView with `.page` style might have lazy loading issues
- View lifecycle timing problem

**Fix**: Change auto-generation to trigger in `onAppear` with explicit Task:
```swift
.onAppear {
    print("🔴 DigDeeperView .onAppear fired")
    questionsViewModel.markQuestionsAsSeen()

    Task {
        print("🔴 Checking auto-generation...")
        autoGenerateQuestionsIfNeeded()
    }

    // ... rest of onAppear
}
```

---

### Issue 2: `totalCompletedCount` Not Initialized
**Symptom**: Generation logic chooses wrong strategy

**Check**: Add debug in DigDeeperView line 98:
```swift
let isFirstTimeUser = questionsViewModel.totalCompletedCount == 0
print("🔍 DEBUG: isFirstTimeUser = \(isFirstTimeUser), totalCompletedCount = \(questionsViewModel.totalCompletedCount)")
```

**Fix**: Ensure `fetchTotalCompletedCount()` is called before any generation

---

### Issue 3: Edge Function Not Deployed
**Symptom**: "❌ Error generating questions" with network/404 error

**Check**:
```bash
supabase functions list
# Should show: generate-follow-up
```

**Fix**:
```bash
cd supabase
supabase functions deploy generate-follow-up
```

---

### Issue 4: Authentication Issue
**Symptom**: "❌ Error generating questions: User not authenticated"

**Check**: Verify user is logged in:
```swift
print("🔍 DEBUG: Current user = \(await SupabaseService.shared.getCurrentUser()?.email ?? "NONE")")
```

**Fix**: Ensure user completes onboarding before accessing Dig Deeper

---

### Issue 5: Race Condition with `fetchQuestions()`
**Symptom**: `isLoading` or `isRefreshing` is TRUE when `.onAppear` fires

**Check**: Add timing logs in JournalView line 62:
```swift
await entryViewModel.loadEntriesIfNeeded()
print("🔴 Entries loaded: \(entryViewModel.entries.count)")

if !entryViewModel.entries.isEmpty {
    print("🔴 Calling fetchQuestions...")
    await questionsViewModel.fetchQuestions()
    print("🔴 fetchQuestions completed, isLoading=\(questionsViewModel.isLoading)")
}
```

**Fix**: Remove pre-fetch from JournalView, let DigDeeperView handle it:
```swift
// REMOVE this from JournalView:
// if !entryViewModel.entries.isEmpty {
//     await questionsViewModel.fetchQuestions()
// }
```

---

## Next Steps

1. **Run Test 1** and copy all console logs
2. **Run Test 2** with debug prints
3. **Share the logs** so we can identify the exact issue
4. Based on logs, apply one of the fixes above

---

## Quick Fix Attempt

If you want to try a potential fix immediately, try this:

**File**: `DigDeeperView.swift` (line 53-67)

**Replace** `.onAppear` block with:
```swift
.onAppear {
    print("🔴 DigDeeperView .onAppear fired")

    // Mark questions as seen
    questionsViewModel.markQuestionsAsSeen()

    // Force generation check in Task (ensures async context)
    Task {
        // Small delay to ensure view model state is settled
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        print("🔴 Checking auto-generation conditions...")
        autoGenerateQuestionsIfNeeded()

        // Refresh questions if they exist
        if !questionsViewModel.currentWeekQuestions.isEmpty && !entryViewModel.entries.isEmpty {
            await refreshQuestionsIfNeeded()
        }
    }
}
```

Then rebuild and test.
