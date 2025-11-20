import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'tool_usage_database_service.dart';

/// Service to manage tool usage entries with dates and categories
/// Uses database with fallback to SharedPreferences for offline support
class ToolUsageService {
  static final ToolUsageService _instance = ToolUsageService._internal();
  factory ToolUsageService() => _instance;
  ToolUsageService._internal();

  static const String _storageKey = 'tool_usage_entries';
  static const String _categoriesKey = 'tool_usage_categories';

  final ToolUsageDatabaseService _dbService = ToolUsageDatabaseService.instance;

  /// Check if device has network connectivity
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('ToolUsageService: Network connectivity check failed: $e');
      return false;
    }
  }

  /// Categories for tool usage
  static const String categoryResetEmotions = 'Reset_my_emotions';
  static const String categoryClearMind = 'Clear_my_mind';
  static const String categoryPlanFuture = 'Plan_my_future';

  /// Save a tool usage entry
  Future<bool> saveToolUsage({
    required String toolName,
    required String category,
    String? toolData,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final now = DateTime.now();
      final dateKey = _formatDate(now);

      // Check network connectivity first
      final hasNetwork = await _hasNetworkConnection();
      
      // PRIORITY 1: Try database first (only if network is available)
      bool dbSaveSuccess = false;
      if (hasNetwork) {
        try {
          debugPrint('ToolUsageService: Network available - attempting to save to database...');
          final success = await _dbService.saveToolUsage(
            toolName: toolName,
            category: category,
            toolData: toolData,
            metadata: metadata,
          );
          if (success) {
            debugPrint('✅ Tool usage saved to database: $toolName in $category on $dateKey');
            dbSaveSuccess = true;
            // If database save succeeded, we can return early (local storage is just backup)
            // But we still save to local storage as backup
          } else {
            debugPrint('ToolUsageService: Database save returned false');
          }
        } catch (e, stackTrace) {
          debugPrint('❌ Error saving to database: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint('ToolUsageService: No network connection - skipping database save');
      }

      // PRIORITY 2: Save to local storage (as backup if online, primary if offline)
      final localSaveSuccess = await _saveToLocalStorage(toolName, category, dateKey, now, toolData, metadata);
      
      if (hasNetwork && dbSaveSuccess) {
        debugPrint('ToolUsageService: Saved to both database and local storage (backup)');
        return true;
      } else if (!hasNetwork && localSaveSuccess) {
        debugPrint('ToolUsageService: Saved to local storage (offline mode)');
        return true;
      } else if (localSaveSuccess) {
        debugPrint('ToolUsageService: Saved to local storage (database save failed)');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error saving tool usage: $e');
      return false;
    }
  }

  /// Save to local storage (SharedPreferences)
  Future<bool> _saveToLocalStorage(
    String toolName,
    String category,
    String dateKey,
    DateTime now,
    String? toolData,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create entry
      final entry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'toolName': toolName,
        'category': category,
        'date': dateKey,
        'timestamp': now.toIso8601String(),
        'toolData': toolData,
        'metadata': metadata ?? {},
      };

      // Get existing entries
      final entriesJson = prefs.getString(_storageKey);
      List<Map<String, dynamic>> entries = [];
      
      if (entriesJson != null) {
        final decoded = json.decode(entriesJson);
        if (decoded is List) {
          entries = List<Map<String, dynamic>>.from(
            decoded.map((e) => Map<String, dynamic>.from(e))
          );
        }
      }

      // Add new entry
      entries.add(entry);

      // Save back
      await prefs.setString(_storageKey, json.encode(entries));

      // Update category dates
      await _updateCategoryDates(category, dateKey, prefs);

      debugPrint('✅ Tool usage saved to local storage: $toolName in $category on $dateKey');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving to local storage: $e');
      return false;
    }
  }

  /// Get all entries for a specific date
  Future<List<Map<String, dynamic>>> getEntriesForDate(String date) async {
    try {
      // Check network connectivity first
      final hasNetwork = await _hasNetworkConnection();
      
      List<Map<String, dynamic>> dbEntries = [];
      
      // PRIORITY 1: Try database first (only if network is available)
      if (hasNetwork) {
        try {
          dbEntries = await _dbService.getEntriesForDate(date);
          debugPrint('ToolUsageService: Retrieved ${dbEntries.length} entries from database for date $date');
        } catch (e, stackTrace) {
          debugPrint('❌ Error getting entries from database: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint('ToolUsageService: No network - skipping database query');
      }

      // Also get from local storage
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      List<Map<String, dynamic>> localEntries = [];
      
      if (entriesJson != null) {
        try {
          final decoded = json.decode(entriesJson);
          if (decoded is List) {
            localEntries = List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e))
            ).where((entry) => entry['date'] == date).toList();
            debugPrint('ToolUsageService: Retrieved ${localEntries.length} entries from local storage for date $date');
          }
        } catch (e) {
          debugPrint('❌ Error parsing local storage entries: $e');
        }
      }

      // When online: Database is source of truth - use ONLY database entries
      // When offline: Use local storage entries
      if (hasNetwork) {
        // Online: Return only database entries (database is source of truth)
        final convertedDbEntries = dbEntries.isNotEmpty 
            ? _convertDbEntriesToLocalFormat(dbEntries)
            : <Map<String, dynamic>>[];
        debugPrint('ToolUsageService: Online mode - returning ${convertedDbEntries.length} entries from database only');
        return convertedDbEntries;
      } else {
        // Offline: Return only local storage entries
        debugPrint('ToolUsageService: Offline mode - returning ${localEntries.length} entries from local storage only');
        return localEntries;
      }
    } catch (e) {
      debugPrint('❌ Error getting entries for date: $e');
      return [];
    }
  }

  /// Get all entries for a specific category
  Future<List<Map<String, dynamic>>> getEntriesForCategory(String category) async {
    try {
      // Check network connectivity first
      final hasNetwork = await _hasNetworkConnection();
      
      List<Map<String, dynamic>> dbEntries = [];
      
      // PRIORITY 1: Try database first (only if network is available)
      if (hasNetwork) {
        try {
          dbEntries = await _dbService.getEntriesForCategory(category);
          debugPrint('ToolUsageService: Retrieved ${dbEntries.length} entries from database for category $category');
        } catch (e, stackTrace) {
          debugPrint('❌ Error getting entries from database: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint('ToolUsageService: No network - skipping database query');
      }

      // Also get from local storage
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      List<Map<String, dynamic>> localEntries = [];
      
      if (entriesJson != null) {
        try {
          final decoded = json.decode(entriesJson);
          if (decoded is List) {
            localEntries = List<Map<String, dynamic>>.from(
              decoded.map((e) => Map<String, dynamic>.from(e))
            ).where((entry) => entry['category'] == category).toList();
            debugPrint('ToolUsageService: Retrieved ${localEntries.length} entries from local storage for category $category');
          }
        } catch (e) {
          debugPrint('❌ Error parsing local storage entries: $e');
        }
      }

      // When online: Database is source of truth - use ONLY database entries
      // When offline: Use local storage entries
      if (hasNetwork) {
        // Online: Return only database entries (database is source of truth)
        final convertedDbEntries = dbEntries.isNotEmpty 
            ? _convertDbEntriesToLocalFormat(dbEntries)
            : <Map<String, dynamic>>[];
        final sorted = List<Map<String, dynamic>>.from(convertedDbEntries)..sort((a, b) {
          final dateA = a['timestamp'] as String? ?? '';
          final dateB = b['timestamp'] as String? ?? '';
          return dateB.compareTo(dateA); // Most recent first
        });
        debugPrint('ToolUsageService: Online mode - returning ${sorted.length} entries from database only');
        return sorted;
      } else {
        // Offline: Return only local storage entries
        final sorted = List<Map<String, dynamic>>.from(localEntries)..sort((a, b) {
          final dateA = a['timestamp'] as String? ?? '';
          final dateB = b['timestamp'] as String? ?? '';
          return dateB.compareTo(dateA); // Most recent first
        });
        debugPrint('ToolUsageService: Offline mode - returning ${sorted.length} entries from local storage only');
        return sorted;
      }
    } catch (e) {
      debugPrint('❌ Error getting entries for category: $e');
      return [];
    }
  }

  /// Get all entries for a category and date
  Future<List<Map<String, dynamic>>> getEntriesForCategoryAndDate(
    String category,
    String date,
  ) async {
    try {
      // Get entries from both database and local storage (merged)
      final allEntries = await getEntriesForCategory(category);
      
      // Filter by exact date match
      final filteredEntries = allEntries.where((entry) {
        final entryDate = entry['date'] as String? ?? '';
        final matches = entryDate == date;
        if (!matches) {
          debugPrint('ToolUsageService: Entry date mismatch - entry: $entryDate, requested: $date');
        }
        return matches;
      }).toList();
      
      debugPrint('ToolUsageService: getEntriesForCategoryAndDate - category: $category, date: $date, found: ${filteredEntries.length} entries');
      return filteredEntries;
    } catch (e) {
      debugPrint('❌ Error getting entries for category and date: $e');
      return [];
    }
  }

  /// Get all unique dates that have entries
  Future<List<String>> getAllDatesWithEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) return [];

      final decoded = json.decode(entriesJson);
      if (decoded is! List) return [];

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      final dates = allEntries
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
  Future<List<String>> getDatesForCategory(String category) async {
    try {
      final entries = await getEntriesForCategory(category);
      final dates = entries
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

  /// Get entry by ID
  Future<Map<String, dynamic>?> getEntryById(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) return null;

      final decoded = json.decode(entriesJson);
      if (decoded is! List) return null;

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      try {
        return allEntries.firstWhere((entry) => entry['id'] == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting entry by ID: $e');
      return null;
    }
  }

  /// Delete an entry
  Future<bool> deleteEntry(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) return false;

      final decoded = json.decode(entriesJson);
      if (decoded is! List) return false;

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      allEntries.removeWhere((entry) => entry['id'] == id);

      await prefs.setString(_storageKey, json.encode(allEntries));
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting entry: $e');
      return false;
    }
  }

  /// Get count of unique tools completed today for a category
  Future<int> getUniqueToolsCountForToday(String category) async {
    try {
      final now = DateTime.now();
      final today = _formatDate(now);
      
      debugPrint('ToolUsageService: getUniqueToolsCountForToday - category: $category, today: $today');
      
      // Check network connectivity first
      final hasNetwork = await _hasNetworkConnection();
      
      // When online: Query database directly (real-time, source of truth)
      // When offline: Get from local storage
      List<Map<String, dynamic>> todayEntries = [];
      if (hasNetwork) {
        // Online: Query database directly for today's entries
        try {
          final dbEntries = await _dbService.getEntriesForCategoryAndDate(category, today);
          todayEntries = _convertDbEntriesToLocalFormat(dbEntries);
          debugPrint('ToolUsageService: Online - retrieved ${todayEntries.length} entries from database for today');
        } catch (e) {
          debugPrint('ToolUsageService: Error getting database entries: $e');
          // Fallback to local storage if database query fails
          final entries = await getEntriesForCategoryAndDate(category, today);
          todayEntries = entries.where((entry) {
            final entryDate = entry['date'] as String? ?? '';
            return entryDate == today;
          }).toList();
        }
      } else {
        // Offline: Get from local storage
        final entries = await getEntriesForCategoryAndDate(category, today);
        todayEntries = entries.where((entry) {
          final entryDate = entry['date'] as String? ?? '';
          return entryDate == today;
        }).toList();
        debugPrint('ToolUsageService: Offline - retrieved ${todayEntries.length} entries from local storage for today');
      }
      
      debugPrint('ToolUsageService: getUniqueToolsCountForToday - Found ${todayEntries.length} entries for $category on $today (after filtering)');
      
      // For Plan my future, normalize tool names to count by category, not by theme
      // All Annual goals templates count as 1, Weekly as 1, Monthly as 1, Daily as 1
      if (category == categoryPlanFuture) {
        final normalizedTools = todayEntries.map((e) {
          final toolName = e['toolName'] as String? ?? '';
          final metadata = e['metadata'] as Map<String, dynamic>? ?? {};
          final toolType = metadata['toolType'] as String?;
          
          // Normalize based on toolType in metadata
          if (toolType == 'annual_goals') return 'Annual Goals';
          if (toolType == 'weekly_goals') return 'Weekly Goals';
          if (toolType == 'monthly_goals') return 'Monthly Goals';
          if (toolType == 'daily_goals') return 'Daily Goals';
          
          // Fallback: pattern matching on toolName if metadata not available
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
          
          return toolName; // Return original if can't normalize
        }).where((name) => name.isNotEmpty).toSet();
        
        return normalizedTools.length;
      }
      
      // For other categories, count unique tool names as-is
      final uniqueTools = todayEntries
          .map((e) => e['toolName'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
      
      debugPrint('ToolUsageService: getUniqueToolsCountForToday - Unique tools count: ${uniqueTools.length} for $category');
      return uniqueTools.length;
    } catch (e) {
      debugPrint('❌ Error getting unique tools count: $e');
      return 0;
    }
  }

  /// Get summary statistics
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) {
        return {
          'totalEntries': 0,
          'categories': {
            categoryResetEmotions: 0,
            categoryClearMind: 0,
            categoryPlanFuture: 0,
          },
          'totalDates': 0,
        };
      }

      final decoded = json.decode(entriesJson);
      if (decoded is! List) {
        return {
          'totalEntries': 0,
          'categories': {
            categoryResetEmotions: 0,
            categoryClearMind: 0,
            categoryPlanFuture: 0,
          },
          'totalDates': 0,
        };
      }

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      final categoryCounts = <String, int>{};
      final dates = <String>{};

      for (var entry in allEntries) {
        final category = entry['category'] as String? ?? 'unknown';
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        dates.add(entry['date'] as String);
      }

      return {
        'totalEntries': allEntries.length,
        'categories': {
          categoryResetEmotions: categoryCounts[categoryResetEmotions] ?? 0,
          categoryClearMind: categoryCounts[categoryClearMind] ?? 0,
          categoryPlanFuture: categoryCounts[categoryPlanFuture] ?? 0,
        },
        'totalDates': dates.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting summary: $e');
      return {
        'totalEntries': 0,
        'categories': {
          categoryResetEmotions: 0,
          categoryClearMind: 0,
          categoryPlanFuture: 0,
        },
        'totalDates': 0,
      };
    }
  }

  /// Helper method to update category dates
  Future<void> _updateCategoryDates(
    String category,
    String date,
    SharedPreferences prefs,
  ) async {
    try {
      final categoriesJson = prefs.getString(_categoriesKey);
      Map<String, dynamic> categories = {};
      
      if (categoriesJson != null) {
        categories = Map<String, dynamic>.from(json.decode(categoriesJson));
      }

      if (!categories.containsKey(category)) {
        categories[category] = [];
      }

      final categoryDates = List<String>.from(categories[category] ?? []);
      if (!categoryDates.contains(date)) {
        categoryDates.add(date);
        categoryDates.sort((a, b) => b.compareTo(a)); // Most recent first
        categories[category] = categoryDates;
      }

      await prefs.setString(_categoriesKey, json.encode(categories));
    } catch (e) {
      debugPrint('❌ Error updating category dates: $e');
    }
  }

  /// Convert database entries to local format (for compatibility)
  List<Map<String, dynamic>> _convertDbEntriesToLocalFormat(List<Map<String, dynamic>> dbEntries) {
    return dbEntries.map((e) {
      return {
        'id': e['id']?.toString() ?? '',
        'toolName': e['tool_name'] ?? '',
        'category': e['category'] ?? '',
        'date': e['date'] ?? '',
        'timestamp': e['timestamp'] ?? '',
        'toolData': e['tool_data'],
        'metadata': e['metadata'] ?? {},
      };
    }).toList();
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date for display
  static String formatDateForDisplay(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) return dateString;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (date == today) {
        return 'Today';
      } else if (date == yesterday) {
        return 'Yesterday';
      } else {
        final months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December'
        ];
        return '${months[month - 1]} $day, $year';
      }
    } catch (e) {
      return dateString;
    }
  }
}

