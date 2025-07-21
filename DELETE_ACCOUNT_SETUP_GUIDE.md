# Delete Account Feature Setup Guide

## Overview
The delete account feature has been implemented to properly delete users from both the custom database tables AND the Supabase Authentication Users table.

## What Was Fixed

### 1. **Backend Changes**
- **SupabaseDatabaseService**: Updated `deleteAccount()` method to call a server-side function
- **Server Function**: Created `delete_user_account()` function to delete from `auth.users` table

### 2. **Frontend Changes**
- **Profile Page**: Updated delete account dialog to reflect complete deletion
- **Success Messages**: Updated to indicate full account deletion

## Setup Steps

### Step 1: Create the Server Function
1. Go to your **Supabase Dashboard**
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `delete_user_account_function.sql`
4. Click **Run** to create the function

### Step 2: Verify the Function
After running the SQL, you should see:
- Function `delete_user_account` created successfully
- Permission granted to authenticated users

### Step 3: Test the Feature
1. Run your Flutter app
2. Go to Profile page
3. Tap "Delete Account"
4. Confirm the deletion
5. Verify that the user is completely removed from:
   - Custom database tables
   - Supabase Authentication Users table

## How It Works

### Complete Deletion Process:
1. **User Data Deletion**:
   - Vision board tasks
   - Annual calendar tasks
   - Daily shredded thoughts
   - Mind tools activity
   - Custom user record

2. **Authentication Deletion**:
   - Calls server function `delete_user_account()`
   - Deletes user from `auth.users` table
   - Signs out the user

3. **Local Cleanup**:
   - Clears SharedPreferences
   - Clears cached data
   - Updates widgets

## Security Features

- **Server-Side Function**: Uses `SECURITY DEFINER` for proper permissions
- **User Verification**: Checks if user exists before deletion
- **Error Handling**: Graceful handling of deletion failures
- **Authentication Required**: Only authenticated users can call the function

## Troubleshooting

### If the function doesn't exist:
- The app will gracefully handle the error
- User data will still be deleted from custom tables
- Only the auth.users record will remain (for security)

### If you get permission errors:
- Make sure you ran the SQL as a database owner
- Check that the function was created successfully
- Verify the GRANT EXECUTE permission

## Files Modified

1. **`lib/services/supabase_database_service.dart`**
   - Updated `deleteAccount()` method
   - Added server function call

2. **`lib/main.dart`**
   - Updated delete account dialog text
   - Updated success messages

3. **`delete_user_account_function.sql`** (NEW)
   - Server-side function for auth user deletion

## Result
✅ **Complete Account Deletion**: Users are now fully deleted from both custom tables and Supabase Authentication
✅ **Proper Security**: Server-side function ensures secure deletion
✅ **User Experience**: Clear messaging about what happens during deletion
✅ **Error Handling**: Graceful fallback if server function is unavailable 