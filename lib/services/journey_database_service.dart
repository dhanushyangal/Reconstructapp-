import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'dart:convert';
import 'user_service.dart';
import 'calendar_database_service.dart';

class JourneyDatabaseService {
  static final JourneyDatabaseService instance =
      JourneyDatabaseService._internal();

  late final supabase.SupabaseClient _client;
  late final CalendarDatabaseService _calendarService;

  JourneyDatabaseService._internal() {
    _client = SupabaseConfig.client;
    _calendarService = CalendarDatabaseService();
  }

  // Method to save travel journey data to database
  Future<Map<String, dynamic>> saveTravelJourney({
    required List<String> selectedLocations,
    required List<String> selectedMonths,
    required Map<String, List<dynamic>> completedTasksByCity,
    required Map<int, Map<int, DateTime>> weekDatesByCity,
  }) async {
    try {
      debugPrint('Starting travel journey save to database...');

      // Get user info
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userName = userInfo['userName']!;
      final email = userInfo['email']!;

      // Set user info in services
      _calendarService.setUserInfo(userName, email);

      // 1. Save to Vision Board
      await _saveToVisionBoard(
        userName: userName,
        email: email,
        category: 'Travel',
        tasks:
            _generateTravelVisionBoardTasks(selectedLocations, selectedMonths),
      );

      // 2. Save to Calendar
      await _saveToCalendar(
        userName: userName,
        email: email,
        events: _generateTravelCalendarEvents(selectedLocations, selectedMonths,
            completedTasksByCity, weekDatesByCity),
      );

      // 3. Save to Annual Calendar
      await _saveToAnnualCalendar(
        userName: userName,
        email: email,
        journeyType: 'Travel',
        data: {
          'selectedLocations': selectedLocations,
          'selectedMonths': selectedMonths,
          'completedTasksByCity': completedTasksByCity,
          'weekDatesByCity': weekDatesByCity,
        },
      );

      return {'success': true, 'message': 'Travel journey saved successfully'};
    } catch (e) {
      debugPrint('Error saving travel journey: $e');
      return {'success': false, 'message': 'Failed to save travel journey: $e'};
    }
  }

  // Method to save self-care journey data to database
  Future<Map<String, dynamic>> saveSelfCareJourney({
    required String selectedHabit,
    required String selectedMonth,
    required Map<String, List<dynamic>> selectedTasksByHabit,
    required Map<int, DateTime> weekDates,
  }) async {
    try {
      debugPrint('Starting self-care journey save to database...');

      // Get user info
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userName = userInfo['userName']!;
      final email = userInfo['email']!;

      // Set user info in services
      _calendarService.setUserInfo(userName, email);

      // 1. Save to Vision Board
      await _saveToVisionBoard(
        userName: userName,
        email: email,
        category: 'Self Care',
        tasks: _generateSelfCareVisionBoardTasks(
            selectedHabit, selectedMonth, selectedTasksByHabit),
      );

      // 2. Save to Calendar
      await _saveToCalendar(
        userName: userName,
        email: email,
        events: _generateSelfCareCalendarEvents(
            selectedHabit, selectedTasksByHabit, weekDates),
      );

      // NOTE: Intentionally NOT saving to annual calendar as requested

      return {
        'success': true,
        'message':
            'Self-care journey saved successfully (excluding annual calendar)'
      };
    } catch (e) {
      debugPrint('Error saving self-care journey: $e');
      return {
        'success': false,
        'message': 'Failed to save self-care journey: $e'
      };
    }
  }

  // Method to save finance journey data to database
  Future<Map<String, dynamic>> saveFinanceJourney({
    required String selectedGoal,
    required String selectedMonth,
    required double targetAmount,
    required String selectedTimeline,
    required Map<String, List<dynamic>> selectedTasksByGoal,
    required Map<int, DateTime> weekDates,
  }) async {
    try {
      debugPrint('Starting finance journey save to database...');

      // Get user info
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userName = userInfo['userName']!;
      final email = userInfo['email']!;

      // Set user info in services
      _calendarService.setUserInfo(userName, email);

      // 1. Save to Vision Board
      await _saveToVisionBoard(
        userName: userName,
        email: email,
        category: 'Invest',
        tasks: _generateFinanceVisionBoardTasks(
            selectedGoal, selectedMonth, selectedTasksByGoal),
      );

      // 2. Save to Calendar
      await _saveToCalendar(
        userName: userName,
        email: email,
        events: _generateFinanceCalendarEvents(
            selectedGoal, selectedTasksByGoal, weekDates),
      );

      // NOTE: Intentionally NOT saving to annual calendar as requested

      return {
        'success': true,
        'message':
            'Finance journey saved successfully (excluding annual calendar)'
      };
    } catch (e) {
      debugPrint('Error saving finance journey: $e');
      return {
        'success': false,
        'message': 'Failed to save finance journey: $e'
      };
    }
  }

