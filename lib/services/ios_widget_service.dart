import 'package:flutter/services.dart';

class IOSWidgetService {
  static const MethodChannel _channel = MethodChannel('ios_widget_service');

  // Update Vision Board Widget
  static Future<void> updateVisionBoardWidget({
    required String title,
    required String description,
    required List<String> goals,
  }) async {
    try {
      await _channel.invokeMethod('updateVisionBoardWidget', {
        'title': title,
        'description': description,
        'goals': goals,
      });
    } catch (e) {
      print('Error updating Vision Board widget: $e');
    }
  }

  // Configure Widget
  static Future<void> configureWidget({
    required String widgetId,
    required String theme,
    required String widgetType,
  }) async {
    try {
      await _channel.invokeMethod('configureWidget', {
        'widgetId': widgetId,
        'theme': theme,
        'widgetType': widgetType,
      });
    } catch (e) {
      print('Error configuring widget: $e');
    }
  }

  // Refresh All Widgets
  static Future<void> refreshAllWidgets() async {
    try {
      await _channel.invokeMethod('refreshAllWidgets');
    } catch (e) {
      print('Error refreshing widgets: $e');
    }
  }
}

