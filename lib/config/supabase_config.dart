import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseConfig {
  // Supabase URL and keys
  static const String url = 'https://ruxsfzvrumqxsvanbbow.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg5NTIyNTQsImV4cCI6MjA2NDUyODI1NH0.v-sa-R8Ox8Qcwx6RhCydokwIm--pZytje5cuNyV0Oqg';
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODk1MjI1NCwiZXhwIjoyMDY0NTI4MjU0fQ.nB_wLdAyCGS65u3dvb14V2dAOSGEPdV-FuR6vQ6TYtE';

  // Track if Supabase is already initialized
  static bool _isInitialized = false;

  // Initialize Supabase client
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('SupabaseConfig: Already initialized, skipping');
      return;
    }

    try {
      await supabase.Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('SupabaseConfig: Successfully initialized');
    } catch (e) {
      debugPrint('SupabaseConfig: Initialization failed: $e');
      // Don't rethrow - allow app to continue even if Supabase init fails
    }
  }

  // Get the Supabase client instance
  static supabase.SupabaseClient get client {
    if (!_isInitialized) {
      debugPrint(
          'SupabaseConfig: Warning - Client accessed before initialization');
    }
    return supabase.Supabase.instance.client;
  }

  // Connection timeouts
  static int get connectionTimeout => 10;
  static int get receiveTimeout => 15;
  static int get retryAttempts => 5;

  // Check if initialized
  static bool get isInitialized => _isInitialized;
}
