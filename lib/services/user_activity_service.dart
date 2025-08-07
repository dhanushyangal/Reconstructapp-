import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import 'user_service.dart';
import 'dart:async';

class UserActivityService {
  static final UserActivityService instance = UserActivityService._internal();

  late final supabase.SupabaseClient _client;

  // Throttling variables
  DateTime _lastActivityTime = DateTime.now();
  static const int _activityThrottleDelayMs =
      1000; // 1 second between similar activities

  // Cache for current session
  String? _cachedUserEmail;
  String? _cachedUserName;

  UserActivityService._internal() {
    _client = SupabaseConfig.nativeAuthClient;
  }

  // Helper method to format response
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

  // Get current user info with caching
  Future<Map<String, String?>> _getCurrentUserInfo() async {
    try {
      // Return cached data if available
      if (_cachedUserEmail != null && _cachedUserName != null) {
        return {
          'email': _cachedUserEmail,
          'userName': _cachedUserName,
        };
      }

      // Get fresh user info
      final userInfo = await UserService.instance.getUserInfo();

      if (userInfo['email']?.isNotEmpty == true) {
        _cachedUserEmail = userInfo['email'];
        _cachedUserName = userInfo['userName'] ?? '';

        return {
          'email': _cachedUserEmail,
          'userName': _cachedUserName,
        };
      }

      // Fallback for non-logged-in users
      return {
        'email': 'anonymous@example.com',
        'userName': 'Anonymous',
      };
    } catch (e) {
      debugPrint('Error getting user info for activity tracking: $e');
      return {
        'email': 'anonymous@example.com',
        'userName': 'Anonymous',
      };
    }
  }

  // Check if activity should be throttled
  bool _isThrottled() {
    final now = DateTime.now();
    final timeSinceLastActivity =
        now.difference(_lastActivityTime).inMilliseconds;

    if (timeSinceLastActivity < _activityThrottleDelayMs) {
      return true; // Throttle this activity
    }

    // Update the last activity time
    _lastActivityTime = now;
    return false; // Don't throttle
  }

  // Record page visit activity
  Future<Map<String, dynamic>> recordPageVisit(String pageName) async {
    return await recordActivity(
      pageName: pageName,
      actionType: 'visit',
      details: 'Page visited',
    );
  }

  // Record user interaction activity
  Future<Map<String, dynamic>> recordInteraction(
    String pageName,
    String actionType, {
    String? details,
  }) async {
    return await recordActivity(
      pageName: pageName,
      actionType: actionType,
      details: details ?? actionType,
    );
  }

