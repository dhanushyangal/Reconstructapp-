import 'package:flutter/foundation.dart';
import 'supabase_database_service.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  final SupabaseDatabaseService _supabaseService = SupabaseDatabaseService();

  // Current user data
  Map<String, dynamic>? _userData;
  bool _isInitializing = false;

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

    debugPrint('AuthService: Initializing with Supabase authentication');

    try {
      // Check if user is already authenticated
      if (_supabaseService.isAuthenticated) {
        final profileResult = await _supabaseService.getUserProfile();
        if (profileResult['success'] == true) {
          _userData = profileResult['user'];
          debugPrint('AuthService: User already authenticated');
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
    return _supabaseService.isAuthenticated && _userData != null;
  }

  // Get current user (Supabase user object)
  dynamic getCurrentUser() {
    return _supabaseService.currentUser;
  }

  // Add getter for currentUser for easier access
  dynamic get currentUser => _supabaseService.currentUser;

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
    try {
      final result = await _supabaseService.loginUser(
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _userData = result['user'];
        debugPrint('AuthService: Email/password sign-in successful');
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('AuthService: Email/password sign-in error: $e');
      return {
        'success': false,
        'message': 'Sign-in failed: $e',
      };
    }
  }

  // Sign in with Google
  Future<dynamic> signInWithGoogle() async {
    try {
      final result = await _supabaseService.signInWithGoogle();

      if (result['success'] == true) {
        _userData = result['user'];
        debugPrint('AuthService: Google sign-in successful');
        notifyListeners();

        // Return a mock user credential for compatibility
        return MockUserCredential(result['user']);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('AuthService: Google sign-in error: $e');
      return null;
    }
  }

  // Register new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _supabaseService.registerUser(
        username: username,
        email: email,
        password: password,
      );

      if (result['success'] == true) {
        _userData = result['user'];
        debugPrint('AuthService: User registration successful');
        notifyListeners();
      }

      return result;
    } catch (e) {
      debugPrint('AuthService: User registration error: $e');
      return {
        'success': false,
        'message': 'Registration failed: $e',
      };
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabaseService.logout();
      _userData = null;
      debugPrint('AuthService: User signed out successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Sign out error: $e');
    }
  }

  // Get auth token
  String? get authToken => _supabaseService.authToken;

  // Get auth token (method version for backward compatibility)
  Future<String?> getToken() async {
    return _supabaseService.authToken;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _supabaseService.isAuthenticated;
}

// Mock classes for compatibility with existing code
class MockUserCredential {
  final MockUser user;

  MockUserCredential(Map<String, dynamic> userData) : user = MockUser(userData);
}

class MockUser {
  final String? email;
  final String? displayName;
  final String uid;
  final String? photoURL;

  MockUser(Map<String, dynamic> userData)
      : email = userData['email'],
        displayName = userData['name'] ?? userData['username'],
        uid = userData['id'] ?? userData['supabase_uid'] ?? 'unknown',
        photoURL = null;
}
