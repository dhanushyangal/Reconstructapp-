import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../config/api_config.dart';

class MySqlDatabaseService {
  // Base URL for your API endpoints
  String baseUrl;

  // Store the auth token after successful login
  String? _authToken;

  // Constructor
  MySqlDatabaseService({required this.baseUrl});

  // Getter for auth token
  String? get authToken => _authToken;

  // Setter for auth token
  set authToken(String? value) {
    _authToken = value;
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

    // Add auth token if available
    if (_authToken != null) {
      requestHeaders['Authorization'] = 'Bearer $_authToken';
    }

    debugPrint('API Request: $method $url');
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
        debugPrint('API Request failed (attempt $attempts/$retries): $e');
        await Future.delayed(
            Duration(seconds: 1 * attempts)); // Exponential backoff
      }
    }

    if (response != null) {
      debugPrint('API Response: ${response.statusCode}');
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

  // Method to register a new user - updated to use the helper method
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint('MySqlDatabaseService: Starting registration for email: $email');
    try {
      final response = await _performRequest(
        method: 'POST',
        endpoint: '/auth/register',
        body: {
          'username': username,
          'email': email,
          'password': password,
        },
      );

      // Handle empty or invalid response
      if (response.body.isEmpty) {
        debugPrint(
            'MySqlDatabaseService: Received empty response body for registration');
        return {
          'success': false,
          'message': 'Server returned an empty response',
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint(
            'MySqlDatabaseService: Failed to decode registration response: $e');
        return {
          'success': false,
          'message': 'Invalid response from server',
        };
      }

      if (response.statusCode == 201) {
        // Store the token if available
        if (data.containsKey('token')) {
          _authToken = data['token'];
          debugPrint(
              'MySqlDatabaseService: Registration successful, token received');
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'user': data['user'],
          'token': data['token'],
        };
      } else {
        debugPrint(
            'MySqlDatabaseService: Registration failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Error in registerUser: $e');

      // Provide more specific error messages for common issues
      String errorMessage = 'An error occurred during registration';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection to server timed out. Please try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Helper function for min calculation
  int min(int a, int b) => a < b ? a : b;

  // Method to login a user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    bool isGoogleSignIn = false,
    Map<String, dynamic>? googleData,
  }) async {
    debugPrint(
        'MySqlDatabaseService: Attempting to connect to $baseUrl/auth/login');
    try {
      final endpoint = isGoogleSignIn ? '/auth/google' : '/auth/login';

      // Validate email format
      if (!email.contains('@')) {
        return {
          'success': false,
          'message': 'Please enter a valid email address',
        };
      }

      // Validate password
      if (password.isEmpty) {
        return {
          'success': false,
          'message': 'Password cannot be empty',
        };
      }

      // Prepare request body
      final body = {
        'email': email.trim(),
        'password': password,
      };

      // Add Google-specific data if needed
      if (isGoogleSignIn && googleData != null) {
        debugPrint('Adding Google sign-in data to request');
        body.addAll({
          'displayName': googleData['displayName'],
          'firebaseUid': googleData['firebaseUid'],
          'isGoogleSignIn': 'true',
          'storePassword': 'true',
          'passwordRequiresHashing': 'true',
          'isGoogleUser': 'true', // Additional flag to identify Google users
        });
        debugPrint('Request body with Google data: $body');
      }

      debugPrint(
          'MySqlDatabaseService: Sending request to $baseUrl$endpoint for email: $email');

      final response = await _performRequest(
        method: 'POST',
        endpoint: endpoint,
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      // Handle empty response
      if (response.body.isEmpty) {
        debugPrint('MySqlDatabaseService: Empty response from server');
        return {
          'success': false,
          'message': 'Server returned an empty response',
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
        debugPrint('MySqlDatabaseService: Response data: $data');
      } catch (e) {
        debugPrint('MySqlDatabaseService: Failed to decode response: $e');
        return {
          'success': false,
          'message': 'Invalid response format from server',
        };
      }

      if (response.statusCode == 200) {
        // Store the token if available
        if (data.containsKey('token')) {
          _authToken = data['token'];
          debugPrint('MySqlDatabaseService: Login successful, token received');
        }

        // Ensure we have user data
        if (data['user'] != null) {
          debugPrint('MySqlDatabaseService: User data received in response');

          // For Google sign-in, verify firebaseUid is stored
          if (isGoogleSignIn && googleData != null) {
            final userData = data['user'] as Map<String, dynamic>;
            if (userData['firebaseUid'] != googleData['firebaseUid']) {
              debugPrint(
                  'MySqlDatabaseService: Firebase UID mismatch or missing');
            }
          }
        }

        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'user': data['user'],
          'token': data['token'],
        };
      } else if (response.statusCode == 404) {
        debugPrint('MySqlDatabaseService: User not found');
        return {
          'success': false,
          'message': 'User not found',
        };
      } else {
        debugPrint(
            'MySqlDatabaseService: Login failed with status ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      debugPrint('Error in loginUser: $e');
      String errorMessage = 'An error occurred during login';

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Cannot connect to server. Please check your internet connection.';
      } else if (e is TimeoutException) {
        errorMessage = 'Connection to server timed out. Please try again.';
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  // Method to get the current user's profile
  Future<Map<String, dynamic>> getUserProfile() async {
    if (_authToken == null) {
      debugPrint('getUserProfile: No auth token available');
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }

    try {
      debugPrint('getUserProfile: Requesting profile with token');
      final response = await _performRequest(
        method: 'GET',
        endpoint: '/auth/profile',
      );

      // Handle empty response
      if (response.body.isEmpty) {
        debugPrint('getUserProfile: Empty response body');
        return {
          'success': false,
          'message': 'Empty response from server',
        };
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        debugPrint('getUserProfile: Failed to decode JSON: $e');
        return {
          'success': false,
          'message': 'Invalid response format',
        };
      }

      if (response.statusCode == 200) {
        if (data['user'] != null) {
          debugPrint('getUserProfile: Success, user data received');

          // Log the user data for debugging
          final userData = data['user'];
          debugPrint('getUserProfile: User email: ${userData['email']}');
          debugPrint('getUserProfile: Name: ${userData['name']}');
          debugPrint('getUserProfile: User ID: ${userData['id']}');

          return {
            'success': true,
            'user': userData,
          };
        } else {
          debugPrint('getUserProfile: Success response but no user data');
          return {
            'success': false,
            'message': 'No user data in response',
          };
        }
      } else {
        debugPrint('getUserProfile: Failed, message: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (e) {
      debugPrint('Error in getUserProfile: $e');
      return {
        'success': false,
        'message': 'An error occurred while fetching user profile: $e',
      };
    }
  }

  // Method to logout the user
  Future<void> logout() async {
    debugPrint('MySqlDatabaseService: Logging out, clearing token');

    // If you have a server endpoint to invalidate the token, call it here
    if (_authToken != null) {
      try {
        // Call logout endpoint if available
        // Example:
        // await http.post(
        //   Uri.parse('$baseUrl/auth/logout'),
        //   headers: {
        //     'Content-Type': 'application/json',
        //     'Authorization': 'Bearer $_authToken',
        //   },
        // );

        debugPrint('MySqlDatabaseService: Token cleared');
      } catch (e) {
        debugPrint('Error in server logout: $e');
      }
    }

    // Clear the token locally
    _authToken = null;
  }
}
