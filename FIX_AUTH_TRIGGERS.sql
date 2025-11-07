-- Fix Auth Users Triggers
-- These triggers are causing the 500 error during signup

-- 1. First, let's see what these triggers do
SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users'
ORDER BY trigger_name;

-- 2. Check if any of these triggers are causing errors
-- Let's see the function definitions
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN (
    'handle_email_verification',
    'handle_firebase_user',
    'handle_email_confirmation',
    'handle_new_user'
)
AND routine_schema = 'public';

-- 3. Disable problematic triggers temporarily
-- This will allow user registration to work
DROP TRIGGER IF EXISTS on_email_verification ON auth.users;
DROP TRIGGER IF EXISTS on_firebase_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
DROP TRIGGER IF EXISTS on_new_user_created ON auth.users;

-- 4. Test if user registration works now
-- Try registering a user in your app after running the above

-- 5. If registration works, we can recreate the triggers properly
-- (Only run this after confirming registration works)

-- Recreate only the necessary trigger for email confirmation
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

-- Create only one trigger for email confirmation
CREATE TRIGGER on_email_confirmed_simple
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_email_confirmation_simple();

-- 6. Check if the fix worked
SELECT 
    'Triggers after fix' as check_type,
    COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_schema = 'auth' 
AND event_object_table = 'users'; 