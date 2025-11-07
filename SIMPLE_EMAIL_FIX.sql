-- Simple Email Confirmation Fix
-- This fixes the email confirmation issue without complex operations

-- 1. Check current email confirmation status
SELECT 
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. Mark recent users as confirmed (last 24 hours)
UPDATE auth.users 
SET email_confirmed_at = created_at 
WHERE email_confirmed_at IS NULL 
AND created_at > NOW() - INTERVAL '24 hours';

-- 3. Check for users in user table without auth records
SELECT 
    email,
    name,
    created_at
FROM "user" 
WHERE email NOT IN (
    SELECT email FROM auth.users
)
ORDER BY created_at DESC;

-- 4. Create simple auth records for missing users
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
    email,
    crypt('password123', gen_salt('bf')) as encrypted_password,
    created_at as email_confirmed_at,
    created_at,
    created_at as updated_at,
    '{"provider": "email", "providers": ["email"]}'::jsonb as raw_app_meta_data,
    '{"name": "' || name || '"}'::jsonb as raw_user_meta_data,
    false as is_super_admin,
    created_at as confirmed_at
FROM "user" 
WHERE email NOT IN (
    SELECT email FROM auth.users
)
ON CONFLICT (email) DO NOTHING;

-- 5. Final check - show all users
SELECT 
    u.email,
    u.name,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as auth_status
FROM auth.users au
LEFT JOIN "user" u ON au.email = u.email
ORDER BY au.created_at DESC
LIMIT 10; 