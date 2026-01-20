# UIPlayground Setup Instructions

## ✅ What's Been Done

All showcase files have been created:
- `UIPlayground/ComponentGallery.swift` - Main navigation hub
- `UIPlayground/Showcases/ButtonShowcase.swift`
- `UIPlayground/Showcases/SocialButtonShowcase.swift`
- `UIPlayground/Showcases/JournalCardShowcase.swift`
- `UIPlayground/Showcases/InsightCardShowcase.swift`
- `UIPlayground/Showcases/TabSwitcherShowcase.swift`
- `UIPlayground/Showcases/TopNavShowcase.swift`
- `UIPlayground/Showcases/TextFieldShowcase.swift`
- `UIPlaygroundApp.swift` updated to launch `ComponentGallery`

## 🎯 Setup Steps in Xcode

### Step 1: Create the UIPlayground Target

1. Open `MeetMemento.xcodeproj` in Xcode
2. Click on the project name in the navigator (top of file tree)
3. At the bottom of the targets list, click the **"+"** button
4. Select **iOS → App** → Click **Next**
5. Configure the target:
   - **Product Name**: `UIPlayground`
   - **Team**: (select your team)
   - **Organization Identifier**: `com.sebmendo` (or your identifier)
   - **Bundle Identifier**: `com.sebmendo.MeetMemento.UIPlayground`
   - **Interface**: SwiftUI
   - **Language**: Swift
6. Click **Finish**
7. Select **"Don't Create Git repository"** when prompted

### Step 2: Replace Generated Files

1. **Delete** the auto-generated UIPlayground folder that Xcode created
2. In Finder, navigate to your project folder
3. You should see the `UIPlayground` folder with all showcase files
4. In Xcode, **right-click** on the project navigator → **Add Files to "MeetMemento"**
5. Select the `UIPlayground` folder
6. **IMPORTANT**: Check the following options:
   - ☑️ **Copy items if needed** (UNCHECK THIS - we don't want to copy)
   - ☑️ **Create groups**
   - ☑️ **Add to targets**: Select **UIPlayground** only
7. Click **Add**

### Step 3: Add Shared Components

Now we need to add the shared UI components from MeetMemento to UIPlayground:

1. Select **all files** in `MeetMemento/Components` folder in the navigator
2. Open **File Inspector** (⌥⌘1)
3. Under **Target Membership**, check ☑️ **UIPlayground**

Repeat for these folders/files:
- `MeetMemento/Components/Buttons/` (all .swift files)
- `MeetMemento/Components/Cards/` (all .swift files)
- `MeetMemento/Components/Inputs/` (all .swift files)
- `MeetMemento/Components/Navigation/` (all .swift files)
- `MeetMemento/Resources/Theme.swift`
- `MeetMemento/Resources/Typography.swift`
- `MeetMemento/Extensions/Color+Theme.swift`
- `MeetMemento/Extensions/View+Theme.swift`
- `MeetMemento/Extensions/View+Typography.swift`

### Step 4: Configure Build Settings (Optional - for faster builds)

1. Select **UIPlayground** target
2. Go to **Build Settings** tab
3. Search for "optimization"
4. Under **Swift Compiler - Code Generation**:
   - Set **Optimization Level** to **No Optimization [-Onone]** for Debug

### Step 5: Build and Run!

1. Select **UIPlayground** scheme from the scheme selector (next to the play button)
2. Press **⌘B** to build (should be fast!)
3. Press **⌘R** to run

You should see the Component Gallery with all your UI components! 🎉

## 🎨 Using UIPlayground for UI Development

### Quick Preview Workflow

1. Select **UIPlayground** scheme
2. Open any showcase file (e.g., `ButtonShowcase.swift`)
3. Press **⌥⌘↩** to open Canvas
4. See instant previews without building the full app!

### Adding New Components

1. Create your component in `MeetMemento/Components/`
2. Add it to **UIPlayground** target membership
3. Create a new showcase file in `UIPlayground/Showcases/`
4. Add a link in `ComponentGallery.swift`

### Benefits

- ⚡️ **Fast builds** (3-5 seconds vs 30+ seconds)
- 👁️ **Instant previews** without app overhead
- 🎯 **Focused development** on UI only
- 🔄 **Live updates** see changes immediately

## 📋 Files Added to UIPlayground Target

**Must Include:**
- All UIPlayground/*.swift files
- All UIPlayground/Showcases/*.swift files
- MeetMemento/Components/**/*.swift
- MeetMemento/Resources/Theme.swift
- MeetMemento/Resources/Typography.swift
- MeetMemento/Extensions/Color+Theme.swift
- MeetMemento/Extensions/View+Theme.swift
- MeetMemento/Extensions/View+Typography.swift

**Must Exclude (DO NOT add to UIPlayground):**
- MeetMemento/Services/**
- MeetMemento/ViewModels/**
- MeetMemento/Views/** (except components)
- MeetMementoApp.swift (from main target)
- Any Supabase-related files

## 🐛 Troubleshooting

### "Cannot find 'ComponentGallery' in scope"
- Make sure ComponentGallery.swift is added to UIPlayground target

### "Cannot find type 'PrimaryButton'"
- Select the component file → File Inspector → Check UIPlayground under Target Membership

### "Cannot find 'Theme' in scope"
- Add Theme.swift and View+Theme.swift to UIPlayground target

### Preview still slow
- Make sure you're running the **UIPlayground** scheme, not **MeetMemento**
- Check that Services/ViewModels are NOT included in UIPlayground target

---

**Ready to build beautiful UI components quickly!** 🚀

