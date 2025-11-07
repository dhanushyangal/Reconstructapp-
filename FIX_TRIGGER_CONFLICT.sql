-- Fix Trigger Conflict and Update Email Verification
-- This will drop the existing trigger and recreate it with proper email verification

-- 1. Drop the existing trigger first
DROP TRIGGER IF EXISTS on_email_confirmed_simple ON auth.users;

-- 2. Recreate the function with proper email verification
CREATE OR REPLACE FUNCTION public.handle_email_confirmation_simple()
RETURNS trigger AS $$
BEGIN
  -- Only create user record when email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Check if user record already exists
    IF EXISTS (SELECT 1 FROM public.user WHERE email = NEW.email) THEN
      -- Update existing user record with email verification
      UPDATE public.user SET 
        email_verified = true,
        email_verified_at = NEW.email_confirmed_at
      WHERE email = NEW.email;
      
      RAISE NOTICE 'User record updated with email verification: %', NEW.email;
    ELSE
      -- Insert new user record with email verification
      INSERT INTO public.user (
        name,
        email,
        password_hash,
        welcome_email_sent,
        is_premium,
        trial_start_date,
        trial_end_date,
        created_at,
        email_verified,
        email_verified_at
      ) VALUES (
        COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'username', 'User'),
        NEW.email,
        'supabase_auth',
        false,
        false,
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '7 days',
        NOW(),
        true,
        NEW.email_confirmed_at
      )
      ON CONFLICT (email) DO UPDATE SET
        email_verified = true,
        email_verified_at = NEW.email_confirmed_at;
      
      RAISE NOTICE 'User record created/updated with email verification: %', NEW.email;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Create the trigger
CREATE TRIGGER on_email_confirmed_simple
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_email_confirmation_simple();

-- 4. Update existing users who have confirmed emails but missing verification
UPDATE public.user 
SET 
    email_verified = true,
    email_verified_at = auth_users.email_confirmed_at
FROM auth.users auth_users
WHERE public.user.email = auth_users.email
AND auth_users.email_confirmed_at IS NOT NULL
AND (public.user.email_verified IS NULL OR public.user.email_verified = false);

-- 5. Check the results
SELECT 
    'Trigger status' as check_type,
    COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users';

-- 6. Show updated users
SELECT 
    email,
    name,
    email_verified,
    email_verified_at,
    created_at
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5; 