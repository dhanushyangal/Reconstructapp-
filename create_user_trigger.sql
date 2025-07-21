-- Create a database trigger to automatically create user records
-- Run this in your Supabase SQL Editor

-- First, create a function that will be called by the trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create the trigger on the auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Also create a function to manually create user profile if needed
CREATE OR REPLACE FUNCTION public.create_user_profile_manual(
  user_name TEXT,
  user_email TEXT,
  user_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user already exists
  IF EXISTS (SELECT 1 FROM public.user WHERE email = user_email) THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User already exists'
    );
  END IF;
  
  -- Insert user profile
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
    user_name,
    user_email,
    'supabase_auth',
    user_id,
    false,
    false,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days'
  );
  
  RETURN json_build_object(
    'success', true,
    'message', 'User profile created successfully'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error creating user profile: ' || SQLERRM
    );
END;
$$; 