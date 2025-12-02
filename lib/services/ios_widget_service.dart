import 'package:flutter/services.dart';
import 'dart:convert';
import '../main.dart' show navigatorKey;

class IOSWidgetService {
  static const MethodChannel _channel = MethodChannel('ios_widget_service');
  // Optional callbacks the app can set to handle widget deep links
  static void Function()? onOpenVisionBoardTheme;
  static void Function()? onOpenVisionBoardCategorySelect;
  static void Function(String category)? onOpenVisionBoardCategory;

  // Call once during app startup (e.g., in main.dart) to handle deep links from widgets
  static void initDeepLinkHandling() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'openVisionBoardTheme':
            if (onOpenVisionBoardTheme != null) {
              onOpenVisionBoardTheme!();
            } else {
              // Fallback: navigate using navigatorKey if available
              try {
                // Import at call site: main.dart defines navigatorKey
                // ignore: avoid_dynamic_calls
                navigatorKey.currentState?.pushNamed('/visionboard/theme-picker');
              } catch (_) {}
            }
            break;
          case 'openVisionBoardCategorySelect':
            if (onOpenVisionBoardCategorySelect != null) onOpenVisionBoardCategorySelect!();
            break;
          case 'openVisionBoardCategory':
            final args = (call.arguments as Map?) ?? {};
            final category = args['category'] as String? ?? '';
            if (onOpenVisionBoardCategory != null) onOpenVisionBoardCategory!(category);
            break;
          default:
            // ignore
            break;
        }
      } catch (e) {
        // ignore
      }
    });
  }

  // Update Notes Widget with existing notes data (matches daily_notes_page.dart structure)
  static Future<void> updateNotesWidget({
    required List<Map<String, dynamic>> notesData,
    String? selectedNoteId,
    String? theme,
  }) async {
    try {
      final notesDataJson = json.encode(notesData);
      await _channel.invokeMethod('updateNotesWidget', {
        'notesData': notesDataJson,
        'selectedNoteId': selectedNoteId,
        'theme': theme,
      });
      print('Notes widget updated successfully with ${notesData.length} notes and theme: $theme');
    } catch (e) {
      print('Error updating Notes widget: $e');
    }
  }

  // Refresh All Widgets
  static Future<void> refreshAllWidgets() async {
    try {
      await _channel.invokeMethod('refreshAllWidgets');
      print('All widgets refreshed successfully');
    } catch (e) {
      print('Error refreshing widgets: $e');
    }
  }

  // Update Notes Widget with automatic refresh
  static Future<void> updateNotesWidgetWithRefresh({
    required List<Map<String, dynamic>> notesData,
    String? selectedNoteId,
    String? theme,
  }) async {
    await updateNotesWidget(notesData: notesData, selectedNoteId: selectedNoteId, theme: theme);
    await refreshAllWidgets();
  }

  // Vision Board: sync theme, categories, and todos map (JSON strings per category)
  static Future<void> updateVisionBoardWidget({
    required String theme,
    required List<String> categories,
    required Map<String, String> todosByCategoryJson,
  }) async {
    try {
      await _channel.invokeMethod('updateVisionBoardWidget', {
        'theme': theme,
        'categories': categories,
        'todosByCategoryJson': todosByCategoryJson,
      });
      await refreshAllWidgets();
    } catch (e) {
      print('Error updating Vision Board widget: $e');
    }
  }

  // Fetch current theme from native side (for category picker default)
  static Future<String?> getCurrentTheme() async {
    try {
      final theme = await _channel.invokeMethod<String>('getCurrentTheme');
      return (theme != null && theme.isNotEmpty) ? theme : null;
    } catch (_) {
      return null;
    }
  }

  // Calendar widget: push summer calendar data to iOS widget
  static Future<void> updateCalendarWidget({
    required Map<String, String> calendarData,
  }) async {
    try {
      await _channel.invokeMethod('updateCalendarWidget', {
        'calendarData': calendarData,
      });
      await refreshAllWidgets();
    } catch (e) {
      // Silent catch to avoid UI disruption if widget extension is unavailable
    }
  }

  // Weekly Planner: sync theme and todos map (JSON strings per day)
  static Future<void> updateWeeklyPlannerWidget({
    required String theme,
    required Map<String, String> todosByDayJson,
  }) async {
    try {
      await _channel.invokeMethod('updateWeeklyPlannerWidget', {
        'theme': theme,
        'todosByDayJson': todosByDayJson,
      });
      await refreshAllWidgets();
    } catch (e) {
      print('Error updating Weekly Planner widget: $e');
    }
  }

  // Annual Planner: sync theme and todos map (JSON strings per month)
  static Future<void> updateAnnualPlannerWidget({
    required String theme,
    required Map<String, String> todosByMonthJson,
  }) async {
    try {
      await _channel.invokeMethod('updateAnnualPlannerWidget', {
        'theme': theme,
        'todosByMonthJson': todosByMonthJson,
      });
      await refreshAllWidgets();
    } catch (e) {
      print('Error updating Annual Planner widget: $e');
    }
  }
}

