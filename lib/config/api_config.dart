import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static Environment _environment = Environment.development;

  // Initialize the configuration
  static void initialize({Environment environment = Environment.development}) {
    _environment = environment;
    debugPrint('API Environment: ${_environment.toString()}');
  }

  // Base URL for the API
  static String get baseUrl => 'https://reconstrect-api.onrender.com';

  // Connection timeout in seconds
  static int get connectionTimeout => 10;

  // Retry attempts for failed API calls
  static int get retryAttempts => 3;
}
