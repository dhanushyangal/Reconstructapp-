-- Email Confirmation Trigger
-- This creates user records automatically when email is confirmed

-- 1. Create function to handle email confirmation
CREATE OR REPLACE FUNCTION public.handle_email_confirmation()
RETURNS trigger AS $$
BEGIN
  -- Only create user record when email is confirmed
  IF NEW.email_confirmed_at IS NOT NULL AND OLD.email_confirmed_at IS NULL THEN
    -- Insert user record into public.user table
    INSERT INTO public.user (
      name,
      email,
      supabase_uid,
      password_hash,
      welcome_email_sent,
      is_premium,
      trial_start_date,
      trial_end_date,
      created_at
    ) VALUES (
      COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'username', 'User'),
      NEW.email,
      NEW.id,
      'supabase_auth',
      false,
      false,
      CURRENT_DATE,
      CURRENT_DATE + INTERVAL '7 days',
      NOW()
    )
    ON CONFLICT (email) DO NOTHING;
    
    RAISE NOTICE 'User record created for confirmed email: %', NEW.email;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger to watch for email confirmations
DROP TRIGGER IF EXISTS on_email_confirmed ON auth.users;
CREATE TRIGGER on_email_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_email_confirmation();

-- 3. Create trigger for new user registrations (backup)
DROP TRIGGER IF EXISTS on_user_created ON auth.users;
CREATE TRIGGER on_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_email_confirmation();

-- 4. Check current email confirmation status
SELECT 
    email,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Not Confirmed'
        ELSE 'Confirmed'
    END as status,
    raw_user_meta_data->>'name' as name
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Check if user records exist for confirmed users
SELECT 
    au.email,
    au.email_confirmed_at,
    CASE 
        WHEN u.email IS NOT NULL THEN 'User Record Exists'
        ELSE 'No User Record'
    END as user_record_status
FROM auth.users au
LEFT JOIN public.user u ON au.email = u.email
WHERE au.email_confirmed_at IS NOT NULL
ORDER BY au.created_at DESC
LIMIT 5; 