  // Method to save self-care journey data to database (excluding annual calendar)
  Future<Map<String, dynamic>> saveSelfCareJourneyWithoutAnnual({
    required String selectedHabit,
    required String selectedMonth,
    required Map<String, List<dynamic>> selectedTasksByHabit,
    required Map<int, DateTime> weekDates,
  }) async {
    try {
      debugPrint(
          'Starting self-care journey save to database (excluding annual calendar)...');

      // Get user info
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userName = userInfo['userName']!;
      final email = userInfo['email']!;

      // Set user info in services
      _calendarService.setUserInfo(userName, email);

      // 1. Save to Vision Board
      await _saveToVisionBoard(
        userName: userName,
        email: email,
        category: 'Self Care',
        tasks: _generateSelfCareVisionBoardTasks(
            selectedHabit, selectedMonth, selectedTasksByHabit),
      );

      // 2. Save to Calendar
      await _saveToCalendar(
        userName: userName,
        email: email,
        events: _generateSelfCareCalendarEvents(
            selectedHabit, selectedTasksByHabit, weekDates),
      );

      // NOTE: Intentionally NOT saving to annual calendar as requested

      return {
        'success': true,
        'message':
            'Self-care journey saved successfully (excluding annual calendar)'
      };
    } catch (e) {
      debugPrint('Error saving self-care journey: $e');
      return {
        'success': false,
        'message': 'Failed to save self-care journey: $e'
      };
    }
  }

