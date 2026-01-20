# Sprints 3 & 4: Remaining Settings Tasks

## 📊 Current Status

### ✅ Sprint #1: COMPLETE
- Settings page redesign with card-based layout
- Navigation instead of sheet presentation
- Back button fix across all views
- SettingsRow reusable component

### ⚠️ Sprint #2: UI ONLY (Functional Implementation Pending)
- Profile row added (shows "Coming Soon")
- Appearance section added (shows "Coming Soon")
- **Still Need:** Actual ProfileSettingsView and AppearanceSettingsView implementation

---

## 🎯 Sprint #2 Completion Tasks (Should finish first)

Before moving to Sprints 3 & 4, these Sprint #2 items need full implementation:

### **1. Profile Settings (4-6 hours)**
**Status:** UI placeholder exists, needs implementation

**Files to Create:**
- `ProfileSettingsView.swift` - Profile editing page
- `PreferencesService.swift` - UserDefaults wrapper (needed for both Profile & Appearance)

**Features:**
- Edit first name and last name
- Pre-fill with current user data from Supabase
- Form validation (required, 1-50 chars)
- Save button with loading state
- Success/error message display
- Auto-dismiss after successful save

**Backend:** Already exists (`AuthViewModel.updateProfile()`, `SupabaseService.updateUserMetadata()`)

---

### **2. Appearance Settings (4-6 hours)**
**Status:** UI placeholder exists, needs implementation

**Files to Create:**
- `AppearanceSettingsView.swift` - Theme & font size page

**Files to Modify:**
- `Theme.swift` - Update ThemeProvider to respect preferences
- `ContentView.swift` - Add navigation routes
- `Typography.swift` (optional) - Font size offset support

**Features:**
- **Theme Selector:**
  - System (auto) / Light / Dark options
  - Segmented control UI
  - Real-time theme switching
  - Persist to UserDefaults

- **Font Size (Optional - can defer):**
  - Small / Medium / Large / Extra Large
  - Live preview text
  - Apply globally via Typography
  - Persist to UserDefaults

---

## 🚀 Sprint #3: Data & Personalization (3-4 days)

Once Sprint #2 is complete, Sprint #3 focuses on data management and customization.

### **1. Personalization Settings** ⭐ Priority
**Goal:** Allow users to view/edit their onboarding data

**New View:** `PersonalizationSettingsView.swift`

**Features:**
- **View Personalization Text**
  - Display current `user_personalization_node` from Supabase
  - Read-only card showing original onboarding input
  - "Edit" button to modify

- **Edit Personalization Text**
  - TextEditor similar to LearnAboutYourselfView
  - Character count (min 20 chars)
  - Save changes to Supabase user metadata
  - Update `SupabaseService.updateUserPersonalization()`

- **View/Edit Selected Themes**
  - Display `selected_themes` from Supabase
  - Grid of OnboardingThemeTag components
  - Toggle themes on/off
  - Save updated selection
  - Update `SupabaseService.updateUserThemes()`

- **Re-run Onboarding Button**
  - Reset `onboarding_completed` flag
  - Navigate user back to OnboardingCoordinatorView
  - Warning: "This will restart your onboarding experience"

**Backend Methods Needed:**
```swift
// Add to SupabaseService.swift
func getUserPersonalization() async throws -> String?
func getUserThemes() async throws -> [String]

// Add to AuthViewModel.swift
func resetOnboarding() async
```

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ Personalization                 │
├─────────────────────────────────┤
│ 📝 Your Goals & Themes       → │
│    View and edit your          │
│    personalization             │
├─────────────────────────────────┤
│ 🔄 Re-run Onboarding         → │
│    Start over from scratch     │
└─────────────────────────────────┘
```

---

### **2. Data & Privacy Settings**
**Goal:** Give users control over their data

**New View:** `DataPrivacySettingsView.swift`

**Features:**
- **Export Journal Data**
  - Export all entries to JSON format
  - Export all entries to CSV format (optional)
  - Share sheet to save/send file
  - Progress indicator during export

- **Data Usage Statistics**
  - Total entries count
  - First entry date
  - Most recent entry date
  - Estimated storage size
  - Read-only display

- **Connected Accounts (Read-only for now)**
  - List authentication providers
  - Show: Email, Google, Apple
  - Display which methods are linked
  - Note: "Manage in Authentication settings"

**New Service:**
```swift
// ExportService.swift
class ExportService {
    static let shared = ExportService()

    func exportToJSON(entries: [Entry]) -> Data
    func exportToCSV(entries: [Entry]) -> Data
    func shareFile(_ data: Data, filename: String)
}
```

**Backend Methods:**
```swift
// Add to SupabaseService.swift
func getAllUserEntries() async throws -> [Entry] // No limit
func getUserDataSize() async throws -> Int // In bytes
```

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ Data & Privacy                  │
├─────────────────────────────────┤
│ 💾 Export Data               → │
│    Download your journal       │
├─────────────────────────────────┤
│ 📊 Data Usage                → │
│    View storage statistics     │
└─────────────────────────────────┘
```

