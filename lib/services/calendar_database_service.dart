import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CalendarDatabaseService {
  final String baseUrl;
  String? _authToken;

  // User information cache
  String? _userName;
  String? _userEmail;

  // Constructor
  CalendarDatabaseService({required this.baseUrl});

  // Getters
  String? get authToken => _authToken;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  // Setters
  set authToken(String? value) {
    _authToken = value;
  }

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
      _authToken = prefs.getString('auth_token');

      return _userName != null && _userEmail != null;
    } catch (e) {
      debugPrint('Error loading user info: $e');
      return false;
    }
  }

  // Helper method to perform HTTP requests with retry logic
  Future<http.Response> _performRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int? retryCount,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Add auth using username:email format
    if (_userName != null && _userEmail != null) {
      requestHeaders['Authorization'] = 'Bearer $_userName:$_userEmail';
      debugPrint('Using authentication: Bearer username:email format');
    } else if (_authToken != null) {
      // Fallback to token auth if available
      requestHeaders['Authorization'] = 'Bearer $_authToken';
      debugPrint('Using legacy authentication: Bearer token format');
    }

    debugPrint('Calendar API Request: $method $url');
    if (body != null) {
      debugPrint('Request body: ${jsonEncode(body)}');
    }

    final retries = retryCount ?? ApiConfig.retryAttempts;
    final timeout = Duration(seconds: ApiConfig.connectionTimeout);

    http.Response? response;
    int attempts = 0;
    bool success = false;

    while (!success && attempts <= retries) {
      attempts++;
      try {
        if (method == 'GET') {
          response =
              await http.get(url, headers: requestHeaders).timeout(timeout);
        } else if (method == 'POST') {
          response = await http
              .post(
                url,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        } else if (method == 'PUT') {
          response = await http
              .put(
                url,
                headers: requestHeaders,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(timeout);
        } else if (method == 'DELETE') {
          response =
              await http.delete(url, headers: requestHeaders).timeout(timeout);
        }

        success = true; // Request completed without exceptions
      } catch (e) {
        if (attempts > retries) {
          rethrow; // Re-throw the last exception if all retries failed
        }
        debugPrint(
            'Calendar API Request failed (attempt $attempts/$retries): $e');
        await Future.delayed(
            Duration(seconds: 1 * attempts)); // Exponential backoff
      }
    }

    if (response != null) {
      debugPrint('Calendar API Response: ${response.statusCode}');
      if (response.body.isNotEmpty) {
        try {
          final jsonResponse = jsonDecode(response.body);
          debugPrint('Response data: ${jsonEncode(jsonResponse)}');
        } catch (e) {
          debugPrint(
              'Response is not valid JSON: ${response.body.substring(0, min(100, response.body.length))}...');
        }
      }
    }

    return response!;
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

      // Use the new API endpoint
      String endpoint = '/api/calendar/load';

      // Add required query parameter
      endpoint += '?theme=${Uri.encodeComponent(theme)}';

      // Add optional date range if provided
      if (startDate != null) {
        endpoint += '&start_date=${Uri.encodeComponent(startDate)}';
      }
      if (endDate != null) {
        endpoint += '&end_date=${Uri.encodeComponent(endDate)}';
      }

      debugPrint('Requesting calendar tasks from: $endpoint');
      final response = await _performRequest(
        method: 'GET',
        endpoint: endpoint,
      );

      if (response.statusCode == 200) {
        final dynamic decodedData = jsonDecode(response.body);

        // Check if response is a list (direct array of tasks)
        if (decodedData is List) {
          debugPrint('Received direct list of ${decodedData.length} tasks');
          return {
            'success': true,
            'tasks': decodedData,
          };
        }
        // Check if response is a map with 'tasks' field
        else if (decodedData is Map && decodedData.containsKey('tasks')) {
          debugPrint(
              'Received wrapped response with ${(decodedData['tasks'] as List?)?.length ?? 0} tasks');
          return {
            'success': decodedData['success'] ?? true,
            'tasks': decodedData['tasks'] ?? [],
          };
        }
        // Fallback to empty response
        else {
          debugPrint('Received unknown response format');
          return {
            'success': false,
            'message': 'Invalid response format',
            'tasks': [],
          };
        }
      } else {
        String errorMessage = 'Failed to get calendar tasks';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          // If response is not valid JSON
        }

        return {
          'success': false,
          'message': errorMessage,
          'tasks': [],
        };
      }
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
      final formattedDate =
          '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';

      // Use the updated API endpoint
      final response = await _performRequest(
        method: 'POST',
        endpoint: '/api/calendar/save',
        body: {
          'user_name': _userName,
          'email': _userEmail,
          'task_date': formattedDate,
          'task_type': taskType,
          'task_description': description,
          'color_code': colorCode,
          'theme': theme,
        },
      );

      debugPrint('Save response status: ${response.statusCode}');
      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Task saved successfully',
          'task': data['task'],
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to save task',
        };
      }
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
      Map<String, dynamic> updateData = {
        'user_name': _userName,
        'email': _userEmail,
      };

      // Add optional fields if provided
      if (taskDate != null) {
        final formattedDate =
            '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';
        updateData['task_date'] = formattedDate;
      }
      if (taskType != null) updateData['task_type'] = taskType;
      if (description != null) updateData['task_description'] = description;
      if (colorCode != null) updateData['color_code'] = colorCode;

      // Include the ID in the request body
      updateData['id'] = taskId;

      // Use the updated API endpoint with ID in the body instead of URL
      final response = await _performRequest(
        method: 'POST',
        endpoint: '/api/calendar/save',
        body: updateData,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Task updated successfully',
          'task': data['task'],
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to update task',
        };
      }
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

      // Use the new API endpoint with delete flag
      final response = await _performRequest(
        method: 'POST',
        endpoint: '/api/calendar/save',
        body: {
          'user_name': _userName,
          'email': _userEmail,
          'id': taskId,
          'delete': true,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Task deleted successfully',
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete task',
        };
      }
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
      final formattedDate =
          '${taskDate.year}-${taskDate.month.toString().padLeft(2, '0')}-${taskDate.day.toString().padLeft(2, '0')}';

      final response = await _performRequest(
        method: 'DELETE',
        endpoint:
            '/calendar2025/tasks/by-date?date=$formattedDate&user_name=${Uri.encodeComponent(_userName!)}&theme=${Uri.encodeComponent(theme)}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Tasks deleted successfully',
        };
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to delete tasks',
        };
      }
    } catch (e) {
      debugPrint('Error in deleteCalendarTasksByDate: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting tasks',
      };
    }
  }

  // Helper function for min calculation
  int min(int a, int b) => a < b ? a : b;
}