  // Method to save finance journey data to database (excluding annual calendar)
  Future<Map<String, dynamic>> saveFinanceJourneyWithoutAnnual({
    required String selectedGoal,
    required String selectedMonth,
    required double targetAmount,
    required String selectedTimeline,
    required Map<String, List<dynamic>> selectedTasksByGoal,
    required Map<int, DateTime> weekDates,
  }) async {
    try {
      debugPrint(
          'Starting finance journey save to database (excluding annual calendar)...');

      // Get user info
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isEmpty == true ||
          userInfo['email']?.isEmpty == true) {
        return {'success': false, 'message': 'User not logged in'};
      }

      final userName = userInfo['userName']!;
      final email = userInfo['email']!;

      // Set user info in services
      _calendarService.setUserInfo(userName, email);

      // 1. Save to Vision Board
      await _saveToVisionBoard(
        userName: userName,
        email: email,
        category: 'Invest',
        tasks: _generateFinanceVisionBoardTasks(
            selectedGoal, selectedMonth, selectedTasksByGoal),
      );

      // 2. Save to Calendar
      await _saveToCalendar(
        userName: userName,
        email: email,
        events: _generateFinanceCalendarEvents(
            selectedGoal, selectedTasksByGoal, weekDates),
      );

      // NOTE: Intentionally NOT saving to annual calendar as requested

      return {
        'success': true,
        'message':
            'Finance journey saved successfully (excluding annual calendar)'
      };
    } catch (e) {
      debugPrint('Error saving finance journey: $e');
      return {
        'success': false,
        'message': 'Failed to save finance journey: $e'
      };
    }
  }

  // Helper method to save to vision board
  Future<void> _saveToVisionBoard({
    required String userName,
    required String email,
    required String category,
    required List<Map<String, dynamic>> tasks,
  }) async {
    try {
      // Check if record exists and get existing tasks
      final existingRecord = await _client
          .from('vision_board_tasks')
          .select('id, tasks')
          .eq('user_name', userName)
          .eq('email', email)
          .eq('card_id', category)
          .eq('theme', 'BoxThem')
          .maybeSingle();

      List<Map<String, dynamic>> allTasks = [];

      // If record exists, parse existing tasks first
      if (existingRecord != null && existingRecord['tasks'] != null) {
        try {
          final existingTasksJson = existingRecord['tasks'];
          if (existingTasksJson is String) {
            final existingTasksList = jsonDecode(existingTasksJson);
            if (existingTasksList is List) {
              final existingTasks =
                  existingTasksList.cast<Map<String, dynamic>>();
              allTasks.addAll(existingTasks);
              debugPrint(
                  'Found ${existingTasks.length} existing tasks to preserve');
              for (var existingTask in existingTasks) {
                debugPrint(
                    'Preserving existing task: ${existingTask['text']} with ID: ${existingTask['id']}');
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing existing tasks: $e');
        }
      }

      // Add new tasks with proper format including id
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        // Create unique ID with microseconds and index to avoid duplicates
        final now = DateTime.now().add(Duration(microseconds: i));
        final taskWithId = {
          'id': now.toIso8601String(),
          'text': task['text'] ?? '',
          'isDone': task['isDone'] ?? false,
        };
        allTasks.add(taskWithId);
        debugPrint(
            'Adding new task: ${taskWithId['text']} with ID: ${taskWithId['id']}');
      }

      // Convert combined tasks to JSON format
      final allTasksJson = jsonEncode(allTasks);

      if (existingRecord != null) {
        // Update existing record with combined tasks
        await _client
            .from('vision_board_tasks')
            .update({
              'tasks': allTasksJson,
            })
            .eq('user_name', userName)
            .eq('email', email)
            .eq('card_id', category)
            .eq('theme', 'BoxThem');
      } else {
        // Insert new record
        await _client.from('vision_board_tasks').insert({
          'user_name': userName,
          'email': email,
          'card_id': category,
          'tasks': allTasksJson,
          'theme': 'BoxThem',
        });
      }

      debugPrint('Vision board tasks saved successfully!');
      debugPrint('Total tasks in vision board: ${allTasks.length}');
      debugPrint('Final JSON format: $allTasksJson');
    } catch (e) {
      debugPrint('Error saving vision board tasks: $e');
      rethrow;
    }
  }

  // Helper method to save to calendar
  Future<void> _saveToCalendar({
    required String userName,
    required String email,
    required List<Map<String, dynamic>> events,
  }) async {
    try {
      // Group events by date to handle same-day tasks
      Map<String, List<Map<String, dynamic>>> eventsByDate = {};

      for (var event in events) {
        // Parse the date properly
        DateTime eventDate;
        if (event['date'] is String) {
          eventDate = DateTime.parse(event['date']);
        } else {
          eventDate = event['date'];
        }

        final taskDate = eventDate.toIso8601String().split('T')[0];
        if (!eventsByDate.containsKey(taskDate)) {
          eventsByDate[taskDate] = [];
        }
        eventsByDate[taskDate]!.add(event);
      }

      // Process each date
      for (var dateEntry in eventsByDate.entries) {
        final taskDate = dateEntry.key;
        final dayEvents = dateEntry.value;

        // Check if record exists for this date
        final existingRecord = await _client
            .from('calendar_2025_tasks')
            .select('id, task_description')
            .eq('user_name', userName)
            .eq('email', email)
            .eq('task_date', taskDate)
            .eq('theme', 'animal')
            .maybeSingle();

        // Format all tasks for this day
        List<String> formattedTasks = [];

        // If there's an existing record, parse existing tasks first
        if (existingRecord != null &&
            existingRecord['task_description'] != null) {
          String existingDescription = existingRecord['task_description'];
          // Split by :: to get individual tasks
          List<String> existingTasks = existingDescription.split('::');
          formattedTasks.addAll(existingTasks);
        }

        // Add new tasks for this day
        for (var event in dayEvents) {
          DateTime eventDate;
          if (event['date'] is String) {
            eventDate = DateTime.parse(event['date']);
          } else {
            eventDate = event['date'];
          }

          // Map category to task_type
          int taskType;
          switch (event['category']) {
            case 'Travel':
              taskType = 1;
              break;
            case 'Health':
            case 'Self Care':
              taskType = 4;
              break;
            case 'Finance':
            case 'Invest':
              taskType = 3;
              break;
            default:
              taskType = 1;
          }

          // Format task description like: [16:40] [COLOR-4] Basic grooming: Showers, teeth, nails, moisturize #1750956033
          final timeStr =
              "${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}";
          final colorStr = "COLOR-$taskType";
          final description = event['description'] ?? event['title'];
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final formattedTask =
              "[$timeStr] [$colorStr] $description #$timestamp";

          formattedTasks.add(formattedTask);
        }

        // Combine all tasks with :: separator
        final combinedDescription = formattedTasks.join('::');

        // Get task_type from the first new event (or use existing)
        int taskType = 1; // default
        if (dayEvents.isNotEmpty) {
          switch (dayEvents.first['category']) {
            case 'Travel':
              taskType = 1;
              break;
            case 'Health':
            case 'Self Care':
              taskType = 4;
              break;
            case 'Finance':
            case 'Invest':
              taskType = 3;
              break;
            default:
              taskType = 1;
          }
        }

        if (existingRecord != null) {
          // Update existing record with combined description
          await _client.from('calendar_2025_tasks').update({
            'task_type': taskType,
            'task_description': combinedDescription,
            'color_code': 'selected-color-$taskType',
          }).eq('id', existingRecord['id']);
        } else {
          // Insert new record
          await _client.from('calendar_2025_tasks').insert({
            'user_name': userName,
            'email': email,
            'task_date': taskDate,
            'task_type': taskType,
            'task_description': combinedDescription,
            'color_code': 'selected-color-$taskType',
            'theme': 'animal', // Use animal theme as requested
          });
        }
      }
      debugPrint('Calendar events saved successfully to calendar_2025_tasks');
    } catch (e) {
      debugPrint('Error saving calendar events: $e');
      rethrow;
    }
  }

  // Helper method to save to annual calendar
  Future<void> _saveToAnnualCalendar({
    required String userName,
    required String email,
    required String journeyType,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Generate month-based tasks
      Map<String, List<Map<String, dynamic>>> tasksByMonth =
          _generateMonthBasedTasks(data);

      // Save each month as a separate row
      for (var monthEntry in tasksByMonth.entries) {
        final monthName = monthEntry.key;
        final monthTasks = monthEntry.value;

        // Check if record exists for this month
        final existingRecord = await _client
            .from('annual_calendar_tasks')
            .select('id, tasks')
            .eq('user_name', userName)
            .eq('email', email)
            .eq('card_id', monthName) // Use month name as card_id
            .eq('theme', 'postit')
            .maybeSingle();

        List<Map<String, dynamic>> allTasks = [];

        // If record exists, parse existing tasks first
        if (existingRecord != null && existingRecord['tasks'] != null) {
          try {
            final existingTasksJson = existingRecord['tasks'];
            if (existingTasksJson is String) {
              final existingTasksList = jsonDecode(existingTasksJson);
              if (existingTasksList is List) {
                final existingTasks =
                    existingTasksList.cast<Map<String, dynamic>>();
                allTasks.addAll(existingTasks);
                debugPrint(
                    'Found ${existingTasks.length} existing tasks for $monthName to preserve');
              }
            }
          } catch (e) {
            debugPrint('Error parsing existing tasks for $monthName: $e');
          }
        }

        // Add new tasks for this month
        allTasks.addAll(monthTasks);
        for (var newTask in monthTasks) {
          debugPrint('Adding new task for $monthName: ${newTask['text']}');
        }

        // Convert combined tasks to JSON format
        final allTasksJson = jsonEncode(allTasks);

        if (existingRecord != null) {
          // Update existing record for this month
          await _client
              .from('annual_calendar_tasks')
              .update({
                'tasks': allTasksJson,
              })
              .eq('user_name', userName)
              .eq('email', email)
              .eq('card_id', monthName)
              .eq('theme', 'postit');
        } else {
          // Insert new record for this month
          await _client.from('annual_calendar_tasks').insert({
            'user_name': userName,
            'email': email,
            'card_id': monthName, // Month name as identifier
            'tasks': allTasksJson,
            'theme': 'postit',
          });
        }

        debugPrint('Annual calendar data saved successfully for $monthName!');
        debugPrint('Total tasks for $monthName: ${allTasks.length}');
      }
    } catch (e) {
      debugPrint('Error saving annual calendar data: $e');
      rethrow;
    }
  }

  // Generate travel vision board tasks
  List<Map<String, dynamic>> _generateTravelVisionBoardTasks(
    List<String> selectedLocations,
    List<String> selectedMonths,
  ) {
    List<Map<String, dynamic>> tasks = [];

    for (int i = 0; i < selectedLocations.length; i++) {
      final cityName = selectedLocations[i].split(',').first;
      final monthName = selectedMonths.isNotEmpty && i < selectedMonths.length
          ? _getMonthName(selectedMonths[i])
          : 'Month ${i + 1}';

      tasks.add({
        'id': DateTime.now().add(Duration(milliseconds: i)).toIso8601String(),
        'text': 'Travel to $cityName in $monthName',
        'isDone': false,
      });
    }

    return tasks;
  }

  // Generate self-care vision board tasks
  List<Map<String, dynamic>> _generateSelfCareVisionBoardTasks(
    String selectedHabit,
    String selectedMonth,
    Map<String, List<dynamic>> selectedTasksByHabit,
  ) {
    List<Map<String, dynamic>> tasks = [];
    final selectedTasks = selectedTasksByHabit[selectedHabit] ?? [];

    for (int i = 0; i < selectedTasks.length; i++) {
      final task = selectedTasks[i];
      final taskDescription =
          task.description ?? task['description'] ?? task.toString();
      tasks.add({
        'id': DateTime.now().add(Duration(milliseconds: i)).toIso8601String(),
        'text': '$taskDescription for $selectedHabit in $selectedMonth',
        'isDone': false,
      });
    }

    // Add default if no tasks
    if (tasks.isEmpty) {
      tasks.add({
        'id': DateTime.now().toIso8601String(),
        'text': 'Daily self-care routine for $selectedHabit',
        'isDone': false,
      });
    }

    return tasks;
  }

  // Generate finance vision board tasks
  List<Map<String, dynamic>> _generateFinanceVisionBoardTasks(
    String selectedGoal,
    String selectedMonth,
    Map<String, List<dynamic>> selectedTasksByGoal,
  ) {
    List<Map<String, dynamic>> tasks = [];
    final selectedTasks = selectedTasksByGoal[selectedGoal] ?? [];

    for (int i = 0; i < selectedTasks.length; i++) {
      final task = selectedTasks[i];
      final taskDescription =
          task.description ?? task['description'] ?? task.toString();
      tasks.add({
        'id': DateTime.now().add(Duration(milliseconds: i)).toIso8601String(),
        'text': '$taskDescription for $selectedGoal in $selectedMonth',
        'isDone': false,
      });
    }

    // Add default if no tasks
    if (tasks.isEmpty) {
      tasks.add({
        'id': DateTime.now().toIso8601String(),
        'text': 'Daily finance routine for $selectedGoal',
        'isDone': false,
      });
    }

    return tasks;
  }

  // Generate travel calendar events
  List<Map<String, dynamic>> _generateTravelCalendarEvents(
    List<String> selectedLocations,
    List<String> selectedMonths,
    Map<String, List<dynamic>> completedTasksByCity,
    Map<int, Map<int, DateTime>> weekDatesByCity,
  ) {
    List<Map<String, dynamic>> events = [];

    // Process each city and its selected tasks
    completedTasksByCity.forEach((cityName, cityTasks) {
      debugPrint(
          'Processing $cityName with ${cityTasks.length} selected tasks');

      // Find the corresponding city index to get the selected month
      int cityIndex = -1;
      for (int i = 0; i < selectedLocations.length; i++) {
        if (selectedLocations[i].split(',').first == cityName) {
          cityIndex = i;
          break;
        }
      }

      // Get the selected month for this city
      String monthDateString = DateTime.now().toIso8601String();
      if (cityIndex >= 0 && cityIndex < selectedMonths.length) {
        monthDateString = selectedMonths[cityIndex];
      }

      DateTime baseDate;
      try {
        baseDate = DateTime.parse(monthDateString);
      } catch (e) {
        debugPrint('Error parsing date for $cityName: $e');
        baseDate = DateTime.now();
      }

      // Add each selected task as a calendar event
      for (int taskIndex = 0; taskIndex < cityTasks.length; taskIndex++) {
        final task = cityTasks[taskIndex];
        final taskDescription =
            task.description ?? task['description'] ?? task.toString();
        final weekNumber = task.weekNumber ?? task['weekNumber'] ?? 1;

        // Use the actual week date from weekDatesByCity if available
        DateTime taskDate = baseDate.add(Duration(days: (weekNumber - 1) * 7));
        if (cityIndex >= 0 && weekDatesByCity.containsKey(cityIndex)) {
          final cityWeekDates = weekDatesByCity[cityIndex]!;
          if (cityWeekDates.containsKey(weekNumber)) {
            taskDate = cityWeekDates[weekNumber]!;
          }
        }

        events.add({
          'date': taskDate.toIso8601String(),
          'title': taskDescription,
          'description': '$taskDescription for $cityName trip',
          'category': 'Travel',
          'is_all_day': true,
        });

        debugPrint(
            'Added calendar event: $taskDescription on ${taskDate.toIso8601String().split('T')[0]} for $cityName');
      }
    });

    // If no completed tasks, add default travel events for each location
    if (events.isEmpty) {
      for (int i = 0; i < selectedLocations.length; i++) {
        final cityName = selectedLocations[i].split(',').first;
        final monthName = selectedMonths.isNotEmpty && i < selectedMonths.length
            ? selectedMonths[i]
            : DateTime.now().toIso8601String();

        try {
          final date = DateTime.parse(monthName);
          events.add({
            'date': date.toIso8601String(),
            'title': 'Travel to $cityName',
            'description': 'Planned trip to $cityName',
            'category': 'Travel',
            'is_all_day': true,
          });
        } catch (e) {
          debugPrint('Error parsing date for default event: $e');
        }
      }
    }

    return events;
  }

  // Generate self-care calendar events
  List<Map<String, dynamic>> _generateSelfCareCalendarEvents(
    String selectedHabit,
    Map<String, List<dynamic>> selectedTasksByHabit,
    Map<int, DateTime> weekDates,
  ) {
    List<Map<String, dynamic>> events = [];
    final selectedTasks = selectedTasksByHabit[selectedHabit] ?? [];

    for (var task in selectedTasks) {
      final weekNumber = task.weekNumber ?? task['weekNumber'] ?? 1;
      final taskDescription =
          task.description ?? task['description'] ?? task.toString();
      final weekDate = weekDates[weekNumber] ?? DateTime.now();

      events.add({
        'date': weekDate.toIso8601String(),
        'title': taskDescription,
        'description': 'Self-care activity: $taskDescription',
        'category': 'Health',
        'is_all_day': true,
      });
    }

    return events;
  }

  // Generate finance calendar events
  List<Map<String, dynamic>> _generateFinanceCalendarEvents(
    String selectedGoal,
    Map<String, List<dynamic>> selectedTasksByGoal,
    Map<int, DateTime> weekDates,
  ) {
    List<Map<String, dynamic>> events = [];
    final selectedTasks = selectedTasksByGoal[selectedGoal] ?? [];

    for (var task in selectedTasks) {
      final weekNumber = task.weekNumber ?? task['weekNumber'] ?? 1;
      final taskDescription =
          task.description ?? task['description'] ?? task.toString();
      final weekDate = weekDates[weekNumber] ?? DateTime.now();

      events.add({
        'date': weekDate.toIso8601String(),
        'title': taskDescription,
        'description': 'Finance activity: $taskDescription',
        'category': 'Finance',
        'is_all_day': true,
      });
    }

    return events;
  }

  // Helper method to extract month name from date string
  String _getMonthName(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
      return months[date.month - 1];
    } catch (e) {
      debugPrint('Error parsing date: $e');
      // Return null instead of "Unknown Month" to avoid creating unwanted rows
      return 'Unknown Month';
    }
  }

  // Test database connection
  Future<bool> testConnection() async {
    try {
      await _client.from('vision_board_tasks').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing connection: $e');
      return false;
    }
  }

  // Generate month-based tasks
  Map<String, List<Map<String, dynamic>>> _generateMonthBasedTasks(
      Map<String, dynamic> data) {
    Map<String, List<Map<String, dynamic>>> tasksByMonth = {};

    try {
      // Handle travel journey data
      if (data.containsKey('selectedLocations')) {
        final selectedLocations =
            data['selectedLocations'] as List<String>? ?? [];
        final selectedMonths = data['selectedMonths'] as List<String>? ?? [];
        final completedTasksByCity =
            data['completedTasksByCity'] as Map<String, List<dynamic>>? ?? {};

        // Add location-based tasks organized by month
        debugPrint(
            'Processing ${selectedLocations.length} locations for annual calendar');
        for (int i = 0; i < selectedLocations.length; i++) {
          final cityName = selectedLocations[i].split(',').first;
          final monthName =
              selectedMonths.isNotEmpty && i < selectedMonths.length
                  ? _getMonthName(selectedMonths[i])
                  : null; // Don't create fallback months

          debugPrint(
              'City: $cityName, Month: $monthName (from ${selectedMonths.isNotEmpty && i < selectedMonths.length ? selectedMonths[i] : 'no date'})');

          // Only add if we have a valid month name
          if (monthName != null && monthName != 'Unknown Month') {
            if (!tasksByMonth.containsKey(monthName)) {
              tasksByMonth[monthName] = [];
            }
            tasksByMonth[monthName]!.add({
              'text': 'Travel to $cityName in $monthName',
              'completed': false,
            });

            // Add specific tasks from completedTasksByCity for this city to the same month
            if (completedTasksByCity.containsKey(cityName)) {
              final cityTasks = completedTasksByCity[cityName]!;
              for (var task in cityTasks) {
                final taskDescription =
                    task.description ?? task['description'] ?? task.toString();
                final isCompleted = task.isDone ??
                    task['isDone'] ??
                    task.isCompleted ??
                    task['isCompleted'] ??
                    false;

                tasksByMonth[monthName]!.add({
                  'text': '$taskDescription for $cityName',
                  'completed': isCompleted,
                });
              }
            }
          }
        }
      }

      // Handle self-care journey data
      else if (data.containsKey('selectedHabit')) {
        final selectedHabit = data['selectedHabit'] as String? ?? '';
        final selectedMonth = data['selectedMonth'] as String? ?? '';
        final selectedTasksByHabit =
            data['selectedTasksByHabit'] as Map<String, List<dynamic>>? ?? {};

        selectedTasksByHabit.forEach((habit, habitTasks) {
          for (var task in habitTasks) {
            final taskDescription =
                task.description ?? task['description'] ?? task.toString();
            final isCompleted = task.isDone ??
                task['isDone'] ??
                task.isCompleted ??
                task['isCompleted'] ??
                false;

            if (!tasksByMonth.containsKey(habit)) {
              tasksByMonth[habit] = [];
            }
            tasksByMonth[habit]!.add({
              'text': '$taskDescription for $habit in $selectedMonth',
              'completed': isCompleted,
            });
          }
        });

        // Add default if no tasks
        if (!tasksByMonth.containsKey(selectedHabit)) {
          tasksByMonth[selectedHabit] = [];
        }
        tasksByMonth[selectedHabit]!.add({
          'text': 'Daily self-care routine for $selectedHabit',
          'completed': false,
        });
      }

      // Handle finance journey data
      else if (data.containsKey('selectedGoal')) {
        final selectedGoal = data['selectedGoal'] as String? ?? '';
        final selectedMonth = data['selectedMonth'] as String? ?? '';
        final targetAmount = data['targetAmount'] as double? ?? 0.0;
        final selectedTasksByGoal =
            data['selectedTasksByGoal'] as Map<String, List<dynamic>>? ?? {};

        // Add goal-based task
        tasksByMonth[selectedMonth] = [
          {
            'text':
                'Achieve $selectedGoal goal of \$${targetAmount.toStringAsFixed(2)} by $selectedMonth',
            'completed': false,
          },
        ];

        selectedTasksByGoal.forEach((goal, goalTasks) {
          for (var task in goalTasks) {
            final taskDescription =
                task.description ?? task['description'] ?? task.toString();
            final isCompleted = task.isDone ??
                task['isDone'] ??
                task.isCompleted ??
                task['isCompleted'] ??
                false;

            if (!tasksByMonth.containsKey(selectedMonth)) {
              tasksByMonth[selectedMonth] = [];
            }
            tasksByMonth[selectedMonth]!.add({
              'text': '$taskDescription for $goal in $selectedMonth',
              'completed': isCompleted,
            });
          }
        });

        // Add default if no tasks
        if (!tasksByMonth.containsKey(selectedMonth)) {
          tasksByMonth[selectedMonth] = [];
        }
        tasksByMonth[selectedMonth]!.add({
          'text': 'Daily finance routine for $selectedGoal',
          'completed': false,
        });
      }
    } catch (e) {
      debugPrint('Error generating month-based tasks: $e');
      // Don't add fallback tasks to avoid creating unwanted rows
    }

    return tasksByMonth;
  }
}
