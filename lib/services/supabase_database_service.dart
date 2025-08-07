import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class SupabaseDatabaseService {
  // Supabase client instance
  late final supabase.SupabaseClient _client;

  // Email API configuration
  static const String _emailApiUrl = 'https://reconstrect-api.onrender.com';

  // Constructor
  SupabaseDatabaseService() {
    _client = SupabaseConfig.client;
  }

  // Use main client for auth operations (has proper storage)
  supabase.SupabaseClient get _authClient => _client;

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

  // Method to check if email already exists in user table
  Future<bool> _checkEmailExists(String email) async {
    try {
      debugPrint('🔍 Checking if email exists: $email');

      // Create a public client for checking email availability (no auth required)
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );

      // Check in user table using public client
      final response = await publicClient
          .from('user')
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

      // Create a public client for checking username availability (no auth required)
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );

      // Check in public.user table using public client
      final response = await publicClient
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

      // Create auth user with Supabase Auth (without email confirmation)
      debugPrint(
          'SupabaseDatabaseService: Registering user with username: $username');

      // Register user with email confirmation for normal Supabase registration
      debugPrint('🔐 Attempting to register user with Supabase Auth...');
      
      final supabase.AuthResponse response = await _authClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'name': username,
          'display_name': username,
        },
        emailRedirectTo: 'https://reconstructyourmind.com/email-verification-handler.php',
      );
      
      debugPrint('🔐 Supabase Auth response: ${response.user?.id}');
      debugPrint('🔐 User created in auth.users: ${response.user != null}');

      debugPrint('SupabaseDatabaseService: Registration response received');
      debugPrint(
          'SupabaseDatabaseService: User metadata: ${response.user?.userMetadata}');

      if (response.user != null) {
        debugPrint('User registered successfully. Creating user record in database...');

        // Check if email confirmation is required
        final requiresEmailConfirmation = response.user!.emailConfirmedAt == null;

        // Create user record immediately for all registrations
        debugPrint('Creating user record immediately...');
        
        try {
          // Create user record immediately in the user table
          final now = DateTime.now();
          final trialEndDate = now.add(const Duration(days: 7));
          
          final userData = {
            'name': username,
            'email': email,
            'password_hash': 'supabase_auth',
            'welcome_email_sent': false,
            'is_premium': false,
            'trial_start_date': now.toIso8601String().split('T')[0],
            'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
            'created_at': now.toIso8601String(),
          };

          // Try to insert user data using public client to bypass RLS
          final publicClient = supabase.SupabaseClient(
            'https://ruxsfzvrumqxsvanbbow.supabase.co',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
          );

          await publicClient.from('user').insert(userData);
          debugPrint('✅ User record created successfully in database');
        } catch (dbError) {
          debugPrint('⚠️ Failed to create user record: $dbError');
          // Continue anyway - user can still log in
        }

        // Format user data to match the expected structure
        final userData = {
          'id': response.user!.id,
          'email': response.user!.email,
          'username': username,
          'name': username,
          'is_premium': false,
          'email_confirmed': !requiresEmailConfirmation,
        };

        String message;
        if (requiresEmailConfirmation) {
          message = 'Registration successful! Your account has been created. Please check your email and click the confirmation link to activate your account.';
        } else {
          message = 'Registration successful! Your account has been created and you can now log in.';
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
      debugPrint('❌ Error in registerUser: $e');
      debugPrint('❌ Error type: ${e.runtimeType}');

      String errorMessage = 'An error occurred during registration';
      if (e is supabase.AuthException) {
        errorMessage = e.message;
        debugPrint('❌ AuthException: ${e.message}');
        debugPrint('❌ AuthException status: ${e.statusCode}');
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
          '🔐 SupabaseDatabaseService: Calling main client signInWithPassword...');
      final supabase.AuthResponse response =
          await _authClient.auth.signInWithPassword(
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
  // Remove Supabase Google sign-in method
  // Remove: Future<Map<String, dynamic>> signInWithGoogle() async { ... }

  // Method to get the current user's profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final currentUser = _authClient.auth.currentUser;

      if (currentUser == null) {
        return _formatResponse(
          success: false,
          message: 'No authenticated user found',
        );
      }

      // Get additional user data from custom user table
      Map<String, dynamic>? customUserData;
      try {
        customUserData = await _authClient
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
            await _authClient.rpc('create_user_profile', params: {
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
            await _authClient.from('user').insert({
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
            customUserData = await _authClient
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
      await _authClient.auth.signOut();
    } catch (e) {
      debugPrint('Error in logout: $e');
    }
  }

  // Method to delete user account and all associated data
  Future<Map<String, dynamic>> deleteAccount() async {
    debugPrint('SupabaseDatabaseService: Starting account deletion');
    try {
      final currentUser = _authClient.auth.currentUser;
      if (currentUser == null) {
        return _formatResponse(
          success: false,
          message: 'No authenticated user found',
        );
      }

      final userEmail = currentUser.email;
      if (userEmail == null) {
        return _formatResponse(
          success: false,
          message: 'User email not found',
        );
      }

      debugPrint('Deleting account for user: $userEmail');

      // 1. Delete all vision board tasks
      await _authClient.from('vision_board_tasks').delete().eq('email', userEmail);

      // 2. Delete all annual calendar tasks
      await _authClient
          .from('annual_calendar_tasks')
          .delete()
          .eq('email', userEmail);

      // 3. Delete all daily shredded thoughts
      await _authClient
          .from('daily_shredded_thoughts')
          .delete()
          .eq('email', userEmail);

      // 4. Delete all mind tools daily activity
      await _authClient
          .from('mind_tools_daily_activity')
          .delete()
          .eq('email', userEmail);

      // 5. Delete user record from custom user table
      await _authClient.from('user').delete().eq('email', userEmail);

      // 6. Try to delete the user from auth.users using a server function
      // This requires a server-side function to be created in Supabase
      bool authUserDeleted = false;
      try {
        await _authClient.rpc('delete_user_account', params: {
          'user_id': currentUser.id,
        });
        debugPrint('User deleted from auth.users successfully');
        authUserDeleted = true;
      } catch (rpcError) {
        debugPrint('Could not delete from auth.users: $rpcError');
        // This is expected if the server function doesn't exist
        // We'll handle this gracefully
      }

      // 6b. Alternative method: Try to delete using direct SQL if server function doesn't exist
      if (!authUserDeleted) {
        try {
          // Try to use a different approach - this might work in some cases
          await _authClient.from('auth.users').delete().eq('id', currentUser.id);
          debugPrint('User deleted from auth.users using direct method');
          authUserDeleted = true;
        } catch (directError) {
          debugPrint('Direct deletion also failed: $directError');
          // This is expected due to RLS policies
        }
      }

      // 7. Sign out the user
      await _authClient.auth.signOut();

      debugPrint('Account deletion completed successfully');

      String message;
      if (authUserDeleted) {
        message =
            'Account deleted successfully. All your data has been removed.';
      } else {
        message =
            'Account data deleted successfully. Your authentication record may still exist for security purposes.';
      }

      return _formatResponse(
        success: true,
        message: message,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to delete account: $e',
      );
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

  // Check if user is authenticated (use Firebase when using accessToken function)
  bool get isAuthenticated {
    try {
      // When using accessToken function, check Firebase auth instead
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      return firebaseUser != null;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      return false;
    }
  }

  // Get current user (use Firebase when using accessToken function)
  dynamic get currentUser {
    try {
      // When using accessToken function, return Firebase user wrapped
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return _FirebaseUserWrapper(firebaseUser);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting current user: $e');
      return null;
    }
  }

  // Get auth token
  String? get authToken {
    try {
      // Check if we have a Supabase session (for native auth users)
      final supabaseSession = _authClient.auth.currentSession;
      if (supabaseSession != null) {
        return supabaseSession.accessToken;
      }
      
      // Check if we have a Firebase user (for social login users)
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // For Firebase users, the token is handled by the accessToken function in SupabaseConfig
        // But we can return a placeholder to indicate authentication
        return 'firebase_authenticated';
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting auth token: $e');
      return null;
    }
  }

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

      await _authClient.from('user').update(updateData).eq('email', email);

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
      debugPrint('🔄 Checking trial status for: $email');
      
      // Since Supabase session creation is failing, use public client directly
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );
      
      try {
        debugPrint('🔍 Querying user table for email: $email');
        final userData = await publicClient
            .from('user')
            .select(
                'is_premium, trial_start_date, trial_end_date, premium_converted_date')
            .eq('email', email)
            .maybeSingle();

        debugPrint('🔍 Query result: $userData');

        if (userData != null) {
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

          debugPrint('✅ Premium status check successful (public client): isPremium=$isPremium, hasActiveAccess=$hasActiveAccess, isOnTrial=$isOnTrial');

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
        } else {
          debugPrint('❌ User not found in database for premium status check: $email');
          return _formatResponse(
            success: false,
            message: 'User not found',
          );
        }
      } catch (publicError) {
        debugPrint('❌ Public client failed for premium status check: $publicError');
        return _formatResponse(
          success: false,
          message: 'Failed to check trial status: $publicError',
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking trial status: $e');
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

      await _authClient.from('user').update(updateData).eq('email', email);

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
      debugPrint('🔄 Upserting Thought Shredder activity for: $email');
      
      // Ensure Supabase session exists for Firebase users
      await SupabaseConfig.ensureSupabaseSession();
      
      final shredDate = date.toIso8601String().split('T')[0];
      
      // Try using authenticated client first
      try {
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
          debugPrint('✅ Thought Shredder activity incremented successfully');
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
          debugPrint('✅ Thought Shredder activity inserted successfully');
          return _formatResponse(
              success: true, message: 'Shred activity inserted');
        }
      } catch (authError) {
        debugPrint('⚠️ Authenticated client failed for Thought Shredder: $authError');
        
        // Fallback: Try using public client
        try {
          final publicClient = supabase.SupabaseClient(
            'https://ruxsfzvrumqxsvanbbow.supabase.co',
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
          );
          
          // Check if a record exists for this user and date
          final existing = await publicClient
              .from('daily_shredded_thoughts')
              .select()
              .eq('email', email)
              .eq('shred_date', shredDate)
              .maybeSingle();

          if (existing != null) {
            // Increment shred_count
            final newCount = (existing['shred_count'] ?? 0) + 1;
            await publicClient.from('daily_shredded_thoughts').update({
              'shred_count': newCount,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', existing['id']);
            debugPrint('✅ Thought Shredder activity incremented via public client');
            return _formatResponse(
                success: true, message: 'Shred count incremented');
          } else {
            // Insert new record
            await publicClient.from('daily_shredded_thoughts').insert({
              'email': email,
              'user_name': userName,
              'shred_date': shredDate,
              'shred_count': 1,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            debugPrint('✅ Thought Shredder activity inserted via public client');
            return _formatResponse(
                success: true, message: 'Shred activity inserted');
          }
        } catch (publicError) {
          debugPrint('❌ Public client failed for Thought Shredder: $publicError');
          return _formatResponse(
              success: false, message: 'Failed to upsert Thought Shredder activity: $publicError');
        }
      }
    } catch (e) {
      debugPrint('❌ Error in upsertThoughtShredderActivity: $e');
      return _formatResponse(
          success: false, message: 'Failed to upsert Thought Shredder activity: $e');
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
      
      // Use public client since authenticated client has session issues
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );
      
      final response = await publicClient
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

      // Ensure Supabase session exists for Firebase users
      await SupabaseConfig.ensureSupabaseSession();

      // Create a public client for activity operations (bypasses RLS)
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );

      // Try using public client first (bypasses RLS)
      try {
        // Check if a record exists for this user, tool, and date
        debugPrint(
            '🔍 SupabaseDB: Searching for existing record: email=$email, tool_type=$toolType, activity_date=$activityDate');
        final existingList = await publicClient
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

          await publicClient.from('mind_tools_daily_activity').update({
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

          await publicClient.from('mind_tools_daily_activity').insert({
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
      } catch (publicError) {
        debugPrint('⚠️ Public client failed for $toolType: $publicError');
        
        // Fallback: Try using authenticated client
        try {
          // Check if a record exists for this user, tool, and date
          debugPrint(
              '🔍 SupabaseDB: Searching with authenticated client: email=$email, tool_type=$toolType, activity_date=$activityDate');
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
                '✅ SupabaseDB: Activity count incremented to $newCount for $toolType via authenticated client');
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

            debugPrint('✅ SupabaseDB: New activity inserted for $toolType via authenticated client');
            return _formatResponse(
                success: true, message: 'New activity inserted for $toolType');
          }
        } catch (authError) {
          debugPrint('❌ Both public and authenticated clients failed for $toolType: $authError');
          return _formatResponse(
              success: false, message: 'Failed to upsert $toolType activity: $authError');
        }
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

      // Use public client since authenticated client has session issues
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );

      final response = await publicClient
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

  /// Check if a user exists in user table by email
  Future<bool> isUserInUserTable(String email) async {
    try {
      // Create a public client for checking user existence (no auth required)
      final publicClient = supabase.SupabaseClient(
        'https://ruxsfzvrumqxsvanbbow.supabase.co',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg',
      );
      
      final result = await publicClient.from('user').select('id').eq('email', email).maybeSingle();
      return result != null;
    } catch (e) {
      debugPrint('Error checking user table: $e');
      return false;
    }
  }

  /// Insert user data into 'user' table after Firebase sign-in
  Future<void> upsertUserToUserAndUsersTables({
    required String id, // Firebase UID
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      debugPrint("🔄 Attempting to upsert user data for: $email");
      
      // Ensure Supabase session exists for Firebase users
      await SupabaseConfig.ensureSupabaseSession();
      
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
        'password_hash': 'firebase', // Added to satisfy NOT NULL constraint
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
        
        // If it's a duplicate key error, the user already exists
        if (insertError.toString().contains('duplicate key value violates unique constraint')) {
          debugPrint("✅ User already exists in database: $email");
          return;
        }
        
        // Fallback: Try upsert with conflict resolution
        try {
          await _client.from('user').upsert(userData, onConflict: 'email');
          debugPrint("✅ Successfully upserted user: $email");
        } catch (upsertError) {
          debugPrint("❌ All insertion methods failed for user: $email");
          debugPrint("Final error: $upsertError");
          // Don't throw - let the sign-in process continue
        }
      }
      
    } catch (e) {
      debugPrint("❌ Error in upsertUserToUserAndUsersTables: $e");
      // Don't throw the error - let the sign-in process continue
      // The user can still use the app even if database insertion fails
    }
  }

  Future<Map<String, dynamic>> upsertUserData({
    required String username,
    required String email,
    required String firebaseUid,
  }) async {
    try {
      debugPrint("🔄 Attempting to upsert user data for: $email");
      
      // Ensure Supabase session exists for Firebase users
      await SupabaseConfig.ensureSupabaseSession();
      
      // Prepare user data with all required fields
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 7));
      
      final userData = {
        'email': email,
        'name': username,
        'firebase_uid': firebaseUid,
        'password_hash': 'firebase',
        'welcome_email_sent': false,
        'is_premium': false,
        'trial_start_date': now.toIso8601String().split('T')[0],
        'trial_end_date': trialEndDate.toIso8601String().split('T')[0],
        'created_at': now.toIso8601String(),
      };
      
      debugPrint("📝 Inserting user data: $username ($email)");
      
      // Try to insert using authenticated client
      try {
        await _client.from('user').upsert(userData, onConflict: 'email');
        debugPrint("✅ Successfully upserted user into 'user' table: $email");
      } catch (upsertError) {
        debugPrint("❌ Upsert failed: $upsertError");
        return {'success': false, 'message': 'Failed to upsert user: $upsertError'};
      }

      // Also try to insert into 'users' table if it exists
      try {
        await _client.from('users').upsert({
          'email': email,
          'username': username,
          'supabase_uid': firebaseUid,
        });
        debugPrint("✅ Successfully upserted user into 'users' table: $email");
      } catch (usersError) {
        debugPrint("⚠️ Could not upsert into 'users' table: $usersError");
        // This is not critical, so we don't fail the operation
      }

      return {'success': true};
    } catch (e) {
      debugPrint("❌ Error in upsertUserData: $e");
      // If it's a 404 with empty message, treat as success
      if (e.toString().contains('code: 404') && e.toString().contains('message: {}')) {
        return {'success': true};
      }
      return {'success': false, 'message': 'Failed to upsert user: $e'};
    }
  }
}

// Wrapper class to make Firebase user compatible with Supabase user structure
class _FirebaseUserWrapper {
  final fb_auth.User _firebaseUser;

  _FirebaseUserWrapper(this._firebaseUser);

  // Mimic Supabase user properties
  String get id => _firebaseUser.uid;
  String? get email => _firebaseUser.email;
  String? get emailConfirmedAt => DateTime.now().toIso8601String(); // Assume confirmed for Firebase users
  Map<String, dynamic>? get userMetadata => {
    'name': _firebaseUser.displayName,
    'username': _firebaseUser.displayName,
    'avatar_url': _firebaseUser.photoURL,
    'picture': _firebaseUser.photoURL,
    'profile_image_url': _firebaseUser.photoURL,
  };
}
