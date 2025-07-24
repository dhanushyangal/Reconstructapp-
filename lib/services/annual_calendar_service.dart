import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AnnualCalendarService {
  static final AnnualCalendarService instance =
      AnnualCalendarService._internal();

  // Supabase client instance
  late final supabase.SupabaseClient _client;

  AnnualCalendarService._internal() {
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
      await _client.from('annual_calendar_tasks').select('id').limit(1);
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
        debugPrint('Invalid user info for loading tasks');
        return [];
      }

      var query = _client
          .from('annual_calendar_tasks')
          .select()
          .eq('user_name', userInfo['userName'])
          .eq('email', userInfo['email']);

      // If a theme is specified, filter tasks by that theme
      if (theme != null) {
        query = query.eq('theme', theme);
      }

      final response = await query;

      debugPrint('Loaded ${response.length} tasks from Supabase');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading tasks from Supabase: $e');
      return [];
    }
  }

  // Method to save annual calendar tasks - following vision board pattern exactly
  Future<Map<String, dynamic>> saveAnnualCalendarTask({
    required String userName,
    required String email,
    required String cardId,
    required String tasks,
    required String theme,
  }) async {
    try {
      debugPrint(
          'Saving annual calendar task for user: $userName, card: $cardId');
      debugPrint(
          'Task data: ${tasks.substring(0, tasks.length > 100 ? 100 : tasks.length)}...');

      // First, check if a record exists
      final existingRecord = await _client
          .from('annual_calendar_tasks')
          .select('id')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', cardId)
          .eq('theme', theme)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record
        await _client
            .from('annual_calendar_tasks')
            .update({
              'tasks': tasks,
            })
            .eq('user_name', userName)
            .eq('email', email)
            .eq('card_id', cardId)
            .eq('theme', theme);
        debugPrint('Updated existing record for $cardId');
      } else {
        // Insert new record
        await _client.from('annual_calendar_tasks').insert({
          'user_name': userName,
          'email': email,
          'card_id': cardId,
          'tasks': tasks,
          'theme': theme,
        });
        debugPrint('Inserted new record for $cardId');
      }

      return _formatResponse(
        success: true,
        message: 'Task saved successfully',
      );
    } catch (e) {
      debugPrint('Error saving annual calendar task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to save task: $e',
      );
    }
  }

  // Method to get annual calendar tasks - following vision board pattern exactly
  Future<Map<String, dynamic>> getAnnualCalendarTasks({
    required String userName,
    required String email,
    String? theme,
    String? cardId,
  }) async {
    try {
      var query = _client
          .from('annual_calendar_tasks')
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
      debugPrint('Error getting annual calendar tasks: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to get tasks: $e',
        data: [],
      );
    }
  }

  // Legacy method for backward compatibility
  Future<bool> saveTodoItem(
      Map<String, dynamic> userInfo, String month, String tasks,
      {String theme = 'floral'}) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for saving task');
        return false;
      }

      final result = await saveAnnualCalendarTask(
        userName: userInfo['userName'],
        email: userInfo['email'],
        cardId: month,
        tasks: tasks,
        theme: theme,
      );

      return result['success'] ?? false;
    } catch (e) {
      debugPrint('Error in legacy saveTodoItem: $e');
      return false;
    }
  }

  // Method to delete annual calendar task - following vision board pattern exactly
  Future<Map<String, dynamic>> deleteAnnualCalendarTask({
    required String userName,
    required String email,
    required String cardId,
    required String theme,
  }) async {
    try {
      await _client
          .from('annual_calendar_tasks')
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
      debugPrint('Error deleting annual calendar task: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to delete task: $e',
      );
    }
  }

  // Legacy method for backward compatibility
  Future<bool> deleteTodoItem(
      Map<String, dynamic> userInfo, String month, String theme) async {
    try {
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        debugPrint('Invalid user info for deleting task');
        return false;
      }

      final result = await deleteAnnualCalendarTask(
        userName: userInfo['userName'],
        email: userInfo['email'],
        cardId: month,
        theme: theme,
      );

      return result['success'] ?? false;
    } catch (e) {
      debugPrint('Error in legacy deleteTodoItem: $e');
      return false;
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

  // Check if user is currently authenticated with Supabase
  bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current user
  supabase.User? get currentUser => _client.auth.currentUser;

  // Get auth token from Supabase
  String? get authToken => _client.auth.currentSession?.accessToken;
}
