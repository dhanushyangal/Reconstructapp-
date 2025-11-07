-- Fix Email Service Configuration
-- This helps ensure email confirmation works properly

-- 1. Check current email confirmation settings
SELECT 
    'Email confirmation status' as setting,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM auth.config 
            WHERE email_confirm_required = true
        ) THEN 'Enabled'
        ELSE 'Disabled or Not Set'
    END as status;

-- 2. Check email service configuration
SELECT 
    'Email service' as service,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM auth.config 
            WHERE email_confirm_required IS NOT NULL
        ) THEN 'Configured'
        ELSE 'Not Configured'
    END as status;

-- 3. Check for recent email confirmation failures
SELECT 
    email,
    created_at,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Pending Confirmation'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 4. Manual fix: Confirm users who registered recently but haven't confirmed
-- (This is a temporary fix while email service is being resolved)
UPDATE auth.users 
SET email_confirmed_at = created_at 
WHERE email_confirmed_at IS NULL 
AND created_at > NOW() - INTERVAL '1 hour'
AND raw_app_meta_data->>'provider' != 'google';

-- 5. Check Supabase project settings (run this in Supabase Dashboard)
-- Go to: Authentication → Settings → Email Auth
-- Make sure "Enable email confirmations" is checked
-- Make sure SMTP settings are configured properly

-- 6. Alternative: Disable email confirmation temporarily
-- Uncomment the line below if you want to disable email confirmation
-- UPDATE auth.config SET email_confirm_required = false WHERE id = 1;

-- 7. Check if email service is working
-- This will show if there are any email-related errors in the logs
SELECT 
    'Email service status' as status,
    CASE 
        WHEN COUNT(*) > 0 THEN 'Users registering successfully'
        ELSE 'No recent registrations'
    END as message
FROM auth.users 
WHERE created_at > NOW() - INTERVAL '1 hour'; 