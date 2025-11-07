import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service to manage tool usage entries with dates and categories
class ToolUsageService {
  static final ToolUsageService _instance = ToolUsageService._internal();
  factory ToolUsageService() => _instance;
  ToolUsageService._internal();

  static const String _storageKey = 'tool_usage_entries';
  static const String _categoriesKey = 'tool_usage_categories';

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
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateKey = _formatDate(now);

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

      debugPrint('✅ Tool usage saved: $toolName in $category on $dateKey');
      return true;
    } catch (e) {
      debugPrint('❌ Error saving tool usage: $e');
      return false;
    }
  }

  /// Get all entries for a specific date
  Future<List<Map<String, dynamic>>> getEntriesForDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) return [];

      final decoded = json.decode(entriesJson);
      if (decoded is! List) return [];

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      return allEntries.where((entry) => entry['date'] == date).toList();
    } catch (e) {
      debugPrint('❌ Error getting entries for date: $e');
      return [];
    }
  }

  /// Get all entries for a specific category
  Future<List<Map<String, dynamic>>> getEntriesForCategory(String category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = prefs.getString(_storageKey);
      
      if (entriesJson == null) return [];

      final decoded = json.decode(entriesJson);
      if (decoded is! List) return [];

      final allEntries = List<Map<String, dynamic>>.from(
        decoded.map((e) => Map<String, dynamic>.from(e))
      );

      return allEntries
          .where((entry) => entry['category'] == category)
          .toList()
        ..sort((a, b) {
          final dateA = a['timestamp'] as String;
          final dateB = b['timestamp'] as String;
          return dateB.compareTo(dateA); // Most recent first
        });
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
      final entries = await getEntriesForCategory(category);
      return entries.where((entry) => entry['date'] == date).toList();
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
      final today = _formatDate(DateTime.now());
      final entries = await getEntriesForCategoryAndDate(category, today);
      
      // For Plan my future, normalize tool names to count by category, not by theme
      // All Annual goals templates count as 1, Weekly as 1, Monthly as 1, Daily as 1
      if (category == categoryPlanFuture) {
        final normalizedTools = entries.map((e) {
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
      final uniqueTools = entries
          .map((e) => e['toolName'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
      
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

