# Sprint #2: Profile & Appearance Settings - Requirements

## 📋 Overview

**Goal:** Add user-facing settings for managing profile information and customizing app appearance.

**Duration:** 2-3 days

**Dependencies:** Sprint #1 (Settings page redesign) ✅ Complete

---

## 🎯 User Stories

### Profile Management
- **As a user**, I want to edit my first name and last name so that my profile information is accurate
- **As a user**, I want to see my current profile information before editing it
- **As a user**, I want to see confirmation when my profile is successfully updated
- **As a user**, I want to see clear error messages if profile update fails

### Appearance Customization
- **As a user**, I want to choose between Light, Dark, or System theme so I can use the app in my preferred color scheme regardless of system settings
- **As a user**, I want to adjust the text size so the app is comfortable to read
- **As a user**, I want my appearance preferences saved across app launches

---

## 🚀 Features to Implement

### 1. Profile Settings Page

#### **User Interface**
- **Navigation:** Tappable row in Settings → Profile Settings
- **Layout:** Card-based design matching Sprint #1 aesthetic
- **Form fields:**
  - First Name (text input)
  - Last Name (text input)
- **Actions:**
  - Save button (primary action)
  - Cancel/Back button (navigation)
- **States:**
  - Loading state while fetching current data
  - Saving state with progress indicator
  - Success state (brief confirmation)
  - Error state with message display

#### **Data Flow**
```
User taps "Profile" in Settings
  ↓
Navigate to ProfileSettingsView
  ↓
Load current user metadata from AuthViewModel.currentUser
  ↓
Pre-fill form with firstName, lastName
  ↓
User edits and taps Save
  ↓
Validate input (not empty, reasonable length)
  ↓
Call AuthViewModel.updateProfile()
  ↓
Show success message → Navigate back
```

#### **Validation Rules**
- First Name: Required, 1-50 characters, letters/spaces/hyphens only
- Last Name: Required, 1-50 characters, letters/spaces/hyphens only
- Trim whitespace on save

#### **Error Handling**
- Network errors: "Could not update profile. Check your connection and try again."
- Validation errors: "Please enter a valid name (1-50 characters)"
- Supabase errors: Display actual error message from service

---

### 2. Appearance Settings Page

#### **User Interface**
- **Navigation:** Tappable row in Settings → Appearance
- **Layout:** Card-based design matching Sprint #1 aesthetic
- **Sections:**

**Theme Section:**
- Section header: "Theme"
- Options:
  - 🌓 System (follows device settings)
  - ☀️ Light (always light mode)
  - 🌙 Dark (always dark mode)
- UI Component: Segmented control or radio button group
- Selected state: Highlighted with theme.primary color

**Font Size Section:**
- Section header: "Font Size"
- Options:
  - Small (base - 2pt)
  - Medium (base) [Default]
  - Large (base + 2pt)
  - Extra Large (base + 4pt)
- UI Component: Slider or segmented control
- Live preview: Sample text showing current size

#### **Data Storage**
All preferences stored in UserDefaults:
```swift
UserDefaults.standard.set(value, forKey: key)

Keys:
- "app_theme_preference": String ("system", "light", "dark")
- "app_font_size_offset": Int (-2, 0, 2, 4)
```

#### **Data Flow**
```
User taps "Appearance" in Settings
  ↓
Navigate to AppearanceSettingsView
  ↓
Load preferences from PreferencesService
  ↓
Display current selections
  ↓
User changes theme/font size
  ↓
Immediately save to PreferencesService
  ↓
Apply changes to app UI in real-time
```

#### **Theme Application Logic**
```swift
// Current (Sprint #1):
ThemeProvider uses colorScheme == .dark ? .dark : .light

// New (Sprint #2):
1. Check UserDefaults for "app_theme_preference"
2. If "system" or nil → use colorScheme
3. If "light" → always use Theme.light
4. If "dark" → always use Theme.dark
```

---

## 📁 Files to Create

### 1. **PreferencesService.swift** (NEW)
**Location:** `Services/PreferencesService.swift`

**Purpose:** Centralized service for managing app preferences with UserDefaults

**Interface:**
```swift
class PreferencesService {
    static let shared = PreferencesService()

    // MARK: - Keys
    private enum Keys {
        static let themePreference = "app_theme_preference"
        static let fontSizeOffset = "app_font_size_offset"
    }

    // MARK: - Theme Preference
    enum ThemePreference: String {
        case system
        case light
        case dark
    }

    var themePreference: ThemePreference { get set }

    // MARK: - Font Size
    var fontSizeOffset: Int { get set } // -2, 0, 2, 4

    // MARK: - Reset
    func resetToDefaults()
}
```

### 2. **ProfileSettingsView.swift** (NEW)
**Location:** `Views/Settings/ProfileSettingsView.swift`

**Purpose:** View for editing user profile (first name, last name)

**Key Components:**
- Text fields for first name, last name
- Save button with loading state
- Error message display
- Form validation

### 3. **AppearanceSettingsView.swift** (NEW)
**Location:** `Views/Settings/AppearanceSettingsView.swift`

