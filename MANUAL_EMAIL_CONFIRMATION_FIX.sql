-- Manual Email Confirmation Fix
-- For users who registered during email service failures

-- 1. Check for users who registered but haven't confirmed email
SELECT 
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
WHERE email_confirmed_at IS NULL
ORDER BY created_at DESC;

-- 2. Manually confirm users who registered recently (last 24 hours)
-- This helps users who registered during email service failures
UPDATE auth.users 
SET email_confirmed_at = created_at 
WHERE email_confirmed_at IS NULL 
AND created_at > NOW() - INTERVAL '24 hours';

-- 3. Check for users in the user table who might not have auth records
SELECT 
    email,
    created_at,
    name
FROM "user" 
WHERE email NOT IN (
    SELECT email FROM auth.users
)
ORDER BY created_at DESC;

-- 4. Create auth records for users who exist in user table but not in auth.users
-- This is for users created manually during email service failures
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
    confirmed_at,
    email_change,
    email_change_token_new,
    recovery_token
)
SELECT 
    gen_random_uuid() as id,
    email,
    crypt('temp_password', gen_salt('bf')) as encrypted_password,
    created_at as email_confirmed_at,
    created_at,
    created_at as updated_at,
    '{"provider": "email", "providers": ["email"]}'::jsonb as raw_app_meta_data,
    '{"name": "' || name || '"}'::jsonb as raw_user_meta_data,
    false as is_super_admin,
    created_at as confirmed_at,
    '' as email_change,
    '' as email_change_token_new,
    '' as recovery_token
FROM "user" 
WHERE email NOT IN (
    SELECT email FROM auth.users
)
ON CONFLICT (email) DO NOTHING;

-- 5. Final check - show all users and their status
SELECT 
    u.email,
    u.name,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as auth_status,
    CASE 
        WHEN u.email IS NOT NULL THEN 'User Record Exists'
        ELSE 'No User Record'
    END as user_record_status
FROM auth.users au
LEFT JOIN "user" u ON au.email = u.email
ORDER BY au.created_at DESC
LIMIT 10; 