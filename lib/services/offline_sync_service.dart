import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class OfflineSyncService {
  static const String _mindToolsActivityKey = 'offline_mind_tools_activity';
  final AuthService _authService = AuthService();

  // Cache mind tools activity for later syncing
  Future<bool> cacheMindToolsActivity({
    required String trackerType,
    required DateTime activityDate,
    int count = 1,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing cached activities or create new list
      List<Map<String, dynamic>> activities = [];
      final cachedData = prefs.getString(_mindToolsActivityKey);

      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> decoded = jsonDecode(cachedData);
          activities =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } catch (e) {
          debugPrint('Error decoding cached activities: $e');
        }
      }

      // Add the new activity
      final formattedDate = activityDate.toIso8601String().split('T')[0];
      activities.add({
        'tracker_type': trackerType,
        'activity_date': formattedDate,
        'count': count,
      });

      // Save the updated list
      final success =
          await prefs.setString(_mindToolsActivityKey, jsonEncode(activities));

      return success;
    } catch (e) {
      debugPrint('Error caching mind tools activity: $e');
      return false;
    }
  }

  // Sync all cached mind tools activity data
  Future<bool> syncMindToolsActivity() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        debugPrint('No auth token available for syncing');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_mindToolsActivityKey);

      if (cachedData == null || cachedData.isEmpty) {
        debugPrint('No cached mind tools activity to sync');
        return true; // Nothing to sync is a successful state
      }

      final List<dynamic> activities = jsonDecode(cachedData);
      if (activities.isEmpty) {
        await prefs.remove(_mindToolsActivityKey);
        return true;
      }

      // Send the sync request to the API
      final response = await http
          .post(
            Uri.parse(
                '${ApiConfig.baseUrl}${ApiConfig.mindToolsEndpoint}/sync'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'activities': activities}),
          )
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));

      if (response.statusCode == 200) {
        // Clear the cache on successful sync
        await prefs.remove(_mindToolsActivityKey);
        debugPrint(
            'Successfully synced ${activities.length} mind tools activities');
        return true;
      } else {
        debugPrint(
            'Failed to sync mind tools activities: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing mind tools activities: $e');
      return false;
    }
  }

  // Check if there's any offline data waiting to be synced
  Future<bool> hasOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasActivities = prefs.containsKey(_mindToolsActivityKey) &&
          (prefs.getString(_mindToolsActivityKey)?.isNotEmpty ?? false);

      return hasActivities;
    } catch (e) {
      debugPrint('Error checking for offline data: $e');
      return false;
    }
  }

  // Clear all offline cached data
  Future<bool> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mindToolsActivityKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
      return false;
    }
  }
}
