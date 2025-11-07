-- Quick Auth Users Diagnostic
-- Run this first to identify the issue

-- 1. Check if auth.users table exists and has basic structure
SELECT 
    'Table exists' as check_type,
    EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'auth' 
        AND table_name = 'users'
    ) as result;

-- 2. Check basic columns that should exist
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
AND column_name IN ('id', 'email', 'encrypted_password', 'email_confirmed_at', 'created_at')
ORDER BY column_name;

-- 3. Check if there are any users in the table
SELECT 
    'User count' as check_type,
    COUNT(*) as result
FROM auth.users;

-- 4. Check for any unique constraints that might be causing conflicts
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'auth' 
AND tc.table_name = 'users'
AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY');

-- 5. Check if there are any triggers that might be interfering
SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- 6. Check for any recent errors or issues
SELECT 
    'Recent users' as check_type,
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '24 hours';

-- 7. Check if the email column has any special constraints
SELECT 
    'Email constraints' as check_type,
    column_name,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'auth' 
AND table_name = 'users'
AND column_name = 'email'; 