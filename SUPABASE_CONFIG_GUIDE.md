# Supabase Configuration for Existing Verification Website

## Overview
Your Flutter app will now redirect users to your existing verification page at `https://reconstructyourmind.com/verify-email.php` after registration.

## Step-by-Step Configuration

### Step 1: Configure Supabase Authentication Settings

1. **Go to Supabase Dashboard** → **Authentication** → **Settings**

2. **Enable Email Confirmations** ✅
   - Check "Enable email confirmations"
   - Check "Enable email change confirmations"

3. **Set Site URL**
   - Set to: `https://reconstructyourmind.com`

4. **Add Redirect URLs**
   - `https://reconstructyourmind.com/verify-email.php`
   - `com.reconstrect.visionboard://login-callback/`

### Step 2: Run Database Configuration

Go to **SQL Editor** and run the SQL from `supabase_config_for_existing_website.sql`:

```sql
-- This will:
-- 1. Add email verification tracking columns
-- 2. Create email verification trigger
-- 3. Update existing users as verified
-- 4. Show current verification status
```

### Step 3: Update Email Templates (Optional)

1. Go to **Authentication** → **Email Templates**
2. Update **"Confirm signup"** template:

**Subject:** Verify your Reconstruct account

**Content:**
```html
<h2>Welcome to Reconstruct!</h2>
<p>Hi there,</p>
<p>Please click the link below to verify your email address and complete your registration:</p>
<p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
<p>After verification, you can log into the Reconstruct app.</p>
<p>If you didn't create an account, you can safely ignore this email.</p>
<p>Best regards,<br>The Reconstruct Team</p>
```

### Step 4: Test the Flow

1. **Register a new user** in your Flutter app
2. **Check email** for verification link
3. **Click the link** - should redirect to your website
4. **Verify email** on your website
5. **Try logging in** to the Flutter app

## How It Works

### Registration Flow:
1. User registers in Flutter app
2. Supabase sends email with verification link
3. User clicks link → goes to `https://reconstructyourmind.com/verify-email.php`
4. Your website handles verification
5. User can then log into Flutter app

### Database Updates:
- When user verifies email, Supabase updates `auth.users.email_confirmed_at`
- Database trigger automatically updates `public.user.email_verified`
- Flutter app can check verification status

## Troubleshooting

### Issue 1: Email not received
- Check spam folder
- Verify Supabase email settings are enabled
- Check email templates are configured

### Issue 2: Website not loading
- Verify URL is correct: `https://reconstructyourmind.com/verify-email.php`
- Check if website is accessible
- Test the verification page directly

### Issue 3: Verification fails
- Check Supabase logs for errors
- Verify redirect URLs are configured correctly
- Check if your website's verification logic is working

### Issue 4: App can't log in after verification
- Check if user is marked as confirmed in Supabase
- Verify custom user table is updated
- Check AuthService initialization

## Verification Status Check

Run this SQL to check verification status:

```sql
SELECT 
  u.email,
  u.email_verified,
  u.email_verified_at,
  au.email_confirmed_at,
  CASE 
    WHEN u.email_verified THEN '✅ App Verified'
    WHEN au.email_confirmed_at IS NOT NULL THEN '✅ Supabase Verified'
    ELSE '❌ Not Verified'
  END as status
FROM public.user u
LEFT JOIN auth.users au ON u.email = au.email
ORDER BY u.created_at DESC 
LIMIT 10;
```

## Benefits

✅ **Uses your existing website** - No need to create new pages
✅ **Consistent branding** - Matches your website design
✅ **Already working** - Your verification system is proven
✅ **App integration** - Flutter app works seamlessly
✅ **Database tracking** - Track verification status in both systems

## Next Steps

1. **Run the SQL configuration** in Supabase
2. **Test the complete flow** end-to-end
3. **Monitor verification success rates**
4. **Check if users can log in** after verification
5. **Verify database updates** are working correctly 