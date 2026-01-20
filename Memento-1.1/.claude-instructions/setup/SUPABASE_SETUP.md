# Supabase Setup Guide

## ✅ Installation Complete

The Supabase Swift SDK (v2.5.1+) has been successfully installed and configured in your project!

## 📦 What Was Installed

- **Package**: `supabase-swift` from GitHub
- **Version**: 2.5.1 or later
- **Product**: Supabase (includes Auth, Database, Storage, Realtime, Functions)

## 🔧 Configuration Steps

### 1. Get Your Supabase Credentials

1. Go to your Supabase project dashboard: https://app.supabase.com
2. Navigate to **Settings** → **API**
3. Copy your:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **Anon/Public Key** (the `anon` `public` key)

### 2. Update Configuration File

Open `MeetMemento/Resources/SupabaseConfig.swift` and replace the placeholder values:

```swift
struct SupabaseConfig {
    static let url = "https://your-project.supabase.co"  // ← Your Project URL
    static let anonKey = "your-anon-key-here"            // ← Your Anon Key
}
```

⚠️ **Security Note**: For production apps, consider using:
- Environment variables
- Secure key storage (Keychain)
- A `.gitignore`d configuration file

### 3. Test the Connection

The `SupabaseService` is already set up as a singleton. You can test it like this:

```swift
import SwiftUI

struct TestSupabaseView: View {
    @State private var message = "Testing..."
    
    var body: some View {
        VStack {
            Text(message)
            Button("Test Supabase") {
                testSupabase()
            }
        }
    }
    
    func testSupabase() {
        Task {
            do {
                // Try to get current user (will fail if not logged in, but tests connection)
                let user = try await SupabaseService.shared.getCurrentUser()
                message = user == nil ? "Connected! (No user logged in)" : "Connected and authenticated!"
            } catch {
                message = "Error: \(error.localizedDescription)"
            }
        }
    }
}
```

## 📚 Available Methods

The `SupabaseService` includes:

### Authentication
- `signIn(email:password:)` - Sign in existing user
- `signUp(email:password:)` - Create new user
- `signOut()` - Sign out current user
- `getCurrentUser()` - Get current authenticated user

### Database & Storage
- Add your custom methods in the marked sections

## 🔍 Verify Installation

To verify that Supabase is properly installed, you should be able to:

1. Build the project without errors ✅
2. Import Supabase in any Swift file:
   ```swift
   import Supabase
   ```
3. See initialization logs in the console when the app launches

## 📖 Documentation

- [Supabase Swift Docs](https://supabase.com/docs/reference/swift)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Supabase Database](https://supabase.com/docs/guides/database)

## 🐛 Troubleshooting

### Build Errors
If you see build errors:
1. Clean build folder: **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. Close and reopen Xcode
3. Verify Package: **File** → **Packages** → **Resolve Package Versions**

### Import Not Working
If `import Supabase` shows an error:
1. Check that the package is listed in **File** → **Packages**
2. Verify target membership in project settings
3. Try resolving packages again

### Runtime Errors
Check the console for the initialization log:
- ✅ `"✅ Supabase client initialized"` - Success!
- ⚠️ `"⚠️ Supabase not configured"` - Update SupabaseConfig.swift

---

## 🗑️ Account Deletion Setup (Required)

To enable complete account deletion functionality, you need to create a database function in Supabase.

### Why is this needed?

The iOS app allows users to delete their accounts. This requires deleting:
1. All user data (journal entries) - ✅ Works automatically
2. The auth account itself - ⚠️ Requires this SQL function

### Setup Instructions:

1. Go to your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste this SQL:

```sql
-- Function to allow users to delete their own account
-- Called from the iOS app when users tap "Delete Account" in Settings
CREATE OR REPLACE FUNCTION delete_user()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delete the authenticated user's account from auth.users
  -- This will cascade and delete all related data due to foreign key constraints
  DELETE FROM auth.users WHERE id = auth.uid();
END;
$$;

-- Grant execute permission to authenticated users only
GRANT EXECUTE ON FUNCTION delete_user() TO authenticated;

-- Add documentation comment
COMMENT ON FUNCTION delete_user() IS 'Allows authenticated users to delete their own account and all associated data';
```

5. Click **Run** or press `Cmd + Enter`
6. Verify success message appears

### How It Works:

- `auth.uid()` ensures users can only delete their own account (security)
- `SECURITY DEFINER` runs with elevated privileges (required for auth table access)
- Deletion cascades to all related data via foreign keys
- Only authenticated users can call this function

### Testing:

After creating the function:
1. Open the app → Settings
2. Tap "Delete Account"
3. Confirm the warning
4. You should see: ✅ Account deleted successfully

### Without This Function:

If you don't create this function, account deletion still works with limitations:
- ✅ All user data (entries, metadata) is deleted
- ✅ User is signed out
- ⚠️ Auth account remains in Supabase (but user can't access data)

The app handles this gracefully without showing errors.

---

**Next Steps**: Update your `SupabaseConfig.swift` with real credentials and start building! 🚀

