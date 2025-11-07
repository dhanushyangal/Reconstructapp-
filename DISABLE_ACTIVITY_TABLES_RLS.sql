-- Disable RLS on activity tables to fix storage issues
-- Run this in your Supabase SQL Editor

-- Disable RLS on activity tables
ALTER TABLE "daily_shredded_thoughts" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "mind_tools_daily_activity" DISABLE ROW LEVEL SECURITY;

-- Also disable RLS on user table to ensure user data can be stored
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('daily_shredded_thoughts', 'mind_tools_daily_activity', 'user');

-- Test inserts (optional - uncomment to test)
-- INSERT INTO "daily_shredded_thoughts" (email, user_name, shred_date, shred_count, created_at)
-- VALUES ('test@example.com', 'test_user', CURRENT_DATE, 1, NOW());

-- INSERT INTO "mind_tools_daily_activity" (email, user_name, activity_date, tool_type, activity_count, created_at)
-- VALUES ('test@example.com', 'test_user', CURRENT_DATE, 'make_me_smile', 1, NOW());

-- INSERT INTO "user" (name, email, firebase_uid, password_hash, welcome_email_sent, is_premium, trial_start_date, trial_end_date, created_at)
-- VALUES ('Test User', 'test@example.com', 'test_firebase_uid', 'firebase', false, false, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', NOW());

-- Check if the test inserts worked (if you ran the tests above)
-- SELECT * FROM "daily_shredded_thoughts" WHERE email = 'test@example.com';
-- SELECT * FROM "mind_tools_daily_activity" WHERE email = 'test@example.com';
-- SELECT * FROM "user" WHERE email = 'test@example.com'; 