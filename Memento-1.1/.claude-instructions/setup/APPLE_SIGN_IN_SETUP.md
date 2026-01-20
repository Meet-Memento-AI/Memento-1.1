# Apple Sign-In Configuration Guide

## Error 1000 Troubleshooting

The error `AuthenticationServices.AuthorizationError error 1000` typically indicates one of these issues:

### 1. **Missing Entitlements** ✅ FIXED
I've created `MeetMemento.entitlements` with the Sign in with Apple capability.

**Next Step in Xcode:**
1. Open `MeetMemento.xcodeproj` in Xcode
2. Select the **MeetMemento** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **Sign in with Apple**
6. Verify the entitlements file is linked

### 2. **Bundle Identifier Not Registered**

**Apple Developer Portal:**
1. Go to https://developer.apple.com/account/
2. **Identifiers** → Select your App ID (`com.sebmendo.MeetMemento`)
3. Enable **Sign in with Apple** capability
4. Click **Configure** next to Sign in with Apple
5. Set it as **Primary App ID** if asked
6. Save

### 3. **Provisioning Profile Issues**

**For Simulator (Development):**
- Simulator testing requires a valid development provisioning profile
- The profile must include Sign in with Apple capability

**Steps:**
1. Xcode → Preferences → Accounts
2. Select your Apple ID
3. Download Manual Profiles (or let Xcode manage automatically)
4. Clean build folder: Product → Clean Build Folder (⌘⇧K)
5. Rebuild

### 4. **Team/Bundle ID Mismatch**

**Verify in Xcode:**
1. Target → **General** tab
2. Check **Bundle Identifier** matches Apple Developer Portal
3. Check **Team** is selected correctly
4. Ensure **Automatically manage signing** is enabled (or manually configured)

### 5. **Supabase Configuration**

**Supabase Dashboard:**
1. Go to Authentication → Providers → Apple
2. Ensure **Enabled** is toggled ON
3. You need EITHER:
   - **Option A (Recommended)**: Services ID setup with JWT
   - **Option B**: Use native iOS Sign-In (what we're using)

For native iOS, Supabase needs to accept Apple ID tokens. Verify:
- Client ID = Your Services ID (e.g., `com.sebmendo.MeetMemento.signin`)
- You have the `.p8` key configured OR using native flow

### 6. **iOS Simulator Limitations**

**Known Issues:**
- Some iOS Simulator versions have bugs with Sign in with Apple
- Try on a **real device** if simulator continues to fail
- Ensure simulator is iOS 13.0+

### 7. **Testing Checklist**

- [ ] Entitlements file exists and is linked to target
- [ ] Sign in with Apple capability added in Xcode
- [ ] Bundle ID registered in Apple Developer Portal
- [ ] Sign in with Apple enabled for App ID
- [ ] Valid development provisioning profile
- [ ] Team selected in Xcode project
- [ ] Supabase Apple provider enabled
- [ ] Testing on iOS 13+ simulator or device

## Error Code Reference

| Code | Meaning | Solution |
|------|---------|----------|
| 1000 | Unknown/Failed | Check all configuration steps above |
| 1001 | Canceled | User tapped "Cancel" - this is normal |
| 1002 | Invalid Response | Check Supabase configuration |
| 1003 | Not Handled | Verify entitlements and capabilities |
| 1004 | Failed | General failure - check all settings |

## Current Implementation

We're using **Native Apple Sign-In** which:
1. Shows Apple's native authentication sheet
2. Obtains an ID token
3. Exchanges the token with Supabase
4. Creates a Supabase session

This is MORE reliable than OAuth web flow because:
- No complex JWT generation needed
- Works entirely within iOS
- No web redirects required
- Better user experience

## Quick Fix Steps

1. **In Xcode:**
   ```
   - Open project
   - Select MeetMemento target
   - Signing & Capabilities → + Capability → Sign in with Apple
   - Ensure Development Team is selected
   - Build and run
   ```

2. **In Apple Developer:**
   ```
   - App IDs → Select your app
   - Enable "Sign in with Apple"
   - Save
   ```

3. **Test:**
   ```
   - Clean build folder (⌘⇧K)
   - Run on simulator or device
   - Tap "Sign in with Apple"
   - Check console for detailed logs
   ```

## Debug Logs

The app now provides detailed logging:
```
🍎 Starting Apple Sign-In...
🔑 Generated nonce: xYz123...
🚀 Performing Apple auth request...
AppleAuthDelegate initialized
[If error] Apple authorization error: [specific error code]
[If success] Apple authorization completed
```

Check Xcode console for these logs to diagnose exactly where the flow is failing.

