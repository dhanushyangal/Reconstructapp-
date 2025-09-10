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
  }) async {
    try {
      final notesDataJson = json.encode(notesData);
      await _channel.invokeMethod('updateNotesWidget', {
        'notesData': notesDataJson,
        'selectedNoteId': selectedNoteId,
      });
      print('Notes widget updated successfully with ${notesData.length} notes');
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
  }) async {
    await updateNotesWidget(notesData: notesData, selectedNoteId: selectedNoteId);
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
}

