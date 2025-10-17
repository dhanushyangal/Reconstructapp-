import 'package:flutter/services.dart';
import 'dart:convert';

class IOSWidgetService {
  static const MethodChannel _channel = MethodChannel('ios_widget_service');

  // Call once during app startup (e.g., in main.dart) to handle deep links from widgets
  static void initDeepLinkHandling() {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
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
}

