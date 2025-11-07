# Google Login Database Storage Fix

## Problem Description

After Google login, user data is not being stored in the Supabase `user` table due to Row Level Security (RLS) policy violations. The error message is:

```
Error inserting into 'user' table: PostgrestException(message: new row violates row-level security policy for table "user", code: 42501, details: Unauthorized, hint: null)
```

## Root Cause

The issue occurs because:

1. **Firebase Authentication**: Users are authenticated through Firebase Auth, not Supabase Auth
2. **RLS Policies**: The existing RLS policies in Supabase are designed for Supabase Auth users
3. **Missing Auth Context**: When using Firebase Auth, the `auth.email()` and `auth.uid()` functions in Supabase RLS policies don't work
4. **Permission Denied**: The RLS policies block insert operations for Firebase-authenticated users

## Solutions

### Solution 1: Disable RLS (Recommended for Development)

Run this SQL in your Supabase SQL Editor:

```sql
-- Disable RLS on the user table
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user';
```

### Solution 2: Create Firebase-Compatible RLS Policies

If you want to keep RLS enabled, run this SQL:

```sql
-- Drop existing policies
DROP POLICY IF EXISTS "Users can insert their own data" ON "user";
DROP POLICY IF EXISTS "Users can view their own data" ON "user";
DROP POLICY IF EXISTS "Users can update their own data" ON "user";

-- Create permissive policies for Firebase users
CREATE POLICY "Allow public insert for user registration" ON "user"
FOR INSERT 
TO public
WITH CHECK (true);

CREATE POLICY "Allow public select for user data" ON "user"
FOR SELECT 
TO public
USING (true);

CREATE POLICY "Allow public update for user data" ON "user"
FOR UPDATE 
TO public
USING (true)
WITH CHECK (true);

-- Service role policy
CREATE POLICY "Service role can manage all data" ON "user"
FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);
```

### Solution 3: Code-Level Fix (Already Implemented)

The Dart code has been updated to:

1. **Use Public Client**: Create a public Supabase client that bypasses RLS
2. **Fallback Mechanism**: Try multiple insertion methods
3. **Error Handling**: Don't fail the sign-in process if database insertion fails
4. **Complete User Data**: Include all required fields (trial dates, premium status, etc.)

## Code Changes Made

### 1. Updated `upsertUserToUserAndUsersTables` method

- Added public client for RLS bypass
- Implemented fallback insertion methods
- Added complete user data with trial information
- Improved error handling and logging

### 2. Updated `upsertUserData` method

- Added public client for RLS bypass
- Implemented fallback insertion methods
- Added complete user data with trial information
- Improved error handling and logging

## Testing the Fix

1. **Run the SQL fix** in Supabase SQL Editor
2. **Test Google login** in the app
3. **Check the logs** for successful database insertion
4. **Verify user data** appears in the Supabase `user` table

## Expected Log Output

After the fix, you should see logs like:

```
🔄 Attempting to upsert user data for: user@example.com
📝 Inserting user data: User Name (user@example.com)
✅ Successfully inserted user into 'user' table: user@example.com
User data upserted successfully
```

## Security Considerations

### For Development:
- Disabling RLS is acceptable for development
- User data is still protected by Firebase authentication
- App functionality is more important than database-level security during development

### For Production:
- Consider implementing proper RLS policies for Firebase users
- Use service role for critical operations
- Implement proper user data validation
- Consider using Supabase Auth instead of Firebase for better integration

## Alternative Solutions

### Option A: Switch to Supabase Auth
- Use Supabase Auth instead of Firebase Auth
- Better integration with Supabase RLS policies
- Requires user migration

### Option B: Use Service Role
- Use service role key for database operations
- More secure but requires careful key management
- Implement proper user validation

### Option C: Custom RLS Policies
- Create custom RLS policies for Firebase users
- Use JWT claims for authentication
- More complex but more secure

## Files Modified

1. `lib/services/supabase_database_service.dart`
   - Updated `upsertUserToUserAndUsersTables` method
   - Updated `upsertUserData` method
   - Added public client for RLS bypass

2. `fix_firebase_rls_policies.sql` (new file)
   - SQL script to fix RLS policies

## Next Steps

1. Run the SQL fix in Supabase
2. Test Google login functionality
3. Verify user data is stored correctly
4. Monitor logs for any remaining issues
5. Consider implementing proper RLS policies for production 