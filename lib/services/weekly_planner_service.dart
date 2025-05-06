import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeeklyPlannerService {
  static final WeeklyPlannerService instance = WeeklyPlannerService._internal();
  final String baseUrl = 'https://reconstrect-api.onrender.com';

  WeeklyPlannerService._internal();

  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing connection: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadUserTasks(
      Map<String, dynamic> userInfo,
      {String? theme}) async {
    try {
      final Uri uri = theme != null
          ? Uri.parse('$baseUrl/weekly-planner/tasks?theme=$theme')
          : Uri.parse('$baseUrl/weekly-planner/tasks');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['tasks'] != null) {
          final tasks = List<Map<String, dynamic>>.from(data['tasks']);

          if (theme != null) {
            // Only return tasks that match the specified theme
            final filteredTasks = tasks.where((task) {
              // First check if the theme matches exactly
              if (task['theme'] != theme) return false;

              // Get the card_id (day)
              final cardId = task['card_id'] as String? ?? '';

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

              // Accept tasks with either format:
              // 1. Just the day name (new format)
              // 2. Theme_day format (legacy format)
              final themePrefix = '${theme}_';

              return validDays.contains(cardId) ||
                  cardId.startsWith(themePrefix);
            }).toList();

            return filteredTasks;
          }

          return tasks;
        }
      }
      return [];
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  Future<bool> saveTodoItem(
      Map<String, dynamic> userInfo, String day, String tasks,
      {String theme = 'japanese'}) async {
    try {
      // Use day directly as card_id (without theme prefix)
      // The theme is stored in the separate theme column
      final response = await http.post(
        Uri.parse('$baseUrl/weekly-planner/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'user_name': userInfo['userName'],
          'email': userInfo['email'],
          'card_id': day,
          'tasks': tasks,
          'theme': theme
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error saving task: $e');
      return false;
    }
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
