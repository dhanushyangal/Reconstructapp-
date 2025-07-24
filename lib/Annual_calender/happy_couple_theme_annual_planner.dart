import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/calendar_database_service.dart';
import '../config/api_config.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/user_service.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';
import '../utils/platform_features.dart';
import '../pages/active_tasks_page.dart';

class HappyCoupleThemeCalendarApp extends StatefulWidget {
  final int monthIndex;
  final String? eventId;
  final bool showEvents;

  const HappyCoupleThemeCalendarApp({
    super.key,
    required this.monthIndex,
    this.eventId,
    this.showEvents = false,
  });

  // Add route name to make navigation easier
  static const routeName = '/happy-couple-theme-calendar';

  @override
  State<HappyCoupleThemeCalendarApp> createState() =>
      _HappyCoupleThemeCalendarAppState();
}

class _HappyCoupleThemeCalendarAppState
    extends State<HappyCoupleThemeCalendarApp> with ActivityTrackerMixin {
  final screenshotController = ScreenshotController();
  final List<String> months = [
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

  final Map<int, int> daysInMonth2025 = {
    1: 31,
    2: 28,
    3: 31,
    4: 30,
    5: 31,
    6: 30,
    7: 31,
    8: 31,
    9: 30,
    10: 31,
    11: 30,
    12: 31
  };

  Map<String, Map<int, int>> selectedDates = {};

  // Replace colorOptions with categoryColors
  final Map<String, Color> categoryColors = {
    'Personal': const Color(0xFFff6f61), // Coral
    'Professional': const Color(0xFF1b998b), // Teal
    'Finance': const Color(0xFFfddb3a), // Yellow
    'Health': const Color(0xFF8360c3), // Purple
  };

  // Add this variable to track if full calendar is open
  bool showFullCalendar = false;

  // Store events in a Map
  Map<DateTime, List<Map<String, String>>> events = {};

  late DateTime _selectedDate;
  int _currentMonthIndex = DateTime.now().month - 1;

  // Add this variable to control the height of the event box
  double eventBoxHeight = 100.0; // Default height

  // Add a ScrollController to handle scrolling
  final ScrollController _eventScrollController = ScrollController();

  // Add the database service
  late CalendarDatabaseService _calendarDatabaseService;
  bool _isConnected = true;
  bool _isLoading = true;
  bool _isLoadingData = false;
  String? _userName;
  String? _userEmail;

  // Map to store task IDs from database
  Map<DateTime, int> taskIds = {};

  // Add a helper method to normalize dates (remove time components)
  DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Helper method to get events for a specific day regardless of time component
  List<Map<String, String>> getEventsForDay(DateTime date) {
    // Normalize the input date
    final normalizedDate = normalizeDate(date);

    // First try direct lookup
    if (events.containsKey(normalizedDate)) {
      return events[normalizedDate] ?? [];
    }

    // If not found, search through all keys
    for (var entry in events.entries) {
      final eventDate = entry.key;
      if (eventDate.year == normalizedDate.year &&
          eventDate.month == normalizedDate.month &&
          eventDate.day == normalizedDate.day) {
        return entry.value;
      }
    }

    return [];
  }

  // New method to handle initialization
  Future<void> _initializeCalendar() async {
    try {
      // First, load saved dates from local storage to show something quickly
      await _loadSavedDates();

      // Show the UI immediately after loading basic local data
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Continue loading user info and checking connectivity in the background
      await Future.wait([
        _loadUserInfo(),
        _checkConnectivity(),
      ]);

      // After getting user info and connectivity, sync with database if possible
      if (_isConnected && _isUserLoggedIn()) {
        // Show subtle loading indicator for database operations
        setState(() {
          _isLoadingData = true;
        });

        // Load from database
        await _loadEventsFromDatabase();

        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      }

      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((result) {
        final wasConnected = _isConnected;
        _isConnected = (result != ConnectivityResult.none);

        // If connection is restored and user is logged in, sync with database
        if (!wasConnected && _isConnected && _isUserLoggedIn()) {
          _syncWithDatabase();
        }
      });
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Even if there's an error, we should show the UI
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize the database service
    _calendarDatabaseService =
        CalendarDatabaseService(baseUrl: ApiConfig.baseUrl);

    // Set the initial state based on constructor parameters
    _currentMonthIndex = widget.monthIndex;
    _selectedDate = DateTime(2025, _currentMonthIndex + 1, 1);

    // Initialize HomeWidget with proper configuration
    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    HomeWidget.registerBackgroundCallback(backgroundCallback);

    // Setup method channel for widget events
    const channel = MethodChannel('com.reconstrect.visionboard/widget');
    channel.setMethodCallHandler(_handleMethodCall);

    // Start the initialization process
    _initializeCalendar();

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Handle method channel calls
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'openEventsView') {
      final monthIndex = call.arguments['month_index'] as int;
      final showEvents = call.arguments['show_events'] as bool? ?? false;

      setState(() {
        showFullCalendar = true;
        _currentMonthIndex = monthIndex;
      });

      if (showEvents) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _buildFullCalendarView();
        });
      }
      return true;
    } else if (call.method == 'navigateTo') {
      final route = call.arguments as String;
      Navigator.pushNamed(context, route);
      return true;
    }
    return null;
  }

  // Check internet connectivity
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = (connectivityResult != ConnectivityResult.none);
    });
  }

  // Load user information from UserService
  Future<void> _loadUserInfo() async {
    try {
      // Get user info from UserService
      final userInfo = await UserService.instance.getUserInfo();
      _userName = userInfo['userName'];
      _userEmail = userInfo['email'];

      debugPrint(
          'HappyCoupleThemeCalendar: Loaded user info - Name: $_userName, Email: $_userEmail');

      // Set user info in the database service
      if (_userName != null &&
          _userName!.isNotEmpty &&
          _userEmail != null &&
          _userEmail!.isNotEmpty) {
        _calendarDatabaseService.setUserInfo(_userName!, _userEmail!);

        debugPrint(
            'HappyCoupleThemeCalendar: User info set in database service');
      } else {
        // If no user info found, show a snackbar message
        debugPrint('HappyCoupleThemeCalendar: No user info found');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Please log in to sync your calendar with the cloud'),
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Login',
                  onPressed: _showLoginDialog,
                ),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
    }
  }

  // Add a method to show login dialog
  void _showLoginDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Login to Sync Calendar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                hintText: 'Enter your name',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();

              if (name.isNotEmpty && email.isNotEmpty) {
                await UserService.instance.setManualUserInfo(
                  userName: name,
                  email: email,
                );

                // Reload user info
                await _loadUserInfo();

                // Sync with database
                if (_isConnected && _isUserLoggedIn()) {
                  await _syncWithDatabase();
                }

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Login successful! Syncing calendar...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter both name and email'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> dataToSave = {};

      for (var entry in events.entries) {
        final dateStr =
            "${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}";
        final category = entry.value.first['category'] ?? 'Personal';
        dataToSave[dateStr] = category;
      }

      final String jsonData = json.encode(dataToSave);

      // Use unique keys for happy couple theme
      await Future.wait([
        prefs.setString('happy_couple.calendar_theme_2025', jsonData),
        prefs.setString('happy_couple.calendar_data', jsonData),
        HomeWidget.saveWidgetData('happy_couple.calendar_data', jsonData),
        HomeWidget.saveWidgetData('happy_couple.calendar_theme_2025', jsonData),
      ]);

      await HomeWidget.updateWidget(
        name: 'CalendarThemeWidget',
        iOSName: 'CalendarThemeWidget',
        qualifiedAndroidName: 'com.reconstrect.visionboard.CalendarThemeWidget',
      );
    } catch (e) {
      debugPrint('Error saving dates: $e');
    }
  }

  Future<void> _loadSavedDates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData =
          prefs.getString('happy_couple.calendar_theme_2025');

      if (savedData != null) {
        final Map<String, dynamic> decodedData = json.decode(savedData);

        events.clear();
        decodedData.forEach((dateStr, category) {
          try {
            final date = normalizeDate(DateTime.parse(dateStr));
            events[date] = [
              {'category': category, 'title': category, 'type': 'Event'}
            ];
          } catch (e) {
            debugPrint('Error parsing date: $dateStr - $e');
          }
        });

        debugPrint(
            'Parsed ${events.length} events from SharedPreferences'); // Debug log
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading dates from SharedPreferences: $e');
    }
  }

  Future<void> _takeScreenshotAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/happy_couple_calendar_2025.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'My Happy Couple Theme Calendar 2025');
    } catch (e) {
      debugPrint('Error sharing calendar: $e');
    }
  }

  Widget _buildMonthCard(String month, int monthIndex) {
    return Card(
      elevation: 7,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Image section (4 parts of 10)
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: SizedBox(
                      height:
                          constraints.maxHeight * 0.45, // 40% of total height
                      width: constraints.maxWidth,
                      child: Image.asset(
                        'assets/couple_calender/couple${monthIndex + 1}.png',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Month name section
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      month,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Calendar section (adjusted height)
                  SizedBox(
                    height: constraints.maxHeight * 0.45, // 60% of total height
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: _buildCalendarGrid(month, monthIndex + 1),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: SizedBox(
              width: 22, // Reduced size for the button
              height: 22, // Reduced size for the button
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    showFullCalendar = true;
                    _currentMonthIndex = monthIndex;
                    _selectedDate = DateTime(2025, monthIndex + 1, 1);
                    Future.delayed(Duration.zero, () {
                      _showEventDialog();
                    });
                  });
                }, // Even smaller icon
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4,
                child: const Icon(Icons.add, size: 14), // Optional: reduced elevation for better fit
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(String month, int monthNumber) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Text(day,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  )))
              .toList(),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              crossAxisSpacing: 1,
              mainAxisSpacing: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final firstDay = DateTime(2025, monthNumber, 1);
              final offset = firstDay.weekday % 7;
              final adjustedIndex = index - offset;

              if (adjustedIndex < 0 ||
                  adjustedIndex >= daysInMonth2025[monthNumber]!) {
                return const SizedBox();
              }

              final day = adjustedIndex + 1;
              final date = DateTime(2025, monthNumber, day);

              // Get events for this date
              final dayEvents = events[date] ?? [];
              Color? backgroundColor = Colors.white;

              // If there are events, use the color of the first event's category
              if (dayEvents.isNotEmpty) {
                final category = dayEvents.first['category'] ?? 'Personal';
                backgroundColor = categoryColors[category];
              }

              return Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      color: backgroundColor == Colors.white
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Save events to SharedPreferences
  Future<void> _saveEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = json.encode(
      events.map((key, value) => MapEntry(key.toIso8601String(), value)),
    );
    await prefs.setString('happy_couple.calendar_events', eventsJson);
  }

  // Modified _addEvent method
  void _addEvent(DateTime date, Map<String, String> event) {
    trackClick(
        'happy_couple_calendar_event_added - ${event['category'] ?? 'Personal'}');
    // Normalize the date to remove time components
    final normalizedDate = normalizeDate(date);

    setState(() {
      if (!events.containsKey(normalizedDate)) {
        events[normalizedDate] = [];
      }
      events[normalizedDate]!.add(event);
      _saveEvents(); // Save to SharedPreferences
      _saveDates(); // Update the widget

      // Save to database if connected and logged in
      if (_isConnected && _isUserLoggedIn()) {
        _saveEventToDatabase(normalizedDate, event);
      } else if (_isConnected && !_isUserLoggedIn()) {
        // If connected but not logged in, show login dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please log in to save events to the cloud'),
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Login',
                  onPressed: _showLoginDialog,
                ),
              ),
            );
          }
        });
      }
    });
  }

  // Helper method to get standardized color code from task type
  String getStandardizedColorCode(int taskType) {
    return 'selected-color-$taskType';
  }

  // Method to save event to database
  Future<void> _saveEventToDatabase(
      DateTime date, Map<String, String> event) async {
    try {
      // Ensure date is normalized
      final normalizedDate = normalizeDate(date);
      final category = event['category'] ?? 'Personal';
      final description = event['type'] ?? 'Event';

      // Map category to task_type
      int taskType;
      switch (category) {
        case 'Personal':
          taskType = 1;
          break;
        case 'Professional':
          taskType = 2;
          break;
        case 'Finance':
          taskType = 3;
          break;
        case 'Health':
          taskType = 4;
          break;
        default:
          taskType = 1;
      }

      // Use standardized color code format
      final colorCode = getStandardizedColorCode(taskType);

      // Save to database
      final result = await _calendarDatabaseService.saveCalendarTask(
        taskDate: normalizedDate,
        taskType: taskType,
        description: description,
        colorCode: colorCode,
        theme: 'happy_couple',
      );

      if (result['success'] && result['task'] != null) {
        // Store the task ID
        taskIds[normalizedDate] = result['task']['id'];
        debugPrint('Event saved to database with ID: ${result['task']['id']}');
      } else {
        debugPrint('Failed to save event to database: ${result['message']}');
      }
    } catch (e) {
      debugPrint('Error saving event to database: $e');
    }
  }

  // Modified method to handle event deletion
  Future<void> _deleteEvent(DateTime date, int index) async {
    trackClick('happy_couple_calendar_event_deleted');
    // Normalize the date to remove time components
    final normalizedDate = normalizeDate(date);

    setState(() {
      events[normalizedDate]!.removeAt(index);
      if (events[normalizedDate]!.isEmpty) {
        events.remove(normalizedDate);
      }
      _saveEvents(); // Save after deleting
      _saveDates(); // Also update the widget
    });

    // Delete from database if connected and logged in
    if (_isConnected &&
        _isUserLoggedIn() &&
        taskIds.containsKey(normalizedDate)) {
      try {
        debugPrint('Deleting event from database for user: $_userName');
        final result = await _calendarDatabaseService.deleteCalendarTask(
          taskId: taskIds[normalizedDate]!,
        );

        if (result['success']) {
          taskIds.remove(normalizedDate);
          debugPrint('Event deleted from database');
        } else {
          debugPrint(
              'Failed to delete event from database: ${result['message']}');
        }
      } catch (e) {
        debugPrint('Error deleting event from database: $e');
      }
    }
  }

  // Updated _showEventDialog with better date handling and validation
  void _showEventDialog() {
    DateTime selectedDate = _selectedDate;
    final typeController = TextEditingController();
    String selectedCategory = 'Personal';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        // Use StatefulBuilder to update dialog state
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  '${selectedDate.day} ${months[selectedDate.month - 1]} 2025',
                  style: const TextStyle(fontSize: 16),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2025, 1, 1),
                    lastDate: DateTime(2025, 12, 31),
                  );
                  if (picked != null) {
                    setDialogState(() {
                      selectedDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                onChanged: (String? newValue) {
                  setDialogState(() {
                    selectedCategory = newValue!;
                  });
                },
                items: ['Personal', 'Professional', 'Finance', 'Health']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (typeController.text.isNotEmpty) {
                  _addEvent(selectedDate, {
                    'title': selectedCategory,
                    'type': typeController.text,
                    'category': selectedCategory,
                  });
                  Navigator.pop(context);
                  // Update the view if needed
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _buildEventsList to filter events by current month
  Widget _buildEventsList() {
    final currentMonthEvents = events.entries
        .where((entry) => entry.key.month == _currentMonthIndex + 1)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.only(top: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: currentMonthEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events for ${months[_currentMonthIndex]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    controller: _eventScrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: currentMonthEvents.length,
                    itemBuilder: (context, dateIndex) {
                      final date = currentMonthEvents[dateIndex].key;
                      final dayEvents = currentMonthEvents[dateIndex].value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...dayEvents.asMap().entries.map((entry) {
                            final eventIndex = entry.key;
                            final event = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 0.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        [
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                          'Sat',
                                          'Sun'
                                        ][date.weekday - 1],
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${date.day}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildEventItem(
                                        date, event, eventIndex),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (dateIndex < currentMonthEvents.length - 1)
                            Divider(
                              color: Colors.grey[200],
                              height: 8,
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Update the event item builder to use _deleteEvent method
  Widget _buildEventItem(DateTime date, Map<String, String> event, int index) {
    final category = event['category'] ?? 'Personal';
    final backgroundColor = categoryColors[category] ?? Colors.grey;

    return Dismissible(
      key: Key('${date.toString()}_$index'),
      onDismissed: (direction) {
        _deleteEvent(date, index);
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0, left: 24.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    event['type'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullCalendarView() {
    final monthEvents = events.entries
        .where((entry) => entry.key.month == _currentMonthIndex + 1)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  months[_currentMonthIndex],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => showFullCalendar = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: monthEvents.isEmpty
                ? Center(
                    child: Text(
                      'No events for ${months[_currentMonthIndex]}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : _buildEventsList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Couple Theme Calendar 2025'),
        actions: [
          if (!_isUserLoggedIn())
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Login',
              onPressed: _showLoginDialog,
            ),
          if (_isUserLoggedIn())
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync with cloud',
              onPressed: () async {
                if (_isConnected) {
                  await _loadEventsFromDatabase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calendar synced with cloud'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No internet connection'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          showFullCalendar
              ? _buildFullCalendarView()
              : Column(
                  children: [
                    Expanded(
                      child: Screenshot(
                        controller: screenshotController,
                        child: Container(
                          color: Colors.white,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(6),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.47,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                            ),
                            itemCount: months.length,
                            itemBuilder: (context, index) =>
                                _buildMonthCard(months[index], index),
                          ),
                        ),
                      ),
                    ),
                    if (PlatformFeatures.isFeatureAvailable('add_widgets'))
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url =
                                'https://youtube.com/shorts/IAeczaEygUM?feature=share';
                            final uri = Uri.parse(url);
                            if (!await launchUrl(uri,
                                mode: LaunchMode.externalApplication)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Could not open YouTube shorts: $url')),
                              );
                            }
                          },
                          icon: const Icon(Icons.widgets),
                          label: const Text('Add Widgets'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const ActiveTasksPage()),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save Calendar'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          // Loading indicator
          if (_isLoadingData)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.black54,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Syncing calendar data...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: showFullCalendar
          ? FloatingActionButton(
              onPressed: _showAddEventDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Method to show the add event dialog
  void _showAddEventDialog() {
    _showEventDialog();
  }

  // Add background callback for widget updates
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updatewidget') {
      await HomeWidget.updateWidget(
        name: 'CalendarThemeWidget',
        iOSName: 'CalendarThemeWidget',
        qualifiedAndroidName: 'com.reconstrect.visionboard.CalendarThemeWidget',
      );
    }
  }

  // Add method to load events from database
  Future<void> _loadEventsFromDatabase() async {
    try {
      if (!_isUserLoggedIn()) {
        debugPrint('Cannot load from database: user not logged in');
        return;
      }

      debugPrint('Loading events from database for user: $_userName');

      // Show loading indicator during database operations
      setState(() {
        _isLoadingData = true;
      });

      final result = await _calendarDatabaseService.getCalendarTasks(
        theme: 'happy_couple',
      );

      // Add concise logging for the result
      debugPrint('Database response: success=${result['success']}');

      if (!result.containsKey('success') || !result.containsKey('tasks')) {
        debugPrint('Invalid response format');
        setState(() {
          _isLoadingData = false;
        });
        return;
      }

      if (!result['success']) {
        debugPrint('Failed to load tasks: ${result['message']}');
        setState(() {
          _isLoadingData = false;
        });
        return;
      }

      try {
        final tasks = result['tasks'] as List;
        debugPrint('Received ${tasks.length} tasks from database');

        // Only clear existing events if we successfully received data
        if (tasks.isNotEmpty) {
          events.clear();
          taskIds.clear();
        }

        // Process tasks from database
        int processedCount = 0;
        for (var task in tasks) {
          try {
            // Reduce verbose output for each task
            final taskDateStr = task['task_date'] as String;
            final taskDate = normalizeDate(DateTime.parse(taskDateStr));

            int taskType = task['task_type'] as int;
            final description = task['task_description'] as String;
            final taskId = task['id'] as int;

            // Check if color_code is in the standardized format and update taskType if needed
            final colorCode = task['color_code'] as String? ?? '';
            if (colorCode.startsWith('selected-color-')) {
              try {
                final typeFromColor = int.parse(colorCode.split('-').last);
                if (typeFromColor >= 1 && typeFromColor <= 4) {
                  // If color code has a valid type, use it
                  taskType = typeFromColor;
                }
              } catch (e) {
                debugPrint('Error parsing color code: $colorCode - $e');
              }
            }

            // Map task_type to category
            String category;
            switch (taskType) {
              case 1:
                category = 'Personal';
                break;
              case 2:
                category = 'Professional';
                break;
              case 3:
                category = 'Finance';
                break;
              case 4:
                category = 'Health';
                break;
              default:
                category = 'Personal';
            }

            // Store in events map with normalized date
            if (!events.containsKey(taskDate)) {
              events[taskDate] = [];
            }

            events[taskDate]!.add({
              'category': category,
              'title': category,
              'type': description,
            });

            // Store task ID for future updates
            taskIds[taskDate] = taskId;
            processedCount++;
          } catch (e) {
            debugPrint('Error processing task: $e');
          }
        }

        debugPrint(
            'Successfully processed $processedCount out of ${tasks.length} tasks');

        // Update UI and save to local storage
        _forceRefresh(); // Force a refresh instead of just setState
        await _saveDates();

        debugPrint('Calendar data loaded and saved to local storage');
      } catch (e) {
        debugPrint('Error processing tasks list: $e');
      }
    } catch (e) {
      debugPrint('Error loading events from database: $e');
    } finally {
      // Always hide loading indicator
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Helper method to force refresh
  void _forceRefresh() {
    if (mounted) {
      setState(() {
        // Force rebuild by setting a flag or similar
        debugPrint('Refreshing calendar grid with ${events.length} events');
      });
    }
  }

  // Check if user is logged in
  bool _isUserLoggedIn() {
    return _userName != null &&
        _userName!.isNotEmpty &&
        _userEmail != null &&
        _userEmail!.isNotEmpty;
  }

  // Method to sync changes with database when connection is restored
  Future<void> _syncWithDatabase() async {
    try {
      // Check if user is logged in
      if (!_isUserLoggedIn()) {
        debugPrint('Cannot sync with database: user not logged in');
        return;
      }

      debugPrint('Syncing with database for user: $_userName');

      // First load latest data from database
      await _loadEventsFromDatabase();

      // Then save any local changes back to database
      for (var entry in events.entries) {
        final eventDate = normalizeDate(entry.key); // Normalize date
        final eventsList = entry.value;

        for (var event in eventsList) {
          final category = event['category'] ?? 'Personal';
          final description = event['type'] ?? 'Event';

          // Map category to task_type
          int taskType;
          switch (category) {
            case 'Personal':
              taskType = 1;
              break;
            case 'Professional':
              taskType = 2;
              break;
            case 'Finance':
              taskType = 3;
              break;
            case 'Health':
              taskType = 4;
              break;
            default:
              taskType = 1;
          }

          // Use standardized color code format
          final colorCode = getStandardizedColorCode(taskType);

          // Check if we have a task ID for this date
          if (taskIds.containsKey(eventDate)) {
            // Update existing task
            await _calendarDatabaseService.updateCalendarTask(
              taskId: taskIds[eventDate]!,
              taskType: taskType,
              description: description,
              colorCode: colorCode,
            );
          } else {
            // Create new task
            final result = await _calendarDatabaseService.saveCalendarTask(
              taskDate: eventDate,
              taskType: taskType,
              description: description,
              colorCode: colorCode,
              theme: 'happy_couple',
            );

            // Store the task ID if successful
            if (result['success'] && result['task'] != null) {
              taskIds[eventDate] = result['task']['id'];
            }
          }
        }
      }

      debugPrint('Sync with database completed');
      _forceRefresh(); // Force a refresh after syncing
    } catch (e) {
      debugPrint('Error syncing with database: $e');
    }
  }

  // Method to track activity in recent activities
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Happy Couple Theme Calendar',
        imagePath: 'assets/couple_calender/couple1.png',
        timestamp: DateTime.now(),
        routeName: HappyCoupleThemeCalendarApp.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }
}
