import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'user_service.dart';

// Access service role key from SupabaseConfig
extension SupabaseConfigExtension on SupabaseConfig {
  static const String url = 'https://ruxsfzvrumqxsvanbbow.supabase.co';
  static const String serviceRoleKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ1eHNmenZydW1xeHN2YW5iYm93Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0ODk1MjI1NCwiZXhwIjoyMDY0NTI4MjU0fQ.nB_wLdAyCGS65u3dvb14V2dAOSGEPdV-FuR6vQ6TYtE';
}

/// Service to manage tool usage entries in PostgreSQL database
class ToolUsageDatabaseService {
  static final ToolUsageDatabaseService instance = ToolUsageDatabaseService._internal();

  // Supabase client instance - using service role to bypass RLS
  late final supabase.SupabaseClient _client;

  ToolUsageDatabaseService._internal() {
    // Use service role client to bypass RLS (since we're using Firebase Auth, not Supabase Auth)
    // The service role key bypasses RLS policies, allowing queries to work properly
    try {
      _client = supabase.SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.serviceRoleKey,
      );
      debugPrint('ToolUsageDatabaseService: Using service role client (bypasses RLS)');
    } catch (e) {
      debugPrint('ToolUsageDatabaseService: Error creating service role client, falling back to anon: $e');
      _client = SupabaseConfig.nativeAuthClient;
    }
  }

  // Get current user info using UserService (consistent with other services)
  Future<Map<String, String>?> _getUserInfo() async {
    try {
      final userInfo = await UserService.instance.getUserInfo();
      final userName = userInfo['userName']?.trim() ?? '';
      final email = userInfo['email']?.trim() ?? '';
      
      debugPrint('ToolUsageDatabaseService: Retrieved user info - userName: ${userName.isNotEmpty ? userName : "empty"}, email: ${email.isNotEmpty ? email : "empty"}');
      
      if (userName.isNotEmpty && email.isNotEmpty) {
        return {'userName': userName, 'email': email};
      }
      
      debugPrint('ToolUsageDatabaseService: User info is empty or invalid - userName length: ${userName.length}, email length: ${email.length}');
      return null;
    } catch (e) {
      debugPrint('ToolUsageDatabaseService: Error getting user info: $e');
      return null;
    }
  }

  /// Save a tool usage entry to database
  Future<bool> saveToolUsage({
    required String toolName,
    required String category,
    String? toolData,
    Map<String, dynamic>? metadata,
    String? userName,
    String? email,
  }) async {
    try {
      // Get user info if not provided
      Map<String, String>? userInfo;
      if (userName == null || email == null || userName.isEmpty || email.isEmpty) {
        userInfo = await _getUserInfo();
        if (userInfo == null) {
          debugPrint('ToolUsageDatabaseService: No user info available - cannot save to database');
          return false;
        }
        userName = userInfo['userName']!.trim();
        email = userInfo['email']!.trim();
      } else {
        userName = userName.trim();
        email = email.trim();
      }

      if (userName.isEmpty || email.isEmpty) {
        debugPrint('ToolUsageDatabaseService: Invalid user info after processing - userName: "$userName", email: "$email"');
        return false;
      }

      final now = DateTime.now();
      final dateKey = _formatDate(now);

      debugPrint('ToolUsageDatabaseService: Attempting to save - tool: $toolName, category: $category, user: $userName, email: $email');

      // Check if entry already exists (based on unique constraint)
      final existing = await _client
          .from('tool_usage_entries')
          .select('id')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('tool_name', toolName)
          .eq('category', category)
          .eq('date', dateKey)
          .maybeSingle();

      if (existing != null) {
        // Update existing entry
        await _client
            .from('tool_usage_entries')
            .update({
              'timestamp': now.toIso8601String(),
              'tool_data': toolData,
              'metadata': metadata ?? {},
              'updated_at': now.toIso8601String(),
            })
            .eq('id', existing['id']);
        debugPrint('✅ Tool usage updated in database: $toolName in $category on $dateKey for user $userName');
      } else {
        // Insert new entry
        final insertResponse = await _client
            .from('tool_usage_entries')
            .insert({
              'user_name': userName,
              'email': email,
              'tool_name': toolName,
              'category': category,
              'date': dateKey,
              'timestamp': now.toIso8601String(),
              'tool_data': toolData,
              'metadata': metadata ?? {},
            })
            .select();
        
        debugPrint('✅ Tool usage saved to database: $toolName in $category on $dateKey for user $userName');
        debugPrint('ToolUsageDatabaseService: Insert response: ${insertResponse.length} row(s) inserted');
        if (insertResponse.isNotEmpty) {
          debugPrint('ToolUsageDatabaseService: Inserted entry ID: ${insertResponse.first['id']}');
          debugPrint('ToolUsageDatabaseService: Inserted data - user_name: ${insertResponse.first['user_name']}, email: ${insertResponse.first['email']}, category: ${insertResponse.first['category']}, date: ${insertResponse.first['date']}');
        } else {
          debugPrint('⚠️ ToolUsageDatabaseService: Insert returned empty response - save may have failed');
        }
      }
      
      // Verify the save by immediately querying for it (with a small delay to allow DB to process)
      try {
        await Future.delayed(const Duration(milliseconds: 100)); // Small delay for DB consistency
        final verifyQuery = await _client
            .from('tool_usage_entries')
            .select('id, tool_name, date, user_name, email, category')
            .eq('user_name', userName)
            .eq('email', email)
            .eq('tool_name', toolName)
            .eq('category', category)
            .eq('date', dateKey)
            .maybeSingle();
        
        if (verifyQuery != null) {
          debugPrint('✅ ToolUsageDatabaseService: Verified save - entry exists with ID: ${verifyQuery['id']}');
        } else {
          debugPrint('⚠️ ToolUsageDatabaseService: Save verification failed - entry not found');
          debugPrint('ToolUsageDatabaseService: Query params - user: "$userName", email: "$email", tool: "$toolName", category: "$category", date: "$dateKey"');
          
          // Try a broader query to see if ANY data exists
          try {
            final anyData = await _client
                .from('tool_usage_entries')
                .select('id, user_name, email')
                .limit(1);
            debugPrint('ToolUsageDatabaseService: Test query - found ${anyData.length} total entries in table');
            if (anyData.isNotEmpty) {
              debugPrint('ToolUsageDatabaseService: Sample entry - user: "${anyData.first['user_name']}", email: "${anyData.first['email']}"');
            }
          } catch (testError) {
            debugPrint('ToolUsageDatabaseService: Test query failed: $testError');
          }
        }
      } catch (verifyError) {
        debugPrint('⚠️ ToolUsageDatabaseService: Error verifying save: $verifyError');
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving tool usage to database: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get all entries for a specific date
  Future<List<Map<String, dynamic>>> getEntriesForDate(String date, {String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) return [];
        userName = userInfo['userName']!.trim();
        email = userInfo['email']!.trim();
      } else {
        userName = userName.trim();
        email = email.trim();
      }

      debugPrint('ToolUsageDatabaseService: Querying entries for date: $date, user: "$userName", email: "$email"');

      final response = await _client
          .from('tool_usage_entries')
          .select()
          .eq('user_name', userName)
          .eq('email', email)
          .eq('date', date)
          .order('timestamp', ascending: false);

      final entries = List<Map<String, dynamic>>.from(response);
      debugPrint('ToolUsageDatabaseService: Retrieved ${entries.length} entries for date $date');
      
      if (entries.isEmpty) {
        // Try case-insensitive search
        try {
          final caseInsensitiveResponse = await _client
              .from('tool_usage_entries')
              .select()
              .ilike('user_name', userName)
              .ilike('email', email)
              .eq('date', date)
              .order('timestamp', ascending: false);
          final caseInsensitiveEntries = List<Map<String, dynamic>>.from(caseInsensitiveResponse);
          debugPrint('ToolUsageDatabaseService: Found ${caseInsensitiveEntries.length} entries with case-insensitive search');
          if (caseInsensitiveEntries.isNotEmpty) {
            return caseInsensitiveEntries;
          }
        } catch (e) {
          debugPrint('ToolUsageDatabaseService: Case-insensitive search failed: $e');
        }
      }
      
      return entries;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting entries for date: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get all entries for a specific category
  Future<List<Map<String, dynamic>>> getEntriesForCategory(String category, {String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) {
          debugPrint('ToolUsageDatabaseService: No user info for getEntriesForCategory');
          return [];
        }
        userName = userInfo['userName']!.trim();
        email = userInfo['email']!.trim();
      } else {
        userName = userName.trim();
        email = email.trim();
      }

      debugPrint('ToolUsageDatabaseService: Querying entries for category: $category, user: "$userName", email: "$email"');

      // First, try a query without user filters to see if there's any data at all
      try {
        final allEntriesTest = await _client
            .from('tool_usage_entries')
            .select('user_name, email, category, tool_name, date')
            .eq('category', category)
            .limit(5);
        debugPrint('ToolUsageDatabaseService: Found ${allEntriesTest.length} total entries for category $category (test query)');
        if (allEntriesTest.isNotEmpty) {
          debugPrint('ToolUsageDatabaseService: Sample entry from test - user: "${allEntriesTest.first['user_name']}", email: "${allEntriesTest.first['email']}"');
        }
      } catch (e) {
        debugPrint('ToolUsageDatabaseService: Test query failed: $e');
      }

      // Now do the actual query with user filters
      final response = await _client
          .from('tool_usage_entries')
          .select()
          .eq('user_name', userName)
          .eq('email', email)
          .eq('category', category)
          .order('timestamp', ascending: false);

      final entries = List<Map<String, dynamic>>.from(response);
      debugPrint('ToolUsageDatabaseService: Retrieved ${entries.length} entries from database for category $category with user filters');
      
      // Log first few entries for debugging
      if (entries.isNotEmpty) {
        debugPrint('ToolUsageDatabaseService: Sample entry - tool: ${entries.first['tool_name']}, date: ${entries.first['date']}, user: ${entries.first['user_name']}');
      } else {
        // If no entries found, try a case-insensitive search
        debugPrint('ToolUsageDatabaseService: No entries found with exact match. Trying case-insensitive search...');
        try {
          final caseInsensitiveResponse = await _client
              .from('tool_usage_entries')
              .select()
              .ilike('user_name', userName)
              .ilike('email', email)
              .eq('category', category)
              .order('timestamp', ascending: false);
          final caseInsensitiveEntries = List<Map<String, dynamic>>.from(caseInsensitiveResponse);
          debugPrint('ToolUsageDatabaseService: Found ${caseInsensitiveEntries.length} entries with case-insensitive search');
          if (caseInsensitiveEntries.isNotEmpty) {
            return caseInsensitiveEntries;
          }
        } catch (e) {
          debugPrint('ToolUsageDatabaseService: Case-insensitive search failed: $e');
        }
      }
      
      return entries;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting entries for category: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get all entries for a category and date
  Future<List<Map<String, dynamic>>> getEntriesForCategoryAndDate(
    String category,
    String date, {
    String? userName,
    String? email,
  }) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) return [];
        userName = userInfo['userName']!.trim();
        email = userInfo['email']!.trim();
      } else {
        userName = userName.trim();
        email = email.trim();
      }

      debugPrint('ToolUsageDatabaseService: Querying entries for category: $category, date: $date, user: "$userName", email: "$email"');

      final response = await _client
          .from('tool_usage_entries')
          .select()
          .eq('user_name', userName)
          .eq('email', email)
          .eq('category', category)
          .eq('date', date)
          .order('timestamp', ascending: false);

      final entries = List<Map<String, dynamic>>.from(response);
      debugPrint('ToolUsageDatabaseService: Retrieved ${entries.length} entries for category $category and date $date');
      
      if (entries.isEmpty) {
        // Try case-insensitive search
        try {
          final caseInsensitiveResponse = await _client
              .from('tool_usage_entries')
              .select()
              .ilike('user_name', userName)
              .ilike('email', email)
              .eq('category', category)
              .eq('date', date)
              .order('timestamp', ascending: false);
          final caseInsensitiveEntries = List<Map<String, dynamic>>.from(caseInsensitiveResponse);
          debugPrint('ToolUsageDatabaseService: Found ${caseInsensitiveEntries.length} entries with case-insensitive search');
          if (caseInsensitiveEntries.isNotEmpty) {
            return caseInsensitiveEntries;
          }
        } catch (e) {
          debugPrint('ToolUsageDatabaseService: Case-insensitive search failed: $e');
        }
      }
      
      return entries;
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting entries for category and date: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get count of unique tools completed today for a category
  Future<int> getUniqueToolsCountForToday(String category, {String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) {
          debugPrint('ToolUsageDatabaseService: No user info for getUniqueToolsCountForToday');
          return 0;
        }
        userName = userInfo['userName']!;
        email = userInfo['email']!;
      }

      final today = _formatDate(DateTime.now());
      debugPrint('ToolUsageDatabaseService: Getting unique tools count for category: $category, date: $today, user: $userName');
      
      final entries = await getEntriesForCategoryAndDate(category, today, userName: userName, email: email);
      debugPrint('ToolUsageDatabaseService: Found ${entries.length} entries for $category on $today');

      // For Plan my future, normalize tool names
      if (category == 'Plan_my_future') {
        final normalizedTools = entries.map((e) {
          final toolName = e['tool_name'] as String? ?? '';
          final metadata = e['metadata'] as Map<String, dynamic>? ?? {};
          final toolType = metadata['toolType'] as String?;
          
          if (toolType == 'annual_goals') return 'Annual Goals';
          if (toolType == 'weekly_goals') return 'Weekly Goals';
          if (toolType == 'monthly_goals') return 'Monthly Goals';
          if (toolType == 'daily_goals') return 'Daily Goals';
          
          final name = toolName.toLowerCase();
          if (name.contains('annual') || name.contains('vision board') || 
              name.contains('boxy theme') || name.contains('post it theme') ||
              name.contains('premium black') || name.contains('floral theme')) {
            return 'Annual Goals';
          }
          if (name.contains('weekly') || name.contains('weekly planner')) {
            return 'Weekly Goals';
          }
          if (name.contains('monthly') || name.contains('monthly planner')) {
            return 'Monthly Goals';
          }
          if (name.contains('daily') || name.contains('daily notes')) {
            return 'Daily Goals';
          }
          
          return toolName;
        }).where((name) => name.isNotEmpty).toSet();
        
        return normalizedTools.length;
      }
      
      // For other categories, count unique tool names
      final uniqueTools = entries
          .map((e) => e['tool_name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
      
      return uniqueTools.length;
    } catch (e) {
      debugPrint('❌ Error getting unique tools count: $e');
      return 0;
    }
  }

  /// Get all unique dates that have entries
  Future<List<String>> getAllDatesWithEntries({String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) return [];
        userName = userInfo['userName']!;
        email = userInfo['email']!;
      }

      final response = await _client
          .from('tool_usage_entries')
          .select('date')
          .eq('user_name', userName)
          .eq('email', email);

      final dates = (response as List)
          .map((e) => e['date'] as String)
          .toSet()
          .toList();
      
      dates.sort((a, b) => b.compareTo(a)); // Most recent first
      return dates;
    } catch (e) {
      debugPrint('❌ Error getting all dates: $e');
      return [];
    }
  }

  /// Get all unique dates for a specific category
  Future<List<String>> getDatesForCategory(String category, {String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) return [];
        userName = userInfo['userName']!;
        email = userInfo['email']!;
      }

      final response = await _client
          .from('tool_usage_entries')
          .select('date')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('category', category);

      final dates = (response as List)
          .map((e) => e['date'] as String)
          .toSet()
          .toList();
      
      dates.sort((a, b) => b.compareTo(a)); // Most recent first
      return dates;
    } catch (e) {
      debugPrint('❌ Error getting dates for category: $e');
      return [];
    }
  }

  /// Delete an entry by ID
  Future<bool> deleteEntry(String id, {String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) return false;
        userName = userInfo['userName']!;
        email = userInfo['email']!;
      }

      await _client
          .from('tool_usage_entries')
          .delete()
          .eq('id', id)
          .eq('user_name', userName)
          .eq('email', email);

      return true;
    } catch (e) {
      debugPrint('❌ Error deleting entry: $e');
      return false;
    }
  }

  /// Get summary statistics
  Future<Map<String, dynamic>> getSummary({String? userName, String? email}) async {
    try {
      Map<String, String>? userInfo;
      if (userName == null || email == null) {
        userInfo = await _getUserInfo();
        if (userInfo == null) {
          return {
            'totalEntries': 0,
            'categories': {
              'Reset_my_emotions': 0,
              'Clear_my_mind': 0,
              'Plan_my_future': 0,
            },
            'totalDates': 0,
          };
        }
        userName = userInfo['userName']!;
        email = userInfo['email']!;
      }

      final response = await _client
          .from('tool_usage_entries')
          .select('category, date')
          .eq('user_name', userName)
          .eq('email', email);

      final entries = List<Map<String, dynamic>>.from(response);
      final categoryCounts = <String, int>{};
      final dates = <String>{};

      for (var entry in entries) {
        final category = entry['category'] as String? ?? 'unknown';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        dates.add(entry['date'] as String);
      }

      return {
        'totalEntries': entries.length,
        'categories': {
          'Reset_my_emotions': categoryCounts['Reset_my_emotions'] ?? 0,
          'Clear_my_mind': categoryCounts['Clear_my_mind'] ?? 0,
          'Plan_my_future': categoryCounts['Plan_my_future'] ?? 0,
        },
        'totalDates': dates.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting summary: $e');
      return {
        'totalEntries': 0,
        'categories': {
          'Reset_my_emotions': 0,
          'Clear_my_mind': 0,
          'Plan_my_future': 0,
        },
        'totalDates': 0,
      };
    }
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      await _client.from('tool_usage_entries').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing database connection: $e');
      return false;
    }
  }
}

