import 'package:flutter/foundation.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static Environment _environment = Environment.development;

  // Initialize the configuration
  static void initialize({Environment environment = Environment.development}) {
    _environment = environment;
    debugPrint('API Environment: ${_environment.toString()}');
  }

  // Base URL for the API based on environment
  static String get baseUrl {
    switch (_environment) {
      case Environment.staging:
        return 'https://reconstrect-api.onrender.com';
      case Environment.production:
        return 'https://api.reconstrect.com';
      default:
        return 'https://reconstrect-api.onrender.com';
    }
  }

  // Alternative URLs for direct access
  static const String stagingUrl = 'https://reconstrect-api.onrender.com';
  static const String productionUrl = 'https://api.reconstrect.com';

  // API endpoints
  static const String authEndpoint = '/auth';
  static const String mindToolsEndpoint = '/api/mind-tools';
  static const String healthEndpoint = '/health';

  // Connection timeout in seconds
  static int get connectionTimeout => 10;

  // Receive timeout in seconds
  static int get receiveTimeout => 15;

  // Retry attempts for failed API calls
  static int get retryAttempts => 5;

  // Connectivity check timeouts
  static int get connectivityCheckTimeout => 8;
  static int get connectivityCheckFallbackTimeout => 5;

  // Max time to wait for a sync operation in seconds
  static int get syncOperationTimeout => 20;
}
