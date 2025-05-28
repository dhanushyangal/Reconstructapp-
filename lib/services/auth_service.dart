import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'mysql_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math'; // Add import for Random
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'subscription_manager.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isInitializing = false;

  // MySQL database service
  late final MySqlDatabaseService _mysqlService;

  // Constructor that initializes the MySQL service
  AuthService() {
    _mysqlService = MySqlDatabaseService(
      baseUrl: ApiConfig.baseUrl,
    );
    debugPrint('AuthService: Initialized with API URL: ${ApiConfig.baseUrl}');
  }

  // User data from MySQL
  Map<String, dynamic>? _userData;

  // Getter for user data
  Map<String, dynamic>? get userData => _userData;

  // Getter for initialization status
  bool get isInitializing => _isInitializing;

  // Add method to check if user is signed in
  bool isUserSignedIn() {
    return _userData != null || _auth.currentUser != null;
  }

  // Add method to get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Initialize auth service and check for stored token
  Future<void> initialize() async {
    // Prevent concurrent initializations
    if (_isInitializing) {
      debugPrint(
          'AuthService initialize: Already initializing, skipping duplicate call');
      return;
    }

    _isInitializing = true;
    notifyListeners();

    debugPrint('AuthService initialize: Starting initialization');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      debugPrint(
          'AuthService initialize: Checking for stored token. Token exists: ${token != null}');

      if (token != null) {
        // We have a stored token, attempt to get user profile
        try {
          // Set the token in MySQL service first
          _mysqlService.authToken = token;
          debugPrint(
              'AuthService initialize: Attempting to get user profile with stored token');

          final response = await _mysqlService.getUserProfile().timeout(
            const Duration(seconds: 5), // Shorter timeout for better UX
            onTimeout: () {
              debugPrint('AuthService initialize: Profile request timed out');
              return {
                'success': false,
                'message': 'Connection timed out',
              };
            },
          );

          debugPrint(
              'AuthService initialize: Got response: success=${response['success']}');

          if (response['success']) {
            _userData = response['user'];
            debugPrint(
                'AuthService initialize: User authenticated with token. User: ${_userData?['email']}');
            _isInitializing = false;
            notifyListeners();
            return; // Success, we are authenticated with MySQL
          } else {
            // Token is invalid, clear it
            debugPrint('AuthService initialize: Token invalid, clearing');
            _userData = null;
            await prefs.remove('auth_token');
          }
        } catch (e) {
          debugPrint('Error initializing auth: $e');
          // Clear token on error
          _userData = null;
          await prefs.remove('auth_token');
        }
      } else {
        debugPrint('AuthService initialize: No stored token found');
      }

      // Check if user is signed in with Firebase as a fallback
      final firebaseUser = FirebaseAuth.instance.currentUser;
      debugPrint(
          'AuthService initialize: Firebase user exists: ${firebaseUser != null}');

      // If we have a Firebase user but no MySQL token, try to link the accounts or log in
      if (firebaseUser != null && _userData == null) {
        debugPrint(
            'AuthService initialize: Firebase user without MySQL token, checking if we can authenticate');

        // Here you could add logic to authenticate with MySQL using Firebase credentials
        // For now, just use the Firebase user data as a fallback to prevent endless refresh cycles
        if (_userData == null) {
          // Create a basic user data object from Firebase user
          _userData = {
            'email': firebaseUser.email ?? 'No Email',
            'name': firebaseUser.displayName ??
                firebaseUser.email?.split('@')[0] ??
                'User',
            'id': firebaseUser.uid,
            'firebase_user':
                true, // Flag to indicate this is from Firebase, not MySQL
          };

          debugPrint(
              'AuthService initialize: Created fallback user data from Firebase');
        }
      }
    } catch (e) {
      debugPrint('Critical error in AuthService initialize: $e');
      // In case of critical error, ensure userData is null
      _userData = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Direct check if user is authenticated without waiting for initialize
  bool hasAuthenticatedUser() {
    // Check MySQL
    final hasMySqlUser = _userData != null;

    // Check Firebase
    final hasFirebaseUser = _auth.currentUser != null;

    debugPrint(
        'Direct auth check - MySQL: $hasMySqlUser, Firebase: $hasFirebaseUser');

    return hasMySqlUser || hasFirebaseUser;
  }

  // Register with email and password using MySQL
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint(
          'AuthService: Attempting registration with MySQL for email: $email');

      final response = await _mysqlService
          .registerUser(
        username: username,
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint(
              'AuthService: Registration request timed out after 15 seconds');
          return {
            'success': false,
            'message':
                'Registration request timed out. Please check your connection and try again.',
          };
        },
      );

      if (response['success']) {
        debugPrint('AuthService: MySQL registration successful for: $email');

        // Ensure we have complete user data
        if (response['user'] != null) {
          _userData = response['user'];
          debugPrint(
              'AuthService: User data received after registration: ${_userData?.toString()}');

          // Log specific fields to help debug
          debugPrint('AuthService: User email: ${_userData?['email']}');
          debugPrint('AuthService: Name: ${_userData?['name']}');
          debugPrint('AuthService: User ID: ${_userData?['id']}');

          // If name is missing in the response, add it manually
          if (_userData != null &&
              (_userData!['name'] == null ||
                  _userData!['name'].toString().isEmpty)) {
            debugPrint('AuthService: Adding missing name to user data');
            _userData!['name'] = username;
          }
        } else {
          debugPrint(
              'AuthService: Warning - No user data received in registration response');
          // Create minimal user data if none was returned
          _userData = {
            'email': email,
            'name': username,
            'id': DateTime.now()
                .millisecondsSinceEpoch
                .toString(), // Temporary ID
          };
          debugPrint('AuthService: Created minimal user data: $_userData');
        }

        // Store token in shared preferences
        if (response.containsKey('token') && response['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response['token']);
          debugPrint(
              'AuthService: Token stored in preferences after registration');
        } else {
          debugPrint(
              'AuthService: No token received from server after registration!');
        }
      } else {
        debugPrint(
            'AuthService: MySQL registration failed: ${response['message']}');
        _userData = null;
      }

      return response;
    } catch (e) {
      debugPrint('Error in registerWithEmailAndPassword: $e');
      _userData = null;
      return {
        'success': false,
        'message': 'An error occurred during registration: $e',
      };
    }
  }

  // Login with email and password using MySQL
  Future<Map<String, dynamic>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting MySQL login for email: $email');

      final response = await _mysqlService
          .loginUser(
        email: email,
        password: password,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('AuthService: Login request timed out after 15 seconds');
          return {
            'success': false,
            'message':
                'Login request timed out. Please check your connection and try again.',
          };
        },
      );

      if (response['success']) {
        debugPrint('AuthService: MySQL login successful for: $email');

        // Store user data
        _userData = response['user'];
        debugPrint('User data stored: ${_userData.toString()}');

        // Store auth token
        if (response['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', response['token']);
          debugPrint('Authentication token saved to preferences');

          // Check if the user is premium and update status
          debugPrint('Checking premium status after successful login...');

          final subscriptionManager = SubscriptionManager();

          // First, ensure all premium flags are reset to avoid inconsistency
          await prefs.setBool('has_completed_payment', false);
          await prefs.setBool('is_subscribed', false);
          await prefs.setBool('premium_features_enabled', false);

          // Use enhanced premium sync method
          await subscriptionManager.syncPremiumStatusOnLogin(response['token']);

          // Double-check premium status directly from server for consistency
          final isPremium =
              await subscriptionManager.checkPremiumStatus(response['token']);

          debugPrint('Server premium status verified after login: $isPremium');

          // If premium, ensure all flags are set and refresh UI
          if (isPremium) {
            debugPrint('User is premium, ensuring all premium flags are set');
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('is_subscribed', true);
            await prefs.setBool('premium_features_enabled', true);

            // Refresh premium features UI
            await subscriptionManager.refreshPremiumFeatures();
          }
        }

        // Create Firebase account with these credentials
        try {
          // Check if this user already exists in Firebase
          final firebaseAuth = FirebaseAuth.instance;
          User? firebaseUser;

          try {
            final userCredential = await firebaseAuth
                .signInWithEmailAndPassword(
                  email: email,
                  password: password,
                )
                .timeout(
                  const Duration(seconds: 5),
                );
            firebaseUser = userCredential.user;
            debugPrint(
                'Existing Firebase account found, signed in: ${firebaseUser?.email}');
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              debugPrint(
                  'No Firebase account found, will create a new account');
              // Create a new account
              final userCredential = await firebaseAuth
                  .createUserWithEmailAndPassword(
                    email: email,
                    password: password,
                  )
                  .timeout(
                    const Duration(seconds: 5),
                  );
              firebaseUser = userCredential.user;
              debugPrint(
                  'New Firebase account created: ${firebaseUser?.email}');
            } else {
              // For other errors, continue without Firebase
              debugPrint('Firebase auth error: ${e.code} - ${e.message}');
            }
          } catch (e) {
            // For timeout or other errors, continue without Firebase
            debugPrint('Error signing in with Firebase: $e');
          }
        } catch (e) {
          // Error with Firebase auth but MySQL login was successful,
          // so we continue without Firebase
          debugPrint('Failed to create Firebase account: $e');
        }

        return response;
      } else {
        debugPrint(
            'AuthService: MySQL login failed: ${response['message'] ?? 'Unknown error'}');
        return response;
      }
    } catch (e) {
      debugPrint('Error in loginWithEmailAndPassword: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Check if Firebase is initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Make sure to sign out completely from any previous session
      try {
        await _auth.signOut();
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
        debugPrint('Previous sign-in sessions cleared');
      } catch (e) {
        debugPrint('Error clearing previous sessions: $e');
        // Continue with sign-in process even if clearing fails
      }

      // Add a small delay to ensure previous sign-out is processed
      await Future.delayed(const Duration(milliseconds: 500));

      // Trigger the Google Sign-In flow with forceCodeForRefreshToken to ensure fresh tokens
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('User cancelled Google Sign-In');
        return null;
      }

      debugPrint('Google Sign-In successful for: ${googleUser.email}');

      // Get authentication details with forceRefresh set to true
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if we have valid tokens
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        debugPrint('Failed to get valid Google auth tokens');
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Could not obtain valid Google authentication tokens',
        );
      }

      // Create credential with fresh tokens
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Attempting Firebase sign-in with Google credential');

      // Sign in with Firebase with force refresh
      final userCredential = await _auth.signInWithCredential(credential);

      // Verify sign in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint(
            'Firebase sign-in failed - no current user after authentication');
        throw FirebaseAuthException(
          code: 'sign-in-failed',
          message: 'Firebase authentication succeeded but no user was returned',
        );
      }

      debugPrint('User signed in with Google: ${currentUser.email}');

      // Store user data in MySQL
      debugPrint('Storing Google user data in MySQL');
      try {
        // Generate a secure random password for Google users
        final String securePassword = _generateSecurePassword();
        debugPrint(
            'Generated secure password for Google user: $securePassword');

        // First try to login with Google credentials
        var response = await _mysqlService.loginUser(
          email: currentUser.email!,
          password: securePassword,
          isGoogleSignIn: true,
          googleData: {
            'displayName':
                currentUser.displayName ?? currentUser.email!.split('@')[0],
            'firebaseUid': currentUser.uid,
            'hasGeneratedPassword': true,
            'storePassword': true,
            'passwordRequiresHashing': true,
          },
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('MySQL login request timed out');
            return {
              'success': false,
              'message': 'Connection to server timed out',
            };
          },
        );

        // If login fails, try to register the user
        if (!response['success'] &&
            response['message']?.toLowerCase().contains('not found')) {
          debugPrint('User not found in MySQL, attempting registration');

          // Register the user in MySQL
          response = await _mysqlService
              .registerUser(
            username:
                currentUser.displayName ?? currentUser.email!.split('@')[0],
            email: currentUser.email!,
            password: securePassword,
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              debugPrint('MySQL registration request timed out');
              return {
                'success': false,
                'message': 'Connection to server timed out',
              };
            },
          );

          if (response['success']) {
            debugPrint('Successfully registered Google user in MySQL');

            // Now try to login again to get the proper token
            response = await _mysqlService.loginUser(
              email: currentUser.email!,
              password: securePassword,
              isGoogleSignIn: true,
              googleData: {
                'displayName':
                    currentUser.displayName ?? currentUser.email!.split('@')[0],
                'firebaseUid': currentUser.uid,
                'hasGeneratedPassword': true,
                'storePassword': true,
                'passwordRequiresHashing': true,
              },
            ).timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('MySQL login after registration timed out');
                return {
                  'success': false,
                  'message': 'Connection to server timed out',
                };
              },
            );
          }
        }

        if (response['success']) {
          debugPrint('Successfully stored Google user data in MySQL');

          // Store user data
          _userData = response['user'];
          debugPrint('User data stored: ${_userData.toString()}');

          // Store token in shared preferences
          if (response['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', response['token']);
            debugPrint('MySQL auth token stored in preferences');

            // Sync premium status with server if needed
            try {
              final subscriptionManager = SubscriptionManager();

              // First, ensure all premium flags are reset to avoid inconsistency
              await prefs.setBool('has_completed_payment', false);
              await prefs.setBool('is_subscribed', false);
              await prefs.setBool('premium_features_enabled', false);

              // Use enhanced premium sync method
              await subscriptionManager
                  .syncPremiumStatusOnLogin(response['token']);

              // Double-check premium status directly from server for consistency
              final isPremium = await subscriptionManager
                  .checkPremiumStatus(response['token']);

              debugPrint(
                  'Server premium status verified after Google sign-in: $isPremium');

              // If premium, ensure all flags are set and refresh UI
              if (isPremium) {
                debugPrint(
                    'Google user is premium, ensuring all premium flags are set');
                await prefs.setBool('has_completed_payment', true);
                await prefs.setBool('is_subscribed', true);
                await prefs.setBool('premium_features_enabled', true);

                // Refresh premium features UI
                await subscriptionManager.refreshPremiumFeatures();
              }
            } catch (e) {
              debugPrint(
                  'AuthService: Error syncing/checking premium status after Google sign-in: $e');
            }
          }
        } else {
          debugPrint(
              'Failed to store Google user data in MySQL: ${response['message']}');
          // Continue even if MySQL storage fails - we still have Firebase auth
        }
      } catch (e) {
        debugPrint('Error storing Google user data in MySQL: $e');
        // Continue even if MySQL storage fails - we still have Firebase auth
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error in signInWithGoogle: $e');

      // Handle specific Firebase auth errors
      if (e is FirebaseAuthException) {
        if (e.code == 'invalid-credential' ||
            e.message?.contains('stale') == true ||
            e.message?.contains('expired') == true) {
          debugPrint('Handling stale token error: ${e.message}');
          // Clear any stored credentials
          try {
            await _auth.signOut();
            await _googleSignIn.signOut();
            await _googleSignIn.disconnect();
          } catch (_) {}
        }
      }

      rethrow;
    }
  }

  // Helper method to generate a secure random password
  String _generateSecurePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    final random = Random.secure();
    // Generate a password of length 16
    return String.fromCharCodes(List.generate(
        16, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  Future<void> signOut() async {
    // Clear MySQL user data and token
    _userData = null;
    await _mysqlService.logout();

    // Clear stored token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    // Sign out of Google/Firebase
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Method to update the base URL (useful for testing on physical devices)
  void updateApiUrl(String newUrl) {
    _mysqlService.baseUrl = newUrl;
  }

  // Add a method to get the auth token for API calls
  Future<String?> getToken() async {
    try {
      // First try to get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token != null && token.isNotEmpty) {
        return token;
      }

      // If no token in preferences, check if we can get one from Firebase
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        try {
          final idToken = await firebaseUser.getIdToken();
          if (idToken != null && idToken.isNotEmpty) {
            // If this is the first time we're getting a Firebase token,
            // we could store it in preferences for future use
            await prefs.setString('auth_token', idToken);
            return idToken;
          }
        } catch (e) {
          debugPrint('Error getting Firebase ID token: $e');
        }
      }

      // If we have userData but no token, attempt to login again to get a token
      if (_userData != null && _userData!['email'] != null) {
        // This is a fallback and might not work in all cases
        debugPrint(
            'No token found but user data exists. Consider re-authenticating.');
      }

      return null;
    } catch (e) {
      debugPrint('Error in getToken: $e');
      return null;
    }
  }
}
