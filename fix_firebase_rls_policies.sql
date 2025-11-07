-- Fix RLS policies for Firebase authentication
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

-- For Firebase authentication, we need more permissive policies
-- Since Firebase users don't have Supabase auth context, we'll allow public access for now

-- Option 1: Disable RLS temporarily (recommended for development)
ALTER TABLE "user" DISABLE ROW LEVEL SECURITY;

-- Option 2: Create permissive policies for Firebase users (alternative)
-- CREATE POLICY "Allow public insert for user registration" ON "user"
-- FOR INSERT 
-- TO public
-- WITH CHECK (true);

-- CREATE POLICY "Allow public select for user data" ON "user"
-- FOR SELECT 
-- TO public
-- USING (true);

-- CREATE POLICY "Allow public update for user data" ON "user"
-- FOR UPDATE 
-- TO public
-- USING (true)
-- WITH CHECK (true);

-- Also create a policy that allows service role to manage all data
CREATE POLICY "Service role can manage all data" ON "user"
FOR ALL 
TO service_role
USING (true)
WITH CHECK (true);

-- Verify the policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE tablename = 'user';

-- Verify RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'user'; 