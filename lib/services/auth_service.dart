import 'package:flutter/foundation.dart';
import 'supabase_database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';

class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  final SupabaseDatabaseService _supabaseService = SupabaseDatabaseService();

  // Current user data
  Map<String, dynamic>? _userData;
  bool _isInitializing = false;
  static bool _isGuest = false;
  static bool get isGuest => _isGuest;
  
  static Future<void> signInAsGuest() async {
    _isGuest = true;
    _instance?._userData = {
      'id': 'guest',
      'email': null,
      'name': 'Guest',
      'photoUrl': null,
      'firebase_uid': null,
    };
    // Save guest state to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest_user', true);
    _instance?.notifyListeners();
  }
  
  static Future<void> signOutGuest() async {
    _isGuest = false;
    _instance?._userData = null;
    // Clear guest state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest_user');
    _instance?.notifyListeners();
  }
  
  // Load guest state from SharedPreferences
  static Future<void> loadGuestState() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest_user') ?? false;
    if (_isGuest && _instance != null) {
      _instance!._userData = {
        'id': 'guest',
        'email': null,
        'name': 'Guest',
        'photoUrl': null,
        'firebase_uid': null,
      };
      _instance!.notifyListeners();
    }
  }

  static AuthService get instance {
    _instance ??= AuthService();
    return _instance!;
  }

  // Get current user data
  Map<String, dynamic>? get userData => _userData;

  // Get user email
  String? get userEmail {
    if (_isGuest) return null;
    if (_userData != null) return _userData!['email'];
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser?.email;
  }

  // Get user name
  String? get userName {
    if (_isGuest) return 'Guest';
    if (_userData != null) return _userData!['name'];
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser?.displayName;
  }

  // Get user ID
  String? get userId {
    if (_isGuest) return 'guest';
    if (_userData != null) return _userData!['id'];
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser?.uid;
  }

  // Get isInitializing state
  bool get isInitializing => _isInitializing;

  // Initialize the service
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    debugPrint('AuthService: Initializing with hybrid authentication');

    try {
      // Load guest state first
      await loadGuestState();
      
      // If guest, don't check authentication
      if (_isGuest) {
        debugPrint('AuthService: Guest user detected');
        _isInitializing = false;
        notifyListeners();
        return;
      }
      
      // Check if user is already authenticated with Firebase
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // User is authenticated with Firebase
        _userData = {
          'id': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'User',
          'photoUrl': firebaseUser.photoURL,
          'firebase_uid': firebaseUser.uid,
        };
        debugPrint('AuthService: User already authenticated with Firebase: ${firebaseUser.email}');
      } else {
        debugPrint('AuthService: No Firebase user found');
        
        // Check for existing Supabase session
        final supabaseSession = SupabaseConfig.nativeAuthClient.auth.currentSession;
        if (supabaseSession != null) {
          debugPrint('AuthService: Supabase session found');
          // Try to restore user data
          await _restoreUserSession();
        } else {
          // Check for persisted session data
          await _restoreUserSession();
        }
      }
    } catch (e) {
      debugPrint('AuthService: Error during initialization: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  // Check if user is authenticated
  bool hasAuthenticatedUser() {
    if (_isGuest) return true;
    
    // Check if we have user data stored (for Supabase auth)
    if (_userData != null && _userData!['id'] != null) {
      return true;
    }
    
    // Check Firebase auth (for social logins)
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return true;
    }
    
    // Check if we have a persisted session (for app restart scenarios)
    return _hasPersistedSession();
  }

  // Get current user (supports both Supabase and Firebase auth)
  dynamic getCurrentUser() {
    if (_isGuest) {
      return _GuestUserWrapper();
    }
    
    // If we have stored user data (Supabase auth), return it
    if (_userData != null && _userData!['id'] != null) {
      return _SupabaseUserWrapper(_userData!);
    }
    
    // Check Firebase auth (for social logins)
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return _FirebaseUserWrapper(firebaseUser);
    }
    
    return null;
  }

  // Add getter for currentUser for easier access
  dynamic get currentUser => getCurrentUser();

  // Check if there's a persisted session
  bool _hasPersistedSession() {
    try {
      // Check if we have stored user data
      if (_userData != null && _userData!['id'] != null) {
        return true;
      }
      
      // Check Firebase auth
      final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        return true;
      }
      
      // Check Supabase session
      final supabaseSession = SupabaseConfig.nativeAuthClient.auth.currentSession;
      if (supabaseSession != null) {
        return true;
      }
      
      // Check SharedPreferences for persisted data
      // Note: This is async, so we'll handle it in initialize()
      return false;
    } catch (e) {
      debugPrint('Error checking persisted session: $e');
      return false;
    }
  }

  // Persist user session data
  Future<void> _persistUserSession(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userData['id'] ?? '');
      await prefs.setString('user_email', userData['email'] ?? '');
      await prefs.setString('user_name', userData['name'] ?? userData['username'] ?? '');
      debugPrint('AuthService: User session persisted');
    } catch (e) {
      debugPrint('Error persisting user session: $e');
    }
  }

  // Clear persisted session data
  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      debugPrint('AuthService: User session cleared');
    } catch (e) {
      debugPrint('Error clearing persisted session: $e');
    }
  }

  // Restore user session from persistence
  Future<void> _restoreUserSession() async {
    try {
      debugPrint('AuthService: Attempting to restore user session...');
      
      // First, check if we have a valid Supabase session
      final supabaseSession = SupabaseConfig.nativeAuthClient.auth.currentSession;
      if (supabaseSession != null) {
        debugPrint('AuthService: Found valid Supabase session');
        final supabaseUser = SupabaseConfig.nativeAuthClient.auth.currentUser;
        
        if (supabaseUser != null) {
          // Restore user data from Supabase session
          _userData = {
            'id': supabaseUser.id,
            'email': supabaseUser.email,
            'name': supabaseUser.userMetadata?['name'] ?? supabaseUser.email?.split('@')[0] ?? 'User',
            'username': supabaseUser.userMetadata?['username'] ?? supabaseUser.email?.split('@')[0] ?? 'User',
            'supabase_uid': supabaseUser.id,
            'is_premium': false, // Will be fetched from database if needed
          };
          debugPrint('AuthService: User session restored from Supabase session: ${supabaseUser.email}');
          notifyListeners();
          return;
        }
      }
      
      // Fallback: Check SharedPreferences for persisted data
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      final userName = prefs.getString('user_name');
      
      if (userId != null && userId.isNotEmpty && userEmail != null) {
        debugPrint('AuthService: Found persisted session data');
        
        // Try to restore user data from Supabase database
        try {
          final supabaseService = SupabaseDatabaseService();
          final profileResult = await supabaseService.getUserProfile();
          
          if (profileResult['success'] == true && profileResult['user'] != null) {
            _userData = Map<String, dynamic>.from(profileResult['user']);
            debugPrint('AuthService: User session restored from database: ${_userData!['email']}');
            notifyListeners();
            return;
          }
        } catch (e) {
          debugPrint('AuthService: Could not restore from database: $e');
        }
        
        // Last resort: Use persisted data
        _userData = {
          'id': userId,
          'email': userEmail,
          'name': userName ?? userEmail.split('@')[0],
          'username': userName ?? userEmail.split('@')[0],
          'supabase_uid': userId,
          'is_premium': false,
        };
        debugPrint('AuthService: User session restored from SharedPreferences: $userEmail');
        notifyListeners();
      } else {
        debugPrint('AuthService: No persisted session data found');
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
    }
  }

  // Sign in with email and password (legacy method name for compatibility)
  Future<Map<String, dynamic>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await signInWithEmailPassword(email: email, password: password);
  }

  /// Sign in with email/password using Supabase Auth
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Clear guest state when signing in
      if (_isGuest) {
        await signOutGuest();
      }
      
      debugPrint('Starting Supabase email/password sign-in...');
      
      final result = await SupabaseDatabaseService().loginUser(
        email: email,
        password: password,
      );
      
      if (result['success']) {
        debugPrint('Supabase email/password sign-in successful');
        
        // Store user data in AuthService for consistency
        if (result['user'] != null) {
          _userData = Map<String, dynamic>.from(result['user']);
          debugPrint('AuthService: User data stored: $_userData');
          // Persist the session
          await _persistUserSession(_userData!);
          notifyListeners();
        }
        
        return result;
      } else {
        debugPrint('Supabase email/password sign-in failed: ${result['message']}');
        return result;
      }
      
    } catch (e) {
      debugPrint('Supabase email/password sign-in error: $e');
        return {
          'success': false,
        'message': 'Sign-in error: $e',
      };
    }
  }

  /// Register new user with email/password using Supabase Auth
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Clear guest state when signing in
      if (_isGuest) {
        await signOutGuest();
      }
      
      debugPrint('Starting Supabase email/password registration...');
      
      final result = await SupabaseDatabaseService().registerUser(
        email: email,
        password: password,
        username: username,
      );
      
      if (result['success']) {
        debugPrint('Supabase email/password registration successful');
        
        // Store user data in AuthService for consistency
        if (result['user'] != null) {
          _userData = Map<String, dynamic>.from(result['user']);
          debugPrint('AuthService: User data stored: $_userData');
          // Persist the session
          await _persistUserSession(_userData!);
          
          // Set new user flag for premium status refresh
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_new_user', true);
          debugPrint('AuthService: Set new user flag for premium status refresh');
          
          notifyListeners();
        }
        
        return result;
      } else {
        debugPrint('Supabase email/password registration failed: ${result['message']}');
        return result;
      }
      
    } catch (e) {
      debugPrint('Supabase email/password registration error: $e');
      return {
        'success': false,
        'message': 'Registration error: $e',
      };
    }
  }

  /// Sign in with Google using Firebase Auth
  Future<Map<String, dynamic>> signInWithGoogleFirebase() async {
    try {
      // Clear guest state when signing in
      if (_isGuest) {
        await signOutGuest();
      }
      
      debugPrint('Starting Firebase Google sign-in...');
      
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        debugPrint('Google sign-in cancelled by user');
        return {
          'success': false,
          'message': 'Google sign-in cancelled',
        };
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        debugPrint('Firebase user is null after sign-in');
        return {
          'success': false,
          'message': 'Firebase sign-in failed',
        };
      }
      
      debugPrint('Firebase Google sign-in successful: ${firebaseUser.email}');
      
      // Force refresh the Firebase ID token to ensure it's fresh
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        debugPrint('Failed to get Firebase ID token');
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }
      
      debugPrint('Firebase ID token refreshed successfully');
      
      // Create Supabase session from Firebase JWT
      debugPrint('AuthService: Creating Supabase session from Firebase JWT');
      final supabaseSessionCreated = await SupabaseConfig.ensureSupabaseSession();
      
      if (supabaseSessionCreated) {
        debugPrint('AuthService: Supabase session created successfully');
      } else {
        debugPrint('AuthService: Failed to create Supabase session, but continuing with Firebase auth');
      }
      
      // Check if this is a new user by checking if they exist in the database
      final supabaseService = SupabaseDatabaseService();
      final isNewUser = !(await supabaseService.isUserInUserTable(firebaseUser.email!));
      
      if (isNewUser) {
        debugPrint('AuthService: New Google user detected, setting new user flag');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_new_user', true);
      }
      
      // Return success with user data
      return {
        'success': true,
        'message': 'Google sign-in successful',
        'user': {
          'id': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'User',
          'photoUrl': firebaseUser.photoURL,
          'firebase_uid': firebaseUser.uid,
        },
        'firebaseUser': firebaseUser,
        'isNewUser': isNewUser,
      };
      
    } catch (e) {
      debugPrint('Firebase Google sign-in error: $e');
      return {
        'success': false,
        'message': 'Google sign-in error: $e',
      };
    }
  }

  /// Sign in with Apple using Firebase Auth
  Future<Map<String, dynamic>> signInWithAppleFirebase() async {
    try {
      // Clear guest state when signing in
      if (_isGuest) {
        await signOutGuest();
      }
      
      debugPrint('Starting Firebase Apple sign-in...');
      
      // Check if Apple Sign-In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        debugPrint('Apple Sign-In is not available on this device');
        return {
          'success': false,
          'message': 'Apple Sign-In is not available on this device',
        };
      }
      
      // Request Apple Sign-In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      
      if (credential.userIdentifier == null) {
        debugPrint('Apple Sign-In cancelled by user');
        return {
          'success': false,
          'message': 'Apple Sign-In cancelled',
        };
      }
      
      debugPrint('Apple Sign-In successful: ${credential.email}');
      
      // Create Firebase credential
      final oauthCredential = fb_auth.OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );
      
      // Sign in to Firebase with Apple credential
      final userCredential = await fb_auth.FirebaseAuth.instance.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        debugPrint('Firebase user is null after Apple sign-in');
        return {
          'success': false,
          'message': 'Firebase sign-in failed',
        };
      }
      
      debugPrint('Firebase Apple sign-in successful: ${firebaseUser.email}');
      
      // Force refresh the Firebase ID token to ensure it's fresh
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        debugPrint('Failed to get Firebase ID token');
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }
      
      debugPrint('Firebase ID token refreshed successfully');
      
      // When using accessToken function, Supabase automatically handles authentication
      // No need to check currentUser or currentSession - they're not accessible
      debugPrint('Supabase authentication handled automatically via Firebase JWT');
      
      // Return success with user data
      return {
        'success': true,
        'message': 'Apple sign-in successful',
        'user': {
          'id': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'Apple User',
          'photoUrl': firebaseUser.photoURL,
          'firebase_uid': firebaseUser.uid,
        },
        'firebaseUser': firebaseUser,
      };
      
    } catch (e) {
      debugPrint('Firebase Apple sign-in error: $e');
      return {
        'success': false,
        'message': 'Apple sign-in error: $e',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 AuthService: Starting registration for: $email');
      
      // Clear guest state when registering
      if (_isGuest) {
        await signOutGuest();
      }
      
      // 1. Register with Firebase Auth
      debugPrint('🔐 AuthService: Creating Firebase user...');
      final userCredential = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        debugPrint('🔐 AuthService: Firebase user creation failed');
        return {'success': false, 'message': 'Firebase registration failed'};
      }

      debugPrint('🔐 AuthService: Firebase user created successfully: ${firebaseUser.uid}');

      // 2. Update Firebase user profile with username
      try {
        await firebaseUser.updateDisplayName(username);
        debugPrint('🔐 AuthService: Updated Firebase display name to: $username');
      } catch (e) {
        debugPrint('🔐 AuthService: Could not update display name: $e');
        // Continue anyway, this is not critical
      }

      // 3. Insert user data into Supabase 'user' table
      debugPrint('🔐 AuthService: Inserting user data into Supabase...');
      try {
        await _supabaseService.upsertUserToUserAndUsersTables(
          id: firebaseUser.uid,
          email: email,
          name: username,
          photoUrl: null,
        );
        debugPrint('🔐 AuthService: User data inserted into Supabase successfully');
      } catch (e) {
        debugPrint('🔐 AuthService: Supabase insertion error: $e');
        // Don't fail registration if Supabase insertion fails
        // The user is already created in Firebase
      }

      // 4. Update local user data
      _userData = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email,
        'name': username,
        'username': username,
        'firebase_uid': firebaseUser.uid,
      };

      debugPrint('🔐 AuthService: Registration successful for: $email');
      notifyListeners();

      return {
        'success': true,
        'message': 'Registration successful! Please check your email for verification.',
        'user': _userData,
        'firebaseUser': firebaseUser,
      };
      
    } catch (e) {
      debugPrint('🔐 AuthService: Registration error: $e');
      
      // Handle specific Firebase auth errors
      String errorMessage = 'Registration failed';
      if (e is fb_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'An account with this email already exists';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'weak-password':
            errorMessage = 'Password is too weak. Please choose a stronger password';
            break;
          case 'operation-not-allowed':
            errorMessage = 'Email/password accounts are not enabled';
            break;
          default:
            errorMessage = 'Registration failed: ${e.message}';
        }
      }
      
      return {'success': false, 'message': errorMessage};
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear guest state if guest
      if (_isGuest) {
        await signOutGuest();
        return;
      }
      
      // Clear persisted session
      await _clearPersistedSession();
      
      // Sign out from Firebase Auth
      await fb_auth.FirebaseAuth.instance.signOut();
      
      // Sign out from Supabase Auth
      await SupabaseConfig.nativeAuthClient.auth.signOut();
      
      _userData = null;
      debugPrint('AuthService: User signed out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
    }
  }

  // Delete account
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      debugPrint('AuthService: Starting account deletion');

      // Delete account from Supabase
      final result = await _supabaseService.deleteAccount();

      if (result['success'] == true) {
        _userData = null;
        debugPrint('AuthService: Account deleted successfully');
        notifyListeners();
      } else {
        debugPrint(
            'AuthService: Account deletion failed: ${result['message']}');
      }

      return result;
    } catch (e) {
      debugPrint('AuthService: Delete account error: $e');
      return {
        'success': false,
        'message': 'Failed to delete account: $e',
      };
    }
  }

  // Get auth token
  String? get authToken => _supabaseService.authToken;

  // Get auth token (method version for backward compatibility)
  Future<String?> getToken() async {
    return _supabaseService.authToken;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _isGuest || _supabaseService.isAuthenticated;

  // Check username availability
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    return await _supabaseService.checkUsernameAvailability(username);
  }

  // Check email availability
  Future<Map<String, dynamic>> checkEmailAvailability(String email) async {
    return await _supabaseService.checkEmailAvailability(email);
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

// Add guest user wrapper
class _GuestUserWrapper {
  String get id => 'guest';
  String? get email => null;
  Map<String, dynamic>? get userMetadata => {
    'name': 'Guest',
    'username': 'Guest',
    'avatar_url': null,
    'picture': null,
    'profile_image_url': null,
  };
}

// Wrapper class for Supabase user data
class _SupabaseUserWrapper {
  final Map<String, dynamic> _userData;

  _SupabaseUserWrapper(this._userData);

  // Mimic Supabase user properties
  String get id => _userData['id'] ?? '';
  String? get email => _userData['email'];
  String? get emailConfirmedAt {
    // Check if user is verified in Supabase Auth
    try {
      final supabaseUser = SupabaseConfig.client.auth.currentUser;
      if (supabaseUser != null && supabaseUser.emailConfirmedAt != null) {
        return supabaseUser.emailConfirmedAt;
      }
    } catch (e) {
      debugPrint('Error checking Supabase Auth email confirmation: $e');
    }
    
    // Fallback to database field
    return _userData['email_confirmed'] == true ? DateTime.now().toIso8601String() : null;
  }
  Map<String, dynamic>? get userMetadata => {
    'name': _userData['name'],
    'username': _userData['username'],
    'avatar_url': _userData['photoUrl'],
    'picture': _userData['photoUrl'],
    'profile_image_url': _userData['photoUrl'],
  };
}
