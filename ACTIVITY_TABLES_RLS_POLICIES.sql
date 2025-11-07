-- RLS Policies for Activity Tables
-- Run these in your Supabase SQL Editor

-- Allow unconfirmed users to insert activity data
CREATE POLICY "Allow unconfirmed users to insert activity" ON "daily_shredded_thoughts"
FOR INSERT WITH CHECK (true);

-- Allow unconfirmed users to select their own activity data
CREATE POLICY "Allow unconfirmed users to select activity" ON "daily_shredded_thoughts"
FOR SELECT USING (auth.email() = email);

-- Allow unconfirmed users to update their own activity data
CREATE POLICY "Allow unconfirmed users to update activity" ON "daily_shredded_thoughts"
FOR UPDATE USING (auth.email() = email);

-- Mind Tools Activity Table Policies
CREATE POLICY "Allow unconfirmed users to insert mind tools" ON "mind_tools_daily_activity"
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select mind tools" ON "mind_tools_daily_activity"
FOR SELECT USING (auth.email() = email);

CREATE POLICY "Allow unconfirmed users to update mind tools" ON "mind_tools_daily_activity"
FOR UPDATE USING (auth.email() = email);

-- Verify policies were created
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename IN ('daily_shredded_thoughts', 'mind_tools_daily_activity', 'user')
ORDER BY tablename, policyname; 