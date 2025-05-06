import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AnnualCalendarService {
  static final AnnualCalendarService instance =
      AnnualCalendarService._internal();
  final String baseUrl = 'https://reconstrect-api.onrender.com';

  AnnualCalendarService._internal();

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
          ? Uri.parse('$baseUrl/annual-calendar/tasks?theme=$theme')
          : Uri.parse('$baseUrl/annual-calendar/tasks');

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

          // If a theme is specified, filter tasks by that theme
          if (theme != null) {
            return tasks.where((task) => task['theme'] == theme).toList();
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
      Map<String, dynamic> userInfo, String month, String tasks,
      {String theme = 'floral'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/annual-calendar/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAuthToken()}',
        },
        body: json.encode({
          'user_name': userInfo['userName'],
          'email': userInfo['email'],
          'card_id': month,
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
