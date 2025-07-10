import 'package:flutter/material.dart';
import '../services/user_activity_service.dart';

/// Utility for determining if a page/action should be tracked and mapping names
class ActivityTrackingUtils {
  // List of allowed page names (matching website logic)
  static const Set<String> allowedPages = {
    'Vision Board',
    'Boxy Vision Board',
    'PostIt Vision Board',
    'Premium Vision Board',
    'Sport Vision Board',
    'Watercolor Vision Board',
    'Ruby Vision Board',
    'Coffee Vision Board',
    'Winter Vision Board',
    'Animal Vision Board',
    'Animal Calendar',
    'Summer Calendar',
    'Spaniel Calendar',
    'Couple Calendar',
    'Calendar',
    'PostIt Annual Planner',
    'Premium Annual Planner',
    'Floral Annual Planner',
    'Watercolor Annual Planner',
    'Annual Planner',
    'Watercolor Weekly Planner',
    'Patterns Weekly Planner',
    'Floral Weekly Planner',
    'Japanese Weekly Planner',
    'Weekly Planner',
    'Bubble Wrap Popper',
    'Break Things',
    'Box Breathing',
    'Sliding Puzzle',
    'Thought Shredder',
    'Smile Therapy',
    'Decide For Me',
    'Digital Coloring',
    'Memory Game',
    'Riddles',
    'To Do List',
    'Creative Activities',
    'Word Games',
    'Number Games',
    'Distract My Mind Journey',
    'Activity Progress',
    'Annual Calendar',
    'Happy Couple Calendar',
  };

  // Map widget/route names to analytics names
  static String mapPageName(String rawName) {
    final Map<String, String> pageNameMappings = {
      'PremiumThemeVisionBoard': 'Premium Vision Board',
      'WinterWarmthThemeVisionBoard': 'Winter Vision Board',
      'RubyRedsThemeVisionBoard': 'Ruby Vision Board',
      'PostItThemeVisionBoard': 'PostIt Vision Board',
      'CoffeeHuesThemeVisionBoard': 'Coffee Vision Board',
      'VisionBoardDetailsPage': 'Boxy Vision Board',
      'VisionBoardPage': 'Vision Board',
      'CreativeActivitiesPage': 'Creative Activities',
      'WordGames': 'Word Games',
      'NumberGames': 'Number Games',
      'DistractMyMindJourney': 'Distract My Mind Journey',
      'ActivityProgressPage': 'Activity Progress',
      'JumbleWords': 'Word Games',
      'CrosswordPuzzle': 'Word Games',
      'Game2048': 'Number Games',
      'SudokuGame': 'Number Games',
      'PrimeFinder': 'Number Games',
      'AnnualCalenderPage': 'Annual Calendar',
      'AnimalThemeCalendarApp': 'Animal Calendar',
      'SummerThemeCalendarApp': 'Summer Calendar',
      'SpanielThemeCalendarApp': 'Spaniel Calendar',
      'HappyCoupleThemeCalendarApp': 'Happy Couple Calendar',
      'WeeklyPlannerPage': 'Weekly Planner',
      'WatercolorThemeWeeklyPlanner': 'Watercolor Weekly Planner',
      'PatternsThemeWeeklyPlanner': 'Patterns Weekly Planner',
      'FloralThemeWeeklyPlanner': 'Floral Weekly Planner',
      'JapaneseThemeWeeklyPlanner': 'Japanese Weekly Planner',
      // Add more as needed
    };
    if (pageNameMappings.containsKey(rawName)) {
      return pageNameMappings[rawName]!;
    }
    // Fallback: remove common suffixes and format
    String cleanName = rawName
        .replaceAll('Page', '')
        .replaceAll('Screen', '')
        .replaceAll('Widget', '')
        .replaceAll('/', '')
        .trim();
    cleanName = cleanName.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return cleanName.trim();
  }

  // Should this page be tracked?
  static bool shouldTrackPage(String pageName) {
    return allowedPages.contains(pageName);
  }
}

/// Mixin to track only allowed actions on allowed pages
mixin ActivityTrackerMixin<T extends StatefulWidget> on State<T> {
  // Get the analytics page name for this widget
  String get analyticsPageName =>
      ActivityTrackingUtils.mapPageName(widget.runtimeType.toString());

  // Only allow explicit action tracking
  void trackUserInteraction(String actionType, {required String details}) {
    final pageName = analyticsPageName;
    if (!ActivityTrackingUtils.shouldTrackPage(pageName)) {
      debugPrint('Activity tracking skipped for page: $pageName');
      return;
    }
    // Only allow specific actions (typing, coloring, clicking, etc.)
    final allowedActions = {'typing', 'coloring', 'click', 'edit', 'tap'};
    if (!allowedActions.contains(actionType)) {
      debugPrint('Action "$actionType" not tracked for page: $pageName');
      return;
    }
    try {
      UserActivityService.instance
          .recordInteraction(
        pageName,
        actionType,
        details: details,
      )
          .then((result) {
        if (result['success']) {
          debugPrint(
              '📊 Interaction tracked: $actionType on $pageName: $details');
        } else {
          debugPrint('⚠️ Failed to track interaction: ${result['message']}');
        }
      }).catchError((error) {
        debugPrint('❌ Error tracking interaction: $error');
      });
    } catch (e) {
      debugPrint('❌ Exception tracking interaction: $e');
    }
  }

  // Helper for button taps
  void trackButtonTap(String buttonName, {String? additionalDetails}) {
    final details = additionalDetails != null
        ? '$buttonName - $additionalDetails'
        : buttonName;
    trackUserInteraction('tap', details: details);
  }

  // Helper for text input
  void trackTextInput(String fieldName, {String? value}) {
    final details = value != null && value.isNotEmpty
        ? '$fieldName (${value.length} chars)'
        : fieldName;
    trackUserInteraction('typing', details: details);
  }

  // Helper for coloring
  void trackColoring(String details) {
    trackUserInteraction('coloring', details: details);
  }

  // Helper for edit
  void trackEdit(String details) {
    trackUserInteraction('edit', details: details);
  }

  // Helper for click
  void trackClick(String details) {
    trackUserInteraction('click', details: details);
  }
}
