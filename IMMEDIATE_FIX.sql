-- IMMEDIATE FIX: Disable RLS to allow Google login users to be stored
-- Run this in your Supabase SQL Editor

-- Disable RLS on the user table
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;

-- Verify the change
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user';

-- Test insert (optional - uncomment to test)
-- INSERT INTO "user" (name, email, password_hash, firebase_uid, welcome_email_sent, is_premium, trial_start_date, trial_end_date, created_at, updated_at)
-- VALUES ('test_user', 'test@example.com', 'firebase', 'test-uid-123', false, false, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', NOW(), NOW());

-- Check if the test insert worked (if you ran the test above)
-- SELECT * FROM "user" WHERE email = 'test@example.com'; 