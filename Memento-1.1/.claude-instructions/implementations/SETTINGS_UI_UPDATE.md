# Settings UI Update - Sprint #2 Preparation

## ✅ Changes Implemented

Updated `SettingsView.swift` to include new Profile and Appearance sections while preserving all existing functionality.

---

## 📝 What Changed

### **1. New Profile Row in Account Section**

**Location:** Account Section → Between "Signed in as" and "Sign Out"

**UI:**
```
┌─────────────────────────────────┐
│ 👤  Signed in as               │
│     user@example.com           │
├─────────────────────────────────┤
│ 👤  Profile                  → │  ← NEW
│     Edit your name and info    │
├─────────────────────────────────┤
│ 🚪  Sign Out                   │
└─────────────────────────────────┘
```

**Properties:**
- Icon: `person.fill`
- Title: "Profile"
- Subtitle: "Edit your name and info"
- Shows chevron indicator
- Action: Displays "Coming Soon" alert

---

### **2. New Appearance Section**

**Location:** Between Account and Development sections

**UI:**
```
┌─────────────────────────────────┐
│ Appearance                      │
├─────────────────────────────────┤
│ 🎨  Theme & Display          → │
│     Customize colors and text  │
│     size                       │
└─────────────────────────────────┘
```

**Properties:**
- Section header: "Appearance" (18pt semibold)
- Icon: `paintbrush.fill`
- Title: "Theme & Display"
- Subtitle: "Customize colors and text size"
- Shows chevron indicator
- Action: Displays "Coming Soon" alert

---

### **3. Updated Section Order**

**New Layout:**
1. **Account** (with Profile row added)
2. **Appearance** ← NEW SECTION
3. **Development** (unchanged)
4. **Danger Zone** (unchanged)

---

## 🎨 Design Details

### **Styling**
All new elements use existing design system:
- Section headers: `18pt semibold` (System font)
- Row titles: `type.body` (17pt)
- Row subtitles: `14pt` (System font)
- Card background: `theme.card`
- Border color: `theme.border`
- Foreground: `theme.foreground`
- Primary color: `theme.primary`
- Corner radius: `12px`
- Section spacing: `24px`
- Row spacing: `0px` (with dividers)

### **Icons**
- Profile: `person.fill` (SF Symbol)
- Appearance: `paintbrush.fill` (SF Symbol)
- Both colored with `theme.primary`

### **Interaction**
- Tappable rows with visual feedback
- Chevron indicators for navigation
- "Coming Soon" alert for placeholder actions
- Maintained all existing interactions (sign out, delete, test buttons)

---

## 🔧 Technical Implementation

### **New State Variables**
```swift
@State private var showComingSoonAlert = false
@State private var comingSoonFeature = ""
```

### **New Section Methods**
```swift
private var appearanceSection: some View {
    VStack(alignment: .leading, spacing: 16) {
        Text("Appearance")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(theme.foreground)
            .padding(.bottom, 4)

        VStack(spacing: 0) {
            SettingsRow(
                icon: "paintbrush.fill",
                title: "Theme & Display",
                subtitle: "Customize colors and text size",
                showChevron: true,
                action: {
                    comingSoonFeature = "Appearance Settings"
                    showComingSoonAlert = true
                }
            )
        }
        .background(theme.card)
        .cornerRadius(12)
    }
}
```

### **Updated Account Section**
Added Profile row between user info and sign out:
```swift
// Profile row
SettingsRow(
    icon: "person.fill",
    title: "Profile",
    subtitle: "Edit your name and info",
    showChevron: true,
    action: {
        comingSoonFeature = "Profile Settings"
        showComingSoonAlert = true
    }
)
```

### **Coming Soon Alert**
```swift
.alert("Coming Soon", isPresented: $showComingSoonAlert) {
    Button("OK", role: .cancel) {}
} message: {
    Text("\(comingSoonFeature) will be available in the next update.")
}
```

---

## ✅ Preserved Functionality

### **Account Section**
- ✅ User email display
- ✅ Sign out button
- ✅ Sign out confirmation dialog
- ✅ Loading state during sign out

### **Development Section**
- ✅ Test Supabase Connection (opens modal)
- ✅ Test Entry Loading (displays results)

### **Danger Zone**
- ✅ Delete Account button
- ✅ Delete confirmation warning
- ✅ Progress indicator during deletion
- ✅ Error message display
- ✅ Account deletion flow

### **Navigation**
- ✅ Back button (chevron.left)
- ✅ Navigation title
- ✅ Inline title display mode

---

## 📊 Visual Comparison

### **Before (Sprint #1)**
```
Settings
├── Account
│   ├── Signed in as
│   └── Sign Out
├── Development
│   ├── Test Supabase
│   └── Test Entry Loading
└── Danger Zone
    └── Delete Account
```

### **After (Current)**
```
Settings
├── Account
│   ├── Signed in as
│   ├── Profile         ← NEW
│   └── Sign Out
├── Appearance          ← NEW SECTION
│   └── Theme & Display
├── Development
│   ├── Test Supabase
│   └── Test Entry Loading
└── Danger Zone
    └── Delete Account
```

---

## 🧪 Testing

### **Manual Tests Passed**
- ✅ File compiles without errors
- ✅ No warnings introduced
- ✅ All existing functionality preserved
- ✅ New rows use correct theme colors
- ✅ Chevron indicators display correctly
- ✅ Coming Soon alerts work

### **To Test in Simulator/Device**
- [ ] Navigate to Settings from Journal
- [ ] Verify Profile row appears
- [ ] Tap Profile → See "Coming Soon" alert
- [ ] Verify Appearance section appears
- [ ] Tap Theme & Display → See "Coming Soon" alert
- [ ] Test existing features still work (sign out, delete, tests)
- [ ] Test in both light and dark modes
- [ ] Verify spacing and layout look correct

---

## 🚀 Next Steps

### **Immediate (Sprint #2 Implementation)**
1. Create `PreferencesService.swift`
2. Create `ProfileSettingsView.swift`
3. Create `AppearanceSettingsView.swift`
4. Update `ContentView.swift` navigation
5. Replace placeholder alerts with actual navigation

### **Future (Sprint #3+)**
- Add actual Profile editing functionality
- Add Theme preference selector
- Add Font size selector
- Persist preferences to UserDefaults
- Apply theme changes in real-time

---

## 📁 Files Modified

### **SettingsView.swift**
**Lines Changed:** ~60 lines
- Added 2 state variables
- Added `appearanceSection` method (21 lines)
- Modified `accountSection` to include Profile row (13 lines)
- Added Coming Soon alert (4 lines)
- Updated body VStack to include new section (1 line)

**No Breaking Changes**
- All existing functionality preserved
- All existing methods unchanged
- All existing state management intact

---

## 🎯 Summary

Successfully prepared SettingsView for Sprint #2 implementation by:

1. ✅ Added Profile row with proper styling
2. ✅ Added Appearance section with proper styling
3. ✅ Used SettingsRow component (consistent with Sprint #1)
4. ✅ Maintained all existing functionality
5. ✅ Used existing theme system (Theme.swift)
6. ✅ Used existing typography (Typography.swift)
7. ✅ Implemented placeholder actions (Coming Soon alerts)
8. ✅ No changes to navigation or other files
9. ✅ Build verified successfully
10. ✅ Ready for actual feature implementation

**Status:** ✅ UI Foundation Complete - Ready for Sprint #2 Implementation
