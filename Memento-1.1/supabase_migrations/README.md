# Supabase Migrations Guide

This directory contains SQL migration scripts for the MeetMemento Supabase database.

## Migration 001: Journal Insights Table

**Purpose:** Create the `journal_insights` table to store AI-generated insights with milestone versioning (3, 6, 9, 12 entries, etc.)

### Features

- ✅ **Milestone Versioning** - One insight per user per milestone (3, 6, 9, 12...)
- ✅ **Cross-Device Sync** - Realtime updates across all logged-in devices
- ✅ **Row Level Security** - Users can only access their own insights
- ✅ **Optimized Indexes** - Fast queries for user's insights by milestone
- ✅ **Auto Timestamps** - Automatic `updated_at` tracking
- ✅ **Hybrid Storage** - Database + local cache for offline access

### How to Apply the Migration

#### Step 1: Access Supabase SQL Editor

1. Go to your Supabase dashboard: https://app.supabase.com
2. Select your project: **MeetMemento**
3. Click on **SQL Editor** in the left sidebar
4. Click **+ New query**

#### Step 2: Run the Migration Script

1. Open the file: `supabase_migrations/001_create_journal_insights.sql`
2. Copy the entire contents
3. Paste into the Supabase SQL Editor
4. Click **Run** (or press Cmd+Enter)

You should see a success message indicating the table, indexes, and policies were created.

#### Step 3: Verify the Migration

Run these verification queries in the SQL Editor to confirm everything is set up correctly:

```sql
-- Verify table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'journal_insights'
ORDER BY ordinal_position;

-- Verify indexes
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'journal_insights';

-- Verify RLS policies
SELECT policyname, permissive, roles, cmd
FROM pg_policies
WHERE tablename = 'journal_insights';

-- Check realtime is enabled
SELECT schemaname, tablename, rowfilter
FROM pg_publication_tables
WHERE tablename = 'journal_insights';
```

#### Step 4: Enable Realtime (if not automatic)

If realtime isn't automatically enabled, run this in the SQL Editor:

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE journal_insights;
```

### What Changed in the App

#### New Files Created

1. **`Services/InsightsService.swift`** - Handles all database CRUD operations for insights
2. **`supabase_migrations/001_create_journal_insights.sql`** - Database schema

#### Modified Files

1. **`Models/Insight.swift`**
   - Added `entryCountMilestone: Int` property
   - Updated sample data with milestone values

2. **`ViewModels/InsightViewModel.swift`**
   - Added `InsightsService` integration
   - Added hybrid storage (database + UserDefaults cache)
   - Added real-time sync for cross-device updates
   - Added automatic migration from old UserDefaults-only storage
   - Updated logic to save/load insights based on milestone

### How It Works

#### Milestone Logic

- **Entry count 1-2:** Show progress message ("Write X more entries to unlock insights")
- **Entry count 3:** Generate first insights, save as milestone 3
- **Entry count 4-5:** Show cached insights from milestone 3
- **Entry count 6:** Generate new insights, save as milestone 6
- **Entry count 7-8:** Show cached insights from milestone 6
- **Entry count 9:** Generate new insights, save as milestone 9
- And so on...

#### Storage Strategy (Hybrid)

1. **UserDefaults (Local Cache)** - Fast, offline-capable, checked first
2. **Supabase Database (Cloud)** - Cross-device sync, checked if cache miss
3. **Real-time Subscription** - Auto-updates when insights change on other devices

#### Data Flow

```
Generate Insights
    ↓
Save to Database (cloud)
    ↓
Save to Cache (local)
    ↓
Real-time Sync → Other Devices
```

```
Load Insights
    ↓
Check Memory → Found? ✓ Display
    ↓
Check Cache → Found? ✓ Display & Cache
    ↓
Check Database → Found? ✓ Display & Cache
    ↓
