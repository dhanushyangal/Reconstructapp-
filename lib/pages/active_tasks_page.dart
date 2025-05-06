import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../pages/vision_board_page.dart';
import '../pages/box_them_vision_board.dart';
import '../pages/premium_them_vision_board.dart';
import '../pages/post_it_theme_vision_board.dart';
import '../pages/winter_warmth_theme_vision_board.dart';
import '../pages/ruby_reds_theme_vision_board.dart';
import '../pages/coffee_hues_theme_vision_board.dart';
import '../Annual_calender/annual_calendar_page.dart';
import '../Annual_calender/animal_theme_annual_planner.dart' as animal_calendar;
import '../Annual_calender/summer_theme_annual_planner.dart' as summer_calendar;
import '../Annual_calender/spaniel_theme_annual_planner.dart'
    as spaniel_calendar;
import '../Annual_calender/happy_couple_theme_annual_planner.dart'
    as happy_couple_calendar;
import '../Annual_planner/annual_planner_page.dart';
import '../Annual_planner/watercolor_theme_annual_planner.dart';
import '../Annual_planner/postit_theme_annual_planner.dart';
import '../Annual_planner/floral_theme_annual_planner.dart';
import '../Annual_planner/premium_theme_annual_planner.dart';
import '../weekly_planners/weekly_planner_page.dart';
import '../weekly_planners/patterns_theme_weekly_planner.dart';
import '../weekly_planners/japanese_theme_weekly_planner.dart';
import '../weekly_planners/floral_theme_weekly_planner.dart';
import '../weekly_planners/watercolor_theme_weekly_planner.dart';

class ActiveTasksPage extends StatefulWidget {
  const ActiveTasksPage({super.key});

  @override
  State<ActiveTasksPage> createState() => _ActiveTasksPageState();
}

