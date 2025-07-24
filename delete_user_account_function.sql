-- Create a server-side function to delete user accounts
-- This function will delete the user from auth.users table
-- Run this in your Supabase SQL Editor

-- Function to delete user account from auth.users table
CREATE OR REPLACE FUNCTION delete_user_account(user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if the user exists
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = user_id) THEN
    RETURN json_build_object(
      'success', false,
      'message', 'User not found'
    );
  END IF;

  -- Delete the user from auth.users table
  DELETE FROM auth.users WHERE id = user_id;

  -- Check if deletion was successful
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Failed to delete user'
    );
  END IF;

  RETURN json_build_object(
    'success', true,
    'message', 'User deleted successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'message', 'Error deleting user: ' || SQLERRM
    );
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account(UUID) TO authenticated;

-- Test the function (optional - remove this line after testing)
-- SELECT delete_user_account('your-user-id-here'); 