---

### **3. Journal Preferences**
**Goal:** Customize journaling experience

**New View:** `JournalPreferencesView.swift`

**Features:**
- **Default Entry Title Behavior**
  - Auto-generate from date (e.g., "October 16, 2025")
  - Leave blank (user fills in)
  - Picker component
  - Save to UserDefaults

- **Auto-save Frequency**
  - Immediate (on every change)
  - Every 5 seconds
  - Every 30 seconds
  - Manual only
  - Picker component

- **Show Character Counter**
  - Toggle on/off
  - Affects AddEntryView and JournalPageView

- **Delete Confirmation**
  - Require confirmation (default)
  - Delete immediately
  - Toggle switch

**PreferencesService Updates:**
```swift
// Add to PreferencesService.swift
enum DefaultTitleBehavior: String {
    case autoGenerate
    case blank
}

enum AutoSaveFrequency: String {
    case immediate
    case fiveSeconds
    case thirtySeconds
    case manual
}

var defaultTitleBehavior: DefaultTitleBehavior { get set }
var autoSaveFrequency: AutoSaveFrequency { get set }
var showCharacterCounter: Bool { get set }
var requireDeleteConfirmation: Bool { get set }
```

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ Journal                         │
├─────────────────────────────────┤
│ 📔 Journaling Preferences    → │
│    Customize your writing      │
│    experience                  │
└─────────────────────────────────┘
```

---

## 🚀 Sprint #4: Advanced & About (2-3 days)

Final polish and required App Store metadata.

### **1. About & Legal Settings** ⭐ REQUIRED FOR APP STORE
**Goal:** Meet App Store requirements and provide support

**New View:** `AboutSettingsView.swift`

**Features:**
- **App Version**
  - Display from `Bundle.main.infoDictionary`
  - Format: "Version 1.0.0 (Build 1)"
  - Tappable to copy to clipboard (optional)

- **What's New**
  - NavigationLink to `WhatsNewView`
  - Markdown-based changelog
  - Parse from `CHANGELOG.md`

- **Terms of Service**
  - Opens URL in Safari
  - Required for App Store

- **Privacy Policy**
  - Opens URL in Safari
  - Required for App Store

- **Contact Support**
  - Opens Mail.app with pre-filled email
  - Include: app version, device info, iOS version
  - Alternative: Opens support URL

- **Rate on App Store**
  - Uses `SKStoreReviewController.requestReview()`
  - Button: "Rate MeetMemento"

- **Share App**
  - Native iOS share sheet
  - Share App Store link
  - Include message: "Check out MeetMemento!"

**Files to Create:**
```
Views/Settings/AboutSettingsView.swift
Views/Settings/WhatsNewView.swift
Resources/CHANGELOG.md
```

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ About                           │
├─────────────────────────────────┤
│ ℹ️ About MeetMemento         → │
│    Version, legal, support     │
└─────────────────────────────────┘
```

---

### **2. AI & Insights Settings** (Optional - depends on AI implementation)
**Goal:** Control AI-powered features

**New View:** `InsightsSettingsView.swift`

**Features:**
- **Insights Generation Frequency**
  - After every entry
  - Daily (once per day)
  - Weekly (once per week)
  - Manual only
  - Picker component

- **Regenerate Insights**
  - Button to manually trigger
  - "Regenerate Now" with loading state
  - Success message

- **Privacy Mode** (Future)
  - Exclude specific entries from AI
  - Toggle per entry (requires Entry model update)

- **AI Personalization Strength** (Future)
  - Slider: Generic ←→ Highly Personal
  - Affects prompt customization

**Backend Methods:**
```swift
// Add to InsightViewModel.swift
func regenerateInsights() async throws
func updateInsightFrequency(_ frequency: InsightFrequency)
```

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ Insights                        │
├─────────────────────────────────┤
│ ✨ AI Insights              → │
│    Configure insights          │
│    generation                  │
└─────────────────────────────────┘
```

---

### **3. Advanced Settings**
**Goal:** Power user features

**New View:** `AdvancedSettingsView.swift`

**Features:**
- **Clear Cache**
  - Button with confirmation
  - Clears: Image cache, temporary files
  - Shows amount to be cleared

- **Reset App to Defaults**
  - Button with strong warning
  - Resets: All preferences to default
  - Does NOT delete: Account, journal entries

- **Debug Mode** (Development only)
  - Toggle for development features
  - Show: API logs, performance metrics
  - Hide in production builds with `#if DEBUG`

- **Network Logs** (Development only)
  - View recent API calls
  - Timestamps, endpoints, status codes

