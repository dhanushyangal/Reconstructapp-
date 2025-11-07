-- Check and Fix Auth Users Table
-- This will diagnose the 500 error during signup

-- 1. Check the structure of auth.users table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'auth'
ORDER BY ordinal_position;

-- 2. Check constraints on auth.users table
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    tc.table_name,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'users' 
AND tc.table_schema = 'auth';

-- 3. Check indexes on auth.users table
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'users' 
AND schemaname = 'auth';

-- 4. Check current users in auth.users table
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    raw_app_meta_data,
    is_super_admin,
    confirmed_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Check for any recent failed signup attempts
SELECT 
    'Recent auth.users entries' as info,
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users,
    MIN(created_at) as oldest_user,
    MAX(created_at) as newest_user
FROM auth.users;

-- 6. Check if there are any trigger functions that might be causing issues
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 7. Check for any RLS policies on auth.users (should be none)
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'auth';

-- 8. Check if there are any foreign key constraints that might be failing
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'users'
AND tc.table_schema = 'auth';

-- 9. Check for any recent errors in the database logs
-- (This might not be available in all Supabase instances)
SELECT 
    'Database error check' as info,
    'Check Supabase Dashboard -> Logs for recent errors' as note;

-- 10. Test creating a simple user record (for debugging)
-- (Only run this if you want to test the table structure)
/*
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    confirmed_at
) VALUES (
    gen_random_uuid(),
    'test@example.com',
    crypt('testpassword', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"provider": "email", "providers": ["email"]}'::jsonb,
    '{"name": "Test User"}'::jsonb,
    false,
    NOW()
) ON CONFLICT (email) DO NOTHING;
*/ 