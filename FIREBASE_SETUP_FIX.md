# Firebase Authentication Fix Guide

## Problem
The error "Requests from this Android client application com.reconstrect.visionboard are blocked" indicates that Firebase Authentication is blocking requests from your Android app.

## Root Cause
This error occurs when:
1. Firebase Authentication is not properly enabled for your Android app
2. SHA-1 fingerprint mismatch between Firebase console and your app
3. Firebase project settings are not correctly configured

## Solution Steps

### 1. Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `recostrect3`
3. Navigate to **Authentication** in the left sidebar
4. Click on **Sign-in method** tab
5. Enable **Email/Password** authentication:
   - Click on **Email/Password**
   - Toggle **Enable** to ON
   - Click **Save**

### 2. Verify SHA-1 Fingerprint

#### For Debug Build:
```bash
cd android
./gradlew signingReport
```

Look for the debug certificate SHA-1 fingerprint in the output.

#### For Release Build:
If you have a release keystore, get its SHA-1:
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

### 3. Update Firebase Console

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Find your Android app: `com.reconstrect.visionboard`
4. Click **Add fingerprint** under **SHA certificate fingerprints**
5. Add the SHA-1 fingerprint from step 2
6. Click **Save**

### 4. Verify Package Name

Ensure the package name in Firebase matches your app:
- Firebase Console: `com.reconstrect.visionboard`
- Your app: `com.reconstrect.visionboard` ✅

### 5. Download Updated Configuration

1. After updating SHA-1, download the updated `google-services.json`
2. Replace the existing file in `android/app/google-services.json`
3. Clean and rebuild your project

### 6. Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### 7. Test Registration

Try registering a new user again. The error should be resolved.

## Alternative Solutions

### Option 1: Use Supabase Auth Instead
If Firebase continues to have issues, you can switch to using Supabase Authentication:

1. Update `lib/services/auth_service.dart` to use Supabase auth
2. Remove Firebase Authentication dependency
3. Use the existing Supabase configuration

### Option 2: Temporary Workaround
Add error handling to gracefully handle Firebase blocking:

```dart
// In registerUser method
try {
  // Firebase registration
} catch (e) {
  if (e.toString().contains('blocked')) {
    // Fallback to Supabase registration
    return await _supabaseService.registerUser(
      username: username,
      email: email,
      password: password,
    );
  }
  rethrow;
}
```

## Verification

After implementing the fix:

1. ✅ Firebase Authentication enabled
2. ✅ SHA-1 fingerprint added to Firebase console
3. ✅ Package name matches
4. ✅ Updated google-services.json downloaded
5. ✅ App cleaned and rebuilt
6. ✅ Registration works without blocking error

## Common Issues

### Issue: SHA-1 not found
**Solution**: Use the debug SHA-1 for development, release SHA-1 for production

### Issue: Package name mismatch
**Solution**: Ensure Firebase console package name exactly matches AndroidManifest.xml

### Issue: Firebase project not found
**Solution**: Verify you're in the correct Firebase project: `recostrect3`

## Support

If the issue persists after following these steps:
1. Check Firebase Console logs for detailed error messages
2. Verify network connectivity
3. Ensure Firebase project billing is enabled
4. Contact Firebase support if needed 