**Purpose:** View for customizing app appearance (theme, font size)

**Key Components:**
- Theme preference selector (segmented control)
- Font size selector (slider or segmented control)
- Live preview of font size
- Real-time updates

---

## 📝 Files to Modify

### 1. **SettingsView.swift**
**Changes:**
- Add "Profile" row in Account section (before Sign Out)
- Add new "Appearance" section with navigation to AppearanceSettingsView
- Update navigation to support new routes

**New Sections:**
```swift
// Account Section - Add before Sign Out
SettingsRow(
    icon: "person.fill",
    title: "Profile",
    subtitle: "Edit your name and info",
    showChevron: true,
    action: {
        // Navigate to ProfileSettingsView
    }
)

// New Appearance Section
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
                    // Navigate to AppearanceSettingsView
                }
            )
        }
        .background(theme.card)
        .cornerRadius(12)
    }
}
```

### 2. **ContentView.swift**
**Changes:**
- Add new cases to SettingsRoute enum
- Add navigation destinations for new views

**Code:**
```swift
public enum SettingsRoute: Hashable {
    case main
    case profile      // NEW
    case appearance   // NEW
}

.navigationDestination(for: SettingsRoute.self) { route in
    switch route {
    case .main:
        SettingsView()
            .environmentObject(authViewModel)
    case .profile:
        ProfileSettingsView()
            .environmentObject(authViewModel)
    case .appearance:
        AppearanceSettingsView()
    }
}
```

### 3. **Theme.swift**
**Changes:**
- Update ThemeProvider to respect user preference
- Add PreferencesService integration

**Modified ThemeProvider:**
```swift
struct ThemeProvider: ViewModifier {
    @Environment(\.colorScheme) private var systemColorScheme

    func body(content: Content) -> some View {
        let theme: Theme

        switch PreferencesService.shared.themePreference {
        case .system:
            theme = systemColorScheme == .dark ? .dark : .light
        case .light:
            theme = .light
        case .dark:
            theme = .dark
        }

        content.environment(\.theme, theme)
    }
}
```

### 4. **Typography.swift** (Optional - if implementing font size)
**Changes:**
- Add font size offset support
- Apply offset to all font sizes

**Example:**
```swift
private var offset: CGFloat {
    CGFloat(PreferencesService.shared.fontSizeOffset)
}

public var h1: Font {
    headingFont(size: h1Size + offset, weight: .regular)
}
public var body: Font {
    bodyFont(size: bodyL + offset, weight: .regular)
}
```

---

## 🎨 Design Specifications

### ProfileSettingsView
**Layout:**
- Horizontal padding: 20px
- Top padding: 24px
- Field spacing: 20px
- Save button: Full-width, 48pt height

**Form Fields:**
- Label: 15pt medium, theme.foreground
- Input: 17pt regular, theme.card background
- Border: 1px theme.border, 8px corner radius
- Height: 48pt minimum
- Padding: 12px horizontal, 14px vertical

**Save Button:**
- Background: theme.primary
- Text: theme.primaryForeground
- Height: 48pt
- Corner radius: 12px
- Loading state: Shows ProgressView

### AppearanceSettingsView
**Theme Selector:**
- Segmented control style
- Options: System | Light | Dark
- Selected: theme.primary background
- Unselected: theme.card background
- Height: 40pt per segment

**Font Size Selector:**
- Four options in horizontal layout
- Labels: "S", "M", "L", "XL"
- Selected: theme.primary background with white text
- Unselected: theme.card background
- Size: 44pt × 44pt (tap target)

**Preview Card:**
- Sample text showing current font size
- Background: theme.card
- Padding: 16px
- Corner radius: 12px
- Text: "The quick brown fox jumps over the lazy dog"

---

## 🔧 Technical Implementation Details

### PreferencesService Implementation
```swift
class PreferencesService {
    static let shared = PreferencesService()
    private init() {}

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Keys {
        static let themePreference = "app_theme_preference"
        static let fontSizeOffset = "app_font_size_offset"
    }

    // MARK: - Theme
    enum ThemePreference: String {
        case system
        case light
        case dark
    }

    var themePreference: ThemePreference {
        get {
            guard let value = defaults.string(forKey: Keys.themePreference),
                  let preference = ThemePreference(rawValue: value) else {
                return .system
            }
            return preference
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.themePreference)
        }
    }

    // MARK: - Font Size
    var fontSizeOffset: Int {
        get {
            defaults.integer(forKey: Keys.fontSizeOffset)
        }
        set {
            defaults.set(newValue, forKey: Keys.fontSizeOffset)
        }
    }

    // MARK: - Reset
    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.themePreference)
        defaults.removeObject(forKey: Keys.fontSizeOffset)
    }
}
```

### Profile Update Flow
```swift
// In ProfileSettingsView
func saveProfile() {
    // Validate
    guard validateInput() else { return }

    isSaving = true
    errorMessage = nil

    Task {
        do {
            try await authViewModel.updateProfile(
                firstName: firstName.trimmingCharacters(in: .whitespaces),
                lastName: lastName.trimmingCharacters(in: .whitespaces)
            )

            await MainActor.run {
                isSaving = false
                showSuccessMessage = true

                // Auto-dismiss after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
```

