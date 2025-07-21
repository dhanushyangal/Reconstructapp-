# Web-Based Email Verification Setup Guide

## Overview
This setup creates a web-based email verification flow where:
1. User registers in the app
2. Receives email with link to your website
3. Clicks link and gets redirected to your website
4. Website verifies the email and shows success page
5. User can then log into the app

## Step-by-Step Setup

### Step 1: Configure Supabase

1. **Go to Supabase Dashboard** → **Authentication** → **Settings**
2. **Enable email confirmations** ✅
3. **Set Site URL** to your website URL (e.g., `https://your-website.com`)
4. **Add Redirect URLs**:
   - `https://your-website.com/verify-email`
   - `com.reconstrect.visionboard://login-callback/`

### Step 2: Run Supabase SQL

Go to **SQL Editor** and run the SQL from `supabase_email_config.sql`:

```sql
-- This will:
-- 1. Create email verification trigger
-- 2. Add email verification columns
-- 3. Update existing users
```

### Step 3: Set Up Your Website

#### Option A: Simple HTML Page
1. Upload `web_verification_page.html` to your website
2. Rename it to `verify-email.html`
3. Update the logo URL and app download links

#### Option B: Full Backend Integration
1. Add the API endpoint from `api_verification_endpoint.js` to your backend
2. Install required dependencies:
   ```bash
   npm install @supabase/supabase-js express
   ```
3. Set environment variables:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

### Step 4: Update Flutter App

The app is already updated to redirect to your website. Just update the URL in `supabase_database_service.dart`:

```dart
emailRedirectTo: 'https://your-website.com/verify-email',
```

### Step 5: Test the Flow

1. **Register a new user** in the app
2. **Check email** for verification link
3. **Click the link** - should open your website
4. **Verify email** on the website
5. **Try logging in** to the app

## File Structure

```
your-website/
├── verify-email.html          # Verification page
├── api/
│   └── verify-email.js        # Backend API (optional)
└── assets/
    └── reconstruct-logo.png   # Your logo

your-flutter-app/
├── lib/services/
│   └── supabase_database_service.dart  # Updated
└── ... (other files)
```

## Customization

### Update Website URLs
- Replace `https://your-website.com` with your actual website URL
- Update logo URL in the HTML file
- Update app download links

### Styling
- Modify the CSS in `web_verification_page.html`
- Match your brand colors and fonts
- Add your logo and branding

### Email Templates
1. Go to **Supabase** → **Authentication** → **Email Templates**
2. Update **"Confirm signup"** template:
   - **Subject**: "Verify your Reconstrect account"
   - **Content**: 
     ```
     <h2>Welcome to Reconstrect!</h2>
     <p>Click the link below to verify your email address:</p>
     <p><a href="{{ .ConfirmationURL }}">Verify Email Address</a></p>
     <p>After verification, you can log into the Reconstrect app.</p>
     ```

## Troubleshooting

### Issue 1: Email not received
- Check spam folder
- Verify Supabase email settings
- Check email templates

### Issue 2: Website not loading
- Verify website URL is correct
- Check if website is accessible
- Test the verification page directly

### Issue 3: Verification fails
- Check Supabase logs
- Verify API endpoint is working
- Check token format

### Issue 4: App can't log in after verification
- Check if user is marked as confirmed in Supabase
- Verify custom user table is updated
- Check AuthService initialization

## Security Considerations

1. **Use HTTPS** for your website
2. **Validate tokens** on the backend
3. **Set proper CORS** headers
4. **Rate limit** verification attempts
5. **Log verification attempts** for monitoring

## Benefits of This Approach

✅ **Better User Experience** - Users see your website
✅ **Brand Consistency** - Matches your website design
✅ **App Promotion** - Can show app download links
✅ **Analytics** - Track verification success rates
✅ **Customization** - Full control over verification flow
✅ **SEO Benefits** - Verification pages are indexed

## Next Steps

1. **Deploy the verification page** to your website
2. **Test the complete flow** end-to-end
3. **Monitor verification success rates**
4. **Add analytics** to track user behavior
5. **Optimize the verification page** based on user feedback 