class _ActiveTasksPageState extends State<ActiveTasksPage> {
  final AuthService _authService = AuthService();
  String? _userId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activeBoards = [];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadActiveTasks();
  }

  Future<void> _loadUserInfo() async {
    // Get Firebase user (if available)
    final firebaseUser = FirebaseAuth.instance.currentUser;
    // Get MySQL user data (if available)
    final mysqlUserData = _authService.userData;

    // Determine which user data to use
    if (mysqlUserData != null) {
      _userId = mysqlUserData['id']?.toString() ?? 'mysql_user';
    } else if (firebaseUser != null) {
      _userId = firebaseUser.uid;
    }
  }

  Future<void> _loadActiveTasks() async {
    setState(() {
      _isLoading = true;
      _activeBoards = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear cache to ensure we get fresh data - this helps prevent duplicates
      await prefs.reload();

      final allKeys = prefs.getKeys();

      // Perform checks in specific order for better categorization - same as in _performFullRefresh
      _checkVisionBoardTodos(allKeys, prefs);
      _checkAnnualCalendarEvents(allKeys, prefs);
      _checkAnnualPlannerTodos(allKeys, prefs);
      _checkWeeklyPlannerTodos(allKeys, prefs);

      // Only run dynamic detection if we haven't found enough boards - helps prevent duplicates
      if (_activeBoards.isEmpty || _activeBoards.length < 2) {
        _detectAdditionalTaskPatterns(allKeys, prefs);
      }

      // Remove any duplicate boards
      _removeAllDuplicateBoards();
    } catch (e) {
      // Handle errors silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkVisionBoardTodos(Set<String> allKeys, SharedPreferences prefs) {
    // Check Box Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'BoxThem_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Box Theme Vision Board',
        'icon': Icons.crop_square,
        'color': Colors.teal,
        'type': 'vision',
        'theme': 'box'
      });
    }

    // Check Premium Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'premium_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Premium Theme Vision Board',
        'icon': Icons.grade,
        'color': Colors.amber,
        'type': 'vision',
        'theme': 'premium'
      });
    }

    // Check PostIt Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'postit_todos_', prefs)) {
      _activeBoards.add({
        'name': 'PostIt Theme Vision Board',
        'icon': Icons.sticky_note_2,
        'color': Colors.yellow,
        'type': 'vision',
        'theme': 'postit'
      });
    }

    // Check Winter Warmth Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'winterwarmth_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Winter Warmth Theme Vision Board',
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'type': 'vision',
        'theme': 'winter'
      });
    }

    // Check Ruby Reds Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'rubyreds_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Ruby Reds Theme Vision Board',
        'icon': Icons.favorite,
        'color': Colors.red,
        'type': 'vision',
        'theme': 'ruby'
      });
    }

    // Check Coffee Hues Theme Vision Board
    if (_checkBoardHasTasks(allKeys, 'coffeehues_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Coffee Hues Theme Vision Board',
        'icon': Icons.coffee,
        'color': Colors.brown,
        'type': 'vision',
        'theme': 'coffee'
      });
    }
  }

  void _checkAnnualCalendarEvents(
      Set<String> allKeys, SharedPreferences prefs) {
    // Track which calendar themes we've already added
    final Set<String> addedCalendarThemes = {};

    // First check for direct matches - these are most reliable
    final directPatterns = [
      {
        'key': 'animal.calendar_events',
        'theme': 'animal',
        'name': 'Animal Theme',
        'color': Colors.orange
      },
      {
        'key': 'summer.calendar_events',
        'theme': 'summer',
        'name': 'Summer Theme',
        'color': Colors.orange
      },
      {
        'key': 'spaniel.calendar_events',
        'theme': 'spaniel',
        'name': 'Spaniel Theme',
        'color': Colors.brown
      },
      {
        'key': 'happy_couple.calendar_events',
        'theme': 'happy_couple',
        'name': 'Happy Couple Theme',
        'color': Colors.pink
      },
    ];

    // Process direct patterns first - highest priority
    for (var pattern in directPatterns) {
      final key = pattern['key'] as String;
      final theme = pattern['theme'] as String;

      if (allKeys.contains(key) && !addedCalendarThemes.contains(theme)) {
        if (_checkCalendarHasEvents(allKeys, key, prefs)) {
          _activeBoards.add({
            'name': '${pattern['name']} 2025 Calendar',
            'icon': Icons.calendar_today,
            'color': pattern['color'] as Color,
            'type': 'calendar',
            'theme': theme,
            'key': key
          });
          addedCalendarThemes.add(theme);
        }
      }
    }

    // Check for additional calendar files only if we haven't found the themes yet
    final directFilenamePatterns = [
      {
        'pattern': 'animal_theme_annual_calendar',
        'theme': 'animal',
        'name': 'Animal Theme'
      },
      {
        'pattern': 'summer_theme_annual_calendar',
        'theme': 'summer',
        'name': 'Summer Theme'
      },
      {
        'pattern': 'spaniel_theme_annual_calendar',
        'theme': 'spaniel',
        'name': 'Spaniel Theme'
      },
      {
        'pattern': 'happy_couple_theme_annual_calendar',
        'theme': 'happy_couple',
        'name': 'Happy Couple Theme'
      },
    ];

    // Process filename patterns only if not already added
    for (var pattern in directFilenamePatterns) {
      if (addedCalendarThemes.contains(pattern['theme'])) continue;

      final matchingKeys = allKeys
          .where((key) =>
              key.toLowerCase().contains(pattern['pattern']!.toLowerCase()))
          .toList();

      if (matchingKeys.isNotEmpty) {
        for (var key in matchingKeys) {
          final data = prefs.getString(key);
          if (data != null && data.isNotEmpty) {
            final themeName = pattern['name'] as String;
            final theme = pattern['theme'] as String;

            _activeBoards.add({
              'name': '$themeName 2025 Calendar',
              'icon': Icons.calendar_today,
              'color': _getCalendarColor(theme),
              'type': 'calendar',
              'theme': theme,
              'key': key
            });

            addedCalendarThemes.add(theme);
            break; // Only add one card per theme
          }
        }
      }
    }

    // Also check for month pattern keys, but only for themes we haven't added yet
    if (addedCalendarThemes.length < 4) {
      // Only if we haven't found all themes
      _checkAdditionalCalendarFormats(allKeys, prefs, addedCalendarThemes);
    }
  }

  bool _checkCalendarHasEvents(
      Set<String> allKeys, String key, SharedPreferences prefs) {
    if (!allKeys.contains(key)) {
      return false;
    }

    final eventsJson = prefs.getString(key);
    if (eventsJson != null && eventsJson.isNotEmpty) {
      try {
        final eventsMap = jsonDecode(eventsJson);
        if (eventsMap is Map) {
          // Always return true if the map has any entries
          return eventsMap.isNotEmpty;
        } else if (eventsMap is List) {
          // Always return true if the list has any entries
          return eventsMap.isNotEmpty;
        }
      } catch (e) {
        // Error parsing JSON, but still return true if there's content
        return eventsJson.length > 20;
      }
    }

    return false;
  }

  void _checkAdditionalCalendarFormats(
      Set<String> allKeys, SharedPreferences prefs, Set<String> addedThemes) {
    // Check for alternative storage formats for calendar events
    final calendarPatterns = [
      '.calendar_',
      'calendar.',
      'calendar_',
      'annual_calendar',
      'events_2025',
      'calendar_events',
      '2025_events'
    ];

    // Check for month-specific patterns
    final months = [
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december'
    ];

    // First, check for pattern-based keys
    for (var pattern in calendarPatterns) {
      final matchingKeys = allKeys.where((key) =>
          key.contains(pattern) &&
          !key.startsWith('animal.') &&
          !key.startsWith('summer.') &&
          !key.startsWith('spaniel.') &&
          !key.startsWith('happy_couple.'));

      for (var key in matchingKeys) {
        // Skip keys that are already part of planners
        if (key.contains('_todos_')) {
          continue;
        }

        _tryAddCalendarBoard(key, prefs, addedThemes);
      }
    }

    // Then check for month-based keys
    for (var month in months) {
      final monthKeys = allKeys.where((key) =>
          key.toLowerCase().contains(month) &&
          (key.contains('event') || key.contains('calendar')) &&
          // Skip keys that are already part of planners
          !key.contains('_todos_'));

      for (var key in monthKeys) {
        _tryAddCalendarBoard(key, prefs, addedThemes);
      }
    }
  }

  void _tryAddCalendarBoard(
      String key, SharedPreferences prefs, Set<String> addedThemes) {
    final data = prefs.getString(key);
    if (data == null || data.isEmpty) return;

    try {
      final parsed = jsonDecode(data);
      if ((parsed is Map && parsed.isNotEmpty) ||
          (parsed is List && parsed.isNotEmpty)) {
        // Generate theme based on key
        String theme = _extractCalendarTheme(key);

        // Skip if we've already added this theme
        if (addedThemes.contains(theme)) return;

        // Generate name based on key
        String themeName = _extractCalendarThemeName(key);

        _activeBoards.add({
          'name': '$themeName 2025 Calendar',
          'icon': Icons.calendar_today,
          'color': _getCalendarColor(theme),
          'type': 'calendar',
          'theme': theme,
          'key': key
        });

        // Mark this theme as added
        addedThemes.add(theme);
      }
    } catch (e) {
      // Not valid JSON or empty data
      if (data.length > 20) {
        // Still might be content, add it as a board
        String theme = _extractCalendarTheme(key);

        // Skip if we've already added this theme
        if (addedThemes.contains(theme)) return;

        String themeName = _extractCalendarThemeName(key);

        _activeBoards.add({
          'name': '$themeName 2025 Calendar',
          'icon': Icons.calendar_today,
          'color': _getCalendarColor(key),
          'type': 'calendar',
          'theme': theme,
          'key': key
        });

        // Mark this theme as added
        addedThemes.add(theme);
      }
    }
  }

  String _extractCalendarThemeName(String key) {
    String themeName = "Calendar";

    if (key.contains('animal')) {
      themeName = "Animal Theme";
    } else if (key.contains('summer')) {
      themeName = "Summer Theme";
    } else if (key.contains('spaniel')) {
      themeName = "Spaniel Theme";
    } else if (key.contains('happy') || key.contains('couple')) {
      themeName = "Happy Couple Theme";
    } else {
      // Extract a name from the key
      String name = key.split('.').first.split('_').first;

      // Capitalize first letter of each word
      name = name.replaceAllMapped(RegExp(r'[_\.]'), (match) => ' ');
      name = name.split(' ').map((word) {
        if (word.isNotEmpty) {
          return '${word[0].toUpperCase()}${word.substring(1)}';
        }
        return '';
      }).join(' ');

      themeName = name;
    }

    return themeName;
  }

  String _extractCalendarTheme(String key) {
    if (key.contains('animal')) return 'animal';
    if (key.contains('summer')) return 'summer';
    if (key.contains('spaniel')) return 'spaniel';
    if (key.contains('happy') || key.contains('couple')) return 'happy_couple';

    return key.split('.').first.split('_').first;
  }

  Color _getCalendarColor(String key) {
    if (key.contains('animal')) return Colors.orange;
    if (key.contains('summer')) return Colors.yellow.shade800;
    if (key.contains('spaniel')) return Colors.brown;
    if (key.contains('happy') || key.contains('couple')) return Colors.pink;

    // Generate a consistent color based on the key
    final int hash = key.hashCode;
    final int hue = hash % 360;

    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  void _checkAnnualPlannerTodos(Set<String> allKeys, SharedPreferences prefs) {
    // Check Watercolor Theme Annual Planner
    if (_checkBoardHasTasks(allKeys, 'WatercolorTheme_todos_', prefs,
        excludeKeys: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ],
        requiredKeys: [
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
        ])) {
      _activeBoards.add({
        'name': 'Watercolor Theme Annual Planner',
        'icon': Icons.brush,
        'color': Colors.purple,
        'type': 'annual',
        'theme': 'watercolor'
      });
    }

    // Check PostIt Theme Annual Planner
    if (_checkBoardHasTasks(allKeys, 'PostItTheme_todos_', prefs, excludeKeys: [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ], requiredKeys: [
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
    ])) {
      _activeBoards.add({
        'name': 'PostIt Theme Annual Planner',
        'icon': Icons.sticky_note_2,
        'color': Colors.yellow,
        'type': 'annual',
        'theme': 'postit'
      });
    }

    // Check Floral Theme Annual Planner
    if (_checkBoardHasTasks(allKeys, 'FloralTheme_todos_', prefs, excludeKeys: [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ], requiredKeys: [
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
    ])) {
      _activeBoards.add({
        'name': 'Floral Theme Annual Planner',
        'icon': Icons.local_florist,
        'color': Colors.green,
        'type': 'annual',
        'theme': 'floral'
      });
    }

    // Check Premium Theme Annual Planner
    if (_checkBoardHasTasks(allKeys, 'PremiumTheme_todos_', prefs,
        excludeKeys: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ],
        requiredKeys: [
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
        ])) {
      _activeBoards.add({
        'name': 'Premium Theme Annual Planner',
        'icon': Icons.grade,
        'color': Colors.amber,
        'type': 'annual',
        'theme': 'premium'
      });
    }
  }

  void _checkWeeklyPlannerTodos(Set<String> allKeys, SharedPreferences prefs) {
    // Check Patterns Theme Weekly Planner
    if (_checkBoardHasTasks(allKeys, 'PatternsTheme_todos_', prefs,
        excludeKeys: [
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
        ],
        requiredKeys: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ])) {
      _activeBoards.add({
        'name': 'Patterns Theme Weekly Planner',
        'icon': Icons.dashboard,
        'color': Colors.indigo,
        'type': 'weekly',
        'theme': 'patterns'
      });
    }

    // Check Japanese Theme Weekly Planner
    if (_checkBoardHasTasks(allKeys, 'JapaneseTheme_todos_', prefs,
        excludeKeys: [
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
        ],
        requiredKeys: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ])) {
      _activeBoards.add({
        'name': 'Japanese Theme Weekly Planner',
        'icon': Icons.center_focus_strong,
        'color': Colors.redAccent,
        'type': 'weekly',
        'theme': 'japanese'
      });
    }

    // Check Floral Theme Weekly Planner
    if (_checkBoardHasTasks(allKeys, 'FloralTheme_todos_', prefs, excludeKeys: [
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
    ], requiredKeys: [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ])) {
      _activeBoards.add({
        'name': 'Floral Theme Weekly Planner',
        'icon': Icons.local_florist,
        'color': Colors.green,
        'type': 'weekly',
        'theme': 'floral'
      });
    }

    // Check Watercolor Theme Weekly Planner
    if (_checkBoardHasTasks(allKeys, 'WatercolorTheme_todos_', prefs,
        excludeKeys: [
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
        ],
        requiredKeys: [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ])) {
      _activeBoards.add({
        'name': 'Watercolor Theme Weekly Planner',
        'icon': Icons.brush,
        'color': Colors.purple,
        'type': 'weekly',
        'theme': 'watercolor'
      });
    }
  }

  bool _checkBoardHasTasks(
      Set<String> allKeys, String prefix, SharedPreferences prefs,
      {List<String>? excludeKeys, List<String>? requiredKeys}) {
    final taskKeys = allKeys.where((key) => key.startsWith(prefix));

    // If no keys found, return false early
    if (taskKeys.isEmpty) {
      return false;
    }

    // If required keys are specified, check that at least one exists
    if (requiredKeys != null && requiredKeys.isNotEmpty) {
      bool hasRequiredKey = false;
      for (var requiredKey in requiredKeys) {
        if (taskKeys.any((key) => key.contains(requiredKey))) {
          hasRequiredKey = true;
          break;
        }
      }
      if (!hasRequiredKey) {
        return false; // None of the required keys found
      }
    }

    // If exclude keys are specified, filter them out
    Set<String> filteredKeys = taskKeys.toSet();
    if (excludeKeys != null && excludeKeys.isNotEmpty) {
      filteredKeys = filteredKeys
          .where((key) =>
              !excludeKeys.any((excludeKey) => key.contains(excludeKey)))
          .toSet();

      // If all keys were excluded, return false
      if (filteredKeys.isEmpty) {
        return false;
      }
    }

    // Check the remaining keys for tasks
    for (var key in filteredKeys) {
      final tasksJson = prefs.getString(key);
      if (tasksJson != null && tasksJson.isNotEmpty) {
        try {
          final dynamic parsedData = jsonDecode(tasksJson);

          // Handle different task formats
          if (parsedData is List) {
            // List format (most common)
            final tasks = parsedData;

            // Multiple ways tasks might be represented
            bool hasActiveTasks = false;

            // Case 1: Standard format with 'completed' field
            final hasIncompleteTasks = tasks.any((task) =>
                task is Map &&
                task.containsKey('completed') &&
                task['completed'] == false);

            // Case 2: Tasks without 'completed' field (assume active)
            final hasTasksWithoutCompletedField = tasks.any((task) =>
                task is Map &&
                !task.containsKey('completed') &&
                (task.containsKey('text') ||
                    task.containsKey('content') ||
                    task.containsKey('title')));

            // Case 3: Tasks with 'done' field instead
            final hasTasksWithDoneField = tasks.any((task) =>
                task is Map &&
                task.containsKey('done') &&
                task['done'] == false);

            // Case 4: Simple string list (assume all active)
            final hasStringTasks =
                tasks.any((task) => task is String && task.isNotEmpty);

            hasActiveTasks = hasIncompleteTasks ||
                hasTasksWithoutCompletedField ||
                hasTasksWithDoneField ||
                hasStringTasks;

            if (hasActiveTasks) {
              return true;
            }
          } else if (parsedData is Map) {
            // Map format - check for nested tasks

            // Case 1: Map of tasks with IDs as keys
            bool hasActiveTasks = false;

            // Loop through all entries in the map
            parsedData.forEach((taskId, taskData) {
              if (taskData is Map) {
                // Check for common task status fields
                if (taskData.containsKey('completed') &&
                    taskData['completed'] == false) {
                  hasActiveTasks = true;
                } else if (taskData.containsKey('done') &&
                    taskData['done'] == false) {
                  hasActiveTasks = true;
                } else if ((taskData.containsKey('text') ||
                        taskData.containsKey('content')) &&
                    !taskData.containsKey('completed') &&
                    !taskData.containsKey('done')) {
                  // If it has content but no status field, assume active
                  hasActiveTasks = true;
                }
              } else if (taskData is String && taskData.isNotEmpty) {
                // Simple string values could be tasks too
                hasActiveTasks = true;
              }
            });

            if (hasActiveTasks) {
              return true;
            }

            // Case 2: Check for nested categories containing tasks
            for (var categoryKey in parsedData.keys) {
              final categoryData = parsedData[categoryKey];
              if (categoryData is Map && categoryData.containsKey('tasks')) {
                final categoryTasks = categoryData['tasks'];
                if (categoryTasks is List && categoryTasks.isNotEmpty) {
                  return true;
                }
              } else if (categoryData is List) {
                // The category might directly contain a list of tasks
                return true;
              }
            }
          }
        } catch (e) {
          // Error parsing JSON, continue to next key
        }
      }
    }

    return false;
  }

  void _detectAdditionalTaskPatterns(
      Set<String> allKeys, SharedPreferences prefs) {
    // Expanded pattern search - look for any key that might contain tasks
    final List<String> potentialTaskKeys = allKeys
        .where((key) =>
            // Check for common task-related words in the key
            (key.contains('todo') ||
                key.contains('task') ||
                key.contains('item') ||
                key.contains('event') ||
                key.contains('note')) &&
            !_isKeyAlreadyChecked(key))
        .toList();

    // Process each potential task key
    for (String key in potentialTaskKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        try {
          final jsonData = jsonDecode(value);
          bool hasActiveTasks = false;

          if (jsonData is List && jsonData.isNotEmpty) {
            // Check if this looks like a task list
            if (jsonData[0] is Map) {
              // Check for common task fields
              final Map firstItem = jsonData[0];

              // Check for tasks with 'completed' field
              if (firstItem.containsKey('completed')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('completed') &&
                    item['completed'] == false);
              }
              // Check for tasks with 'done' field
              else if (firstItem.containsKey('done')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('done') &&
                    item['done'] == false);
              }
              // Check for tasks with 'finished' field
              else if (firstItem.containsKey('finished')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('finished') &&
                    item['finished'] == false);
              }
              // If there's a 'text' or 'content' field, assume it's a task
              else if (firstItem.containsKey('text') ||
                  firstItem.containsKey('content') ||
                  firstItem.containsKey('title') ||
                  firstItem.containsKey('description')) {
                hasActiveTasks = true;
              }
            }
          } else if (jsonData is Map && jsonData.isNotEmpty) {
            // For map-style storage, consider it has active tasks if it's not empty
            hasActiveTasks = true;
          }

          if (hasActiveTasks) {
            _addDynamicBoard(_extractPrefix(key), key);
          }
        } catch (e) {
          // Not valid JSON or other error
        }
      }
    }
  }

  bool _isKeyAlreadyChecked(String key) {
    // List of prefixes we've already explicitly checked
    final List<String> checkedPrefixes = [
      'BoxThem_todos_',
      'premium_todos_',
      'postit_todos_',
      'winterwarmth_todos_',
      'rubyreds_todos_',
      'coffeehues_todos_',
      'WatercolorTheme_todos_',
      'PostItTheme_todos_',
      'FloralTheme_todos_',
      'PremiumTheme_todos_',
      'PatternsTheme_todos_',
      'JapaneseTheme_todos_',
    ];

    // Check if this key uses a prefix we've already handled
    for (String prefix in checkedPrefixes) {
      if (key.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  String _extractPrefix(String key) {
    // Extract a meaningful prefix from the key
    final parts = key.split('_');
    if (parts.length >= 2) {
      // Try to extract theme name
      if (parts[0].toLowerCase().contains('theme')) {
        return parts[0];
      } else if (parts.length >= 3 &&
          parts[1].toLowerCase().contains('theme')) {
        return '${parts[0]}_${parts[1]}';
      } else {
        return parts[0];
      }
    }

    return key.split('.').first; // Fallback to get part before first period
  }

  void _addDynamicBoard(String prefix, String key, {bool isEvent = false}) {
    // Format the name based on the prefix
    final String formattedName = _formatBoardName(prefix);

    // Determine board type
    String boardType = 'other';

    // Check the key pattern to guess the board type
    if (isEvent || key.contains('calendar') || key.contains('events')) {
      boardType = 'calendar';
    } else if (key.contains('annual') || key.contains('month')) {
      boardType = 'annual';
    } else if (key.contains('weekly') ||
        key.contains('week') ||
        key.contains('day')) {
      boardType = 'weekly';
    } else if (key.contains('vision') || key.contains('board')) {
      boardType = 'vision';
    }

    // Check if we already have this board
    final bool boardExists = _activeBoards.any((board) =>
        board['name'] == formattedName && board['type'] == boardType);

    if (!boardExists) {
      _activeBoards.add({
        'name': formattedName,
        'icon': _getBoardIcon(boardType),
        'color': _getBoardColor(prefix),
        'type': boardType,
        'theme': prefix.toLowerCase(),
        'key': key
      });
    }
  }

  String _formatBoardName(String prefix) {
    // Convert snake_case or camelCase to Title Case
    final String withSpaces = prefix
        .replaceAllMapped(
            RegExp(r'([A-Z])'),
            (match) =>
                ' ${match.group(0)}') // Add spaces before uppercase letters
        .replaceAll('_', ' ') // Replace underscores with spaces
        .trim();

    // Capitalize each word
    final formatted = withSpaces
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');

    // Add board type if not present
    if (!formatted.toLowerCase().contains('board') &&
        !formatted.toLowerCase().contains('planner') &&
        !formatted.toLowerCase().contains('calendar')) {
      if (formatted.toLowerCase().contains('theme')) {
        return '$formatted Board';
      } else {
        return '$formatted Theme Board';
      }
    }

    return formatted;
  }

  IconData _getBoardIcon(String boardType) {
    switch (boardType) {
      case 'vision':
        return Icons.dashboard;
      case 'calendar':
        return Icons.calendar_today;
      case 'annual':
        return Icons.view_timeline;
      case 'weekly':
        return Icons.view_week;
      default:
        return Icons.folder;
    }
  }

  Color _getBoardColor(String prefix) {
    // Generate a consistent color based on the prefix
    final int hash = prefix.hashCode;
    final int hue = hash % 360;

    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  void _navigateToBoard(Map<String, dynamic> board) {
    Widget? destinationPage;

    switch (board['type']) {
      case 'vision':
        switch (board['theme']) {
          case 'box':
            destinationPage = VisionBoardDetailsPage(title: 'Box Vision Board');
            break;
          case 'premium':
            destinationPage = const PremiumThemeVisionBoard();
            break;
          case 'postit':
            destinationPage = const PostItThemeVisionBoard();
            break;
          case 'winter':
            destinationPage = const WinterWarmthThemeVisionBoard();
            break;
          case 'ruby':
            destinationPage = const RubyRedsThemeVisionBoard();
            break;
          case 'coffee':
            destinationPage = const CoffeeHuesThemeVisionBoard();
            break;
          default:
            // For dynamically discovered vision boards, navigate to the main page
            destinationPage = const VisionBoardPage();
        }
        break;

      case 'calendar':
        // Fix calendar navigation - always pass monthIndex: 0 and null eventId
        final int monthIndex = 0;
        final String? eventId = null;

        switch (board['theme']) {
          case 'animal':
            destinationPage = animal_calendar.AnimalThemeCalendarApp(
              monthIndex: monthIndex,
              eventId: eventId,
            );
            break;
          case 'summer':
            destinationPage = summer_calendar.SummerThemeCalendarApp(
              monthIndex: monthIndex,
              eventId: eventId,
            );
            break;
          case 'spaniel':
            destinationPage = spaniel_calendar.SpanielThemeCalendarApp(
              monthIndex: monthIndex,
              eventId: eventId,
            );
            break;
          case 'happy_couple':
            destinationPage = happy_couple_calendar.HappyCoupleThemeCalendarApp(
              monthIndex: monthIndex,
              eventId: eventId,
            );
            break;
          default:
            // For dynamically discovered calendars, navigate to the calendar page
            destinationPage = const AnnualCalenderPage();
        }
        break;

      case 'annual':
        // Navigate to the specific annual planner theme page
        switch (board['theme']) {
          case 'watercolor':
            destinationPage = WatercolorThemeAnnualPlanner(
              monthIndex: 0,
              eventId: null,
            );
            break;
          case 'postit':
            destinationPage = PostItThemeAnnualPlanner(
              monthIndex: 0,
              eventId: null,
            );
            break;
          case 'floral':
            destinationPage = FloralThemeAnnualPlanner(
              monthIndex: 0,
              eventId: null,
            );
            break;
          case 'premium':
            destinationPage = PremiumThemeAnnualPlanner(
              monthIndex: 0,
              eventId: null,
            );
            break;
          default:
            // For dynamically discovered annual planners
            destinationPage = const AnnualPlannerPage();
        }
        break;

      case 'weekly':
        // Navigate to the specific weekly planner theme page
        switch (board['theme']) {
          case 'patterns':
            destinationPage = PatternsThemeWeeklyPlanner(
              dayIndex: 0,
              eventId: null,
            );
            break;
          case 'japanese':
            destinationPage = JapaneseThemeWeeklyPlanner(
              dayIndex: 0,
              eventId: null,
            );
            break;
          case 'floral':
            destinationPage = FloralThemeWeeklyPlanner(
              dayIndex: 0,
              eventId: null,
            );
            break;
          case 'watercolor':
            destinationPage = WatercolorThemeWeeklyPlanner(
              dayIndex: 0,
              eventId: null,
            );
            break;
          default:
            // For dynamically discovered weekly planners
            destinationPage = const WeeklyPlannerPage();
        }
        break;

      default:
        // For unknown types, show an info dialog and then navigate to the appropriate page
        _showDynamicBoardInfoDialog(board).then((_) {
          // After showing info, navigate to the most appropriate main page
          if (board['type'] == 'vision' ||
              board['name'].toLowerCase().contains('vision')) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VisionBoardPage()),
            ).then((_) => _loadActiveTasks());
          } else if (board['type'] == 'calendar' ||
              board['name'].toLowerCase().contains('calendar')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AnnualCalenderPage()),
            ).then((_) => _loadActiveTasks());
          } else if (board['type'] == 'annual' ||
              board['name'].toLowerCase().contains('annual')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AnnualPlannerPage()),
            ).then((_) => _loadActiveTasks());
          } else if (board['type'] == 'weekly' ||
              board['name'].toLowerCase().contains('weekly')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const WeeklyPlannerPage()),
            ).then((_) => _loadActiveTasks());
          }
        });
        return; // Exit early since we're handling navigation in the callback
    }

    // If we have a valid destination page, navigate to it
    if (destinationPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destinationPage!),
      ).then((_) {
        // Refresh the list when returning from the board
        _loadActiveTasks();
      });
    } else {
      // If we couldn't determine a specific page, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Could not open this board directly. Please navigate from the main menu.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showDynamicBoardInfoDialog(Map<String, dynamic> board) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(board['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${board['type']}'),
              const SizedBox(height: 8),
              Text('Theme: ${board['theme']}'),
              const SizedBox(height: 16),
              if (board.containsKey('key'))
                Text('Storage Key: ${board['key']}'),
              const SizedBox(height: 16),
              const Text(
                'This board was dynamically discovered based on your tasks. '
                'You\'ll be redirected to the appropriate section.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Active Boards'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ))
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _performFullRefresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your active boards...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _activeBoards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No active tasks found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create tasks in your planners and they will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VisionBoardPage(),
                                ),
                              ).then((_) => _loadActiveTasks());
                            },
                            child: const Text('Go to Vision Boards'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: _forceDeepScan,
                            icon: const Icon(Icons.search),
                            label: const Text('Force Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _performFullRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vision Boards Section
                          _buildSectionWithBoards(
                            context,
                            'Vision Boards',
                            'assets/vision-board-plain.jpg',
                            _activeBoards
                                .where((board) => board['type'] == 'vision')
                                .toList(),
                            Icons.dashboard,
                            Colors.purple.shade700,
                          ),

                          // Calendar Section
                          _buildSectionWithBoards(
                            context,
                            'Annual Calendars',
                            'assets/calendar.jpg',
                            _activeBoards
                                .where((board) => board['type'] == 'calendar')
                                .toList(),
                            Icons.calendar_today,
                            Colors.blue.shade700,
                          ),

                          // Annual Planner Section
                          _buildSectionWithBoards(
                            context,
                            'Annual Planners',
                            'assets/watercolor_theme_annual_planner.png',
                            _activeBoards
                                .where((board) => board['type'] == 'annual')
                                .toList(),
                            Icons.view_timeline,
                            Colors.teal.shade700,
                          ),

                          // Weekly Planner Section
                          _buildSectionWithBoards(
                            context,
                            'Weekly Planners',
                            'assets/weakly_planer.png',
                            _activeBoards
                                .where((board) => board['type'] == 'weekly')
                                .toList(),
                            Icons.view_week,
                            Colors.amber.shade700,
                          ),

                          // Other Boards Section
                          _buildSectionWithBoards(
                            context,
                            'Other Boards',
                            null,
                            _activeBoards
                                .where((board) =>
                                    board['type'] != 'vision' &&
                                    board['type'] != 'calendar' &&
                                    board['type'] != 'annual' &&
                                    board['type'] != 'weekly')
                                .toList(),
                            Icons.folder,
                            Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  // Enhanced refresh function that performs a complete reload
  Future<void> _performFullRefresh() async {
    setState(() {
      _isLoading = true;
    });

    // Clear existing boards before reloading
    _activeBoards.clear();

    try {
      // Wait a moment to ensure UI shows loading state
      await Future.delayed(const Duration(milliseconds: 300));

      // Get fresh SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // Clear cache to ensure we get fresh data
      await prefs.reload();

      final allKeys = prefs.getKeys();

      // Check each task type - be more aggressive with clearing caches
      _activeBoards = []; // Ensure we start with a clean list

      // Perform checks in a specific order for better categorization
      _checkVisionBoardTodos(allKeys, prefs);
      _checkAnnualCalendarEvents(allKeys, prefs);
      _checkAnnualPlannerTodos(allKeys, prefs);
      _checkWeeklyPlannerTodos(allKeys, prefs);

      // Only run dynamic detection if we haven't found enough boards
      if (_activeBoards.isEmpty || _activeBoards.length < 2) {
        _detectAdditionalTaskPatterns(allKeys, prefs);
      }

      // If no boards found, try deeper scan
      if (_activeBoards.isEmpty) {
        await _forceDeepScan(showNotification: false);
      }

      // Remove any duplicate boards that might have been added
      _removeAllDuplicateBoards();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${_activeBoards.length} active boards'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated deep scan function
  Future<void> _forceDeepScan({bool showNotification = true}) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    // Force reload of shared preferences
    await prefs.reload();

    final allKeys = prefs.getKeys();

    // Reset the active boards
    _activeBoards = [];

    // Try to find any content in SharedPreferences
    for (var key in allKeys) {
      if (key == 'hasSeenOnboarding' ||
          key.startsWith('flutter.') ||
          key.isEmpty) {
        continue; // Skip certain system keys
      }

      var value = prefs.get(key);
      if (value == null) continue;

      if (value is String && value.isNotEmpty) {
        // Try to parse as JSON first
        try {
          final data = jsonDecode(value);

          if (data is List && data.isNotEmpty) {
            // It's a list - assume it could be tasks
            _addDynamicBoard(key.split('_').first, key);
          } else if (data is Map && data.isNotEmpty) {
            // It's a map - assume it could be an event or settings
            _addDynamicBoard(key.split('.').first, key, isEvent: true);
          }
        } catch (e) {
          // Not JSON, but still might be relevant
          if (value.length > 10) {
            // Only consider non-trivial strings
            _addDynamicBoard(key, key);
          }
        }
      } else if (value is bool || value is int || value is double) {
        // Skip simple primitive values
        continue;
      }
    }

    // Special check for calendar entries
    _scanForCalendarEntries(allKeys, prefs);

    // Remove duplicates
    _removeAllDuplicateBoards();

    setState(() {
      _isLoading = false;
    });

    if (showNotification) {
      if (_activeBoards.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No active boards found. Try creating a new board.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${_activeBoards.length} active boards!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Special calendar scan function to ensure we catch calendar entries
  void _scanForCalendarEntries(Set<String> allKeys, SharedPreferences prefs) {
    // Get existing calendar themes
    final Set<String> existingThemes = _activeBoards
        .where((board) => board['type'] == 'calendar')
        .map((board) => board['theme'] as String)
        .toSet();

    // Specific calendar theme keys to look for with more exact matching
    final calendarThemes = [
      {'key': 'animal', 'name': 'Animal Theme', 'color': Colors.orange},
      {
        'key': 'summer',
        'name': 'Summer Theme',
        'color': Colors.orange.shade300
      },
      {'key': 'spaniel', 'name': 'Spaniel Theme', 'color': Colors.brown},
      {
        'key': 'happy_couple',
        'name': 'Happy Couple Theme',
        'color': Colors.pink
      },
    ];

    // First check for direct matches - these are the most reliable
    final directPatterns = [
      'animal.calendar_events',
      'summer.calendar_events',
      'spaniel.calendar_events',
      'happy_couple.calendar_events'
    ];

    for (var pattern in directPatterns) {
      final theme = pattern.split('.')[0]; // Extract theme name
      if (existingThemes.contains(theme)) continue; // Skip if already added

      if (allKeys.contains(pattern)) {
        final eventsJson = prefs.getString(pattern);
        if (eventsJson != null && eventsJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(eventsJson);
            if ((decoded is Map && decoded.isNotEmpty) ||
                (decoded is List && decoded.isNotEmpty)) {
              // Find the matching theme data
              final themeData = calendarThemes.firstWhere(
                (t) => t['key'] == theme,
                orElse: () => {
                  'name': _capitalizeFirstLetter(theme),
                  'color': Colors.blue
                },
              );

              _activeBoards.add({
                'name': '${themeData['name']} 2025 Calendar',
                'icon': Icons.calendar_today,
                'color': themeData['color'] as Color,
                'type': 'calendar',
                'theme': theme
              });

              existingThemes.add(theme);
            }
          } catch (e) {
            // Not valid JSON - skip
          }
        }
      }
    }

    // Then look for pattern-based keys for any themes we haven't found yet
    for (var theme in calendarThemes) {
      // Skip if we already have this theme
      if (existingThemes.contains(theme['key'])) continue;

      final themeKey = theme['key'] as String;
      final themeKeys = allKeys
          .where((key) =>
              key.toLowerCase().contains(themeKey.toLowerCase()) &&
              (key.contains('calendar') || key.contains('event')))
          .toList();

      if (themeKeys.isNotEmpty) {
        // Try to find a key with actual content
        bool foundValidContent = false;

        for (var key in themeKeys) {
          final data = prefs.getString(key);
          if (data != null && data.isNotEmpty && data.length > 10) {
            try {
              final parsed = jsonDecode(data);
              if ((parsed is Map && parsed.isNotEmpty) ||
                  (parsed is List && parsed.isNotEmpty)) {
                foundValidContent = true;
                break;
              }
            } catch (e) {
              // Not JSON but still has content
              if (data.length > 20) {
                foundValidContent = true;
                break;
              }
            }
          }
        }

        if (foundValidContent) {
          final themeName = theme['name'] as String;

          _activeBoards.add({
            'name': '$themeName 2025 Calendar',
            'icon': Icons.calendar_today,
            'color': theme['color'] as Color,
            'type': 'calendar',
            'theme': themeKey
          });

          // Add to existing themes to prevent duplicates
          existingThemes.add(themeKey);
        }
      }
    }
  }

  // Helper method to capitalize first letter of a string
  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  // Remove all duplicate boards across all types
  void _removeAllDuplicateBoards() {
    // Get all board types
    final Set<String> boardTypes =
        _activeBoards.map((board) => board['type'] as String).toSet();

    // For each type, remove duplicates
    for (final type in boardTypes) {
      final boards =
          _activeBoards.where((board) => board['type'] == type).toList();

      // Skip if there's only one board of this type
      if (boards.length <= 1) continue;

      // Create a set to track themes we've seen
      final Set<String> processedThemes = {};
      final List<Map<String, dynamic>> duplicatesToRemove = [];

      for (final board in boards) {
        final theme = board['theme'];

        // If we've seen this theme before, mark it for removal
        if (processedThemes.contains(theme)) {
          duplicatesToRemove.add(board);
        } else {
          processedThemes.add(theme);
        }
      }

      // Remove duplicates
      for (final duplicate in duplicatesToRemove) {
        _activeBoards.remove(duplicate);
      }

      if (duplicatesToRemove.isNotEmpty) {
        debugPrint(
            "Removed ${duplicatesToRemove.length} duplicate ${type} entries");
      }
    }
  }

  Widget _buildSectionWithBoards(
    BuildContext context,
    String title,
    String? imagePath,
    List<Map<String, dynamic>> boards,
    IconData fallbackIcon,
    Color sectionColor,
  ) {
    if (boards.isEmpty) return const SizedBox.shrink();

    // Sort boards by name for consistent display
    boards.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simplified section header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: sectionColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                fallbackIcon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid of boards
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: boards.length,
          itemBuilder: (context, index) {
            final board = boards[index];
            return _buildBoardCard(context, board);
          },
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBoardCard(BuildContext context, Map<String, dynamic> board) {
    String? thumbImage = _getBoardThumbnail(board);

    return Card(
      elevation: 4,
      shadowColor: (board['color'] as Color?)?.withOpacity(0.3) ??
          Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToBoard(board),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Board thumbnail or icon
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Board image or color
                    thumbImage != null
                        ? Image.asset(
                            thumbImage,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            color: board['color'] as Color? ?? Colors.grey,
                            child: Center(
                              child: Icon(
                                board['icon'] as IconData? ?? Icons.dashboard,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
            // Board info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                board['name'] as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getBoardThumbnail(Map<String, dynamic> board) {
    final type = board['type'] as String;
    final theme = board['theme'] as String;

    // Vision board thumbnails
    if (type == 'vision') {
      if (theme == 'box') return 'assets/vision-board-plain.jpg';
      if (theme == 'premium') return 'assets/premium-theme.png';
      if (theme == 'postit') return 'assets/Postit-Theme-Vision-Board.png';
      if (theme == 'winter')
        return 'assets/winter-warmth-theme-vision-board.png';
      if (theme == 'ruby') return 'assets/ruby-reds-theme-vision-board.png';
      if (theme == 'coffee') return 'assets/coffee-hues-theme-vision-board.png';
    }

    // Calendar thumbnails
    if (type == 'calendar') {
      if (theme == 'animal') return 'assets/animal_theme_calendar.png';
      if (theme == 'summer') return 'assets/summer_theme_calendar.png';
      if (theme == 'spaniel') return 'assets/spaniel_theme_calendar.png';
      if (theme == 'happy_couple')
        return 'assets/happy_couple_theme_calendar.png';
    }

    // Annual planner thumbnails
    if (type == 'annual') {
      if (theme == 'watercolor')
        return 'assets/watercolor_theme_annual_planner.png';
      if (theme == 'postit') return 'assets/postit_theme_annual_planner.png';
      if (theme == 'floral') return 'assets/floral_theme_annual_planner.png';
      if (theme == 'premium') return 'assets/premium_theme_annual_planner.png';
    }

    // Weekly planner thumbnails
    if (type == 'weekly') {
      if (theme == 'patterns')
        return 'assets/patterns_theme_weekly_planner.png';
      if (theme == 'japanese')
        return 'assets/japanese_theme_weekly_planner.png';
      if (theme == 'floral') return 'assets/floral_theme_weekly_planner.png';
      if (theme == 'watercolor')
        return 'assets/watercolor_theme_weekly_planner.png';
    }

    // Default images by type if no specific theme match
    if (type == 'vision') return 'assets/vision-board-plain.jpg';
    if (type == 'calendar') return 'assets/calendar.jpg';
    if (type == 'annual') return 'assets/watercolor_theme_annual_planner.png';
    if (type == 'weekly') return 'assets/weakly_planer.png';

    // No matching image found
    return null;
  }
}