### Theme Change Application
```swift
// In AppearanceSettingsView
@State private var selectedTheme: PreferencesService.ThemePreference

func updateTheme(_ newTheme: PreferencesService.ThemePreference) {
    selectedTheme = newTheme
    PreferencesService.shared.themePreference = newTheme

    // Force UI update by modifying environment
    // ThemeProvider will pick up the change automatically
    objectWillChange.send()
}
```

---

## ✅ Testing Checklist

### Profile Settings
- [ ] Navigate to Profile Settings from main Settings
- [ ] Current name pre-fills correctly
- [ ] Can edit first name
- [ ] Can edit last name
- [ ] Validation prevents empty names
- [ ] Validation prevents names > 50 characters
- [ ] Save button shows loading state
- [ ] Success message displays after save
- [ ] Auto-dismisses after success
- [ ] Error message displays on failure
- [ ] Network error handling works
- [ ] Back button cancels without saving
- [ ] Updated name appears in Account section

### Appearance Settings
- [ ] Navigate to Appearance Settings
- [ ] Current theme selection pre-loads
- [ ] System theme follows device setting
- [ ] Light theme forces light mode
- [ ] Dark theme forces dark mode
- [ ] Theme changes apply immediately
- [ ] Theme preference persists across app launches
- [ ] Font size slider works
- [ ] Font preview updates in real-time
- [ ] Font size changes apply to entire app
- [ ] Font size preference persists
- [ ] Settings work in both light and dark modes

### Edge Cases
- [ ] Profile update with network disconnected
- [ ] Very long names (50+ chars)
- [ ] Special characters in names (emoji, unicode)
- [ ] Rapid theme switching
- [ ] App restart preserves all preferences
- [ ] Multiple users on same device (different preferences)

---

## 🚧 Out of Scope (Future Sprints)

These features are NOT included in Sprint #2:

- ❌ Email address change
- ❌ Password reset
- ❌ Profile photo upload
- ❌ Account deletion (already implemented in Sprint #1)
- ❌ Notification preferences
- ❌ Export data
- ❌ Language selection
- ❌ Accessibility settings beyond font size
- ❌ Theme customization (color picker)

---

## 📊 Success Criteria

Sprint #2 is complete when:

1. ✅ Users can edit their first and last name
2. ✅ Name changes save to Supabase and persist
3. ✅ Users can choose Light/Dark/System theme
4. ✅ Users can adjust font size (4 sizes)
5. ✅ All preferences save to UserDefaults
6. ✅ Preferences persist across app launches
7. ✅ All UI follows Sprint #1 card-based design
8. ✅ All error states handled gracefully
9. ✅ All testing checklist items pass
10. ✅ Code is documented and follows existing patterns

---

## 🔗 Dependencies

### Existing Services (Already Available)
- ✅ `AuthViewModel.updateProfile()` - Updates user metadata
- ✅ `AuthViewModel.currentUser` - Current user data
- ✅ `SupabaseService.updateUserMetadata()` - Backend update

### New Services (To Be Created)
- ⚠️ `PreferencesService` - UserDefaults wrapper for app preferences

### Existing Components (Can Reuse)
- ✅ `SettingsRow` - Navigation rows
- ✅ `AppTextField` - Text input fields
- ✅ `PrimaryButton` - Action buttons

### New Components (To Be Created)
- ⚠️ None - Will use existing components

---

## 📈 Implementation Order

### Day 1: Profile Settings (4-6 hours)
1. Create `PreferencesService.swift` (foundation for both features)
2. Create `ProfileSettingsView.swift`
3. Update `SettingsView.swift` to add Profile row
4. Update `ContentView.swift` navigation
5. Test profile update flow

### Day 2: Appearance Settings (4-6 hours)
1. Create `AppearanceSettingsView.swift`
2. Update `Theme.swift` ThemeProvider
3. Update `SettingsView.swift` to add Appearance section
4. Update `ContentView.swift` navigation
5. Test theme switching

### Day 3: Polish & Testing (2-4 hours)
1. Add font size support (optional - can defer)
2. Handle edge cases
3. Test on different devices/simulators
4. Fix bugs and refine UX
5. Update documentation

---

## 🎯 Key Decisions Needed

Before implementing, please confirm:

1. **Font Size Feature:** Include in Sprint #2 or defer to later?
   - If included: Adds ~2 hours, affects Typography.swift
   - If deferred: Sprint #2 is simpler, can add later

2. **Theme Persistence:** UserDefaults or Supabase?
   - UserDefaults: ✅ Faster, ✅ Works offline, ❌ Not synced across devices
   - Supabase: ❌ Slower, ❌ Requires internet, ✅ Synced across devices
   - **Recommendation:** UserDefaults for Sprint #2 (can migrate later)

3. **Profile Photo:** Should Profile Settings include photo upload?
   - ❌ Recommended to defer - adds complexity (image picker, upload, storage)
   - Can add in Sprint #3 or later

---

**Ready for Review** - Please confirm requirements before implementation begins!
