# Fonts Directory

This directory contains custom font files for the MeetMemento app.

## Installed Fonts

### Recoleta (Headings) ✅
- **Recoleta-Black.otf** - Highest weight, used for all heading styles (h1, h2, h3, h4)
- **Recoleta-Bold.otf** - Alternative bold weight (backup)
- Used for: titleS (20px), titleM (24px), displayL (32px), displayXL (40px)

### Manrope (Body Text) ✅
- **Manrope-Regular.ttf** - For body text and regular weight
- **Manrope-Medium.ttf** - For labels, buttons, and medium weight text
- **Manrope-Bold.ttf** - For bold emphasis and selected states (e.g., TabSwitcher)

## Installation Steps

✅ **Font files are in place!** Now you need to add them to Xcode:

1. **Open Xcode Project**: Open MeetMemento.xcodeproj
2. **Add to Project Bundle**:
   - Right-click on the "Resources/Fonts" folder in Xcode's project navigator
   - Select "Add Files to MeetMemento"
   - Navigate to and select all 5 font files:
     * Recoleta-Black.otf
     * Recoleta-Bold.otf
     * Manrope-Regular.ttf
     * Manrope-Medium.ttf
     * Manrope-Bold.ttf
   - Ensure "Copy items if needed" is **UNCHECKED** (they're already in place)
   - Ensure "Create groups" is selected
   - Ensure the **MeetMemento target** is checked
3. **Verify Info.plist**: Font references are already configured in UIAppFonts array
4. **Build & Test**: Build the project and check FontDebugger to verify fonts loaded

## Font PostScript Names

The Typography.swift system uses these PostScript names:
- `Recoleta-Black` (for H1, H2, H3, H4 - sizes 40px, 32px, 24px, 20px)
- `Manrope-Regular` (for body text)
- `Manrope-Medium` (for labels, buttons, medium weight text)
- `Manrope-Bold` (for bold variants - bodyBold, labelBold, etc.)

If fonts don't load, use FontDebugger to check the actual PostScript names.

## Testing

After adding fonts, test with:
```swift
// Check available fonts
for family in UIFont.familyNames.sorted() {
    print("Family: \(family)")
    for name in UIFont.fontNames(forFamilyName: family) {
        print("  Font: \(name)")
    }
}
```