  // Main method to record any activity
  Future<Map<String, dynamic>> recordActivity({
    required String pageName,
    required String actionType,
    String? details,
    bool skipThrottling = false,
  }) async {
    try {
      // Skip throttling check if explicitly requested
      if (!skipThrottling && _isThrottled()) {
        debugPrint('Activity throttled: $actionType on $pageName');
        return _formatResponse(
          success: true,
          message: 'Activity throttled',
        );
      }

      // Get user info
      final userInfo = await _getCurrentUserInfo();
      final email = userInfo['email']!;
      final userName = userInfo['userName'] ?? '';

      debugPrint('Recording activity: $actionType on $pageName for $email');

      // Check if record already exists for this user and page
      final existingRecord = await _client
          .from('user_activity')
          .select()
          .eq('email', email)
          .eq('page_name', pageName)
          .maybeSingle();

      if (existingRecord != null) {
        // Update existing record - increment count and update timestamp
        final newCount = (existingRecord['count'] as int? ?? 1) + 1;

        final response = await _client
            .from('user_activity')
            .update({
              'action_type': actionType,
              'last_time': DateTime.now().toIso8601String(),
              'count': newCount,
              'details': details ?? actionType,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRecord['id'])
            .select()
            .single();

        debugPrint(
            '✅ Activity updated: $actionType on $pageName (count: $newCount)');
        return _formatResponse(
          success: true,
          message: 'Activity updated successfully',
          data: response,
        );
      } else {
        // Create new record
        final response = await _client
            .from('user_activity')
            .insert({
              'email': email,
              'user_name': userName,
              'page_name': pageName,
              'action_type': actionType,
              'last_time': DateTime.now().toIso8601String(),
              'count': 1,
              'details': details ?? actionType,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        debugPrint(
            '✅ Activity recorded: $actionType on $pageName (new record)');
        return _formatResponse(
          success: true,
          message: 'Activity recorded successfully',
          data: response,
        );
      }
    } catch (e) {
      debugPrint('❌ Error recording activity: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to record activity: $e',
      );
    }
  }

  // Get user activity history
  Future<Map<String, dynamic>> getUserActivityHistory({
    String? email,
    int limit = 50,
    String? pageNameFilter,
    String? actionTypeFilter,
  }) async {
    try {
      // Get user info if email not provided
      String targetEmail = email ?? (await _getCurrentUserInfo())['email']!;

      var query =
          _client.from('user_activity').select().eq('email', targetEmail);

      // Add optional filters
      if (pageNameFilter != null) {
        query = query.eq('page_name', pageNameFilter);
      }

      if (actionTypeFilter != null) {
        query = query.eq('action_type', actionTypeFilter);
      }

      final response =
          await query.order('last_time', ascending: false).limit(limit);

      debugPrint('Retrieved ${response.length} activity records');
      return _formatResponse(
        success: true,
        data: response,
      );
    } catch (e) {
      debugPrint('Error getting user activity history: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to get activity history: $e',
        data: [],
      );
    }
  }

  // Get activity summary for analytics
  Future<Map<String, dynamic>> getActivitySummary({String? email}) async {
    try {
      // Get user info if email not provided
      String targetEmail = email ?? (await _getCurrentUserInfo())['email']!;

      final response =
          await _client.from('user_activity').select().eq('email', targetEmail);

      // Process data for summary
      Map<String, int> pageVisits = {};
      Map<String, int> actionTypes = {};
      int totalCount = 0;

      for (var record in response) {
        final pageName = record['page_name'] as String;
        final actionType = record['action_type'] as String;
        final count = record['count'] as int? ?? 1;

        pageVisits[pageName] = (pageVisits[pageName] ?? 0) + count;
        actionTypes[actionType] = (actionTypes[actionType] ?? 0) + count;
        totalCount += count;
      }

      return _formatResponse(
        success: true,
        data: {
          'totalActivities': totalCount,
          'uniquePages': pageVisits.length,
          'pageVisits': pageVisits,
          'actionTypes': actionTypes,
          'lastActivity':
              response.isNotEmpty ? response.first['last_time'] : null,
        },
      );
    } catch (e) {
      debugPrint('Error getting activity summary: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to get activity summary: $e',
      );
    }
  }

  // Test connection to activity table
  Future<bool> testConnection() async {
    try {
      await _client.from('user_activity').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing user_activity table connection: $e');
      return false;
    }
  }

  // Clear cache (useful when user logs out)
  void clearCache() {
    _cachedUserEmail = null;
    _cachedUserName = null;
  }

  // Bulk record activities (for offline sync)
  Future<Map<String, dynamic>> recordBulkActivities(
    List<Map<String, dynamic>> activities,
  ) async {
    try {
      debugPrint('Recording ${activities.length} bulk activities');

      // Process each activity
      for (var activity in activities) {
        await recordActivity(
          pageName: activity['page_name'],
          actionType: activity['action_type'],
          details: activity['details'],
          skipThrottling: true, // Skip throttling for bulk operations
        );
      }

      return _formatResponse(
        success: true,
        message: '${activities.length} activities recorded successfully',
      );
    } catch (e) {
      debugPrint('Error recording bulk activities: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to record bulk activities: $e',
      );
    }
  }
}