**UI Section in SettingsView:**
```
┌─────────────────────────────────┐
│ Advanced                        │
├─────────────────────────────────┤
│ 🔧 Advanced Settings         → │
│    Cache, reset, debugging     │
└─────────────────────────────────┘
```

---

## 📊 Sprint Summary

### **Sprint #2 (Incomplete - Finish First)**
- ⚠️ ProfileSettingsView implementation
- ⚠️ AppearanceSettingsView implementation
- ⚠️ PreferencesService creation
- ⚠️ Theme.swift updates
- ⚠️ ContentView navigation updates

**Estimated Time:** 1-2 days remaining

---

### **Sprint #3: Data & Personalization**
**Priority Features:**
1. PersonalizationSettingsView (view/edit onboarding data)
2. DataPrivacySettingsView (export data, statistics)
3. JournalPreferencesView (customize journaling)

**New Files:** 3 views, 1 service (ExportService)
**Modified Files:** SettingsView, ContentView, PreferencesService
**Estimated Time:** 3-4 days

---

### **Sprint #4: Advanced & About**
**Priority Features:**
1. ⭐ AboutSettingsView (REQUIRED for App Store)
2. InsightsSettingsView (if AI features exist)
3. AdvancedSettingsView (optional power user features)

**New Files:** 2-3 views, CHANGELOG.md
**Modified Files:** SettingsView, ContentView
**Estimated Time:** 2-3 days

---

## 🎯 Recommended Implementation Order

### **Phase 1: Complete Sprint #2** (1-2 days)
1. Create PreferencesService.swift
2. Implement ProfileSettingsView.swift
3. Implement AppearanceSettingsView.swift (theme only, defer font size)
4. Update ContentView navigation
5. Test thoroughly

### **Phase 2: Sprint #3 Essentials** (2-3 days)
1. PersonalizationSettingsView (most requested by users)
2. DataPrivacySettingsView (export functionality)
3. JournalPreferencesView (if time permits)

### **Phase 3: App Store Requirements** (1 day)
1. AboutSettingsView with legal links ⭐ REQUIRED
2. Create CHANGELOG.md
3. Set up Terms of Service & Privacy Policy URLs

### **Phase 4: Polish** (1-2 days)
1. InsightsSettingsView (if AI exists)
2. AdvancedSettingsView (nice to have)
3. Testing and bug fixes

---

## 📋 Files That Will Be Created

### Sprint #2 Completion:
- `Services/PreferencesService.swift`
- `Views/Settings/ProfileSettingsView.swift`
- `Views/Settings/AppearanceSettingsView.swift`

### Sprint #3:
- `Views/Settings/PersonalizationSettingsView.swift`
- `Views/Settings/DataPrivacySettingsView.swift`
- `Views/Settings/JournalPreferencesView.swift`
- `Services/ExportService.swift`

### Sprint #4:
- `Views/Settings/AboutSettingsView.swift` ⭐
- `Views/Settings/WhatsNewView.swift`
- `Views/Settings/InsightsSettingsView.swift` (optional)
- `Views/Settings/AdvancedSettingsView.swift` (optional)
- `Resources/CHANGELOG.md` ⭐

**Total New Files:** 12-14 files

---

## ✅ Final Settings Page Structure

```
Settings
├── Account
│   ├── Signed in as (email)
│   ├── Profile → ProfileSettingsView
│   └── Sign Out
│
├── Appearance → AppearanceSettingsView
│   └── Theme & Display
│
├── Personalization → PersonalizationSettingsView
│   └── Your Goals & Themes
│
├── Journal → JournalPreferencesView
│   └── Journaling Preferences
│
├── Insights → InsightsSettingsView (optional)
│   └── AI Insights
│
├── Data & Privacy → DataPrivacySettingsView
│   ├── Export Data
│   └── Data Usage
│
├── About → AboutSettingsView ⭐ REQUIRED
│   └── About MeetMemento
│
├── Advanced → AdvancedSettingsView (optional)
│   └── Advanced Settings
│
├── Development (hide in production)
│   ├── Test Supabase
│   └── Test Entry Loading
│
└── Danger Zone
    └── Delete Account
```

---

## 🚨 Critical Path for App Store Submission

**Must Have Before App Store:**
1. ✅ Account deletion (already implemented)
2. ⚠️ Profile settings (Sprint #2 - implement ProfileSettingsView)
3. ⚠️ About page with version (Sprint #4 - AboutSettingsView)
4. ⚠️ Terms of Service link (Sprint #4 - AboutSettingsView)
5. ⚠️ Privacy Policy link (Sprint #4 - AboutSettingsView)
6. ⚠️ Contact Support option (Sprint #4 - AboutSettingsView)

**Nice to Have:**
- Data export (Sprint #3)
- Theme customization (Sprint #2)
- Personalization editing (Sprint #3)

---

**Next Step:** Complete Sprint #2 implementation before starting Sprint #3!
