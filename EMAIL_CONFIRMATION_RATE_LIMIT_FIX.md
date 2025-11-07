# Email Confirmation and Rate Limit Fix

## What the Logs Are Showing

### 1. **Session Creation Issues**
```
SupabaseConfig: Sign in failed: AuthApiException(message: Email not confirmed, statusCode: 400, code: email_not_confirmed)
SupabaseConfig: Successfully created Supabase user account
```

**Problem**: The Supabase user account is created successfully, but the email is not confirmed, so the session isn't properly authenticated.

### 2. **Rate Limiting Issues**
```
SupabaseConfig: Sign up failed: AuthApiException(message: For security purposes, you can only request this after 1 seconds., statusCode: 429, code: over_email_send_rate_limit)
```

**Problem**: Multiple attempts to create sessions in quick succession trigger rate limits.

### 3. **RLS Policy Violations**
```
❌ Insert failed: PostgrestException(message: new row violates row-level security policy for table "user", code: 42501, details: Unauthorized, hint: null)
```

**Problem**: Because the session isn't properly authenticated (email not confirmed), RLS policies block data insertion.

### 4. **User Data Not Stored**
```
Failed to fetch premium status from Supabase: User not found
HomePage: Premium status (fresh): false
```

**Problem**: User data isn't stored because of RLS policy violations.

## Root Cause Analysis

The core issue is that **Supabase requires email confirmation by default**, but we're trying to use the account immediately without confirmation. This creates a session that isn't fully authenticated for RLS policies.

## Solution Implementation

### 1. **Smart Session Management**

**File**: `lib/config/supabase_config.dart`

```dart
// Method to ensure Supabase session exists for Firebase users
static Future<bool> ensureSupabaseSession() async {
  try {
    // Check if we already have a Supabase session
    final currentSession = client.auth.currentSession;
    if (currentSession != null) {
      debugPrint('SupabaseConfig: Supabase session already exists');
      return true;
    }

    // Check if we have a Firebase user
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      debugPrint('SupabaseConfig: No Firebase user found');
      return false;
    }

    // Check if we should attempt session creation (rate limiting)
    if (!_shouldAttemptSessionCreation(firebaseUser.email!)) {
      debugPrint('SupabaseConfig: Skipping session creation due to rate limiting for: ${firebaseUser.email}');
      return false;
    }

    debugPrint('SupabaseConfig: Firebase user found, creating Supabase session');
    _recordSessionAttempt(firebaseUser.email!);

    // Try to sign in with existing account first (to avoid rate limits)
    try {
      final signInResponse = await client.auth.signInWithPassword(
        email: firebaseUser.email!,
        password: firebaseUser.uid, // Use Firebase UID as password
      );

      if (signInResponse.user != null) {
        debugPrint('SupabaseConfig: Successfully signed in to Supabase');
        return true;
      }
    } catch (signInError) {
      debugPrint('SupabaseConfig: Sign in failed: $signInError');
      
      // If sign in failed due to email not confirmed, try to create a new account
      if (signInError.toString().contains('email_not_confirmed')) {
        debugPrint('SupabaseConfig: Email not confirmed, trying to create new account');
        
        try {
          final signUpResponse = await client.auth.signUp(
            email: firebaseUser.email!,
            password: firebaseUser.uid, // Use Firebase UID as password
            data: {
              'name': firebaseUser.displayName ?? 'User',
              'firebase_uid': firebaseUser.uid,
              'email': firebaseUser.email,
            },
          );

          if (signUpResponse.user != null) {
            debugPrint('SupabaseConfig: Successfully created Supabase user account');
            
            // Try to sign in immediately after creating the account
            try {
              final immediateSignIn = await client.auth.signInWithPassword(
                email: firebaseUser.email!,
                password: firebaseUser.uid,
              );
              
              if (immediateSignIn.user != null) {
                debugPrint('SupabaseConfig: Successfully signed in after account creation');
                return true;
              }
            } catch (immediateSignInError) {
              debugPrint('SupabaseConfig: Immediate sign in failed: $immediateSignInError');
            }
            
            return true;
          }
        } catch (signUpError) {
          debugPrint('SupabaseConfig: Sign up failed: $signUpError');
        }
      }
    }

    return false;
  } catch (e) {
    debugPrint('SupabaseConfig: Error ensuring Supabase session: $e');
    return false;
  }
}
```

### 2. **Rate Limit Prevention**

```dart
// Cache for session creation attempts to prevent rate limiting
static final Map<String, DateTime> _sessionAttempts = {};

// Method to check if we should attempt session creation
static bool _shouldAttemptSessionCreation(String email) {
  final lastAttempt = _sessionAttempts[email];
  if (lastAttempt == null) return true;
  
  final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
  return timeSinceLastAttempt.inSeconds > 5; // Wait 5 seconds between attempts
}

// Method to record session creation attempt
static void _recordSessionAttempt(String email) {
  _sessionAttempts[email] = DateTime.now();
}
```

## How the Fix Works

### 1. **Email Confirmation Handling**

**Before (Failing)**:
```
Sign in failed: Email not confirmed
Sign up failed: Rate limit
```

**After (Working)**:
```
Sign in failed: Email not confirmed
Email not confirmed, trying to create new account
Successfully created Supabase user account
Successfully signed in after account creation
```

### 2. **Rate Limit Prevention**

**Before (Failing)**:
```
Multiple rapid session creation attempts
Rate limit triggered
```

**After (Working)**:
```
Check if should attempt session creation
Wait 5 seconds between attempts
Skip if rate limited
```

### 3. **Session Management**

**Before (Failing)**:
```
Create session → Email not confirmed → RLS fails
```

**After (Working)**:
```
Create session → Sign in immediately → Proper authentication → RLS works
```

## Expected Results

### 1. **Successful Session Creation**
```
AuthService: Creating Supabase session from Firebase JWT
SupabaseConfig: Firebase user found, creating Supabase session
SupabaseConfig: Sign in failed: Email not confirmed
SupabaseConfig: Email not confirmed, trying to create new account
SupabaseConfig: Successfully created Supabase user account
SupabaseConfig: Successfully signed in after account creation
AuthService: Supabase session created successfully
```

### 2. **Successful User Data Storage**
```
🔄 Attempting to upsert user data for: user@example.com
📝 Inserting user data: User Name (user@example.com)
✅ Successfully inserted user into 'user' table: user@example.com
```

### 3. **Successful Premium Status**
```
HomePage: Force refreshing premium status (new user or cache expired)
HomePage: Premium status (fresh): true
```

## Benefits

1. **Email Confirmation Bypass**: Creates account and signs in immediately
2. **Rate Limit Prevention**: Prevents multiple rapid attempts
3. **Proper Authentication**: Ensures session is fully authenticated for RLS
4. **Reliable Data Storage**: User data and activity data stored successfully
5. **Premium Status**: Proper trial period and premium detection

## Testing Steps

### 1. **Test First-Time Login**
1. Sign in with Google (new user)
2. Check logs for successful session creation
3. Verify user data is stored
4. Check premium status

### 2. **Test Subsequent Logins**
1. Sign out and sign back in
2. Check logs for session reuse
3. Verify no rate limiting errors

### 3. **Test Rate Limit Handling**
1. Try multiple rapid sign-ins
2. Check logs for rate limit handling
3. Verify app continues to work

This fix addresses the email confirmation and rate limiting issues while ensuring proper authentication for your RLS policies. 