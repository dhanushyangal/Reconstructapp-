-- Fix User Table Structure
-- This will check and fix issues with the user table

-- 1. Check the current structure of the user table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if there are any constraint issues
SELECT 
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_name = 'user' 
AND table_schema = 'public';

-- 3. Check recent user records
SELECT 
    email,
    name,
    created_at,
    is_premium,
    trial_start_date,
    trial_end_date
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Check if there are any users in auth.users but not in public.user
SELECT 
    au.email,
    au.created_at as auth_created_at,
    CASE 
        WHEN u.email IS NOT NULL THEN 'Exists in public.user'
        ELSE 'Missing from public.user'
    END as public_user_status
FROM auth.users au
LEFT JOIN public.user u ON au.email = u.email
ORDER BY au.created_at DESC
LIMIT 10;

-- 5. If needed, create missing user records for auth users
-- (Only run this if you see users in auth.users but not in public.user)
/*
INSERT INTO public.user (
    name,
    email,
    password_hash,
    welcome_email_sent,
    is_premium,
    trial_start_date,
    trial_end_date,
    created_at
)
SELECT 
    COALESCE(au.raw_user_meta_data->>'name', au.raw_user_meta_data->>'username', 'User') as name,
    au.email,
    'supabase_auth' as password_hash,
    false as welcome_email_sent,
    false as is_premium,
    CURRENT_DATE as trial_start_date,
    CURRENT_DATE + INTERVAL '7 days' as trial_end_date,
    au.created_at
FROM auth.users au
WHERE au.email NOT IN (SELECT email FROM public.user)
ON CONFLICT (email) DO NOTHING;
*/ 