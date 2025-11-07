-- Fix Email Confirmation for Firebase Users Only
-- This keeps email confirmation enabled for normal Supabase registration
-- but handles Firebase users who don't need email confirmation

-- 1. Mark existing Firebase users as confirmed (they don't need email confirmation)
UPDATE auth.users 
SET email_confirmed_at = created_at 
WHERE email_confirmed_at IS NULL 
AND raw_app_meta_data->>'provider' = 'google';

-- 2. Create a function to auto-confirm only Firebase users
CREATE OR REPLACE FUNCTION public.handle_firebase_user()
RETURNS trigger AS $$
BEGIN
  -- Only auto-confirm users who signed up with Google/Firebase
  IF NEW.raw_app_meta_data->>'provider' = 'google' THEN
    UPDATE auth.users 
    SET email_confirmed_at = NOW() 
    WHERE id = NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create trigger to auto-confirm only Firebase users
DROP TRIGGER IF EXISTS on_firebase_user_created ON auth.users;
CREATE TRIGGER on_firebase_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_firebase_user();

-- 4. Check current email confirmation status
SELECT 
    email,
    raw_app_meta_data->>'provider' as provider,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5; 