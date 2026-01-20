# Quick Start: Continuous Weekly Questions

**Goal:** Automatically generate 5 personalized follow-up questions every Sunday based on recent journal entries.

---

## 🚀 3-Step Deployment

### Step 1: Deploy Backend (5 min)

```bash
cd /Users/sebastianmendo/Swift-projects/MeetMemento
bash DEPLOY_WEEKLY_QUESTIONS.sh
```

This will:
- ✅ Create database table
- ✅ Deploy edge functions
- ✅ Set up cron job

---

### Step 2: Test It Works (5 min)

Get your JWT token:
```swift
// In Xcode, add this line after signing in:
print("JWT:", supabaseService.client.auth.session?.accessToken ?? "none")
```

Test:
```bash
export JWT_TOKEN="your_token_here"
bash TEST_QUESTIONS.sh
```

Expected: See 5 generated questions ✅

---

### Step 3: Enable Weekly Cron (2 min)

1. Go to: https://supabase.com/dashboard
2. **Edge Functions** → **weekly-question-generator** → **Settings**
3. **Enable Cron:** `0 21 * * 0` (Sunday 9 PM)
4. Click **Save**

Done! Questions will auto-generate every Sunday.

---

## 📱 Swift Integration (Optional - 30 min)

### Add Files to Xcode

1. `GeneratedFollowUpQuestion.swift` ✅
2. `SupabaseService+FollowUpQuestions.swift` ✅
3. `GeneratedQuestionsViewModel.swift` ✅

### Update JournalView

```swift
@StateObject private var generatedQuestionsViewModel = GeneratedQuestionsViewModel()

// In body:
.task {
    await generatedQuestionsViewModel.fetchQuestions()
}

// Replace follow-up section with:
ForEach(generatedQuestionsViewModel.currentWeekQuestions) { question in
    FollowUpCard(
        question: question.questionText,
        isCompleted: question.isCompleted
    ) {
        onNavigateToEntry(.followUp(question.questionText))
    }
}
```

Full code in: `IMPLEMENTATION_INSTRUCTIONS.md`

---

## ✅ Verification

**Check database:**
```sql
SELECT * FROM follow_up_questions WHERE user_id = auth.uid();
```

**Check logs:**
```bash
supabase functions logs generate-follow-up --tail
```

**Test manually:**
- Open app → Journal tab
- Should see AI-generated questions
- Tap refresh (↻) → New questions appear

---

## 📚 Documentation

- **Complete guide:** `IMPLEMENTATION_INSTRUCTIONS.md`
- **Architecture:** `CONTINUOUS_QUESTIONS_IMPLEMENTATION.md`
- **Deployment script:** `DEPLOY_WEEKLY_QUESTIONS.sh`
- **Test script:** `TEST_QUESTIONS.sh`

---

## 🔧 Configuration

### Change when questions generate:
```
0 21 * * 0  = Sunday 9 PM UTC
0 9 * * 1   = Monday 9 AM UTC
0 20 * * 3  = Wednesday 8 PM UTC
```

### Change lookback window:
In `weekly-question-generator/index.ts`:
```typescript
lookbackDays: 21  // 3 weeks instead of 2
```

### Change question count:
In `generate-follow-up/index.ts` line 176:
```typescript
if (selectedQuestions.length >= 7) break;  // 7 instead of 5
```

---

## 🐛 Troubleshooting

**No questions generated?**
- Check you have 3+ entries in last 14 days
- Entries must have meaningful content (not just stop words)

**Cron not running?**
- Verify cron is enabled in Dashboard
- Check logs: `supabase functions logs weekly-question-generator`

**Questions not showing in app?**
- Check JWT token is valid
- Verify ViewModel is initialized
- Check console for errors

---

## 📊 How It Works

```
Week 1:
  User writes 3+ entries about "work stress"
  ↓
  Sunday 9 PM: Cron runs
  ↓
  Analyzes last 14 days of entries
  ↓
  Generates 5 questions: "What boundaries do you need?", etc.
  ↓
  Saves to database
  ↓
  Monday: User opens app → "5 new questions!"

Week 2:
  User writes entries about "gratitude" + "family"
  ↓
  Sunday 9 PM: Cron runs again
  ↓
  Analyzes last 14 days (different content now)
  ↓
  Generates NEW 5 questions: "What relationships deserve attention?", etc.
  ↓
  Questions adapt to recent themes!
```

---

## 🎯 Next Steps

1. **Deploy** → `bash DEPLOY_WEEKLY_QUESTIONS.sh`
2. **Test** → `bash TEST_QUESTIONS.sh`
3. **Enable Cron** → Supabase Dashboard
4. **Integrate Swift** → Add 3 files, update JournalView
5. **Monitor** → Check logs next Sunday

---

**Ready to deploy? Run:**
```bash
bash DEPLOY_WEEKLY_QUESTIONS.sh
```
