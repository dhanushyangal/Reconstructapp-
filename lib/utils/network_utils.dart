import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class NetworkUtils {
  static const String baseUrl = 'https://reconstrect-api.onrender.com';

  // Check if the API server is reachable
  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Server health check: OK');
        return true;
      } else {
        debugPrint('Server health check: Status ${response.statusCode}');
        return false;
      }
    } on TimeoutException {
      // Silently handle timeout - server may be slow but still functional
      return false;
    } catch (e) {
      // Only log non-timeout errors
      if (e is! TimeoutException) {
        debugPrint('Server health check error: $e');
      }
      return false;
    }
  }

  // Check if the database connection is working
  static Future<bool> isDatabaseConnected() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/db-test'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('Database connection check: OK');
        return true;
      } else {
        debugPrint('Database connection check: Status ${response.statusCode}');
        return false;
      }
    } on TimeoutException {
      // Silently handle timeout
      return false;
    } catch (e) {
      // Only log non-timeout errors
      if (e is! TimeoutException) {
        debugPrint('Database connection check error: $e');
      }
      return false;
    }
  }

  // Get detailed server status
  static Future<Map<String, dynamic>> getServerStatus() async {
    bool serverReachable = false;
    bool databaseConnected = false;
    String message = 'Unknown server status';

    try {
      serverReachable = await isServerReachable();

      if (serverReachable) {
        databaseConnected = await isDatabaseConnected();

        if (databaseConnected) {
          message = 'Server and database connection working properly';
        } else {
          message = 'Server is reachable but database connection failed';
        }
      } else {
        message = 'Cannot reach the server. Please check your connection and try again.';
      }
    } catch (e) {
      message = 'Error checking server status. Please try again.';
    }

    return {
      'serverReachable': serverReachable,
      'databaseConnected': databaseConnected,
      'message': message,
    };
  }
}
