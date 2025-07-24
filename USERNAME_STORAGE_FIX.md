# Username Storage Fix Guide

## Problem
The username is not being stored properly in the `public.user` table's `name` column during registration.

## Root Cause
The database trigger function was not properly extracting the username from the user metadata, and there was insufficient fallback logic.

## Solution

### Step 1: Update Database Trigger Function

Run the updated SQL from `supabase_config_for_existing_website.sql` in your Supabase SQL Editor. This includes:

1. **Better username extraction logic** with multiple fallbacks
2. **Debug logging** to track username extraction
3. **Improved error handling**

### Step 2: Test Current Username Storage

Run the diagnostic queries from `test_username_storage.sql`:

```sql
-- Check current username storage status
SELECT 
  email,
  name,
  CASE 
    WHEN name IS NULL OR name = '' THEN '❌ No Name'
    WHEN name = 'User' THEN '⚠️ Default Name'
    ELSE '✅ Has Name'
  END as name_status,
  created_at
FROM public.user 
ORDER BY created_at DESC 
LIMIT 10;
```

### Step 3: Fix Existing Users (if needed)

If you have existing users with missing names, run this to fix them:

```sql
-- Fix users with missing names
UPDATE public.user 
SET name = split_part(email, '@', 1)
WHERE name IS NULL OR name = '' OR name = 'User';
```

### Step 4: Test New Registration

1. **Register a new user** in your Flutter app
2. **Check the logs** for the debug messages:
   - "SupabaseDatabaseService: Registering user with username: [username]"
   - "SupabaseDatabaseService: User metadata: [metadata]"
3. **Verify email** using your PHP verification page
4. **Check the database** to see if the username was stored correctly

### Step 5: Verify the Fix

After email verification, run this query to check if the username was stored:

```sql
-- Check the most recent user
SELECT 
  email,
  name,
  email_verified,
  created_at,
  CASE 
    WHEN name IS NULL OR name = '' THEN '❌ No Name'
    WHEN name = 'User' THEN '⚠️ Default Name'
    ELSE '✅ Has Name'
  END as name_status
FROM public.user 
ORDER BY created_at DESC 
LIMIT 1;
```

## What Was Fixed

### 1. Enhanced Username Extraction
The trigger function now uses this improved logic:
```sql
user_name := COALESCE(
  NEW.raw_user_meta_data->>'name',
  NEW.raw_user_meta_data->>'username',
  NEW.raw_user_meta_data->>'display_name',
  split_part(NEW.email, '@', 1), -- Use email prefix as fallback
  'User'
);
```

### 2. Added Debug Logging
The trigger now logs:
- When it's creating a user record
- What username was extracted
- When the record is created successfully

### 3. Better Metadata Handling
The Flutter app now sends:
- `username`
- `name` 
- `display_name`

All with the same value for maximum compatibility.

### 4. Improved Error Handling
The trigger function now has better error handling and will use email prefix as a fallback if no username is found in metadata.

## Testing Steps

1. **Run the updated SQL** in Supabase
2. **Register a new test user** with a clear username (e.g., "TestUser123")
3. **Check the logs** in your Flutter app console
4. **Verify the email** using your PHP page
5. **Check the database** to confirm the username was stored
6. **Try logging in** with the new user

## Expected Results

After the fix:
- ✅ Username should be stored in the `name` column
- ✅ No more "User" as default name
- ✅ Email prefix used as fallback if username is missing
- ✅ Debug logs show username extraction process

## Troubleshooting

### Issue 1: Still seeing "User" as name
- Check if the trigger function was updated correctly
- Verify the user metadata contains the username
- Check the debug logs in Supabase

### Issue 2: Name is still null/empty
- Run the fix query for existing users
- Check if email verification completed successfully
- Verify the trigger fired correctly

### Issue 3: Debug logs not showing
- Check if the trigger function has the RAISE NOTICE statements
- Verify the function was created with SECURITY DEFINER

## Verification Commands

Run these in Supabase SQL Editor to verify everything is working:

```sql
-- Check trigger function exists
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name = 'handle_email_verification' 
AND routine_schema = 'public';

-- Check recent users
SELECT 
  email,
  name,
  email_verified,
  created_at
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5;

-- Check auth.users metadata
SELECT 
  email,
  raw_user_meta_data->>'username' as username,
  raw_user_meta_data->>'name' as name,
  email_confirmed_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;
```

## Summary

The fix ensures that:
1. **Usernames are properly extracted** from user metadata
2. **Multiple fallback options** are available
3. **Debug logging** helps track the process
4. **Existing users** can be fixed if needed
5. **New registrations** will work correctly

After implementing this fix, all new user registrations should properly store the username in the `name` column of the `public.user` table. 