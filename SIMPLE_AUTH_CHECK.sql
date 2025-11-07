-- Simple Auth Users Check
-- Run these queries one by one to diagnose the issue

-- 1. Check if auth.users table exists
SELECT 
    'Table exists' as check_type,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) as result;

-- 2. Check basic columns
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- 3. Check user count
SELECT 
    'User count' as check_type,
    COUNT(*) as result
FROM auth.users;

-- 4. Check recent users
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Check constraints (simplified)
SELECT 
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_schema = 'auth' 
AND table_name = 'users';

-- 6. Check if email already exists
SELECT 
    'Email check' as check_type,
    COUNT(*) as count
FROM auth.users 
WHERE email = 'dhanushyangal2@gmail.com';

-- 7. Check for any triggers
SELECT 
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users'; 