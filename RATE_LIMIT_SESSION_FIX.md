# Rate Limit and Session Management Fix

## Problem Analysis

The logs show multiple issues:

1. **Rate Limiting**: `"For security purposes, you can only request this after 1 seconds"`
2. **Email Not Confirmed**: `"Email not confirmed"`
3. **Session Creation Failing**: Multiple attempts to create sessions in quick succession
4. **RLS Policy Violations**: Because no proper session exists, data insertion fails

## Root Cause

The issue is that we're trying to create Supabase user accounts multiple times in quick succession, which triggers:
- Rate limiting (too many requests)
- Email confirmation requirements
- Session conflicts

## Solution

Implement a smarter session management approach that:
1. **Checks for existing sessions first**
2. **Tries sign-in before sign-up** (to avoid rate limits)
3. **Avoids duplicate session creation attempts**
4. **Handles rate limiting gracefully**

## Implementation

### 1. Updated Session Management

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

    debugPrint('SupabaseConfig: Firebase user found, creating Supabase session');

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
      
      // Only try sign up if sign in failed and it's not a rate limit error
      if (!signInError.toString().contains('rate_limit')) {
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

### 2. Session Caching

To avoid multiple session creation attempts, we can implement session caching:

```dart
// Cache for session creation attempts
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

### 3. Updated User Data Insertion

**File**: `lib/services/supabase_database_service.dart`

```dart
/// Insert user data into 'user' table after Firebase sign-in
Future<void> upsertUserToUserAndUsersTables({
  required String id, // Firebase UID
  required String email,
  required String name,
  String? photoUrl,
}) async {
  try {
    debugPrint("🔄 Attempting to upsert user data for: $email");
    
    // Check if we should attempt session creation
    if (!SupabaseConfig._shouldAttemptSessionCreation(email)) {
      debugPrint("⏳ Skipping session creation due to rate limiting for: $email");
      return;
    }
    
    // Ensure Supabase session exists for Firebase users
    final sessionCreated = await SupabaseConfig.ensureSupabaseSession();
    SupabaseConfig._recordSessionAttempt(email);
    
    if (!sessionCreated) {
      debugPrint("❌ Failed to create Supabase session for: $email");
      return;
    }
    
    // Check if user already exists in 'user' table using authenticated client
    final existing = await _client.from('user').select('id').eq('email', email).maybeSingle();
    if (existing != null) {
      debugPrint("✅ User already exists in 'user' table: $email");
      return;
    }
    
    // Prepare user data with all required fields
    final now = DateTime.now();
    final trialEndDate = now.add(const Duration(days: 7));
    
    final userData = {
      'name': name,
      'email': email,
      'firebase_uid': id,
      'profile_image_url': photoUrl,
      'password_hash': 'firebase',
      'welcome_email_sent': false,
      'is_premium': false,
      'trial_start_date': now.toIso8601String().split('T')[0],
      'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
    };
    
    debugPrint("📝 Inserting user data: ${userData['name']} (${userData['email']})");
    
    // Try to insert using authenticated client
    try {
      await _client.from('user').insert(userData);
      debugPrint("✅ Successfully inserted user into 'user' table: $email");
    } catch (insertError) {
      debugPrint("❌ Insert failed: $insertError");
      
      // Fallback: Try upsert with conflict resolution
      try {
        await _client.from('user').upsert(userData, onConflict: 'email');
        debugPrint("✅ Successfully upserted user: $email");
      } catch (upsertError) {
        debugPrint("❌ All insertion methods failed for user: $email");
        debugPrint("Final error: $upsertError");
      }
    }
  } catch (e) {
    debugPrint("❌ Error in upsertUserToUserAndUsersTables: $e");
  }
}
```

## How It Works

### 1. Smart Session Management

1. **Check existing session** → If session exists, use it
2. **Try sign-in first** → Avoid rate limits by trying existing account
3. **Sign-up only if needed** → Only create new account if sign-in fails
4. **Rate limit handling** → Skip session creation if rate limited
5. **Session caching** → Avoid duplicate attempts

### 2. Rate Limit Prevention

- **Session attempt tracking** → Record when session creation was attempted
- **Time-based throttling** → Wait 5 seconds between attempts
- **Error-based skipping** → Skip sign-up if rate limited

### 3. Error Handling

- **Graceful degradation** → Continue with Firebase auth if Supabase fails
- **Comprehensive logging** → Track all session creation attempts
- **Fallback mechanisms** → Multiple strategies for session creation

## Expected Results

### 1. Successful Session Creation (First Time)
```
AuthService: Creating Supabase session from Firebase JWT
SupabaseConfig: Firebase user found, creating Supabase session
SupabaseConfig: Successfully signed in to Supabase
AuthService: Supabase session created successfully
```

### 2. Successful Session Reuse (Subsequent Times)
```
🔄 Attempting to upsert user data for: user@example.com
SupabaseConfig: Supabase session already exists
📝 Inserting user data: User Name (user@example.com)
✅ Successfully inserted user into 'user' table: user@example.com
```

### 3. Rate Limit Handling
```
🔄 Attempting to upsert user data for: user@example.com
⏳ Skipping session creation due to rate limiting for: user@example.com
```

## Benefits

1. **Rate Limit Prevention**: Avoids multiple session creation attempts
2. **Session Reuse**: Uses existing sessions when available
3. **Graceful Degradation**: Continues working even if session creation fails
4. **Better Performance**: Faster subsequent operations
5. **Reliable Data Storage**: Proper authentication for database operations

## Testing Steps

### 1. Test First-Time Login
1. Sign in with Google (new user)
2. Check logs for successful session creation
3. Verify user data is stored

### 2. Test Subsequent Logins
1. Sign out and sign back in
2. Check logs for session reuse
3. Verify no rate limiting errors

### 3. Test Rate Limit Handling
1. Try multiple rapid sign-ins
2. Check logs for rate limit handling
3. Verify app continues to work

This fix addresses the rate limiting and session management issues while maintaining proper authentication for your RLS policies. 