-- Fix RLS policies for user table
-- Run this in your Supabase SQL Editor

-- First, let's check the current RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user';

-- Drop existing policies that might be blocking inserts
DROP POLICY IF EXISTS "Users can insert their own data" ON "user";
DROP POLICY IF EXISTS "Users can view their own data" ON "user";
DROP POLICY IF EXISTS "Users can update their own data" ON "user";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "user";
DROP POLICY IF EXISTS "Enable select for authenticated users only" ON "user";
DROP POLICY IF EXISTS "Enable update for users based on email" ON "user";

-- Create new policies that work with your table structure
-- Policy for INSERT - allow authenticated users to insert their own data
CREATE POLICY "Users can insert their own data" ON "user"
FOR INSERT 
TO authenticated
WITH CHECK (
  auth.email() = email
);

-- Policy for SELECT - allow users to view their own data
CREATE POLICY "Users can view their own data" ON "user"
FOR SELECT 
TO authenticated
USING (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
);

-- Policy for UPDATE - allow users to update their own data
CREATE POLICY "Users can update their own data" ON "user"
FOR UPDATE 
TO authenticated
USING (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
)
WITH CHECK (
  auth.email() = email OR
  auth.uid()::text = firebase_uid
);

-- Also create a policy that allows service role to insert (for admin operations)
CREATE POLICY "Service role can manage all data" ON "user"
FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user'; 