-- Disable Email Confirmation Requirement
-- Run these commands in your Supabase SQL editor

-- Method 1: Try to disable email confirmation via SQL
-- Note: This might not work if the table doesn't exist, but worth trying
UPDATE auth.config SET email_confirm_required = false WHERE id = 1;

-- Method 2: Alternative approach - update auth.users directly
-- This will mark existing users as confirmed
UPDATE auth.users SET email_confirmed_at = created_at WHERE email_confirmed_at IS NULL;

-- Method 3: Create a function to auto-confirm new users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  -- Auto-confirm the user
  UPDATE auth.users 
  SET email_confirmed_at = NOW() 
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-confirm new users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user(); 