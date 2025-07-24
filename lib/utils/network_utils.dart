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
          .timeout(Duration(seconds: 5));

      debugPrint('Server health check: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Server health check failed: $e');
      return false;
    }
  }

  // Check if the database connection is working
  static Future<bool> isDatabaseConnected() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/db-test'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('Database connection check: OK');
        return true;
      } else {
        debugPrint('Database connection check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Database connection check failed: $e');
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
        message = 'Cannot reach the server';
      }
    } catch (e) {
      message = 'Error checking server status: $e';
    }

    return {
      'serverReachable': serverReachable,
      'databaseConnected': databaseConnected,
      'message': message,
    };
  }
}
