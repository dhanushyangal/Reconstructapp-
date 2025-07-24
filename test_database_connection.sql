-- Test script to verify database connection and RLS policies
-- Run this in your Supabase SQL Editor

-- 1. Check if RLS is enabled on the user table
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user';

-- 2. Check current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user';

-- 3. Check table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'user' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. Test insert with service role (this should work)
-- Note: This will only work if you're using the service role key
-- You can test this manually in the SQL Editor

-- 5. Check if trigger exists
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 6. Check if the handle_new_user function exists
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user' 
AND routine_schema = 'public';

-- 7. Test the manual function (if it exists)
-- SELECT public.create_user_profile_manual('test_user', 'test@example.com', '00000000-0000-0000-0000-000000000000'); 