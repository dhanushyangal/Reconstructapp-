-- Quick Fix: Disable email confirmation temporarily
-- Run this in your Supabase SQL Editor

-- Option 1: Mark all existing users as confirmed
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- Option 2: Check current email confirmation status
SELECT 
    email,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 3;

-- Option 3: Mark specific user as confirmed (replace with actual email)
-- UPDATE auth.users 
-- SET email_confirmed_at = NOW() 
-- WHERE email = 'dhanushyangal1@gmail.com';

-- After testing, you can re-enable email confirmation in Supabase Dashboard:
-- Authentication → Settings → Email Auth → Enable email confirmations 