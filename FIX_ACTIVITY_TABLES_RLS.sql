-- Fix RLS policies for activity tables
-- Run this in your Supabase SQL Editor

-- Disable RLS on activity tables to allow data storage
ALTER TABLE "daily_shredded_thoughts" DISABLE ROW LEVEL SECURITY;
ALTER TABLE "mind_tools_daily_activity" DISABLE ROW LEVEL SECURITY;

-- Verify RLS is disabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('daily_shredded_thoughts', 'mind_tools_daily_activity');

-- Test insert (optional - uncomment to test)
-- INSERT INTO "daily_shredded_thoughts" (email, user_name, shred_date, shred_count, created_at, updated_at)
-- VALUES ('test@example.com', 'test_user', CURRENT_DATE, 1, NOW(), NOW());

-- INSERT INTO "mind_tools_daily_activity" (email, user_name, activity_date, tool_type, activity_count, created_at, updated_at)
-- VALUES ('test@example.com', 'test_user', CURRENT_DATE, 'make_me_smile', 1, NOW(), NOW());

-- Check if the test inserts worked (if you ran the tests above)
-- SELECT * FROM "daily_shredded_thoughts" WHERE email = 'test@example.com';
-- SELECT * FROM "mind_tools_daily_activity" WHERE email = 'test@example.com'; 