import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../pages/post_it_theme_vision_board.dart'; // Import to use TodoItem class

class VisionBoardService {
  // Base URL for your API endpoints
  final String baseUrl;
  String? _authToken;

  // Constructor
  VisionBoardService({required this.baseUrl});

  // Getter/setter for auth token
  String? get authToken => _authToken;
  set authToken(String? value) {
    _authToken = value;
  }

  // Helper method to build the authorization headers
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  // Fetch all vision board tasks for a user and category
  Future<Map<String, dynamic>> getVisionBoardTasks({
    required String category,
    String? userId,
    String? theme,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vision-board/tasks');

      final queryParams = {
        'category': category,
        if (userId != null) 'user_id': userId,
        if (theme != null) 'theme': theme,
      };

      final response = await http.get(
        Uri.parse('$url?${Uri(queryParameters: queryParams).query}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'tasks': data['tasks'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch vision board tasks',
        };
      }
    } catch (e) {
      debugPrint('Error fetching vision board tasks: $e');
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }

  // Save vision board tasks for a user and category
  Future<Map<String, dynamic>> saveVisionBoardTasks({
    required String category,
    required List<TodoItem> tasks,
    required String theme,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vision-board/tasks');

      // Convert TodoItems to JSON format understood by the database
      final tasksJson = tasks
          .map((task) => {
                'text': task.text,
                'completed': task.isDone,
                'id': task.id,
              })
          .toList();

      final body = jsonEncode({
        'card_id': category,
        'tasks': tasksJson,
        'theme': theme,
        if (userId != null) 'user_id': userId,
      });

      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Tasks saved successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to save vision board tasks',
        };
      }
    } catch (e) {
      debugPrint('Error saving vision board tasks: $e');
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }

  // Update a vision board task
  Future<Map<String, dynamic>> updateVisionBoardTask({
    required String category,
    required TodoItem task,
    required String theme,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vision-board/tasks/${task.id}');

      final body = jsonEncode({
        'text': task.text,
        'completed': task.isDone,
        'card_id': category,
        'theme': theme,
        if (userId != null) 'user_id': userId,
      });

      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Task updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update vision board task',
        };
      }
    } catch (e) {
      debugPrint('Error updating vision board task: $e');
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }

  // Delete a vision board task
  Future<Map<String, dynamic>> deleteVisionBoardTask({
    required String taskId,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/vision-board/tasks/$taskId');

      final queryParams = {
        if (userId != null) 'user_id': userId,
      };

      final response = await http.delete(
        Uri.parse('$url?${Uri(queryParameters: queryParams).query}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Task deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to delete vision board task',
        };
      }
    } catch (e) {
      debugPrint('Error deleting vision board task: $e');
      return {
        'success': false,
        'message': 'Error connecting to server: $e',
      };
    }
  }
}
