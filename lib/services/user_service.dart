import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';

class UserService {
  static UserService? _instance;
  final AuthService _authService = AuthService();
  bool _isInitialized = false;

  // Cache for user info
  Map<String, String>? _cachedUserInfo;
  DateTime? _lastCacheUpdate;
  static const _cacheDuration = Duration(minutes: 5);

  // Flag to track if manual user info is set
  bool _manualUserInfoSet = false;

  static UserService get instance {
    _instance ??= UserService._();
    return _instance!;
  }

  UserService._();

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _authService.initialize();
    _isInitialized = true;

    // Get and cache user info on initialization
    final userInfo = await getUserInfo();
    if (userInfo['userName']!.isNotEmpty && userInfo['email']!.isNotEmpty) {
      _cachedUserInfo = userInfo;
      _lastCacheUpdate = DateTime.now();
    }
  }

  // Method for manually setting user info
  Future<void> setManualUserInfo(
      {required String userName, required String email}) async {
    _cachedUserInfo = {'userName': userName, 'email': email};
    _lastCacheUpdate = DateTime.now();
    await saveUserInfo(userName: userName, email: email);
    _manualUserInfoSet = true;
    debugPrint('UserService: Manually set user info: $userName, $email');
  }

  Future<void> saveUserInfo(
      {required String userName, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', userName);
    await prefs.setString('user_email', email);
    _cachedUserInfo = {'userName': userName, 'email': email};
    _lastCacheUpdate = DateTime.now();
    debugPrint('UserService: Saved user info: $userName, $email');
  }

  Future<Map<String, String>> getUserInfo() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check cache first
    if (_cachedUserInfo != null && _lastCacheUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
      if (cacheAge < _cacheDuration) {
        debugPrint('UserService: Using cached user info');
        return _cachedUserInfo!;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    String userName = prefs.getString('user_name') ?? '';
    String email = prefs.getString('user_email') ?? '';

    // If we have valid cached data, use it
    if (_cachedUserInfo != null &&
        _cachedUserInfo!['userName']!.isNotEmpty &&
        _cachedUserInfo!['email']!.isNotEmpty) {
      return _cachedUserInfo!;
    }

    // If we have valid stored data, use it
    if (userName.isNotEmpty && email.isNotEmpty) {
      _cachedUserInfo = {'userName': userName, 'email': email};
      _lastCacheUpdate = DateTime.now();
      return _cachedUserInfo!;
    }

    // If no valid data, check AuthService
    if (!_manualUserInfoSet) {
      try {
        // Check MySQL first
        if (_authService.userData != null) {
          userName = _authService.userData!['name'] ?? '';
          email = _authService.userData!['email'] ?? '';
          if (userName.isNotEmpty && email.isNotEmpty) {
            await saveUserInfo(userName: userName, email: email);
            return {'userName': userName, 'email': email};
          }
        }

        // Check Firebase as fallback
        final firebaseUser = _authService.getCurrentUser();
        if (firebaseUser != null) {
          email = firebaseUser.email ?? '';
          userName = firebaseUser.displayName ?? email.split('@').first;
          if (userName.isNotEmpty && email.isNotEmpty) {
            await saveUserInfo(userName: userName, email: email);
            return {'userName': userName, 'email': email};
          }
        }
      } catch (e) {
        debugPrint('UserService: Error getting user info from AuthService: $e');
      }
    }

    return {'userName': userName, 'email': email};
  }

  Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('last_known_user');
    _cachedUserInfo = null;
    _lastCacheUpdate = null;
    _manualUserInfoSet = false;
    debugPrint('UserService: Cleared all user info');
  }

  Future<bool> isUserLoggedIn() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check AuthService first as it's the source of truth
    if (_authService.hasAuthenticatedUser()) {
      // If AuthService says user is logged in, ensure we have the user info
      final userInfo = await getUserInfo();
      if (userInfo['userName']!.isNotEmpty && userInfo['email']!.isNotEmpty) {
        debugPrint('UserService: User is logged in (AuthService verified)');
        return true;
      }
    }

    // Check cache if AuthService check failed
    if (_cachedUserInfo != null && _lastCacheUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastCacheUpdate!);
      if (cacheAge < _cacheDuration) {
        final isValid = _cachedUserInfo!['userName']!.isNotEmpty &&
            _cachedUserInfo!['email']!.isNotEmpty;
        debugPrint('UserService: Cache check - User logged in: $isValid');
        return isValid;
      }
    }

    // Fall back to stored user info
    final userInfo = await getUserInfo();
    final isValid =
        userInfo['userName']!.isNotEmpty && userInfo['email']!.isNotEmpty;
    debugPrint('UserService: Final check - User logged in: $isValid');
    return isValid;
  }
}
