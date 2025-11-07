-- Temporarily Disable Email Confirmation
-- This allows users to register without email confirmation while email service is fixed

-- 1. Disable email confirmation requirement
UPDATE auth.config SET email_confirm_required = false WHERE id = 1;

-- 2. Mark all existing unconfirmed users as confirmed
UPDATE auth.users 
SET email_confirmed_at = created_at 
WHERE email_confirmed_at IS NULL;

-- 3. Create auth records for users who exist in user table but not in auth.users
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

-- 4. Check current status
SELECT 
    'Email confirmation' as setting,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM auth.config 
            WHERE email_confirm_required = false
        ) THEN 'Disabled'
        ELSE 'Enabled'
    END as status;

-- 5. Show recent users and their status
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

-- Note: To re-enable email confirmation later, run:
-- UPDATE auth.config SET email_confirm_required = true WHERE id = 1; 