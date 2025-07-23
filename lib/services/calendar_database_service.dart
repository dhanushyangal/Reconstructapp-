import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class CalendarDatabaseService {
  // Supabase client instance
  late final supabase.SupabaseClient _client;

  // User information cache
  String? _userName;
  String? _userEmail;

  // Constructor
  CalendarDatabaseService({String? baseUrl}) {
    _client = SupabaseConfig.client;
  }

  // Getters
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  // Set user information
  void setUserInfo(String userName, String email) {
    _userName = userName;
    _userEmail = email;
  }

  // Method to fetch user information from local storage
  Future<bool> loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userName = prefs.getString('user_name');
      _userEmail = prefs.getString('user_email');

      return _userName != null && _userEmail != null;
    } catch (e) {
      debugPrint('Error loading user info: $e');
      return false;
    }
  }

  // Method to fetch calendar tasks for a specific user and theme
  Future<Map<String, dynamic>> getCalendarTasks({
    String theme = 'animal',
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Verify user information is available
      if (_userName == null || _userEmail == null) {
        await loadUserInfo();
        if (_userName == null || _userEmail == null) {
          return {
            'success': false,
            'message': 'User information is not available',
            'tasks': [],
          };
        }
      }

      var query = _client
          .from('calendar_2025_tasks')
          .select()
          .eq('user_name', _userName!)
          .eq('email', _userEmail!)
          .eq('theme', theme);

      // Add optional date range filters
      if (startDate != null) {
        query = query.gte('task_date', startDate);
      }
      if (endDate != null) {
        query = query.lte('task_date', endDate);
      }

      final response = await query.order('task_date');

      debugPrint('Loaded ${response.length} calendar tasks from Supabase');
      return {
        'success': true,
        'tasks': response,
      };
    } catch (e) {
      debugPrint('Error in getCalendarTasks: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching tasks',
        'tasks': [],
      };
    }
  }

  // Method to save a calendar task
  Future<Map<String, dynamic>> saveCalendarTask({
    required DateTime taskDate,
    required int taskType,
    required String description,
    required String colorCode,
    String theme = 'animal',
  }) async {
    try {
      // Verify user information is available
      if (_userName == null || _userEmail == null) {
        await loadUserInfo();
        if (_userName == null || _userEmail == null) {
          return {
            'success': false,
            'message': 'User information is not available',
          };
        }
      }

      // Format date as YYYY-MM-DD
      final formattedDate = taskDate.toIso8601String().split('T')[0];

      debugPrint(
          'Saving calendar task for user: $_userName, date: $formattedDate');

      // Insert new record (Supabase will handle conflicts with upsert if needed)
      final response = await _client
          .from('calendar_2025_tasks')
          .insert({
            'user_name': _userName,
            'email': _userEmail,
            'task_date': formattedDate,
            'task_type': taskType,
            'task_description': description,
            'color_code': colorCode,
            'theme': theme,
          })
          .select()
          .single();

      debugPrint('Calendar task saved successfully');
      return {
        'success': true,
        'message': 'Task saved successfully',
        'task': response,
      };
    } catch (e) {
      debugPrint('Error in saveCalendarTask: $e');
      return {
        'success': false,
        'message': 'An error occurred while saving the task',
      };
    }
  }

  // Method to update a calendar task
  Future<Map<String, dynamic>> updateCalendarTask({
    required int taskId,
    DateTime? taskDate,
    int? taskType,
    String? description,
    String? colorCode,
  }) async {
    try {
      // Verify user information is available
      if (_userName == null || _userEmail == null) {
        await loadUserInfo();
        if (_userName == null || _userEmail == null) {
          return {
            'success': false,
            'message': 'User information is not available',
          };
        }
      }

      // Prepare update data
      Map<String, dynamic> updateData = {};

      // Add optional fields if provided
      if (taskDate != null) {
        final formattedDate = taskDate.toIso8601String().split('T')[0];
        updateData['task_date'] = formattedDate;
      }
      if (taskType != null) updateData['task_type'] = taskType;
      if (description != null) updateData['task_description'] = description;
      if (colorCode != null) updateData['color_code'] = colorCode;

      // Only update if there's data to update
      if (updateData.isEmpty) {
        return {
          'success': false,
          'message': 'No data to update',
        };
      }

      debugPrint('Updating calendar task with ID: $taskId');

      final response = await _client
          .from('calendar_2025_tasks')
          .update(updateData)
          .eq('id', taskId)
          .eq('user_name', _userName!)
          .eq('email', _userEmail!)
          .select()
          .single();

      return {
        'success': true,
        'message': 'Task updated successfully',
        'task': response,
      };
    } catch (e) {
      debugPrint('Error in updateCalendarTask: $e');
      return {
        'success': false,
        'message': 'An error occurred while updating the task',
      };
    }
  }

  // Method to delete a calendar task
  Future<Map<String, dynamic>> deleteCalendarTask({
    required int taskId,
  }) async {
    try {
      // Verify user information is available
      if (_userName == null || _userEmail == null) {
        await loadUserInfo();
        if (_userName == null || _userEmail == null) {
          return {
            'success': false,
            'message': 'User information is not available',
          };
        }
      }

      debugPrint('Deleting calendar task with ID: $taskId');

      await _client
          .from('calendar_2025_tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_name', _userName!)
          .eq('email', _userEmail!);

      return {
        'success': true,
        'message': 'Task deleted successfully',
      };
    } catch (e) {
      debugPrint('Error in deleteCalendarTask: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting the task',
      };
    }
  }

  // Method to delete all tasks for a specific date
  Future<Map<String, dynamic>> deleteCalendarTasksByDate({
    required DateTime taskDate,
    String theme = 'animal',
  }) async {
    try {
      // Verify user information is available
      if (_userName == null || _userEmail == null) {
        await loadUserInfo();
        if (_userName == null || _userEmail == null) {
          return {
            'success': false,
            'message': 'User information is not available',
          };
        }
      }

      // Format date as YYYY-MM-DD
      final formattedDate = taskDate.toIso8601String().split('T')[0];

      debugPrint('Deleting all calendar tasks for date: $formattedDate');

      await _client
          .from('calendar_2025_tasks')
          .delete()
          .eq('user_name', _userName!)
          .eq('email', _userEmail!)
          .eq('task_date', formattedDate)
          .eq('theme', theme);

      return {
        'success': true,
        'message': 'Tasks deleted successfully',
      };
    } catch (e) {
      debugPrint('Error in deleteCalendarTasksByDate: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting tasks',
      };
    }
  }

  // Test Supabase connection
  Future<bool> testConnection() async {
    try {
      await _client.from('calendar_2025_tasks').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing Supabase connection: $e');
      return false;
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

  // Get auth token from Supabase
  String? get authToken => _client.auth.currentSession?.accessToken;

  // Legacy getter for compatibility
  String? get baseUrl => 'supabase'; // Just for compatibility

  // Helper function for min calculation
  int min(int a, int b) => a < b ? a : b;
}

// Wrapper class to make Firebase user compatible with Supabase user structure
class _FirebaseUserWrapper {
  final fb_auth.User _firebaseUser;

  _FirebaseUserWrapper(this._firebaseUser);

  // Mimic Supabase user properties
  String get id => _firebaseUser.uid;
  String? get email => _firebaseUser.email;
  String? get emailConfirmedAt => null; // Firebase doesn't have this concept
  Map<String, dynamic>? get userMetadata => {
    'name': _firebaseUser.displayName,
    'username': _firebaseUser.displayName,
    'avatar_url': _firebaseUser.photoURL,
    'picture': _firebaseUser.photoURL,
    'profile_image_url': _firebaseUser.photoURL,
  };
}
