# Email Configuration Fix Guide

## Current Issue
Registration is working but confirmation emails are not being received.

## Step-by-Step Solution

### Step 1: Check Supabase Email Settings

1. Go to your **Supabase Dashboard**
2. Navigate to **Authentication** → **Settings**
3. Under **Email Auth**, verify:
   - ✅ **Enable email confirmations** is checked
   - ✅ **Enable email change confirmations** is checked
   - ✅ **Double confirm changes** is checked (optional)

### Step 2: Check Email Templates

1. Go to **Authentication** → **Email Templates**
2. Check if **Confirm signup** template exists
3. If not, create it with this content:

**Subject:** Confirm your signup
**Content:**
```
<h2>Confirm your signup</h2>

<p>Follow this link to confirm your user:</p>
<p><a href="{{ .ConfirmationURL }}">Confirm your email address</a></p>
```

### Step 3: Check URL Configuration

1. In **Authentication** → **Settings**
2. Under **URL Configuration**:
   - **Site URL**: Set to your app's URL (e.g., `https://your-app.com`)
   - **Redirect URLs**: Add `com.reconstrect.visionboard://login-callback/`

### Step 4: Check Spam Folder

1. Check your **spam/junk folder**
2. Look for emails from `noreply@supabase.co` or your custom email domain
3. Mark as "Not Spam" if found

### Step 5: Test Email Delivery

1. Try registering with a different email address
2. Use a Gmail account for testing
3. Check if the confirmation email arrives

### Step 6: Alternative - Disable Email Confirmation (Temporary)

If you want to test without email confirmation:

1. Go to **Authentication** → **Settings**
2. Uncheck **Enable email confirmations**
3. Users can now log in immediately after registration

### Step 7: Check Supabase Logs

1. Go to **Logs** → **Auth**
2. Look for email-related errors
3. Check if emails are being sent successfully

## Common Issues and Solutions

### Issue 1: Emails going to spam
- **Solution**: Add `noreply@supabase.co` to your contacts
- **Solution**: Check spam folder regularly

### Issue 2: Wrong redirect URL
- **Solution**: Update redirect URLs in Supabase settings
- **Solution**: Make sure the URL matches your app's scheme

### Issue 3: Email template not configured
- **Solution**: Create the confirmation email template
- **Solution**: Test the template with a sample email

### Issue 4: Supabase email service issues
- **Solution**: Check Supabase status page
- **Solution**: Contact Supabase support if needed

## Testing Steps

1. **Register a new user** with a test email
2. **Check Supabase logs** for email sending status
3. **Check email inbox** (including spam)
4. **Click confirmation link** if email is received
5. **Try logging in** after confirmation

## Emergency Fix (No Email Confirmation)

If you need to test immediately without email confirmation:

```sql
-- Run this in Supabase SQL Editor to disable email confirmation for testing
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;
```

This will mark all users as confirmed without requiring email verification. 