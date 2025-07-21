# Email Troubleshooting Guide

## Problem: Registration works but no confirmation email received

### Immediate Solutions (Try in Order)

#### Solution 1: Check Spam Folder
1. Open your email client
2. Check **Spam/Junk folder**
3. Look for emails from `noreply@supabase.co`
4. Mark as "Not Spam" if found

#### Solution 2: Disable Email Confirmation (Quick Fix)
1. Go to **Supabase Dashboard** → **Authentication** → **Settings**
2. Uncheck **"Enable email confirmations"**
3. Save changes
4. Users can now log in immediately after registration

#### Solution 3: Mark User as Confirmed (SQL Fix)
Run this in **Supabase SQL Editor**:
```sql
-- Mark all users as confirmed
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- Or mark specific user
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email = 'dhanushyangal1@gmail.com';
```

#### Solution 4: Check Email Templates
1. Go to **Authentication** → **Email Templates**
2. Verify **"Confirm signup"** template exists
3. If missing, create it with:
   - **Subject**: "Confirm your signup"
   - **Content**: 
     ```
     <h2>Confirm your signup</h2>
     <p>Follow this link to confirm your user:</p>
     <p><a href="{{ .ConfirmationURL }}">Confirm your email address</a></p>
     ```

### Advanced Troubleshooting

#### Check Supabase Logs
1. Go to **Logs** → **Auth**
2. Look for email-related errors
3. Check if emails are being sent

#### Test with Different Email
1. Try registering with a **Gmail account**
2. Gmail has better spam filtering
3. Check if confirmation email arrives

#### Verify URL Configuration
1. Go to **Authentication** → **Settings**
2. Under **URL Configuration**:
   - Set **Site URL** to your app's URL
   - Add **Redirect URLs**: `com.reconstrect.visionboard://login-callback/`

#### Check Supabase Status
1. Visit [Supabase Status Page](https://status.supabase.com/)
2. Check if email service is operational
3. Contact Supabase support if needed

### Testing Steps

1. **Run the SQL fix** to mark users as confirmed
2. **Try logging in** with the registered account
3. **Check if user data appears** in the app
4. **Verify user record** exists in the `user` table

### Expected Results After Fix

- ✅ User can log in immediately after registration
- ✅ User data appears in the app
- ✅ User record exists in the custom `user` table
- ✅ No more "waiting for verification" messages

### Re-enabling Email Confirmation (Later)

Once everything works:
1. Go to **Authentication** → **Settings**
2. Check **"Enable email confirmations"**
3. Test with a new user registration
4. Verify confirmation emails are received 