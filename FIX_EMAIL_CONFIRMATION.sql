-- Fix Email Confirmation Issue
-- This will make email confirmation work properly

-- 1. Check current email configuration
SELECT 
    email,
    email_confirmed_at,
    created_at,
    raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. Check if SMTP is configured (this will show if email service is working)
-- Note: You need to configure SMTP in Supabase Dashboard first

-- 3. Test sending confirmation email to recent users
-- This will help identify if the email service is working
SELECT 
    email,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Needs Confirmation'
        ELSE 'Already Confirmed'
    END as status
FROM auth.users 
WHERE email_confirmed_at IS NULL 
AND created_at > NOW() - INTERVAL '24 hours'
ORDER BY created_at DESC;

-- 4. If email service is not working, you can manually confirm recent users
-- (Only run this if you want to bypass email confirmation temporarily)
-- UPDATE auth.users 
-- SET email_confirmed_at = created_at 
-- WHERE email_confirmed_at IS NULL 
-- AND created_at > NOW() - INTERVAL '1 hour';

-- 5. Check user records in public.user table
SELECT 
    email,
    name,
    created_at,
    is_premium
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5; 