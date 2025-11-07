-- Fix Auth Users Table
-- This will check and fix issues with auth.users table

-- 1. Check current users in auth.users table
SELECT 
    id,
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data,
    raw_app_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;

-- 2. Check if there are any users in public.user but not in auth.users
SELECT 
    u.email,
    u.name,
    u.created_at,
    CASE 
        WHEN au.email IS NOT NULL THEN 'Exists in auth.users'
        ELSE 'Missing from auth.users'
    END as auth_status
FROM public.user u
LEFT JOIN auth.users au ON u.email = au.email
ORDER BY u.created_at DESC
LIMIT 10;

-- 3. Check recent registration attempts
SELECT 
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 4. If users are missing from auth.users, create them
-- (Only run this if you see users in public.user but not in auth.users)
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
)
SELECT 
    gen_random_uuid() as id,
    u.email,
    crypt('temp_password', gen_salt('bf')) as encrypted_password,
    u.created_at as email_confirmed_at,
    u.created_at,
    u.created_at as updated_at,
    '{"provider": "email", "providers": ["email"]}'::jsonb as raw_app_meta_data,
    '{"name": "' || u.name || '", "username": "' || u.name || '"}'::jsonb as raw_user_meta_data,
    false as is_super_admin,
    u.created_at as confirmed_at
FROM public.user u
WHERE u.email NOT IN (SELECT email FROM auth.users)
ON CONFLICT (email) DO NOTHING;
*/

-- 5. Check email confirmation settings
-- This will show if email confirmation is properly configured
SELECT 
    'Email confirmation status check' as info,
    COUNT(*) as total_users,
    COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
    COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users; 