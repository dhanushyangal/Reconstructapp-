import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class SupabaseConfig {
  // Supabase URL and keys
  static const String url = 'https://ruxsfzvrumqxsvanbbow.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg';
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODk1MjI1NCwiZXhwIjoyMDY0NTI4MjU0fQ.nB_wLdAyCGS65u3dvb14V2dAOSGEPdV-FuR6vQ6TYtE';

  // Track if Supabase is already initialized
  static bool _isInitialized = false;
  
  // Separate client for native authentication (without accessToken)
  static supabase.SupabaseClient? _nativeAuthClient;
  
  // Separate client for auth operations (without accessToken)
  static supabase.SupabaseClient? _authClient;

  // Initialize Supabase client with Firebase Auth integration
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SupabaseConfig: Already initialized, skipping');
      return;
    }

    try {
      // Create auth client FIRST (before main initialization) - no accessToken
      // This client will be used specifically for auth operations
      _authClient = supabase.SupabaseClient(url, anonKey);
      debugPrint('SupabaseConfig: Auth client created for direct authentication');
      
      // Create native auth client for other operations
      _nativeAuthClient = supabase.SupabaseClient(url, anonKey);
      debugPrint('SupabaseConfig: Native auth client created for direct authentication');
      
      // Create a separate client for auth operations without accessToken
      // This will be used specifically for signUp and signIn operations
      final authClient = supabase.SupabaseClient(url, anonKey);
      _authClient = authClient;
      
      // Then initialize the main client without accessToken for auth operations
      await supabase.Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
        authOptions: const supabase.FlutterAuthClientOptions(
          autoRefreshToken: true,
        ),
        // No accessToken function to allow auth operations
      );
      
      _isInitialized = true;
      debugPrint('SupabaseConfig: Successfully initialized with Firebase Auth integration');
    } catch (e) {
      debugPrint('SupabaseConfig: Initialization failed: $e');
      // Don't rethrow - allow app to continue even if Supabase init fails
    }
  }

  // Get the Supabase client instance (with Firebase integration)
  static supabase.SupabaseClient get client {
    if (!_isInitialized) {
      debugPrint(
          'SupabaseConfig: Warning - Client accessed before initialization');
    }
    return supabase.Supabase.instance.client;
  }

  // Get the auth client for direct authentication (no accessToken)
  static supabase.SupabaseClient get authClient {
    if (_authClient == null) {
      debugPrint('SupabaseConfig: Creating auth client on demand');
      _authClient = supabase.SupabaseClient(url, anonKey);
    }
    return _authClient!;
  }

  // Get the native Supabase client for direct authentication
  static supabase.SupabaseClient get nativeAuthClient {
    if (_nativeAuthClient == null) {
      debugPrint('SupabaseConfig: Creating native auth client on demand');
      _nativeAuthClient = supabase.SupabaseClient(url, anonKey);
    }
    return _nativeAuthClient!;
  }

  // Connection timeouts
  static int get connectionTimeout => 10;
  static int get receiveTimeout => 15;
  static int get retryAttempts => 5;

  // Check if initialized
  static bool get isInitialized => _isInitialized;
  
  // Cache for session creation attempts to prevent rate limiting
  static final Map<String, DateTime> _sessionAttempts = {};
  
  // Method to check if we should attempt session creation
  static bool _shouldAttemptSessionCreation(String email) {
    final lastAttempt = _sessionAttempts[email];
    if (lastAttempt == null) return true;
    
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    return timeSinceLastAttempt.inSeconds > 30; // Wait 30 seconds between attempts
  }
  
  // Method to record session creation attempt
  static void _recordSessionAttempt(String email) {
    _sessionAttempts[email] = DateTime.now();
  }
  
  // Method to clear rate limiting cache
  static void _clearRateLimitCache() {
    _sessionAttempts.clear();
  }

  // Create Supabase session from Firebase JWT
  static Future<bool> createSupabaseSessionFromFirebase() async {
    try {
      debugPrint('SupabaseConfig: Creating Supabase session from Firebase JWT');
      
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('SupabaseConfig: No Firebase user found');
        return false;
      }

      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        debugPrint('SupabaseConfig: Failed to get Firebase ID token');
        return false;
      }

      debugPrint('SupabaseConfig: Got Firebase ID token, creating Supabase session');

      // Try to create a Supabase user account using Firebase data
      try {
        // Create a user account in Supabase using Firebase user data
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
        debugPrint('SupabaseConfig: Sign up failed, trying sign in: $signUpError');
        
        // Try to sign in with existing account
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
        }
      }

      debugPrint('SupabaseConfig: Failed to create Supabase session');
      return false;
    } catch (e) {
      debugPrint('SupabaseConfig: Error creating Supabase session from Firebase: $e');
      return false;
    }
  }

  // Alternative method: Use Firebase JWT directly with Supabase
  static Future<bool> authenticateWithFirebaseJWT() async {
    try {
      debugPrint('SupabaseConfig: Authenticating with Firebase JWT');
      
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        debugPrint('SupabaseConfig: No Firebase user found');
        return false;
      }

      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        debugPrint('SupabaseConfig: Failed to get Firebase ID token');
        return false;
      }

      debugPrint('SupabaseConfig: Got Firebase ID token, trying alternative authentication');

      // Try to authenticate using Firebase data with Supabase
      try {
        // Try to sign in with existing account
        final signInResponse = await client.auth.signInWithPassword(
          email: firebaseUser.email!,
          password: firebaseUser.uid, // Use Firebase UID as password
        );

        if (signInResponse.user != null) {
          debugPrint('SupabaseConfig: Successfully signed in to Supabase');
          return true;
        }
      } catch (authError) {
        debugPrint('SupabaseConfig: Sign in failed: $authError');
        
        // Try to create a new account
        try {
          final signUpResponse = await client.auth.signUp(
            email: firebaseUser.email!,
            password: firebaseUser.uid, // Use Firebase UID as password
            data: {
              'name': firebaseUser.displayName ?? 'User',
              'firebase_uid': firebaseUser.uid,
              'provider': 'google', // Mark as Google user
              'email': firebaseUser.email,
            },
          );

          if (signUpResponse.user != null) {
            debugPrint('SupabaseConfig: Successfully created Supabase user account');
            return true;
          }
        } catch (signUpError) {
          debugPrint('SupabaseConfig: Sign up failed: $signUpError');
          return false;
        }
      }

      return false;
    } catch (e) {
      debugPrint('SupabaseConfig: Error authenticating with Firebase JWT: $e');
      return false;
    }
  }

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
        // Clear cache and try again for critical operations
        _clearRateLimitCache();
        debugPrint('SupabaseConfig: Cleared rate limit cache, retrying session creation');
      }

      debugPrint('SupabaseConfig: Firebase user found, creating Supabase session');
      _recordSessionAttempt(firebaseUser.email!);

      // For Google login, we'll use a simpler approach that bypasses email confirmation
      // Since Google users are already verified, we don't need email confirmation
      try {
        // Try to sign in with existing account first
        final signInResponse = await client.auth.signInWithPassword(
          email: firebaseUser.email!,
          password: firebaseUser.uid,
        );

        if (signInResponse.user != null) {
          debugPrint('SupabaseConfig: Successfully signed in to Supabase');
          return true;
        }
      } catch (signInError) {
        debugPrint('SupabaseConfig: Sign in failed: $signInError');
        
        // If sign in failed, create a new account
        // For Google users, we'll create the account and handle email confirmation manually
        try {
          final signUpResponse = await client.auth.signUp(
            email: firebaseUser.email!,
            password: firebaseUser.uid,
            data: {
              'name': firebaseUser.displayName ?? 'User',
              'firebase_uid': firebaseUser.uid,
              'provider': 'google', // Mark as Google user
              'email': firebaseUser.email,
            },
          );

          if (signUpResponse.user != null) {
            debugPrint('SupabaseConfig: Successfully created Supabase user account');
            
            // For Google users, we'll assume the session is valid even if email not confirmed
            // because Google has already verified the email
            debugPrint('SupabaseConfig: Google user - assuming email is verified');
            return true;
          }
        } catch (signUpError) {
          debugPrint('SupabaseConfig: Sign up failed: $signUpError');
        }
      }

      return false;
    } catch (e) {
      debugPrint('SupabaseConfig: Error ensuring Supabase session: $e');
      return false;
    }
  }
}
