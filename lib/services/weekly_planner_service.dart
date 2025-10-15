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
    _client = SupabaseConfig.nativeAuthClient;
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

  // Load weekly planner tasks for a specific day (same across all themes)
  Future<String?> loadUserTasks(
      Map<String, dynamic> userInfo,
      {String? theme}) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for loading weekly planner tasks');
        return null;
      }

      // Use day as card_id, universal theme
      var query = _client
          .from('weekly_planner_tasks')
          .select()
          .eq('user_name', userInfo['userName'])
          .eq('email', userInfo['email'])
          .eq('theme', 'WeeklyPlanner'); // Universal theme

      if (theme != null) {
        query = query.eq('card_id', theme); // Use day as card_id
      }

      final response = await query;

      if (response.isNotEmpty) {
        final tasksJson = response[0]['tasks'] as String?;
        debugPrint('Loaded weekly planner tasks for day: $theme from Supabase');
        return tasksJson;
      }
      
      debugPrint('No weekly planner tasks found for day: $theme');
      return null;
    } catch (e) {
      debugPrint('Error loading weekly planner tasks from Supabase: $e');
      return null;
    }
  }

  // Method to save weekly planner tasks - using upsert for reliability
  Future<Map<String, dynamic>> saveWeeklyPlannerTask({
    required String userName,
    required String email,
    required String cardId,
    required String tasks,
    required String theme,
  }) async {
    try {
      debugPrint(
          'Saving weekly planner task for user: $userName, day: $cardId, theme: $theme');
      debugPrint(
          'Task data: ${tasks.substring(0, tasks.length > 100 ? 100 : tasks.length)}...');

      // Delete ALL existing records for this user and card (regardless of theme)
      // This clears out any old theme-specific records
      final deleteResult = await _client
          .from('weekly_planner_tasks')
          .delete()
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', cardId)
          .select();
      
      debugPrint('Deleted ${deleteResult.length} existing records for $cardId');
      
      // Small delay to ensure delete propagates in database
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Now insert the new record
      await _client.from('weekly_planner_tasks').insert({
        'user_name': userName,
        'email': email,
        'card_id': cardId,
        'tasks': tasks,
        'theme': theme,
      });
      
      debugPrint('Successfully saved weekly planner record for day: $cardId');

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

  // Save weekly planner tasks for a specific day (same across all themes)
  Future<bool> saveTodoItem(
      Map<String, dynamic> userInfo, String tasks,
      {String theme = 'Monday'}) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for saving weekly planner task');
        return false;
      }

      // Use day as card_id, universal theme
      final result = await saveWeeklyPlannerTask(
        userName: userInfo['userName'],
        email: userInfo['email'],
        cardId: theme, // Use day as cardId
        tasks: tasks,
        theme: 'WeeklyPlanner', // Universal theme
      );

      return result['success'] ?? false;
    } catch (e) {
      debugPrint('Error in saveTodoItem: $e');
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
  String? get authToken {
    try {
      // Check if we have a Supabase session (for native auth users)
      final supabaseSession = SupabaseConfig.nativeAuthClient.auth.currentSession;
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