Not Found → Show Progress Message
```

### Testing the Implementation

#### Test 1: Milestone Versioning

1. Create 3 journal entries
2. Navigate to Insights tab
3. Verify insights are generated and displayed
4. Create 2 more entries (total: 5)
5. Navigate to Insights tab again
6. Verify same insights from milestone 3 are still shown
7. Create 1 more entry (total: 6)
8. Verify new insights are generated for milestone 6

#### Test 2: Cross-Device Sync

1. Login on Device A (e.g., iPhone)
2. Create entries and generate insights
3. Login on Device B (e.g., iPad) with same account
4. Navigate to Insights tab on Device B
5. Verify insights from Device A are displayed

#### Test 3: Offline Mode

1. Enable Airplane Mode
2. Navigate to Insights tab
3. Verify insights are still displayed (from cache)
4. Disable Airplane Mode
5. Verify insights sync in the background

#### Test 4: Real-time Updates

1. Login on two devices simultaneously
2. Generate new insights on Device A
3. Watch Device B auto-update within 2-3 seconds

### Database Schema

```sql
Table: journal_insights
├── id                     UUID (PK)
├── user_id                UUID (FK → auth.users)
├── entry_count_milestone  INT (3, 6, 9, 12...)
├── summary                TEXT
├── description            TEXT
├── themes                 JSONB
├── entries_analyzed       INT
├── generated_at           TIMESTAMPTZ
├── from_cache             BOOLEAN
├── cache_expires_at       TIMESTAMPTZ
├── created_at             TIMESTAMPTZ
└── updated_at             TIMESTAMPTZ

Unique Constraint: (user_id, entry_count_milestone)
```

### Troubleshooting

#### Issue: Migration fails with "uuid_generate_v4() does not exist"

**Solution:** Enable the uuid-ossp extension:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

#### Issue: Realtime not working

**Solution:** Verify realtime is enabled:

```sql
-- Check if table is in publication
SELECT tablename FROM pg_publication_tables WHERE tablename = 'journal_insights';

-- If not, add it
ALTER PUBLICATION supabase_realtime ADD TABLE journal_insights;
```

#### Issue: RLS policies blocking access

**Solution:** Verify authentication:

```sql
-- Check current user
SELECT auth.uid();

-- Temporarily disable RLS for testing (NOT for production!)
ALTER TABLE journal_insights DISABLE ROW LEVEL SECURITY;
```

#### Issue: Old insights not migrating

**Solution:** The app performs one-time migration automatically. To manually check:

1. Open app
2. Check logs for "Migration complete: insights moved to database"
3. If migration failed, delete the flag and restart:
   - Delete UserDefaults key: `insightsMigratedToDatabase`
   - Restart app

### Rollback

If you need to rollback this migration:

```sql
-- Remove from realtime publication
ALTER PUBLICATION supabase_realtime DROP TABLE journal_insights;

-- Drop the table (cascades to indexes, triggers, policies)
DROP TABLE IF EXISTS journal_insights CASCADE;

-- Drop the trigger function
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
```

### Next Steps

After applying this migration:

1. ✅ Build and run the app
2. ✅ Create some journal entries
3. ✅ Test insights generation at milestones (3, 6, 9...)
4. ✅ Test cross-device sync
5. ✅ Monitor logs for any errors

### Cost Considerations

- **Database Storage:** Each insight is ~2-5KB
  - 10 milestones = ~50KB per user
  - 1000 users with 10 milestones = ~50MB total

- **Realtime Connections:** Each active device maintains 1 connection
  - Free tier: 200 concurrent connections
  - Sufficient for moderate usage

- **Database Operations:** Minimal API calls
  - 1 write per milestone (3, 6, 9...)
  - 1 read when switching devices or app restarts
  - Real-time updates are free (push-based)

### Support

For issues or questions:
- Check Supabase logs in the dashboard
- Review app logs (search for "Insights" in Xcode console)
- Verify RLS policies are not blocking legitimate access
