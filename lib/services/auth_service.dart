import 'package:flutter/foundation.dart';
import 'supabase_database_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Get isInitializing state
  bool get isInitializing => _isInitializing;

  // Initialize the service
  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    debugPrint('AuthService: Initializing with Firebase authentication');

    try {
      // Load guest state first
      await loadGuestState();
      
      // If guest, don't check Firebase auth
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
    // When using accessToken function, check Firebase auth instead of Supabase
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser != null;
  }

  // Get current user (Firebase user object when using accessToken function)
  dynamic getCurrentUser() {
    if (_isGuest) {
      return _GuestUserWrapper();
    }
    // When using accessToken function, return Firebase user
    final firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // Return a mock object that mimics Supabase user structure
      return _FirebaseUserWrapper(firebaseUser);
    }
    return null;
  }

  // Add getter for currentUser for easier access
  dynamic get currentUser => getCurrentUser();

  // Sign in with email and password (legacy method name for compatibility)
  Future<Map<String, dynamic>> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await signInWithEmailPassword(email: email, password: password);
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 AuthService: Starting email/password sign-in for: $email');

    try {
      // Clear guest state when signing in
      if (_isGuest) {
        await signOutGuest();
      }
      
      debugPrint('🔐 AuthService: Using Firebase for email/password sign-in...');
      
      // Use Firebase Auth for email/password sign-in
      final userCredential = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        debugPrint('🔐 AuthService: Firebase user is null after sign-in');
        return {
          'success': false,
          'message': 'Firebase sign-in failed',
        };
      }
      
      debugPrint('🔐 AuthService: Firebase email/password sign-in successful: ${firebaseUser.email}');
      
      // Force refresh the Firebase ID token to ensure it's fresh
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null) {
        debugPrint('🔐 AuthService: Failed to get Firebase ID token');
        return {
          'success': false,
          'message': 'Failed to get authentication token',
        };
      }
      
      debugPrint('🔐 AuthService: Firebase ID token refreshed successfully');
      
      // Update user data
      _userData = {
        'id': firebaseUser.uid,
        'email': firebaseUser.email,
        'name': firebaseUser.displayName ?? 'User',
        'photoUrl': firebaseUser.photoURL,
        'firebase_uid': firebaseUser.uid,
      };
      
        debugPrint('🔐 AuthService: Email/password sign-in successful');
        debugPrint('🔐 AuthService: User data: $_userData');
        notifyListeners();
      
      return {
        'success': true,
        'message': 'Email/password sign-in successful',
        'user': _userData,
        'firebaseUser': firebaseUser,
      };
      
    } catch (e) {
      debugPrint('🔐 AuthService: Email/password sign-in error: $e');
      
      // Handle specific Firebase auth errors
      String errorMessage = 'Sign-in failed';
      if (e is fb_auth.FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed attempts. Please try again later';
            break;
          default:
            errorMessage = 'Authentication failed: ${e.message}';
        }
      }
      
      return {
        'success': false,
        'message': errorMessage,
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
      
      // When using accessToken function, Supabase automatically handles authentication
      // No need to check currentUser or currentSession - they're not accessible
      debugPrint('Supabase authentication handled automatically via Firebase JWT');
      
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
      };
      
    } catch (e) {
      debugPrint('Firebase Google sign-in error: $e');
      return {
        'success': false,
        'message': 'Google sign-in error: $e',
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
      
      // Sign out from Firebase Auth
      await fb_auth.FirebaseAuth.instance.signOut();
      _userData = null;
      debugPrint('AuthService: User signed out successfully from Firebase');
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
