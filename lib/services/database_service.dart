import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  final String apiBaseUrl = 'https://reconstrect-api.onrender.com';
  bool _isConnected = false;

  // Track if the server has task-related tables
  bool _hasTaskTables = false;

  // Singleton pattern
  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  DatabaseService._();

  // Check if we're connected to the API
  bool get isConnected => _isConnected;

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    return await UserService.instance.isUserLoggedIn();
  }

  Future<bool> _checkConnection() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/health'));
      print('Connection check response: ${response.body}');

      // If health check passes, check if tables exist
      if (response.statusCode == 200) {
        _checkTablesExist();
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Connection check failed: $e');
      return false;
    }
  }

  // Check if task tables exist in the database
  Future<void> _checkTablesExist() async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/test/tables'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['tables'] != null &&
            (data['tables']['vision_board_tasks'] != null ||
                data['tables']['weekly_planner_tasks'] != null)) {
          _hasTaskTables = true;
          print(
              'Database has task tables: vision_board_tasks or weekly_planner_tasks');
        } else {
          _hasTaskTables = false;
          print('Task tables not found in database');
        }
      }
    } catch (e) {
      print('Table check failed: $e');
    }
  }

  // New method to try fetching tasks using the test/tables endpoint
  Future<List<Map<String, dynamic>>> fetchTasksFromTestEndpoint(
      Map<String, dynamic> userInfo, String theme) async {
    if (!await _checkConnection()) {
      print('Failed to load tasks: No connection to API');
      return [];
    }

    if (!_hasTaskTables) {
      print('Failed to load tasks: Task tables not found in database');
      return [];
    }

    try {
      // We only have the /test/tables endpoint that works, but it doesn't
      // let us query specific data. In a real app, we would need a proper API endpoint.
      // For now, we'll just inform that we can see the tables but can't query them.
      print(
          'Task tables exist but no API endpoint is available to query them.');

      // Return an empty list since we can't actually query the data
      return [];
    } catch (e) {
      print('Failed to fetch tasks from test endpoint: $e');
      return [];
    }
  }

  // Check if API endpoints exist (cached check to avoid repeated failures)
  bool _apiEndpointsExist = false;
  DateTime? _lastApiCheckTime;

  Future<bool> _checkApiEndpoints() async {
    // Use cached result if checked within the last hour
    if (_lastApiCheckTime != null) {
      final timeSinceLastCheck = DateTime.now().difference(_lastApiCheckTime!);
      if (timeSinceLastCheck.inMinutes < 60) {
        return _apiEndpointsExist;
      }
    }

    try {
      // Try a lightweight call to the task endpoints
      final response = await http.head(
        Uri.parse('$apiBaseUrl/api/tasks/load'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 1));

      _lastApiCheckTime = DateTime.now();
      _apiEndpointsExist = response.statusCode != 404;
      return _apiEndpointsExist;
    } catch (e) {
      _lastApiCheckTime = DateTime.now();
      _apiEndpointsExist = false;
      print('API endpoints check failed: $e');
      return false;
    }
  }

  Future<bool> saveTodoItem(Map<String, dynamic> userInfo, String cardId,
      String tasks, String theme) async {
    // First check if the API is online
    if (!await _checkConnection()) {
      print('Failed to save task: No connection to API');
      return false;
    }

    // Then check if user is logged in
    if (!await isUserLoggedIn()) {
      print('Failed to save task: User not logged in');
      return false;
    }

    // Check if the endpoints exist before trying to use them
    if (!await _checkApiEndpoints()) {
      print('Failed to save task: API endpoints not available');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/tasks/save'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userInfo['userName']}:${userInfo['email']}'
        },
        body: jsonEncode({
          'user_name': userInfo['userName'],
          'email': userInfo['email'],
          'card_id': cardId,
          'tasks': tasks,
          'theme': theme,
          'table': 'vision_board_tasks'
        }),
      );

      print('Save task response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Failed to save task: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> loadUserTasks(
      Map<String, dynamic> userInfo, String theme) async {
    // First check if the API is online
    if (!await _checkConnection()) {
      print('Failed to load tasks: No connection to API');
      return [];
    }

    // Then check if user is logged in
    if (!await isUserLoggedIn()) {
      print('Failed to load tasks: User not logged in');
      return [];
    }

    // First try the regular API endpoint
    try {
      final queryParams = {
        'theme': theme,
        'user_name': userInfo['userName'],
        'email': userInfo['email']
      };

      final uri = Uri.parse('$apiBaseUrl/api/tasks/load')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${userInfo['userName']}:${userInfo['email']}'
        },
      ).timeout(const Duration(seconds: 10));

      print('Load tasks response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        print('API error: ${data['message']}');
        return [];
      }

      // If the API endpoint fails with 404, try the test endpoint
      if (response.statusCode == 404) {
        print('Regular API endpoint not found, trying test endpoint');
        return await fetchTasksFromTestEndpoint(userInfo, theme);
      }

      return [];
    } catch (e) {
      print('Failed to load tasks from API: $e');
      return [];
    }
  }

  // Method to test the API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      debugPrint('Testing API connection...');

      final isLoggedIn = await isUserLoggedIn();
      final userInfo =
          isLoggedIn ? await UserService.instance.getUserInfo() : null;

      // Use the health endpoint since we know it exists
      final response = await http.get(
        Uri.parse('$apiBaseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
          if (isLoggedIn)
            'Authorization':
                'Bearer ${userInfo?['userName']}:${userInfo?['email']}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _isConnected = true;

        // Also check if the tables exist
        await _checkTablesExist();

        String message = 'API connection successful' +
            (isLoggedIn
                ? ' (User is logged in as: ${userInfo?['userName']})'
                : ' (User is not logged in)');

        if (_hasTaskTables) {
          message +=
              '\nTask tables found but API endpoints for tasks are missing.';
        }

        return {
          'success': true,
          'message': message,
          'hasTaskTables': _hasTaskTables
        };
      } else {
        _isConnected = false;
        return {
          'success': false,
          'message':
              'API connection failed: Status ${response.statusCode} - ${response.body}',
          'hasTaskTables': false
        };
      }
    } catch (e) {
      _isConnected = false;

      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException')) {
        errorMessage =
            'Unable to connect to API. Please check your internet connection.';
      } else if (errorMessage.contains('TimeoutException')) {
        errorMessage =
            'API request timed out. The server might be overloaded or down.';
      }

      return {
        'success': false,
        'message': 'API connection failed: $errorMessage',
        'hasTaskTables': false
      };
    }
  }
}
