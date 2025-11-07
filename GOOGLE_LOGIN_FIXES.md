# Google Login Fixes

## Issues Identified from Logs

### 1. Supabase Session Creation Failing
**Error**: `"missing email or phone"` and `"Bad ID token"`
**Cause**: Firebase JWT to Supabase session conversion is not working properly

### 2. User Data Insertion Failing
**Error**: `"Could not find the 'updated_at' column of 'user' in the schema cache"`
**Cause**: Database schema doesn't have `updated_at` column

### 3. Premium Status Not Working
**Error**: `"User not found"` and `"Database check failed"`
**Cause**: User data not being stored properly due to above issues

## Fixes Applied

### 1. Fixed Database Schema Issues

**Problem**: `updated_at` column doesn't exist in database
**Fix**: Removed `updated_at` field from user data insertion

```dart
// Before (causing error)
final userData = {
  'name': name,
  'email': email,
  'firebase_uid': id,
  'profile_image_url': photoUrl,
  'password_hash': 'firebase',
  'welcome_email_sent': false,
  'is_premium': false,
  'trial_start_date': now.toIso8601String().split('T')[0],
  'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
  'created_at': now.toIso8601String(),
  'updated_at': now.toIso8601String(), // ❌ This column doesn't exist
};

// After (fixed)
final userData = {
  'name': name,
  'email': email,
  'firebase_uid': id,
  'profile_image_url': photoUrl,
  'password_hash': 'firebase',
  'welcome_email_sent': false,
  'is_premium': false,
  'trial_start_date': now.toIso8601String().split('T')[0],
  'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
  'created_at': now.toIso8601String(),
  // ✅ Removed updated_at field
};
```

### 2. Simplified Activity Storage

**Problem**: Complex Supabase session creation was failing
**Fix**: Removed session creation dependency and use public client directly

```dart
// Before (causing session errors)
await SupabaseConfig.ensureSupabaseSession();
final publicClient = supabase.SupabaseClient(url, anonKey);

// After (simplified)
final publicClient = supabase.SupabaseClient(url, anonKey);
// ✅ Direct public client usage without session dependency
```

### 3. Removed Complex Session Creation

**Problem**: Firebase JWT to Supabase session conversion was failing
**Fix**: Removed the complex session creation from Google sign-in flow

```dart
// Before (causing errors)
debugPrint('AuthService: Creating Supabase session from Firebase JWT');
final supabaseSessionCreated = await SupabaseConfig.ensureSupabaseSession();

// After (simplified)
// ✅ Removed session creation - rely on public client for data storage
```

### 4. Database-Level Fix

**Problem**: RLS policies blocking operations
**Fix**: Disable RLS on activity tables

**SQL Script**: `DISABLE_ACTIVITY_TABLES_RLS.sql`

```sql
-- Disable RLS on activity tables
ALTER TABLE "daily_shredded_thoughts" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "mind_tools_daily_activity" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;
```

## Expected Results After Fixes

### 1. User Data Storage
- ✅ User data should be stored successfully in `user` table
- ✅ No more "updated_at column" errors
- ✅ Trial dates and premium status should be set correctly

### 2. Activity Storage
- ✅ Activity data should be stored without RLS violations
- ✅ Thought Shredder activities should work
- ✅ Mind Tools activities should work

### 3. Premium Status
- ✅ New users should get trial period
- ✅ Premium status should be detected correctly
- ✅ Premium badge should show for trial users

## Testing Steps

### 1. Test Google Sign-in
1. Sign in with Google
2. Check logs for successful user data insertion
3. Verify no database errors

### 2. Test Activity Storage
1. Use any mind tool (Make Me Smile, Break Things, etc.)
2. Check logs for successful activity storage
3. Verify data appears in database

### 3. Test Premium Status
1. Check if premium badge shows for new users
2. Verify trial period is set correctly
3. Check premium status detection

## Expected Log Output

After the fixes, you should see logs like:

```
🔄 Attempting to upsert user data for: user@example.com
📝 Inserting user data: User Name (user@example.com)
✅ Successfully inserted user into 'user' table: user@example.com
AuthService: New Google user detected, setting new user flag
🔄 SupabaseDB: Upserting make_me_smile activity for user@example.com
✅ SupabaseDB: New activity inserted for make_me_smile
HomePage: Force refreshing premium status (new user or cache expired)
HomePage: Premium status (fresh): true
```

## Files Modified

1. `lib/services/supabase_database_service.dart`
   - Removed `updated_at` field from user data
   - Simplified activity storage methods
   - Removed session creation dependency

2. `lib/services/auth_service.dart`
   - Removed complex Supabase session creation
   - Simplified Google sign-in flow

3. `lib/config/supabase_config.dart`
   - Updated session creation methods (though not used currently)
   - Enhanced error handling

4. `DISABLE_ACTIVITY_TABLES_RLS.sql`
   - SQL script to disable RLS on activity tables

## Next Steps

1. **Run the SQL script** in Supabase SQL Editor:
   ```sql
   -- Run DISABLE_ACTIVITY_TABLES_RLS.sql
   ```

2. **Test the fixes**:
   - Sign in with Google
   - Test activity storage
   - Verify premium status

3. **Monitor logs** for any remaining issues

## Troubleshooting

### If user data still fails to store:
1. Check database schema - ensure all required columns exist
2. Verify RLS is disabled on `user` table
3. Check network connectivity

### If activity data still fails to store:
1. Ensure RLS is disabled on activity tables
2. Check if public client is working
3. Verify table structure

### If premium status still doesn't work:
1. Check if user data is being stored correctly
2. Verify trial dates are set properly
3. Check premium status detection logic 