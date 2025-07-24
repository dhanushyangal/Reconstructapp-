-- Configure Supabase for web-based email verification
-- Run this in your Supabase SQL Editor

-- 1. Create email verification function
CREATE OR REPLACE FUNCTION handle_email_verification()
RETURNS trigger AS $$
BEGIN
  -- Update user record when email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    UPDATE public.user 
    SET 
      email_verified = true,
      email_verified_at = NEW.email_confirmed_at
    WHERE email = NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger for email verification
DROP TRIGGER IF EXISTS on_email_verification ON auth.users;
CREATE TRIGGER on_email_verification
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_email_verification();

-- 3. Add email verification columns to user table (if not exists)
ALTER TABLE public.user 
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

-- 4. Update existing users to have verified email
UPDATE public.user 
SET 
  email_verified = true,
  email_verified_at = NOW()
WHERE email_verified IS NULL;

-- 5. Check current email verification status
SELECT 
  email,
  email_verified,
  email_verified_at,
  CASE 
    WHEN email_verified THEN '✅ Verified'
    ELSE '❌ Not Verified'
  END as status
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5; 