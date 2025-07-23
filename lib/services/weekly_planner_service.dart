import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class WeeklyPlannerService {
  static final WeeklyPlannerService instance = WeeklyPlannerService._internal();

  // Supabase client instance
  late final supabase.SupabaseClient _client;

  WeeklyPlannerService._internal() {
    _client = SupabaseConfig.client;
  }

  // Helper method to handle errors and format response
  Map<String, dynamic> _formatResponse({
    required bool success,
    String? message,
    dynamic data,
  }) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }

  Future<bool> testConnection() async {
    try {
      // Test Supabase connection by making a simple query
      await _client.from('weekly_planner_tasks').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing Supabase connection: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadUserTasks(
      Map<String, dynamic> userInfo,
      {String? theme}) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for loading weekly planner tasks');
        return [];
      }

      var query = _client
          .from('weekly_planner_tasks')
          .select()
          .eq('user_name', userInfo['userName'])
          .eq('email', userInfo['email']);

      if (theme != null) {
        query = query.eq('theme', theme);

        // Valid days in the week
        final validDays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];

        // Filter for valid days
        query = query.inFilter('card_id', validDays);
      }

      final response = await query;

      debugPrint(
          'Loaded ${response.length} weekly planner tasks from Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading weekly planner tasks from Supabase: $e');
      return [];
    }
  }

  // Method to save weekly planner tasks - following the same pattern
  Future<Map<String, dynamic>> saveWeeklyPlannerTask({
    required String userName,
    required String email,
    required String cardId,
    required String tasks,
    required String theme,
  }) async {
    try {
      debugPrint(
          'Saving weekly planner task for user: $userName, day: $cardId');
      debugPrint(
          'Task data: ${tasks.substring(0, tasks.length > 100 ? 100 : tasks.length)}...');

      // First, check if a record exists
      final existingRecord = await _client
          .from('weekly_planner_tasks')
          .select('id')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', cardId)
          .eq('theme', theme)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        await _client
            .from('weekly_planner_tasks')
            .update({
              'tasks': tasks,
            })
            .eq('user_name', userName)
            .eq('email', email)
            .eq('card_id', cardId)
            .eq('theme', theme);
        debugPrint('Updated existing weekly planner record for $cardId');
      } else {
        // Insert new record
        await _client.from('weekly_planner_tasks').insert({
          'user_name': userName,
          'email': email,
          'card_id': cardId,
          'tasks': tasks,
          'theme': theme,
        });
        debugPrint('Inserted new weekly planner record for $cardId');
      }

      return _formatResponse(
        success: true,
        message: 'Task saved successfully',
      );
    } catch (e) {
      debugPrint('Error saving weekly planner task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to save task: $e',
      );
    }
  }

  // Method to get weekly planner tasks
  Future<Map<String, dynamic>> getWeeklyPlannerTasks({
    required String userName,
    required String email,
    String? theme,
    String? cardId,
  }) async {
    try {
      var query = _client
          .from('weekly_planner_tasks')
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
      debugPrint('Error getting weekly planner tasks: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to get tasks: $e',
        data: [],
      );
    }
  }

  // Legacy method for backward compatibility
  Future<bool> saveTodoItem(
      Map<String, dynamic> userInfo, String day, String tasks,
      {String theme = 'japanese'}) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for saving weekly planner task');
        return false;
      }

      final result = await saveWeeklyPlannerTask(
        userName: userInfo['userName'],
        email: userInfo['email'],
        cardId: day,
        tasks: tasks,
        theme: theme,
      );

      return result['success'] ?? false;
    } catch (e) {
      debugPrint('Error in legacy saveTodoItem: $e');
      return false;
    }
  }

  // Method to delete weekly planner task
  Future<Map<String, dynamic>> deleteWeeklyPlannerTask({
    required String userName,
    required String email,
    required String cardId,
    required String theme,
  }) async {
    try {
      await _client
          .from('weekly_planner_tasks')
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
      debugPrint('Error deleting weekly planner task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to delete task: $e',
      );
    }
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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
