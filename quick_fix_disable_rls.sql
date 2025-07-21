-- Quick Fix: Disable RLS temporarily to fix registration
-- Run this in your Supabase SQL Editor

-- 1. Disable RLS on the user table
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;

-- 2. Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user';

-- 3. Test insert manually (optional - uncomment to test)
-- INSERT INTO "user" (name, email, password_hash, firebase_uid, welcome_email_sent, is_premium, trial_start_date, trial_end_date)
-- VALUES ('test_user', 'test@example.com', 'supabase_auth', '00000000-0000-0000-0000-000000000000', false, false, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days');

-- 4. Check if the insert worked
-- SELECT * FROM "user" WHERE email = 'test@example.com';

-- After testing, you can re-enable RLS with proper policies:
-- ALTER TABLE "user" ENABLE ROW LEVEL SECURITY; 