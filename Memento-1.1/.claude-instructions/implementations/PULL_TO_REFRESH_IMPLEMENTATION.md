# Pull-to-Refresh for Question Regeneration

## Overview
Added pull-to-refresh functionality to the DigDeeperView that triggers the edge function to generate new follow-up questions based on recent journal entries.

## Changes Made

### 1. Updated Questions List View (`DigDeeperView.swift:293-297`)

**Before:**
```swift
.refreshable {
    await questionsViewModel.fetchQuestions()
}
```

**After:**
```swift
.refreshable {
    // Regenerate questions using edge function (analyzes recent journal entries)
    print("🔄 Pull-to-refresh: Regenerating questions via edge function...")
    await questionsViewModel.refreshQuestions()
}
```

**Impact:** Now pulls down to regenerate questions using TF-IDF analysis on recent entries.

### 2. Updated All Completed State (`DigDeeperView.swift:186-242`)

**Before:**
```swift
private var allCompletedState: some View {
    VStack(spacing: 20) {
        // ... content ...
    }
    .padding(.horizontal, 32)
}
```

**After:**
```swift
private var allCompletedState: some View {
    ScrollView {
        VStack(spacing: 20) {
            // ... content ...
        }
        .padding(.horizontal, 32)
        .frame(minHeight: 600) // Ensure enough height for pull-to-refresh gesture
    }
    .refreshable {
        // Allow regenerating questions even when all are completed
        print("🔄 Pull-to-refresh: Regenerating new questions...")
        await questionsViewModel.refreshQuestions()
    }
}
```

**Impact:** Users can regenerate questions even after completing all current ones.

---

## How It Works

### User Flow

1. **User navigates to "Dig Deeper" tab**
2. **User pulls down on the screen**
3. **Loading spinner appears** with "Generating personalized questions..."
4. **Edge function executes:**
   - Fetches user's recent journal entries (14-day lookback)
   - Runs TF-IDF analysis on entry text
   - Matches against 15-question bank
   - Selects top 3 questions by relevance
5. **Questions saved to database**
6. **UI refreshes** with new questions
7. **Success notification** (optional)

### Technical Flow

```
Pull gesture detected
    ↓
questionsViewModel.refreshQuestions() called
    ↓
GeneratedQuestionsViewModel.refreshQuestions() - Line 83
    ├─ Sets isRefreshing = true
    ├─ Calls edge function: generateFollowUpQuestions(lookbackDays: 14)
    ├─ Edge function analyzes entries with TF-IDF
    ├─ Edge function saves 3 questions to database
    ├─ Fetches newly generated questions
    └─ Sets isRefreshing = false
    ↓
UI updates with new questions
```

---

## Edge Function Integration

### What Gets Called
**Function**: `supabase.functions.invoke("generate-follow-up")`

**Parameters:**
```swift
{
    "lookbackDays": 14,
    "saveToDatabase": true
}
```

### What Edge Function Does

1. **Fetches Entries** (last 14 days, max 20 entries)
   ```typescript
   .from('entries')
   .select('id, text, created_at')
   .eq('user_id', user.id)
   .gte('created_at', cutoffISO)
   .order('created_at', { ascending: false })
   .limit(20)
   ```

2. **TF-IDF Analysis**
   - Tokenizes entry text
   - Removes stop words
   - Computes TF-IDF vectors
   - Calculates similarity with question bank

3. **Question Selection**
   - Ranks by similarity score
   - Applies theme diversity
   - Selects top 3 questions

4. **Database Save**
   - Deletes old questions for current week
   - Inserts 3 new questions with scores
   - Returns metadata (entries analyzed, themes found)

---

## User Experience

### States with Pull-to-Refresh

#### 1. Questions List View (Incomplete Questions)
- **Trigger**: Pull down on questions list
- **Action**: Regenerates questions based on latest entries
- **Message**: "Generating personalized questions..."
- **Duration**: ~1-3 seconds

#### 2. All Completed State
- **Trigger**: Pull down on "All caught up!" screen
- **Action**: Generates new set of questions
- **Message**: "Generating personalized questions..."
- **Use Case**: User wants new questions after finishing current set

### Visual Feedback

1. **Pull Gesture**: Standard iOS pull-to-refresh spinner
2. **Loading State**:
   - Spinner visible
   - Message: "Generating personalized questions..."
   - Sub-message: "Analyzing your recent entries"
3. **Completion**:
   - Spinner disappears
   - New questions appear with animation
   - Counter updates (e.g., "0/3")

---

## Performance Considerations

### Timing
- **Network request**: ~200-500ms
- **Edge function execution**: ~500-1500ms
- **Database save**: ~100-200ms
- **Total time**: **~1-3 seconds**

### Optimization
- ✅ Timeout protection (3 seconds max)
- ✅ Limited to 20 entries (prevents long analysis)
- ✅ Cached question vectors (fast similarity computation)
- ✅ Indexed database queries (user_id, created_at)

### Error Handling
```swift
catch {
    self.error = "Failed to generate questions: \(error.localizedDescription)"
    print("❌ Error generating questions:", error)
}
```

- Shows user-friendly error message
- Keeps existing questions visible
- User can try again

---

## Testing Scenarios

### Test 1: Generate New Questions
1. Navigate to "Dig Deeper" tab
2. Pull down on questions list
3. **Expected**: Spinner appears, new questions generated in ~2s

### Test 2: Refresh After Completing All
1. Complete all 3 questions
2. See "All caught up!" screen
3. Pull down
4. **Expected**: New set of 3 questions generated

### Test 3: Offline Behavior
1. Turn off network
2. Pull down to refresh
3. **Expected**: Error message "Failed to generate questions"

### Test 4: No New Entries
1. Pull to refresh without writing new entries
2. **Expected**: May get similar questions (based on same entries)

### Test 5: Network Timeout
1. Simulate slow network (> 3s)
2. Pull to refresh
3. **Expected**: "Request timed out" error after 3 seconds

---

## Future Enhancements

### 1. Smart Refresh Detection
**Idea**: Only regenerate if new entries exist since last generation
```swift
if hasNewEntriesSinceLastGeneration() {
    await questionsViewModel.refreshQuestions()
} else {
    // Just refetch existing questions
    await questionsViewModel.fetchQuestions()
}
```

### 2. Haptic Feedback
**Idea**: Add haptic feedback on successful generation
```swift
UINotificationFeedbackGenerator().notificationOccurred(.success)
```

### 3. Animation Improvements
**Idea**: Add custom pull-to-refresh animation with app branding
```swift
.refreshable {
    // Custom branded animation
}
```

### 4. Retry Logic
**Idea**: Automatic retry on network failures
```swift
if retryCount < 3 {
    try await Task.sleep(nanoseconds: 1_000_000_000)
    await questionsViewModel.refreshQuestions(retryCount: retryCount + 1)
}
```

---

## Console Logs

When pull-to-refresh is triggered, you'll see:

```
🔄 Pull-to-refresh: Regenerating questions via edge function...
✅ Generated 3 questions
📊 Analyzed 5 entries
🎯 Found 2 themes
📥 fetchQuestions() called
   📊 Fetched 3 questions
   ✅ Completed: 0/3
✅ fetchQuestions() completed
```

---

## Build Status
✅ **BUILD SUCCEEDED**

All changes compiled successfully with no warnings or errors.
