-- Comprehensive RLS Policies Fix
-- Run these commands in your Supabase SQL editor

-- 1. Fix user table - allow public client to read user data
CREATE POLICY "Allow public client to read user data" ON "user" 
FOR SELECT USING (true);

-- 2. Fix user_activity table - allow inserts and reads
CREATE POLICY "Allow unconfirmed users to insert user_activity" ON "user_activity" 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select user_activity" ON "user_activity" 
FOR SELECT USING (true);

-- 3. Fix notes table - allow inserts and reads
CREATE POLICY "Allow unconfirmed users to insert notes" ON "notes" 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select notes" ON "notes" 
FOR SELECT USING (true);

CREATE POLICY "Allow unconfirmed users to update notes" ON "notes" 
FOR UPDATE USING (true);

CREATE POLICY "Allow unconfirmed users to delete notes" ON "notes" 
FOR DELETE USING (true);

-- 4. Fix daily_shredded_thoughts table - allow inserts and reads
CREATE POLICY "Allow unconfirmed users to insert daily_shredded_thoughts" ON "daily_shredded_thoughts" 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select daily_shredded_thoughts" ON "daily_shredded_thoughts" 
FOR SELECT USING (true);

CREATE POLICY "Allow unconfirmed users to update daily_shredded_thoughts" ON "daily_shredded_thoughts" 
FOR UPDATE USING (true);

-- 5. Fix mind_tools_daily_activity table - allow inserts and reads
CREATE POLICY "Allow unconfirmed users to insert mind_tools_daily_activity" ON "mind_tools_daily_activity" 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select mind_tools_daily_activity" ON "mind_tools_daily_activity" 
FOR SELECT USING (true);

CREATE POLICY "Allow unconfirmed users to update mind_tools_daily_activity" ON "mind_tools_daily_activity" 
FOR UPDATE USING (true);

-- 6. Fix annual_calendar_tasks table - allow inserts and reads
CREATE POLICY "Allow unconfirmed users to insert annual_calendar_tasks" ON "annual_calendar_tasks" 
FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow unconfirmed users to select annual_calendar_tasks" ON "annual_calendar_tasks" 
FOR SELECT USING (true);

CREATE POLICY "Allow unconfirmed users to update annual_calendar_tasks" ON "annual_calendar_tasks" 
FOR UPDATE USING (true);

CREATE POLICY "Allow unconfirmed users to delete annual_calendar_tasks" ON "annual_calendar_tasks" 
FOR DELETE USING (true); 