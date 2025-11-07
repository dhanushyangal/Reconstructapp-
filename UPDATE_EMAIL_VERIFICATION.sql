-- Update Email Verification for Existing Users
-- This will update users who have confirmed emails but missing verification fields

-- 1. Check which users need email verification update
SELECT 
    u.email,
    u.email_verified,
    u.email_verified_at,
    au.email_confirmed_at,
    CASE 
        WHEN au.email_confirmed_at IS NOT NULL AND (u.email_verified IS NULL OR u.email_verified = false) THEN 'Needs Update'
        WHEN au.email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Already Verified'
    END as status
FROM public.user u
JOIN auth.users au ON u.email = au.email
ORDER BY au.created_at DESC;

-- 2. Update users who have confirmed emails but missing verification
UPDATE public.user 
SET 
    email_verified = true,
    email_verified_at = auth_users.email_confirmed_at
FROM auth.users auth_users
WHERE public.user.email = auth_users.email
AND auth_users.email_confirmed_at IS NOT NULL
AND (public.user.email_verified IS NULL OR public.user.email_verified = false);

-- 3. Check the results after update
SELECT 
    'Updated users count' as info,
    COUNT(*) as updated_count
FROM public.user 
WHERE email_verified = true 
AND email_verified_at IS NOT NULL;

-- 4. Show recent users with verification status
SELECT 
    email,
    name,
    email_verified,
    email_verified_at,
    created_at
FROM public.user 
ORDER BY created_at DESC 
LIMIT 10; 