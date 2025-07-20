import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import '../config/google_signin_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupabaseDatabaseService {
  // Supabase client instance
  late final supabase.SupabaseClient _client;

  // Email API configuration
  static const String _emailApiUrl = 'https://reconstrect-api.onrender.com';

  // Constructor
  SupabaseDatabaseService() {
    _client = SupabaseConfig.client;
  }

  // Helper method to handle errors and format response
  Map<String, dynamic> _formatResponse({
    required bool success,
    String? message,
    Map<String, dynamic>? user,
    String? token,
    dynamic data,
  }) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (user != null) 'user': user,
      if (token != null) 'token': token,
      if (data != null) 'data': data,
    };
  }

  // 🚀 SIMPLE EMAIL API INTEGRATION
  // Uses: https://reconstrect-api.onrender.com/api/send-welcome-email
  // Sends welcome email and updates welcome_email_sent to true in database

  // Simple method to send welcome email using API
  Future<bool> _sendWelcomeEmail({
    required String email,
    required String name,
  }) async {
    try {
      debugPrint('🔥 Sending welcome email to: $email');

      final response = await http.post(
        Uri.parse('$_emailApiUrl/api/send-welcome-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          debugPrint('✅ Welcome email sent successfully to: $email');
          return true;
        }
      }

      debugPrint('❌ Failed to send welcome email: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('❌ Error sending welcome email: $e');
      return false;
    }
  }

  // Update welcome email sent status in database
  Future<void> _updateEmailSentStatus(String email) async {
    try {
      await _client
          .from('user')
          .update({'welcome_email_sent': true})
          .eq('email', email)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⚠️ Email status update timed out');
            },
          );
      debugPrint('✅ Updated welcome_email_sent to true for: $email');
    } catch (e) {
      debugPrint('⚠️ Could not update email sent status: $e');
    }
  }

  // Method to check if email already exists in Supabase Auth
  Future<bool> _checkEmailExists(String email) async {
    try {
      debugPrint('🔍 Checking if email exists: $email');

      // Check in auth.users table using admin query
      final response = await _client
          .from('auth.users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      final exists = response != null;
      debugPrint('🔍 Email $email exists: $exists');
      return exists;
    } catch (e) {
      debugPrint('🔍 Error checking email existence: $e');
      // If we can't check, assume it doesn't exist to allow registration
      return false;
    }
  }

  // Method to check if username already exists in custom user table
  Future<bool> _checkUsernameExists(String username) async {
    try {
      debugPrint('🔍 Checking if username exists: $username');

      // Check in public.user table
      final response = await _client
          .from('user')
          .select('id')
          .eq('name', username)
          .maybeSingle();

      final exists = response != null;
      debugPrint('🔍 Username $username exists: $exists');
      return exists;
    } catch (e) {
      debugPrint('🔍 Error checking username existence: $e');
      // If we can't check, assume it doesn't exist to allow registration
      return false;
    }
  }

  // Method to validate registration data before creating user
  Future<Map<String, dynamic>> _validateRegistrationData({
    required String username,
    required String email,
  }) async {
    debugPrint(
        '🔍 Validating registration data for: $email, username: $username');

    // Check if email already exists
    final emailExists = await _checkEmailExists(email);
    if (emailExists) {
      return _formatResponse(
        success: false,
        message:
            'Email is already registered. Please use a different email or try signing in.',
      );
    }

    // Check if username already exists
    final usernameExists = await _checkUsernameExists(username);
    if (usernameExists) {
      return _formatResponse(
        success: false,
        message:
            'Username is already taken. Please choose a different username.',
      );
    }

    debugPrint('✅ Registration validation passed');
    return _formatResponse(success: true);
  }

  // Public method to check username availability
  Future<Map<String, dynamic>> checkUsernameAvailability(
      String username) async {
    try {
      debugPrint('🔍 Checking username availability: $username');

      final exists = await _checkUsernameExists(username);

      if (exists) {
        return _formatResponse(
          success: false,
          message:
              'Username is already taken. Please choose a different username.',
        );
      } else {
        return _formatResponse(
          success: true,
          message: 'Username is available',
        );
      }
    } catch (e) {
      debugPrint('🔍 Error checking username availability: $e');
      return _formatResponse(
        success: false,
        message: 'Error checking username availability',
      );
    }
  }

  // Public method to check email availability
  Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    try {
      debugPrint('🔍 Checking email availability: $email');

      final exists = await _checkEmailExists(email);

      if (exists) {
        return _formatResponse(
          success: false,
          message:
              'Email is already registered. Please use a different email or try signing in.',
        );
      } else {
        return _formatResponse(
          success: true,
          message: 'Email is available',
        );
      }
    } catch (e) {
      debugPrint('🔍 Error checking email availability: $e');
      return _formatResponse(
        success: false,
        message: 'Error checking email availability',
      );
    }
  }

  // Method to register a new user with Supabase Auth
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint(
        'SupabaseDatabaseService: Starting registration for email: $email');

    try {
      // First validate the registration data
      final validationResult = await _validateRegistrationData(
        username: username,
        email: email,
      );

      if (!validationResult['success']) {
        return validationResult;
      }

      // Create auth user with Supabase Auth (with web-based email confirmation)
      debugPrint(
          'SupabaseDatabaseService: Registering user with username: $username');

      final supabase.AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'name': username,
          'display_name':
              username, // Add display_name as well for better compatibility
        },
        emailRedirectTo: 'https://reconstructyourmind.com/verify-email.php',
      );

      debugPrint('SupabaseDatabaseService: Registration response received');
      debugPrint(
          'SupabaseDatabaseService: User metadata: ${response.user?.userMetadata}');

      if (response.user != null) {
        // User record will be created in public.user table after email confirmation
        // via database trigger, so we don't need to create it here
        debugPrint(
            'User registered successfully. User record will be created after email confirmation.');

        // 📧 Send welcome email (will be sent after email confirmation)
        // Note: Welcome email will be sent when user first logs in after verification
        debugPrint(
            'Welcome email will be sent after user verifies their email and logs in.');

        // Check if email confirmation is required
        final requiresEmailConfirmation =
            response.user!.emailConfirmedAt == null;

        // Format user data to match the expected structure
        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'username': username,
          'name': username,
          'supabase_uid': response.user!.id,
          'is_premium': false,
          'email_confirmed': !requiresEmailConfirmation,
        };

        String message;
        if (requiresEmailConfirmation) {
          message =
              'Registration successful! Please check your email to verify your account at reconstructyourmind.com';
        } else {
          message =
              'Registration successful! Welcome email will be sent after verification.';
        }

        return _formatResponse(
          success: true,
          message: message,
          user: userData,
          token: response.session?.accessToken,
        );
      } else {
        return _formatResponse(
          success: false,
          message: 'Registration failed: User creation failed',
        );
      }
    } catch (e) {
      debugPrint('Error in registerUser: $e');

      String errorMessage = 'An error occurred during registration';
      if (e is supabase.AuthException) {
        errorMessage = e.message;
      }

      return _formatResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  // Method to login a user with Supabase Auth
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    debugPrint(
        '🔐 SupabaseDatabaseService: Attempting to login with email: $email');

    try {
      debugPrint(
          '🔐 SupabaseDatabaseService: Calling _client.auth.signInWithPassword...');
      final supabase.AuthResponse response =
          await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('🔐 SupabaseDatabaseService: signInWithPassword completed');

      if (response.user != null) {
        debugPrint(
            '🔐 SupabaseDatabaseService: User found, fetching custom user data...');
        // Get additional user data from custom user table
        Map<String, dynamic>? customUserData;
        try {
          customUserData = await _client
              .from('user')
              .select()
              .eq('email', email)
              .maybeSingle()
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint(
                  '🔐 SupabaseDatabaseService: Database query timed out');
              return null;
            },
          );
          debugPrint(
              '🔐 SupabaseDatabaseService: Custom user data fetched: ${customUserData != null}');
        } catch (e) {
          debugPrint(
              '🔐 SupabaseDatabaseService: Could not fetch custom user data: $e');
        }

        // 📧 Check if welcome email was sent, if not send it
        bool emailSent = false;
        String loginMessage = 'Login successful';

        if (customUserData != null &&
            customUserData['welcome_email_sent'] == false) {
          debugPrint('📧 Welcome email not sent yet, sending now...');
          try {
            emailSent = await _sendWelcomeEmail(
              email: email,
              name: customUserData['name'] ?? email.split('@')[0],
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('📧 Welcome email sending timed out');
                return false;
              },
            );
          } catch (e) {
            debugPrint('📧 Error sending welcome email: $e');
            emailSent = false;
          }

          if (emailSent) {
            try {
              await _updateEmailSentStatus(email).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  debugPrint('📧 Email status update timed out');
                },
              );
            } catch (e) {
              debugPrint('📧 Error updating email status: $e');
            }
            loginMessage = 'Login successful! Welcome email sent.';
          } else {
            loginMessage = 'Login successful! Email sending failed.';
          }
        } else if (customUserData == null) {
          debugPrint(
              '📧 No user record found - user may need to verify email first');
          loginMessage =
              'Login successful! Please verify your email to access all features.';
        } else {
          debugPrint('📧 Welcome email already sent');
        }

        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'username': response.user!.userMetadata?['username'] ??
              customUserData?['name'] ??
              email.split('@')[0],
          'name': response.user!.userMetadata?['name'] ??
              customUserData?['name'] ??
              email.split('@')[0],
          'supabase_uid': response.user!.id,
          'is_premium': customUserData?['is_premium'] ?? false,
        };

        debugPrint(
            '🔐 SupabaseDatabaseService: Login successful, returning user data');
        return _formatResponse(
          success: true,
          message: loginMessage,
          user: userData,
          token: response.session?.accessToken,
        );
      } else {
        debugPrint('🔐 SupabaseDatabaseService: No user found in response');
        return _formatResponse(
          success: false,
          message: 'Login failed: Invalid credentials',
        );
      }
    } catch (e) {
      debugPrint('🔐 SupabaseDatabaseService: Error in loginUser: $e');

      String errorMessage = 'An error occurred during login';
      if (e is supabase.AuthException) {
        errorMessage = e.message;
      }

      return _formatResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  // Method for Google Sign-In with Supabase
  Future<Map<String, dynamic>> signInWithGoogle() async {
    debugPrint('SupabaseDatabaseService: Starting Google Sign-In');

    try {
      // Configure Google Sign-In with proper settings for ID token
      debugPrint('Configuring Google Sign-In for ID token...');

      GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
          'openid', // This is crucial for ID token
        ],
        serverClientId: GoogleSignInConfig.webClientId,
      );

      debugPrint('Google Sign-In configured with:');
      debugPrint('- Platform: [CONFIGURED]');
      debugPrint('- Scopes: ${googleSignIn.scopes}');
      debugPrint('- Server Client ID: [CONFIGURED]');

      // Force sign out to clear any cached credentials
      try {
        await googleSignIn.signOut();
        debugPrint('Previous Google Sign-In session cleared');
      } catch (e) {
        debugPrint('Note: No previous session to clear: $e');
      }

      // Attempt to sign in
      debugPrint('Attempting Google Sign-In...');
      debugPrint('Google Sign-In instance: $googleSignIn');

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await googleSignIn.signIn();
        debugPrint('Google Sign-In attempt completed');
      } catch (signInError) {
        debugPrint('Google Sign-In error: $signInError');
        debugPrint('Error type: ${signInError.runtimeType}');
        rethrow;
      }

      if (googleUser == null) {
        debugPrint('Google Sign-In cancelled by user');
        return _formatResponse(
          success: false,
          message: 'Google Sign-In cancelled by user',
        );
      }

      debugPrint('Google user obtained: ${googleUser.email}');
      debugPrint('Google user display name: ${googleUser.displayName}');
      debugPrint('Google user photo URL: ${googleUser.photoUrl}');

      // Get authentication details
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      debugPrint('Access token available: ${accessToken != null}');
      debugPrint('ID token available: ${idToken != null}');

      if (idToken != null) {
        debugPrint('ID token length: ${idToken.length}');
        debugPrint('ID token starts with: ${idToken.substring(0, 20)}...');
      }

      if (accessToken == null) {
        throw 'No Access Token found from Google.';
      }
      if (idToken == null) {
        throw 'No ID Token found from Google. This usually means:\n'
            '1. The serverClientId is not properly configured\n'
            '2. The OAuth client is not set up correctly in Google Console\n'
            '3. The "openid" scope is missing\n\n'
            'Please check your Google Cloud Console OAuth 2.0 client configuration.';
      }

      debugPrint('Google Sign-In tokens obtained successfully');
      debugPrint('Attempting Supabase authentication...');

      // Sign in with Supabase using Google tokens (this will create user in Supabase Auth)
      final supabase.AuthResponse response =
          await _client.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        debugPrint(
            'Supabase authentication successful for user: ${response.user!.email}');
        debugPrint('Supabase user ID: ${response.user!.id}');
        debugPrint('User metadata: ${response.user!.userMetadata}');

        // Get profile picture URL from Google or Supabase metadata
        String? profileImageUrl = googleUser.photoUrl ??
            response.user!.userMetadata?['avatar_url'] ??
            response.user!.userMetadata?['picture'];

        debugPrint('Profile image URL: $profileImageUrl');

        // Check if user record exists in custom user table
        // User records are only created after email verification via database trigger
        Map<String, dynamic>? customUserData;
        try {
          customUserData = await _client
              .from('user')
              .select()
              .eq('email', response.user!.email!)
              .maybeSingle();
        } catch (e) {
          debugPrint('Could not fetch custom user data: $e');
        }

        // For Google Sign-In, we need to handle the case where user might not have a record yet
        // This can happen if they signed up with Google but haven't verified their email
        if (customUserData == null) {
          debugPrint(
              'No user record found for Google user: ${response.user!.email}');
          debugPrint(
              'User record will be created after email verification via database trigger');

          // For Google users, we can consider them verified since Google handles verification
          // But we'll still wait for the database trigger to create the record
          // This ensures consistency with the email verification flow
        } else {
          // Update existing user with latest profile image
          debugPrint('Updating existing user: ${customUserData['name']}');

          final updateData = {
            'profile_image_url': profileImageUrl,
            'name': response.user!.userMetadata?['full_name'] ??
                response.user!.userMetadata?['name'] ??
                googleUser.displayName ??
                customUserData['name'],
          };

          // If trial dates are null, set them for existing user
          if (customUserData['trial_start_date'] == null) {
            final now = DateTime.now();
            final trialEndDate = now.add(const Duration(days: 7));
            updateData['trial_start_date'] =
                now.toIso8601String().split('T')[0];
            updateData['trial_end_date'] =
                trialEndDate.toIso8601String().split('T')[0];
            debugPrint(
                'Setting trial dates for existing user: ${now.toIso8601String().split('T')[0]} to ${trialEndDate.toIso8601String().split('T')[0]}');
          }

          await _client
              .from('user')
              .update(updateData)
              .eq('email', response.user!.email!);

          debugPrint(
              'User record updated with latest profile image and trial dates');

          // 📧 Check if welcome email was sent for existing Google user
          if (customUserData['welcome_email_sent'] == false) {
            debugPrint(
                '📧 Welcome email not sent yet for existing Google user, sending now...');
            final emailSent = await _sendWelcomeEmail(
              email: response.user!.email!,
              name: response.user!.userMetadata?['full_name'] ??
                  response.user!.userMetadata?['name'] ??
                  googleUser.displayName ??
                  customUserData['name'],
            );

            if (emailSent) {
              await _updateEmailSentStatus(response.user!.email!);
            }
          }
        }

        // Format user data with profile image
        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'username': response.user!.userMetadata?['full_name'] ??
              response.user!.userMetadata?['name'] ??
              googleUser.displayName ??
              response.user!.email!.split('@')[0],
          'name': response.user!.userMetadata?['full_name'] ??
              response.user!.userMetadata?['name'] ??
              googleUser.displayName ??
              response.user!.email!.split('@')[0],
          'supabase_uid': response.user!.id,
          'is_premium': false,
          'profile_image_url': profileImageUrl,
          'google_id': googleUser.id,
        };

        debugPrint('Google Sign-In completed successfully');
        return _formatResponse(
          success: true,
          message: 'Google Sign-In successful',
          user: userData,
          token: response.session?.accessToken,
        );
      } else {
        debugPrint('Supabase authentication failed - no user returned');
        return _formatResponse(
          success: false,
          message: 'Google Sign-In failed - no user returned from Supabase',
        );
      }
    } catch (e) {
      debugPrint('Error in Google Sign-In: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Enhanced error handling for common issues
      if (e.toString().contains('ApiException: 10')) {
        return _formatResponse(
          success: false,
          message: 'Google Sign-In configuration error (Code 10).\n\n'
              'TROUBLESHOOTING STEPS:\n\n'
              '1. ✅ SHA1 fingerprint is correctly added (verified in your screenshot)\n'
              '2. ✅ Package name is correct: com.reconstrect.visionboard\n'
              '3. ❓ Check if these APIs are ENABLED in Google Cloud Console:\n'
              '   • Identity Toolkit API\n'
              '   • Google Sign-In API\n'
              '   • Google+ API\n\n'
              '4. ❓ Clear Google Play Services cache:\n'
              '   Settings → Apps → Google Play Services → Storage → Clear Cache\n\n'
              '5. ❓ OAuth Consent Screen must be configured\n\n'
              'If all above are correct, this might be a Google Play Services caching issue.\n'
              'Try restarting your device or clearing Google Play Services data.\n\n'
              'Full error: $e',
        );
      } else if (e.toString().contains('sign_in_failed')) {
        return _formatResponse(
          success: false,
          message: 'Google Sign-In failed to start.\n\n'
              'This could be due to:\n'
              '• Missing Google Play Services\n'
              '• Incorrect SHA1 certificate\n'
              '• API not enabled in Google Console\n\n'
              'Error: $e',
        );
      } else if (e.toString().contains('network')) {
        return _formatResponse(
          success: false,
          message: 'Network error during Google Sign-In.\n'
              'Please check your internet connection and try again.\n\n'
              'Error: $e',
        );
      } else if (e.toString().contains('No ID Token')) {
        return _formatResponse(
          success: false,
          message: 'ID Token missing from Google Sign-In.\n\n'
              'SOLUTION STEPS:\n\n'
              '1. Go to Google Cloud Console (console.cloud.google.com)\n'
              '2. Select your project: recostrect3\n'
              '3. Go to APIs & Services → Credentials\n'
              '4. Find your OAuth 2.0 client ID\n'
              '5. Make sure it\'s configured as "Web application" type\n'
              '6. Ensure the client ID matches: [CONFIGURED]\n\n'
              'If the client ID is for "Android" type, you need to create a separate "Web application" client ID for ID tokens.\n\n'
              'Error: $e',
        );
      } else if (e.toString().contains('Unacceptable audience')) {
        return _formatResponse(
          success: false,
          message: 'Supabase Google provider not configured properly.\n\n'
              'REQUIRED STEPS:\n\n'
              '1. Go to Supabase Dashboard → Authentication → Providers\n'
              '2. Enable Google provider and configure:\n'
              '   • Client ID: [CONFIGURED]\n'
              '   • Client Secret: [YOUR_CLIENT_SECRET_HERE]\n'
              '   • Redirect URL: https://ruxsfzvrumqxsvanbbow.supabase.co/auth/v1/callback\n\n'
              'This will allow users to appear in Supabase Authentication dashboard.\n\n'
              'Error: $e',
        );
      }

      return _formatResponse(
        success: false,
        message: 'Google Sign-In failed: $e',
      );
    }
  }

  // Method to get the current user's profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final currentUser = _client.auth.currentUser;

      if (currentUser == null) {
        return _formatResponse(
          success: false,
          message: 'No authenticated user found',
        );
      }

      // Get additional user data from custom user table
      Map<String, dynamic>? customUserData;
      try {
        customUserData = await _client
            .from('user')
            .select()
            .eq('email', currentUser.email!)
            .maybeSingle();
      } catch (e) {
        debugPrint('Could not fetch custom user data: $e');
      }

      // If custom user data doesn't exist, try to create it
      if (customUserData == null && currentUser.email != null) {
        debugPrint(
            'Custom user data not found, attempting to create profile...');
        try {
          final now = DateTime.now();
          final trialEndDate = now.add(const Duration(days: 7));

          // Try RPC first, then fallback to direct insert
          try {
            await _client.rpc('create_user_profile', params: {
              'user_name': currentUser.userMetadata?['username'] ??
                  currentUser.email!.split('@')[0],
              'user_email': currentUser.email!,
              'user_id': currentUser.id,
              'trial_start': now.toIso8601String().split('T')[0],
              'trial_end': trialEndDate.toIso8601String().split('T')[0],
            });
            debugPrint('User profile created via RPC');
          } catch (rpcError) {
            debugPrint('RPC failed, trying direct insert: $rpcError');
            await _client.from('user').insert({
              'name': currentUser.userMetadata?['username'] ??
                  currentUser.email!.split('@')[0],
              'email': currentUser.email!,
              'password_hash': 'supabase_auth',
              'firebase_uid': currentUser.id,
              'welcome_email_sent': false,
              'is_premium': false,
              'trial_start_date': now.toIso8601String().split('T')[0],
              'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
            });
            debugPrint('User profile created via direct insert');
          }

          // Try to fetch the newly created data
          try {
            customUserData = await _client
                .from('user')
                .select()
                .eq('email', currentUser.email!)
                .maybeSingle();
          } catch (e) {
            debugPrint('Could not fetch newly created user data: $e');
          }
        } catch (e) {
          debugPrint('Could not create user profile: $e');
        }
      }

      final userData = {
        'id': currentUser.id,
        'email': currentUser.email,
        'username': currentUser.userMetadata?['username'] ??
            customUserData?['name'] ??
            currentUser.email!.split('@')[0],
        'name': currentUser.userMetadata?['name'] ??
            customUserData?['name'] ??
            currentUser.email!.split('@')[0],
        'supabase_uid': currentUser.id,
        'is_premium': customUserData?['is_premium'] ?? false,
      };

      return _formatResponse(
        success: true,
        user: userData,
      );
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
      return _formatResponse(
        success: false,
        message: 'An error occurred while fetching user profile: $e',
      );
    }
  }

  // Method to logout the user
  Future<void> logout() async {
    debugPrint('SupabaseDatabaseService: Logging out');
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('Error in logout: $e');
    }
  }

  // Method to delete vision board tasks
  Future<Map<String, dynamic>> deleteVisionBoardTask({
    required String userName,
    required String email,
    required String cardId,
    required String theme,
  }) async {
    try {
      await _client
          .from('vision_board_tasks')
          .delete()
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', cardId)
          .eq('theme', theme);

      return _formatResponse(
        success: true,
        message: 'Task deleted successfully',
      );
    } catch (e) {
      debugPrint('Error deleting vision board task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to delete task: $e',
      );
    }
  }

  // Method to save vision board tasks
  Future<Map<String, dynamic>> saveVisionBoardTask({
    required String userName,
    required String email,
    required String cardId,
    required String tasks,
    required String theme,
  }) async {
    try {
      debugPrint('Saving vision board task for user: $userName, card: $cardId');
      debugPrint(
          'Task data: ${tasks.substring(0, tasks.length > 100 ? 100 : tasks.length)}...');

      // First, check if a record exists
      final existingRecord = await _client
          .from('vision_board_tasks')
          .select('id')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', cardId)
          .eq('theme', theme)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        await _client
            .from('vision_board_tasks')
            .update({
              'tasks': tasks,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_name', userName)
            .eq('email', email)
            .eq('card_id', cardId)
            .eq('theme', theme);
        debugPrint('Updated existing record for $cardId');
      } else {
        // Insert new record
        await _client.from('vision_board_tasks').insert({
          'user_name': userName,
          'email': email,
          'card_id': cardId,
          'tasks': tasks,
          'theme': theme,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        debugPrint('Inserted new record for $cardId');
      }

      return _formatResponse(
        success: true,
        message: 'Task saved successfully',
      );
    } catch (e) {
      debugPrint('Error saving vision board task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to save task: $e',
      );
    }
  }

  // Method to get vision board tasks
  Future<Map<String, dynamic>> getVisionBoardTasks({
    required String userName,
    required String email,
    String? theme,
    String? cardId,
  }) async {
    try {
      var query = _client
          .from('vision_board_tasks')
          .select()
          .eq('user_name', userName)
          .eq('email', email);

      // Add optional filters
      if (theme != null) {
        query = query.eq('theme', theme);
      }

      if (cardId != null) {
        query = query.eq('card_id', cardId);
      }

      final response = await query;

      return _formatResponse(
        success: true,
        data: response,
      );
    } catch (e) {
      debugPrint('Error getting vision board tasks: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to get tasks: $e',
        data: [],
      );
    }
  }

  // Check if user is currently authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current user
  supabase.User? get currentUser => _client.auth.currentUser;

  // Get auth token
  String? get authToken => _client.auth.currentSession?.accessToken;

  // Method to update user premium status
  Future<Map<String, dynamic>> updateUserPremiumStatus({
    required String email,
    required bool isPremium,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'is_premium': isPremium,
      };

      if (trialStartDate != null) {
        updateData['trial_start_date'] =
            trialStartDate.toIso8601String().split('T')[0];
      }

      if (trialEndDate != null) {
        updateData['trial_end_date'] =
            trialEndDate.toIso8601String().split('T')[0];
      }

      await _client.from('user').update(updateData).eq('email', email);

      return _formatResponse(
        success: true,
        message: 'Premium status updated successfully',
      );
    } catch (e) {
      debugPrint('Error updating premium status: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to update premium status: $e',
      );
    }
  }

  // Method to check trial status from database
  Future<Map<String, dynamic>> checkTrialStatus({required String email}) async {
    try {
      final userData = await _client
          .from('user')
          .select(
              'is_premium, trial_start_date, trial_end_date, premium_converted_date')
          .eq('email', email)
          .maybeSingle();

      if (userData == null) {
        return _formatResponse(
          success: false,
          message: 'User not found',
        );
      }

      final isPremium = userData['is_premium'] ?? false;
      final trialStartDate = userData['trial_start_date'];
      final trialEndDate = userData['trial_end_date'];
      final premiumConvertedDate = userData['premium_converted_date'];

      bool hasActiveAccess = isPremium;
      bool isOnTrial = false;
      bool trialExpired = false;

      // Check trial status if not premium
      if (!isPremium && trialStartDate != null && trialEndDate != null) {
        final now = DateTime.now();
        final endDate = DateTime.parse(trialEndDate);

        if (now.isBefore(endDate) || now.isAtSameMomentAs(endDate)) {
          isOnTrial = true;
          hasActiveAccess = true;
        } else {
          trialExpired = true;
        }
      }

      return _formatResponse(
        success: true,
        data: {
          'is_premium': isPremium,
          'has_active_access': hasActiveAccess,
          'is_on_trial': isOnTrial,
          'trial_expired': trialExpired,
          'trial_start_date': trialStartDate,
          'trial_end_date': trialEndDate,
          'premium_converted_date': premiumConvertedDate,
        },
      );
    } catch (e) {
      debugPrint('Error checking trial status: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to check trial status: $e',
      );
    }
  }

  // Method to set user as premium (after payment)
  Future<Map<String, dynamic>> setPremiumStatus({
    required String email,
    DateTime? conversionDate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'is_premium': true,
      };

      // Add premium conversion date if provided
      if (conversionDate != null) {
        updateData['premium_converted_date'] = conversionDate
            .toIso8601String()
            .split('T')[0]; // Store date in YYYY-MM-DD format
        debugPrint(
            'Setting premium conversion date: ${conversionDate.toIso8601String().split('T')[0]}');
      }

      await _client.from('user').update(updateData).eq('email', email);

      return _formatResponse(
        success: true,
        message: 'User set as premium successfully',
      );
    } catch (e) {
      debugPrint('Error setting premium status: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to set premium status: $e',
      );
    }
  }

  // Upsert (insert or increment) Thought Shredder activity for today
  Future<Map<String, dynamic>> upsertThoughtShredderActivity({
    required String email,
    required String? userName,
    required DateTime date,
  }) async {
    try {
      final shredDate = date.toIso8601String().split('T')[0];
      // Check if a record exists for this user and date
      final existing = await _client
          .from('daily_shredded_thoughts')
          .select()
          .eq('email', email)
          .eq('shred_date', shredDate)
          .maybeSingle();

      if (existing != null) {
        // Increment shred_count
        final newCount = (existing['shred_count'] ?? 0) + 1;
        await _client.from('daily_shredded_thoughts').update({
          'shred_count': newCount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
        return _formatResponse(
            success: true, message: 'Shred count incremented');
      } else {
        // Insert new record
        await _client.from('daily_shredded_thoughts').insert({
          'email': email,
          'user_name': userName,
          'shred_date': shredDate,
          'shred_count': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
        return _formatResponse(
            success: true, message: 'Shred activity inserted');
      }
    } catch (e) {
      debugPrint('Error upserting Thought Shredder activity: $e');
      return _formatResponse(
          success: false, message: 'Failed to upsert activity: $e');
    }
  }

  // Fetch all Thought Shredder activity for the current user for the current year
  Future<Map<String, dynamic>> fetchThoughtShredderActivity({
    required String email,
    required int year,
  }) async {
    try {
      final start = DateTime(year, 1, 1).toIso8601String().split('T')[0];
      final end = DateTime(year, 12, 31).toIso8601String().split('T')[0];
      final response = await _client
          .from('daily_shredded_thoughts')
          .select()
          .eq('email', email)
          .gte('shred_date', start)
          .lte('shred_date', end);
      return _formatResponse(success: true, data: response);
    } catch (e) {
      debugPrint('Error fetching Thought Shredder activity: $e');
      return _formatResponse(
          success: false, message: 'Failed to fetch activity: $e', data: []);
    }
  }

  // Upsert (insert or increment) activity for a mind tool (break_things, bubble_wrap_popper, make_me_smile)
  Future<Map<String, dynamic>> upsertMindToolActivity({
    required String email,
    required String? userName,
    required DateTime date,
    required String toolType,
  }) async {
    try {
      final activityDate = date.toIso8601String().split('T')[0];
      debugPrint(
          '🔄 SupabaseDB: Upserting $toolType activity for $email on $activityDate');

      // Check if a record exists for this user, tool, and date
      debugPrint(
          '🔍 SupabaseDB: Searching for existing record: email=$email, tool_type=$toolType, activity_date=$activityDate');
      final existingList = await _client
          .from('mind_tools_daily_activity')
          .select()
          .eq('email', email)
          .eq('tool_type', toolType)
          .eq('activity_date', activityDate);

      debugPrint(
          '🔍 SupabaseDB: Found ${existingList.length} existing records');
      final existing = existingList.isNotEmpty ? existingList.first : null;

      if (existing != null) {
        // Increment activity_count
        final currentCount = existing['activity_count'] ?? 0;
        final newCount = currentCount + 1;
        debugPrint(
            '📈 SupabaseDB: Existing record found, incrementing from $currentCount to $newCount');

        await _client.from('mind_tools_daily_activity').update({
          'activity_count': newCount,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);

        debugPrint(
            '✅ SupabaseDB: Activity count incremented to $newCount for $toolType');
        return _formatResponse(
            success: true, message: 'Activity count incremented to $newCount');
      } else {
        // Insert new record
        debugPrint(
            '📝 SupabaseDB: No existing record, inserting new activity for $toolType');

        await _client.from('mind_tools_daily_activity').insert({
          'email': email,
          'user_name': userName,
          'activity_date': activityDate,
          'tool_type': toolType,
          'activity_count': 1,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ SupabaseDB: New activity inserted for $toolType');
        return _formatResponse(
            success: true, message: 'New activity inserted for $toolType');
      }
    } catch (e) {
      debugPrint('❌ SupabaseDB: Error upserting $toolType activity: $e');
      return _formatResponse(
          success: false, message: 'Failed to upsert $toolType activity: $e');
    }
  }

  // Fetch all activity for a mind tool for the current user for the current year
  Future<Map<String, dynamic>> fetchMindToolActivity({
    required String email,
    required String toolType,
    required int year,
  }) async {
    try {
      final start = DateTime(year, 1, 1).toIso8601String().split('T')[0];
      final end = DateTime(year, 12, 31).toIso8601String().split('T')[0];
      debugPrint(
          '📊 SupabaseDB: Fetching $toolType activity for $email ($start to $end)');

      final response = await _client
          .from('mind_tools_daily_activity')
          .select()
          .eq('email', email)
          .eq('tool_type', toolType)
          .gte('activity_date', start)
          .lte('activity_date', end);

      debugPrint(
          '📊 SupabaseDB: Found ${response.length} records for $toolType');
      for (final record in response) {
        debugPrint(
            '📅 SupabaseDB: $toolType ${record['activity_date']} -> ${record['activity_count']} activities');
      }

      return _formatResponse(success: true, data: response);
    } catch (e) {
      debugPrint('❌ SupabaseDB: Error fetching $toolType activity: $e');
      return _formatResponse(
          success: false,
          message: 'Failed to fetch $toolType activity: $e',
          data: []);
    }
  }
}
