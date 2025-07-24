# Registration Fix Setup Instructions

## Problem Summary
The registration process has two main issues:
1. **RLS Policy Violation**: User data is not being stored in the custom `user` table due to Row Level Security policies
2. **Email Confirmation**: Need to add proper email verification flow

## Step-by-Step Fix

### 1. Fix RLS Policies in Supabase

Go to your Supabase Dashboard → SQL Editor and run the following SQL:

```sql
-- Check current policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user';

-- Drop existing policies that might be blocking inserts
DROP POLICY IF EXISTS "Users can insert their own data" ON "user";
DROP POLICY IF EXISTS "Users can view their own data" ON "user";
DROP POLICY IF EXISTS "Users can update their own data" ON "user";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "user";
DROP POLICY IF EXISTS "Enable select for authenticated users only" ON "user";
DROP POLICY IF EXISTS "Enable update for users based on email" ON "user";

-- Create new policies that work with your table structure
-- Policy for INSERT - allow authenticated users to insert their own data
CREATE POLICY "Users can insert their own data" ON "user"
FOR INSERT 
TO authenticated
WITH CHECK (
  auth.email() = email
);

-- Policy for SELECT - allow users to view their own data
CREATE POLICY "Users can view their own data" ON "user"
FOR SELECT 
TO authenticated
USING (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
);

-- Policy for UPDATE - allow users to update their own data
CREATE POLICY "Users can update their own data" ON "user"
FOR UPDATE 
TO authenticated
USING (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
)
WITH CHECK (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
);

-- Also create a policy that allows service role to insert (for admin operations)
CREATE POLICY "Service role can manage all data" ON "user"
FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user';
```

### 2. Create Database Trigger (Optional but Recommended)

Run this SQL to create a trigger that automatically creates user records:

```sql
-- Create a function that will be called by the trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user (
    name,
    email,
    password_hash,
    firebase_uid,
    welcome_email_sent,
    is_premium,
    trial_start_date,
    trial_end_date
  ) VALUES (
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'username', 'User'),
    NEW.email,
    'supabase_auth',
    NEW.id,
    false,
    false,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on the auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

### 3. Enable Email Confirmation in Supabase

1. Go to Supabase Dashboard → Authentication → Settings
2. Enable "Enable email confirmations"
3. Set "Secure email change" to enabled
4. Configure your email templates if needed

### 4. Test the Registration

1. Run your Flutter app
2. Try to register a new user
3. Check the Supabase Dashboard → Authentication → Users to see if the user was created
4. Check the Supabase Dashboard → Table Editor → user table to see if the user record was created

### 5. Troubleshooting

If you still have issues:

1. **Check RLS is enabled**: Go to Supabase Dashboard → Table Editor → user table → Settings → Enable RLS should be ON
2. **Check policies**: Run the verification query from step 1 to see if policies were created
3. **Check logs**: Go to Supabase Dashboard → Logs to see any errors
4. **Test manually**: Try inserting a record manually in the SQL Editor to see if RLS is blocking it

### 6. Alternative: Disable RLS Temporarily (For Testing Only)

If you want to test without RLS temporarily:

```sql
-- WARNING: Only for testing, disable in production
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;
```

Remember to re-enable it after testing:

```sql
ALTER TABLE "user" ENABLE ROW LEVEL SECURITY;
```

## Expected Behavior After Fix

1. **Registration**: User should be created in both auth.users and public.user tables
2. **Email Confirmation**: User should receive a confirmation email
3. **Login**: User should be able to log in after confirming email
4. **Profile**: User data should display correctly in the app

## Files Modified

- `lib/services/supabase_database_service.dart` - Updated registration logic
- `lib/login/register_page.dart` - Reduced timeout and improved error handling
- `lib/main.dart` - Enhanced profile loading to handle missing user data

## Next Steps

After implementing these fixes:
1. Test registration with a new email
2. Check that user data appears in both tables
3. Verify email confirmation works
4. Test login after email confirmation
5. Check that user profile displays correctly 