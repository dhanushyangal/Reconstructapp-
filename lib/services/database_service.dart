import 'package:flutter/material.dart';
import 'dart:async';

import 'user_service.dart';
import 'supabase_database_service.dart';
import 'auth_service.dart';
import '../config/supabase_config.dart';

class DatabaseService {
  static DatabaseService? _instance;
  late final SupabaseDatabaseService _supabaseService;
  late final AuthService _authService;
  bool _isConnected = false;


  // Singleton pattern
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  DatabaseService._() {
    _supabaseService = SupabaseDatabaseService();
    _authService = AuthService();
  }

  // Check if we're connected to Supabase
  bool get isConnected => _isConnected;

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return await UserService.instance.isUserLoggedIn();
  }

  // Helper method to ensure Supabase service has valid auth token
  Future<bool> _ensureAuthToken() async {
    try {
      final token = await _authService.getToken();
      if (token != null && token.isNotEmpty) {
        // The SupabaseDatabaseService manages its own auth token
        // so we don't need to set it manually
        debugPrint(
            'DatabaseService: Auth token available for Supabase service');
        return true;
      } else {
        debugPrint('DatabaseService: No auth token available from AuthService');
        return false;
      }
    } catch (e) {
      debugPrint('DatabaseService: Error getting auth token: $e');
      return false;
    }
  }

  // Save todo items to Supabase vision_board_tasks table
  // Each category has its own task list, same across all themes
  Future<bool> saveTodoItem(Map<String, dynamic> userInfo,
      String tasks, String category) async {
    try {
      debugPrint('Saving todo items to Supabase, category: $category');
      debugPrint('Tasks data length: ${tasks.length} characters');

      // Ensure we have user info
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Failed to save task: User info is incomplete');
        return false;
      }

      // Ensure we have auth token
      if (!await _ensureAuthToken()) {
        debugPrint('Failed to save task: No valid auth token');
        return false;
      }

      // Use category as cardId, universal theme
      final result = await _supabaseService.saveVisionBoardTask(
        userName: userInfo['userName'],
        email: userInfo['email'],
        cardId: category, // Use category as cardId
        tasks: tasks,
        theme: 'VisionBoard', // Universal theme
      );

      debugPrint(
          'Save task result: ${result['success']} - ${result['message']}');
      return result['success'] == true;
    } catch (e) {
      debugPrint('Failed to save task to Supabase: $e');
      return false;
    }
  }

  // Load user tasks from Supabase vision_board_tasks table
  // Each category has its own task list
  Future<String?> loadUserTasks(
      Map<String, dynamic> userInfo, String category) async {
    try {
      debugPrint('Loading user tasks from Supabase for category: $category');

      // Ensure we have user info
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Failed to load tasks: User info is incomplete');
        return null;
      }

      // Ensure we have auth token
      if (!await _ensureAuthToken()) {
        debugPrint('Failed to load tasks: No valid auth token');
        return null;
      }

      final result = await _supabaseService.getVisionBoardTasks(
        userName: userInfo['userName'],
        email: userInfo['email'],
        theme: 'VisionBoard', // Universal theme
        cardId: category, // Use category as cardId
      );

      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        if (data.isNotEmpty) {
          final tasksJson = data[0]['tasks'] as String?;
          debugPrint('Loaded tasks for category $category from Supabase');
          return tasksJson;
        }
        debugPrint('No tasks found for category $category in Supabase');
        return null;
      } else {
        debugPrint('Failed to load tasks: ${result['message']}');
        return null;
      }
    } catch (e) {
      debugPrint('Failed to load tasks from Supabase: $e');
      return null;
    }
  }

  // Clear all cached data for user switch
  Future<void> clearUserData() async {
    debugPrint(
        'DatabaseService: Clearing cached user data for logout/user switch');
    _isConnected = false;

    // You could add any other cleanup here if needed
    // For now, just reset connection status
  }

  // Test the Supabase connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      debugPrint('Testing Supabase connection...');

      final isLoggedIn = await isUserLoggedIn();
      final userInfo =
          isLoggedIn ? await UserService.instance.getUserInfo() : null;

      // First ensure we have auth token if user is logged in
      if (isLoggedIn) {
        if (!await _ensureAuthToken()) {
          return {
            'success': false,
            'message': 'User is logged in but no valid auth token available',
            'hasTaskTables': false
          };
        }
      }

      // Test basic connection by trying to access Supabase
      // Since we're using a custom token approach, we'll test with actual user data
      if (isLoggedIn && userInfo != null) {
        // Test if we can query vision_board_tasks table directly
        try {
          final tasksResult = await _supabaseService.getVisionBoardTasks(
            userName: userInfo['userName']!,
            email: userInfo['email']!,
          );

          if (tasksResult['success'] == true) {
            _isConnected = true;
            String message =
                'Supabase connection successful (User: ${userInfo['userName']})';
            message += '\nDatabase connection active';

            return {'success': true, 'message': message, 'hasTaskTables': true};
          } else {
            _isConnected = false;
            return {
              'success': false,
              'message':
                  'Failed to access vision_board_tasks table: ${tasksResult['message']}',
              'hasTaskTables': false
            };
          }
        } catch (e) {
          _isConnected = false;
          return {
            'success': false,
            'message': 'Error accessing vision_board_tasks table: $e',
            'hasTaskTables': false
          };
        }
      } else {
        // Test basic Supabase connection without user-specific data
        try {
          // Just check if we can connect to Supabase
          final client = SupabaseConfig.nativeAuthClient;
          // Make a simple query to test connection
          await client.from('user').select('count').limit(1);

          _isConnected = true;
          return {
            'success': true,
            'message': 'Supabase connection successful (User not logged in)',
            'hasTaskTables': true
          };
        } catch (e) {
          _isConnected = false;
          return {
            'success': false,
            'message': 'Supabase connection failed: $e',
            'hasTaskTables': false
          };
        }
      }
    } catch (e) {
      _isConnected = false;

      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException')) {
        errorMessage =
            'Unable to connect to Supabase. Please check your internet connection.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage = 'Supabase request timed out. Please try again.';
      } else if (errorMessage.contains('AuthException')) {
        errorMessage = 'Authentication failed. Please log in again.';
      }

      return {
        'success': false,
        'message': 'Supabase connection failed: $errorMessage',
        'hasTaskTables': false
      };
    }
  }
}
