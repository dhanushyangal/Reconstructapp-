import 'package:flutter/services.dart';

class IOSWidgetService {
  static const MethodChannel _channel = MethodChannel('ios_widget_service');

  /// Update Daily Notes widget data
  static Future<void> updateDailyNotesWidget({
    required String noteText,
    required int noteCount,
  }) async {
    try {
      await _channel.invokeMethod('updateDailyNotesWidget', {
        'noteText': noteText,
        'noteCount': noteCount,
      });
    } catch (e) {
      print('Error updating Daily Notes widget: $e');
    }
  }

  /// Update Weekly Planner widget data
  static Future<void> updateWeeklyPlannerWidget({
    required List<String> weekGoals,
    required int completedTasks,
    required int totalTasks,
  }) async {
    try {
      await _channel.invokeMethod('updateWeeklyPlannerWidget', {
        'weekGoals': weekGoals,
        'completedTasks': completedTasks,
        'totalTasks': totalTasks,
      });
    } catch (e) {
      print('Error updating Weekly Planner widget: $e');
    }
  }

  /// Update Vision Board widget data
  static Future<void> updateVisionBoardWidget({
    required List<String> goals,
    required String motivation,
  }) async {
    try {
      await _channel.invokeMethod('updateVisionBoardWidget', {
        'goals': goals,
        'motivation': motivation,
      });
    } catch (e) {
      print('Error updating Vision Board widget: $e');
    }
  }

  /// Update Calendar widget data
  static Future<void> updateCalendarWidget({
    required List<String> events,
    required String currentMonth,
    required int daysInMonth,
  }) async {
    try {
      await _channel.invokeMethod('updateCalendarWidget', {
        'events': events,
        'currentMonth': currentMonth,
        'daysInMonth': daysInMonth,
      });
    } catch (e) {
      print('Error updating Calendar widget: $e');
    }
  }

  /// Update Annual Planner widget data
  static Future<void> updateAnnualPlannerWidget({
    required List<String> yearGoals,
    required int completedMilestones,
    required int totalMilestones,
  }) async {
    try {
      await _channel.invokeMethod('updateAnnualPlannerWidget', {
        'yearGoals': yearGoals,
        'completedMilestones': completedMilestones,
        'totalMilestones': totalMilestones,
      });
    } catch (e) {
      print('Error updating Annual Planner widget: $e');
    }
  }

  /// Refresh all widgets
  static Future<void> refreshAllWidgets() async {
    try {
      await _channel.invokeMethod('refreshAllWidgets');
    } catch (e) {
      print('Error refreshing widgets: $e');
    }
  }

  /// Configure widget theme and settings
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
}

