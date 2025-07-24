-- Configure Supabase to work with existing verification website
-- Run this in your Supabase SQL Editor

-- 1. Add email verification columns to user table (if not exists)
ALTER TABLE public.user 
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMP WITH TIME ZONE;

-- 2. Drop any existing triggers that might create user records automatically
DROP TRIGGER IF EXISTS on_email_verification ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_user_created ON auth.users;

-- 3. Create function to handle email verification and user creation
-- This function will ONLY create user records when email is explicitly confirmed
CREATE OR REPLACE FUNCTION handle_email_verification()
RETURNS trigger AS $$
DECLARE
  user_name TEXT;
BEGIN
  -- Only create user record when email_confirmed_at changes from NULL to a timestamp
  -- This ensures user records are only created after explicit email verification
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Check if user record already exists to prevent duplicates
    IF NOT EXISTS (SELECT 1 FROM public.user WHERE email = NEW.email) THEN
      -- Extract username from metadata with better fallback logic
      user_name := COALESCE(
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'username',
        NEW.raw_user_meta_data->>'display_name',
        split_part(NEW.email, '@', 1), -- Use email prefix as fallback
        'User'
      );
      
      -- Log the username extraction for debugging
      RAISE NOTICE 'Creating user record for email: %, extracted name: %', NEW.email, user_name;
      
      -- Insert new user record with trial period
      INSERT INTO public.user (
        name,
        email,
        password_hash,
        firebase_uid,
        welcome_email_sent,
        is_premium,
        trial_start_date,
        trial_end_date,
        email_verified,
        email_verified_at
      ) VALUES (
        user_name,
        NEW.email,
        'supabase_auth',
        NEW.id,
        false,
        false,
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '7 days',
        true,
        NEW.email_confirmed_at
      );
      
      RAISE NOTICE 'User record created successfully for: %', NEW.email;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Create trigger for email verification (only fires when email_confirmed_at is set)
CREATE TRIGGER on_email_verification
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_email_verification();

-- 5. Create function to manually confirm email and create user record
-- This can be called via API when external verification is complete
CREATE OR REPLACE FUNCTION confirm_email_and_create_user(user_email TEXT)
RETURNS JSON AS $$
DECLARE
  auth_user RECORD;
  user_record RECORD;
  user_name TEXT;
  result JSON;
BEGIN
  -- Find the user in auth.users
  SELECT * INTO auth_user 
  FROM auth.users 
  WHERE email = user_email;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User not found in auth.users'
    );
  END IF;
  
  -- Check if user already exists in public.user
  SELECT * INTO user_record 
  FROM public.user 
  WHERE email = user_email;
  
  IF FOUND THEN
    RETURN json_build_object(
      'success', true,
      'message', 'User already exists in public.user table',
      'user_id', user_record.id
    );
  END IF;
  
  -- Update email_confirmed_at in auth.users if not already set
  IF auth_user.email_confirmed_at IS NULL THEN
    UPDATE auth.users 
    SET email_confirmed_at = NOW()
    WHERE email = user_email;
  END IF;
  
  -- Extract username from metadata with better fallback logic
  user_name := COALESCE(
    auth_user.raw_user_meta_data->>'name',
    auth_user.raw_user_meta_data->>'username',
    auth_user.raw_user_meta_data->>'display_name',
    split_part(user_email, '@', 1), -- Use email prefix as fallback
    'User'
  );
  
  -- Create user record in public.user table
  INSERT INTO public.user (
    name,
    email,
    password_hash,
    firebase_uid,
    welcome_email_sent,
    is_premium,
    trial_start_date,
    trial_end_date,
    email_verified,
    email_verified_at
  ) VALUES (
    user_name,
    user_email,
    'supabase_auth',
    auth_user.id,
    false,
    false,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    true,
    COALESCE(auth_user.email_confirmed_at, NOW())
  ) RETURNING * INTO user_record;
  
  RETURN json_build_object(
    'success', true,
    'message', 'Email confirmed and user record created',
    'user_id', user_record.id,
    'email', user_email,
    'name', user_name
  );
  
EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object(
    'success', false,
    'message', 'Error: ' || SQLERRM
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Create RPC endpoint for external verification
-- This allows the PHP page to call this function via API
GRANT EXECUTE ON FUNCTION confirm_email_and_create_user(TEXT) TO anon;
GRANT EXECUTE ON FUNCTION confirm_email_and_create_user(TEXT) TO authenticated;

-- 7. Remove any existing user records that don't have verified emails
-- This ensures only verified users exist in the public.user table
DELETE FROM public.user 
WHERE email_verified = false OR email_verified IS NULL;

-- 8. Update existing verified users to have proper email verification status
UPDATE public.user 
SET 
  email_verified = true,
  email_verified_at = COALESCE(email_verified_at, NOW())
WHERE email_verified IS NULL OR email_verified = false;

-- 9. Check current email verification status
SELECT 
  email,
  name,
  email_verified,
  email_verified_at,
  CASE 
    WHEN email_verified THEN '✅ Verified'
    ELSE '❌ Not Verified'
  END as status
FROM public.user 
ORDER BY created_at DESC 
LIMIT 5;

-- 10. Verification query to check the complete status
SELECT 
  'Current Status' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email_verified THEN 1 END) as verified_users,
  COUNT(CASE WHEN NOT email_verified OR email_verified IS NULL THEN 1 END) as unverified_users
FROM public.user;

-- 11. Debug query to check username storage
SELECT 
  email,
  name,
  CASE 
    WHEN name IS NULL OR name = '' THEN '❌ No Name'
    WHEN name = 'User' THEN '⚠️ Default Name'
    ELSE '✅ Has Name'
  END as name_status,
  created_at
FROM public.user 
ORDER BY created_at DESC 
LIMIT 10; 