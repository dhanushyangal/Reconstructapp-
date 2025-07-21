-- Create automatic user record creation trigger
-- Run this in your Supabase SQL Editor

-- 1. Create function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Insert into public.user table when a new user is created in auth.users
  INSERT INTO public.user (
    name,
    email,
    password_hash,
    firebase_uid,
    welcome_email_sent,
    is_premium,
    trial_start_date,
    trial_end_date
  ) VALUES (
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'username', 'User'),
    NEW.email,
    'supabase_auth',
    NEW.id,
    false,
    false,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days'
  );
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- If user already exists, just return
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log error but don't fail the auth signup
    RAISE WARNING 'Error creating user profile: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 3. Verify trigger was created
SELECT trigger_name, event_manipulation, action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
AND event_object_schema = 'auth';

-- 4. Test the function (optional)
-- SELECT public.handle_new_user(); 