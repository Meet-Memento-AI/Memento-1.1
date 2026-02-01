# Fonts Directory

This directory contains custom font files for the MeetMemento app.

## Installed Fonts

### Manrope (Default — app-wide) ✅
- **Manrope-Regular.ttf** - Body text, captions, micro
- **Manrope-Medium.ttf** - Labels, buttons, emphasized body
- **Manrope-Bold.ttf** - All headings (h1–h6), bold body, buttons

Default typography uses Manrope for all text. See `Typography.swift`.

### Lora (Onboarding only) ✅
- **Lora-Regular.ttf** - Body text on onboarding
- **Lora-Medium.ttf** - Emphasized body on onboarding
- **Lora-SemiBold.ttf** - Headings on onboarding
- **Lora-Bold.ttf** - Bold body on onboarding

Use `Typography.onboarding` (e.g. on WelcomeView and onboarding flow) to get Lora Serif.

### Sora (optional / legacy)
- Sora font files may remain in the bundle for reference but are not used by default typography.

## Installation Steps

✅ **Font files are in place!** Add them to Xcode and ensure Info.plist UIAppFonts includes:
- Manrope-Regular, Manrope-Medium, Manrope-Bold
- Lora-Regular, Lora-Medium, Lora-SemiBold, Lora-Bold

## Font PostScript Names (Typography.swift)

**Default (Manrope):**
- `Manrope-Bold` (h1–h5)
- `Manrope-Regular`, `Manrope-Medium`, `Manrope-Bold` (body, caption, micro, h6)

**Onboarding (Lora):**
- `Lora-SemiBold` (h1–h5)
- `Lora-Regular`, `Lora-Medium`, `Lora-Bold` (body, caption, micro, h6)

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
