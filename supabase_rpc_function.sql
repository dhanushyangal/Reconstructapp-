-- Create RPC function to bypass RLS for user profile creation
-- This function should be run in the Supabase SQL editor

CREATE OR REPLACE FUNCTION create_user_profile(
  user_name TEXT,
  user_email TEXT,
  user_id UUID,
  trial_start DATE,
  trial_end DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER -- This allows the function to bypass RLS
AS $$
BEGIN
  -- Insert user profile with security definer privileges
  INSERT INTO "user" (
    name,
    email,
    password_hash,
    firebase_uid,
    welcome_email_sent,
    is_premium,
    trial_start_date,
    trial_end_date,
    created_at
  ) VALUES (
    user_name,
    user_email,
    'supabase_auth',
    user_id,
    false,
    false,
    trial_start,
    trial_end,
    NOW()
  );
  
  RETURN json_build_object(
    'success', true,
    'message', 'User profile created successfully'
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION create_user_profile(TEXT, TEXT, UUID, DATE, DATE) TO authenticated; 