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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:math';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';

class AnimalThemeCalendarApp extends StatefulWidget {
  final int monthIndex;
  final String? eventId;
  final bool showEvents;

  const AnimalThemeCalendarApp({
    super.key,
    required this.monthIndex,
    this.eventId,
    this.showEvents = false,
  });

  // Add route name to make navigation easier
  static const routeName = '/animal-theme-calendar';

  @override
  State<AnimalThemeCalendarApp> createState() => _AnimalThemeCalendarAppState();
}

class _AnimalThemeCalendarAppState extends State<AnimalThemeCalendarApp>
    with WidgetsBindingObserver, ActivityTrackerMixin {
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
  int currentColorIndex = 0;

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

  // Declare the taskIds variable with the correct type
  Map<DateTime, Map<String, int>> taskIds = {};

  // Add notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // Add timer for updating countdowns
  Timer? _countdownTimer;

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
      debugPrint('📱 Loading events from local storage (SharedPreferences)');
      await _loadSavedDates();
      debugPrint(
          '📊 Loaded ${events.length} dates with ${_countTotalEvents()} events from local storage');

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

        debugPrint(
            '🔄 Connected to internet and logged in, syncing with database');
        // Load from database
        await _loadEventsFromDatabase();

        if (mounted) {
          setState(() {
            _isLoadingData = false;
          });
        }
      } else {
        if (!_isConnected) {
          debugPrint(
              '📴 No internet connection, using cached data from local storage');
        } else if (!_isUserLoggedIn()) {
          debugPrint(
              '👤 User not logged in, using cached data from local storage');
        }
      }

      // Listen for connectivity changes
      Connectivity().onConnectivityChanged.listen((result) {
        final wasConnected = _isConnected;
        _isConnected = (result != ConnectivityResult.none);

        // If connection is restored and user is logged in, sync with database
        if (!wasConnected && _isConnected && _isUserLoggedIn()) {
          debugPrint('🔄 Internet connection restored, syncing with database');
          _syncWithDatabase();
        }
      });
    } catch (e) {
      debugPrint('❌ Error during initialization: $e');
      // Even if there's an error, we should show the UI
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to count total events across all dates
  int _countTotalEvents() {
    int total = 0;
    events.forEach((date, eventsList) {
      total += eventsList.length;
    });
    return total;
  }

  @override
  void initState() {
    super.initState();

    // Initialize the database service
    _calendarDatabaseService =
        CalendarDatabaseService(baseUrl: ApiConfig.baseUrl);

    // Set the initial state based on constructor parameters
    _currentMonthIndex = widget.monthIndex;

    // Set the selected date based on the month
    final now = DateTime.now();
    if (_currentMonthIndex == now.month - 1) {
      // If current month is selected, show today's date
      _selectedDate = DateTime(2025, _currentMonthIndex + 1, now.day);
    } else {
      // For other months, show the first day of the month
      _selectedDate = DateTime(2025, _currentMonthIndex + 1, 1);
    }

    // Initialize HomeWidget with proper configuration
    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    HomeWidget.registerBackgroundCallback(backgroundCallback);

    // Setup method channel for widget events
    const channel = MethodChannel('com.reconstrect.visionboard/widget');
    channel.setMethodCallHandler(_handleMethodCall);

    // Initialize notifications
    _initializeNotifications();

    // Request notification permissions explicitly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsWithDialog();
    });

    // Start the initialization process
    _initializeCalendar();

    // Start timer for countdown updates
    _startCountdownTimer();

    // Add app lifecycle state listener to refresh events when app resumes
    WidgetsBinding.instance.addObserver(this);

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Method to track activity in recent activities
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Animal Theme Calendar',
        imagePath: 'assets/animal_calendar/animaltheme-1.png',
        timestamp: DateTime.now(),
        routeName: AnimalThemeCalendarApp.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Method to request notification permissions with dialog
  Future<void> _requestNotificationPermissionsWithDialog() async {
    final hasPermission = await _checkNotificationPermissions();

    if (!hasPermission && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Enable Notifications'),
          content: Text(
            'To get reminders for your events, please allow notifications. This helps you stay on top of your schedule.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final status = await _requestPermissions();
                if (!status && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Please enable notifications in settings for reminders'),
                      action: SnackBarAction(
                        label: 'Settings',
                        onPressed: _openNotificationSettings,
                      ),
                    ),
                  );
                }
              },
              child: Text('Enable'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    // Remove the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Add method to start countdown timer
  void _startCountdownTimer() {
    // Update countdowns every minute
    _countdownTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will rebuild all widgets with updated countdowns
        });
      }
    });
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
          _loadSavedDates().then((_) {
            _buildFullCalendarView();
          });
        });
      }
      return true;
    } else if (call.method == 'navigateTo') {
      final route = call.arguments as String;
      Navigator.pushNamed(context, route);
      return true;
    } else if (call.method == 'notificationTapped') {
      // Handle notification tap events from system
      final monthIndex =
          call.arguments['month_index'] as int? ?? DateTime.now().month - 1;
      final day = call.arguments['day'] as int? ?? 1;

      final now = DateTime.now();
      int selectedDay = day;

      // If it's the current month and no specific day was provided, use today's date
      if (monthIndex == now.month - 1 && call.arguments['day'] == null) {
        selectedDay = now.day;
      }

      setState(() {
        showFullCalendar = true;
        _currentMonthIndex = monthIndex;
        _selectedDate = DateTime(2025, monthIndex + 1, selectedDay);
      });

      // Reload data and refresh UI
      _loadSavedDates().then((_) {
        _forceRefresh();
      });

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
          'AnimalThemeCalendar: Loaded user info - Name: $_userName, Email: $_userEmail');

      // Set user info in the database service
      if (_userName != null &&
          _userName!.isNotEmpty &&
          _userEmail != null &&
          _userEmail!.isNotEmpty) {
        _calendarDatabaseService.setUserInfo(_userName!, _userEmail!);

        // Auth token no longer needed - Supabase handles authentication automatically

        debugPrint('AnimalThemeCalendar: User info set in database service');
      } else {
        // If no user info found, show a snackbar message
        debugPrint('AnimalThemeCalendar: No user info found');
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
        title: const Text('Login Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Your Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                await UserService.instance.saveUserInfo(
                  userName: nameController.text,
                  email: emailController.text,
                );

                Navigator.pop(context);

                // Reload user info and sync with database
                await _loadUserInfo();
                if (_isConnected) {
                  await _loadEventsFromDatabase();
                }
              }
            },
            child: const Text('Save'),
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

      // Save to SharedPreferences and widget
      await Future.wait([
        prefs.setString('animal.calendar_theme_2025', jsonData),
        prefs.setString('animal.calendar_data', jsonData),
        HomeWidget.saveWidgetData('animal.calendar_data', jsonData),
        HomeWidget.saveWidgetData('animal.calendar_theme_2025', jsonData),
      ]);

      await HomeWidget.updateWidget(
        name: 'CalendarThemeWidget',
        iOSName: 'CalendarThemeWidget',
        qualifiedAndroidName: 'com.reconstrect.visionboard.CalendarThemeWidget',
      );

      debugPrint('Calendar data saved for widget display');
    } catch (e) {
      debugPrint('Error saving dates for widget: $e');
    }
  }

  // Modified _loadSavedDates method
  Future<void> _loadSavedDates() async {
    try {
      debugPrint('📂 Attempting to load saved dates from SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString('animal.calendar_theme_2025');
      final String? savedEventsData = prefs.getString('animal.calendar_events');

      int loadedDates = 0;
      int loadedEvents = 0;

      if (savedEventsData != null && savedEventsData.isNotEmpty) {
        // Parse full event data which contains all event details
        try {
          debugPrint(
              '📋 Found full event data in SharedPreferences, parsing...');
          final Map<String, dynamic> decodedEvents =
              json.decode(savedEventsData);

          // Create a temporary map to hold the parsed events
          final Map<DateTime, List<Map<String, String>>> parsedEvents = {};

          decodedEvents.forEach((dateStr, eventsList) {
            try {
              final date = normalizeDate(DateTime.parse(dateStr));
              parsedEvents[date] = List<Map<String, String>>.from(
                  eventsList.map((e) => Map<String, String>.from(e)));
              loadedEvents += (eventsList as List<dynamic>).length;
              loadedDates++;
            } catch (e) {
              debugPrint('❌ Error parsing date in full events: $dateStr - $e');
            }
          });

          // Only clear existing events after successful parsing
          if (parsedEvents.isNotEmpty) {
            events.clear();
            events.addAll(parsedEvents);
            debugPrint(
                '✅ Successfully loaded $loadedDates dates with $loadedEvents events from full events data');
          }
        } catch (e) {
          debugPrint('❌ Error loading full events data: $e');
        }
      } else if (savedData != null && savedData.isNotEmpty) {
        // Fall back to legacy format if full events not available
        try {
          debugPrint(
              '📋 Found legacy event data in SharedPreferences, parsing...');
          final Map<String, dynamic> decodedData = json.decode(savedData);

          // Create a temporary map for parsed events
          final Map<DateTime, List<Map<String, String>>> parsedEvents = {};

          decodedData.forEach((dateStr, category) {
            try {
              final date = normalizeDate(DateTime.parse(dateStr));
              parsedEvents[date] = [
                {'category': category, 'title': category, 'type': category}
              ];
              loadedEvents++;
              loadedDates++;
            } catch (e) {
              debugPrint('❌ Error parsing date: $dateStr - $e');
            }
          });

          // Only clear after successful parsing
          if (parsedEvents.isNotEmpty) {
            events.clear();
            events.addAll(parsedEvents);
            debugPrint(
                '✅ Successfully loaded $loadedDates dates with $loadedEvents events from legacy format');
          }
        } catch (e) {
          debugPrint('❌ Error parsing legacy data: $e');
        }
      } else {
        debugPrint('ℹ️ No saved calendar data found in SharedPreferences');
      }

      // Properly update the UI after loading events
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('❌ Error loading dates from SharedPreferences: $e');
    }
  }

  Future<void> _takeScreenshotAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/animal_theme_calendar_2025.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'My Animal Theme Calendar 2025');
    } catch (e) {
      debugPrint('Error sharing calendar: $e');
    }
  }

  Widget _buildMonthCard(String month, int monthIndex) {
    return SizedBox(
      height: 450,
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/animal_calendar/animaltheme-${monthIndex + 1}.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: _buildCalendarGrid(month, monthIndex + 1),
                  ),
                ),
              ],
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

                      // Set selected date based on whether this is the current month
                      final now = DateTime.now();
                      if (monthIndex == now.month - 1) {
                        // If current month, show today's date
                        _selectedDate = DateTime(2025, monthIndex + 1, now.day);
                      } else {
                        // For other months, show the first day
                        _selectedDate = DateTime(2025, monthIndex + 1, 1);
                      }

                      Future.delayed(Duration.zero, () {
                        _showEventDialog();
                      });
                    });
                  }, // Even smaller icon
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  child: const Icon(Icons.add,
                      size: 14), // Optional: reduced elevation for better fit
                ),
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 8),
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

              // Get events for this date using our helper method
              final dayEvents = getEventsForDay(date);
              // Only log days with events to reduce noise
              if (dayEvents.isNotEmpty) {
                debugPrint('Day $day has ${dayEvents.length} events');
              }
              Color? backgroundColor = Colors.white;

              // If there are events, use the color of the first event's category
              if (dayEvents.isNotEmpty) {
                final category = dayEvents.first['category'] ?? 'Personal';
                backgroundColor = categoryColors[category];
                debugPrint('Day $day category: $category');
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

  // Initialize notifications - simplified version
  Future<void> _initializeNotifications() async {
    try {
      await _initializeNotificationPermissions();

      // Initialize platform-specific details
      const androidInitializationSettings =
          AndroidInitializationSettings('@drawable/notification_icon');
      const iosInitializationSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: androidInitializationSettings,
        iOS: iosInitializationSettings,
      );

      // Initialize the plugin with settings
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      _notificationsInitialized = true;
      debugPrint('Notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Handle when notification is tapped
  void _handleNotificationResponse(NotificationResponse response) async {
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        debugPrint('Notification payload: $data');

        // Load all saved events to ensure they're in memory
        await _loadSavedDates();

        // Extract payload data
        final int monthIndex = data['month_index'] ?? 0;
        final int day = data['day'] ?? 1;

        // Navigate to the specified month/day
        if (mounted) {
          setState(() {
            _currentMonthIndex = monthIndex;
            // Select the specific day
            _selectedDate = DateTime(_selectedDate.year, monthIndex + 1, day);
          });

          // Trigger save to ensure data consistency
          await _saveEvents();

          // Show event dialog for this day if needed
          Future.delayed(Duration(milliseconds: 500), () {
            _showEventsForDay(day);
          });
        }
      } catch (e) {
        debugPrint('Error processing notification payload: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload events when app is resumed to ensure all data is fresh
      _loadSavedDates().then((_) {
        if (mounted) {
          setState(() {
            // Refresh UI with loaded data
          });
        }
      });
    } else if (state == AppLifecycleState.paused) {
      // Save events when app is paused to ensure no data loss
      _saveEvents();
    }
  }

  // Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final settings = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return settings ?? false;
    }
    return false;
  }

  // Schedule notification for event
  Future<void> _scheduleNotification(DateTime eventDate, String title,
      String description, int reminderMinutes) async {
    if (!_notificationsInitialized) {
      await _initializeNotifications();
    }

    try {
      // Create notification time
      final now = tz.TZDateTime.now(tz.local);
      final notificationTime = tz.TZDateTime.from(
        eventDate.subtract(Duration(minutes: reminderMinutes)),
        tz.local,
      );

      // Only schedule if it's in the future
      if (notificationTime.isAfter(now)) {
        // Create a unique ID for this notification
        final monthIndex = eventDate.month - 1;
        final id =
            eventDate.day + (monthIndex * 100) + (reminderMinutes * 10000);

        // Create notification details
        final androidDetails = AndroidNotificationDetails(
          'calendar_events',
          'Calendar Events',
          channelDescription: 'Notifications for calendar events',
          importance: Importance.high,
          priority: Priority.high,
          largeIcon: const DrawableResourceAndroidBitmap(
              '@drawable/notification_icon'), // Add colored app icon for expanded notification
        );

        final iosDetails = const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        // Schedule notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          description,
          notificationTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: json.encode({
            'month_index': eventDate.month - 1,
            'day': eventDate.day,
            'notification_id': id,
            'event_type': 'calendar',
            'title': title,
            'description': description,
          }),
        );

        debugPrint(
            'Scheduled notification for: ${notificationTime.toString()}');

        // Save events to storage to ensure they're available when notification triggers
        await _saveEvents();
      } else {
        debugPrint('Cannot schedule notification in the past');
      }
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  // Schedule notification for exact time specified by user
  Future<void> _scheduleExactTimeNotification(DateTime notificationTime,
      DateTime eventTime, String title, String description) async {
    if (!_notificationsInitialized) {
      debugPrint('Initializing notifications for exact time notification');
      await _initializeNotifications();
    }

    try {
      // Get current device time
      final now = tz.TZDateTime.now(tz.local);
      debugPrint(
          'Notification set for exact time: ${notificationTime.toString()}');
      debugPrint('Event time: ${eventTime.toString()}');

      // Create a unique notification ID based on timestamp
      final int notificationId = eventTime.millisecondsSinceEpoch ~/ 1000;
      debugPrint('Notification ID: $notificationId');

      // Convert to timezone aware DateTime
      final tzNotificationTime = tz.TZDateTime.from(notificationTime, tz.local);

      // Only schedule if notification time is in the future
      if (tzNotificationTime.isAfter(now)) {
        // Create notification details with high importance
        final androidDetails = AndroidNotificationDetails(
          'calendar_channel',
          'Calendar Notifications',
          channelDescription: 'Notifications for calendar events',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          enableVibration: true,
          enableLights: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
        );

        final notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

        // Create rich payload with event details
        final payload = json.encode({
          'month_index': eventTime.month - 1,
          'day': eventTime.day,
          'notification_id': notificationId,
          'event_type': 'calendar',
          'notification_time': notificationTime.toIso8601String(),
          'event_time': eventTime.toIso8601String(),
          'title': title,
          'description': description,
        });

        // Schedule notification with exact timing
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          title,
          description,
          tzNotificationTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: payload,
        );

        debugPrint(
            '✓ Notification successfully scheduled for exact time: ${tzNotificationTime.toString()}');

        // Always save events to storage to ensure they're available when notification triggers
        await _saveEvents();

        // Show a confirmation message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Notification scheduled for ${notificationTime.hour}:${notificationTime.minute.toString().padLeft(2, '0')}'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        debugPrint(
            '⚠️ Cannot schedule notification in the past: ${tzNotificationTime.toString()}');

        // Show warning message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot schedule notification in the past'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error scheduling exact time notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Improved event dialog with modern design and better UX
  void _showEventDialog() {
    DateTime selectedDate = _selectedDate;
    final typeController = TextEditingController();
    String selectedCategory = 'Personal';
    TimeOfDay eventTime = TimeOfDay.now();
    bool isAllDay = false;

    // For animation
    final animationDuration = Duration(milliseconds: 20);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AnimatedContainer(
            duration: animationDuration,
            curve: Curves.easeInOut,
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with close button
                Container(
                  decoration: BoxDecoration(
                    color: categoryColors[selectedCategory],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Event',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '${selectedDate.day} ${months[selectedDate.month - 1]} 2025',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(20),
                    children: [
                      // Date selection
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2025, 1, 1),
                              lastDate: DateTime(2025, 12, 31),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary:
                                          categoryColors[selectedCategory]!,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            categoryColors[selectedCategory],
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: categoryColors[selectedCategory],
                                  size: 22,
                                ),
                                SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Date',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${selectedDate.day} ${months[selectedDate.month - 1]} 2025',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey.shade400,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Event title
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Details',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 12),
                              TextField(
                                controller: typeController,
                                style: TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Event description',
                                  hintStyle:
                                      TextStyle(color: Colors.grey.shade400),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color:
                                            categoryColors[selectedCategory]!),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                onChanged: (value) {
                                  trackTextInput('Task done', value: value);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Category selection with color preview
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedCategory,
                                      icon: Icon(Icons.arrow_drop_down),
                                      iconSize: 24,
                                      elevation: 16,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                      ),
                                      onChanged: (String? newValue) {
                                        setModalState(() {
                                          selectedCategory = newValue!;
                                        });
                                      },
                                      items: categoryColors.keys
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: categoryColors[value],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Text(value),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Time settings
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  "All Day Event",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16),
                                ),
                                value: isAllDay,
                                activeColor: categoryColors[selectedCategory],
                                onChanged: (value) {
                                  setModalState(() {
                                    isAllDay = value;
                                  });
                                },
                              ),

                              // Only show time picker if not all-day event
                              if (!isAllDay)
                                InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: eventTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: categoryColors[
                                                  selectedCategory]!,
                                            ),
                                            buttonTheme: ButtonThemeData(
                                              colorScheme: ColorScheme.light(
                                                primary: categoryColors[
                                                    selectedCategory]!,
                                              ),
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        eventTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color:
                                              categoryColors[selectedCategory],
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          eventTime.format(context),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Spacer(),
                                        Text(
                                          "Change",
                                          style: TextStyle(
                                            color: categoryColors[
                                                selectedCategory],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Notification settings
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active,
                                    color: categoryColors[selectedCategory],
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Notification',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),

                              // Simple notification text instead of dropdown
                              Text(
                                isAllDay
                                    ? 'You will be notified at 9:00 AM on the day before the event'
                                    : 'You will be notified at the exact time of the event',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Save button at bottom
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (typeController.text.isNotEmpty) {
                        // Set fixed notification timing without dropdown options
                        int reminderMinutes = 0;
                        String notificationHour =
                            isAllDay ? '9' : eventTime.hour.toString();
                        String notificationMinute =
                            isAllDay ? '0' : eventTime.minute.toString();
                        String dayOffset = isAllDay ? '-1' : '0';

                        // Create event data
                        final eventData = {
                          'title': selectedCategory,
                          'type': typeController.text,
                          'category': selectedCategory,
                          'is_all_day': isAllDay.toString(),
                          'event_hour':
                              isAllDay ? '9' : eventTime.hour.toString(),
                          'event_minute':
                              isAllDay ? '0' : eventTime.minute.toString(),
                          'has_custom_notification': 'true',
                          'notification_hour': notificationHour,
                          'notification_minute': notificationMinute,
                          'reminder_minutes': reminderMinutes.toString(),
                          'notification_day_offset': dayOffset,
                        };

                        debugPrint(
                            'Creating event with category: $selectedCategory');

                        // Add event with notification scheduling enabled
                        _addEventWithExactNotification(selectedDate, eventData,
                            scheduleNotification: true);
                        Navigator.pop(context);

                        // Show confirmation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                                bottom: 10, left: 10, right: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: categoryColors[selectedCategory],
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  isAllDay
                                      ? 'All-day event added'
                                      : 'Event added for ${eventTime.format(context)}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        // Show error if description is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                                bottom: 10, left: 10, right: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            backgroundColor: Colors.red.shade400,
                            content: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  'Please enter an event description',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColors[selectedCategory],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Save Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Calculate appropriate reminder time based on event category and description
  int _calculateReminderTime(Map<String, String> event) {
    final category = event['category'] ?? 'Personal';
    final description = event['type']?.toLowerCase() ?? '';
    final isAllDay = event['is_all_day'] == 'true';

    // Customize reminder times based on category and keywords in description
    if (category == 'Health') {
      if (description.contains('appointment') ||
          description.contains('doctor') ||
          description.contains('checkup')) {
        return 120; // 2 hours for medical appointments
      }
      return 60; // 1 hour for other health events
    } else if (category == 'Professional') {
      if (description.contains('meeting') ||
          description.contains('interview') ||
          description.contains('presentation')) {
        return 60; // 1 hour for important work events
      }
      if (description.contains('deadline')) {
        return 24 * 60; // 1 day for deadlines
      }
      return 30; // 30 minutes for other work events
    } else if (category == 'Finance') {
      if (description.contains('payment') ||
          description.contains('bill') ||
          description.contains('due')) {
        return 24 * 60; // 1 day for payments
      }
      return 120; // 2 hours for other financial events
    }
    // Personal events
    else {
      if (description.contains('birthday') ||
          description.contains('anniversary')) {
        return 24 * 60; // 1 day for birthdays/anniversaries
      }
      if (description.contains('party') ||
          description.contains('dinner') ||
          description.contains('lunch')) {
        return 120; // 2 hours for social events
      }
      if (isAllDay) {
        return 12 * 60; // 12 hours for all-day personal events
      }
      return 60; // 1 hour for other personal events
    }
  }

  // Modified _addEvent method to save to database and schedule notification
  // This method is kept for reference but is no longer used
  // ignore: unused_element, deprecated_member_use_from_same_package
  @Deprecated("Use _addEventWithImprovedReminder instead")
  void _addEvent(DateTime date, Map<String, String> event) {
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

    // Schedule notification if reminder time is set - handle this outside setState
    if (event.containsKey('reminder_minutes')) {
      final reminderMinutes =
          int.tryParse(event['reminder_minutes'] ?? '0') ?? 0;
      if (reminderMinutes > 0) {
        _checkAndScheduleNotification(normalizedDate, event, reminderMinutes);
      }
    }
  }

  // Add a method to check permissions and schedule notification
  Future<void> _checkAndScheduleNotification(
      DateTime date, Map<String, String> event, int reminderMinutes) async {
    final hasPermission = await _checkNotificationPermissions();

    if (!hasPermission) {
      // Show dialog prompting to enable notifications
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Notifications Disabled'),
            content: Text(
                'Notifications are disabled for this app. Would you like to enable them to receive reminders?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Not Now'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openNotificationSettings();
                },
                child: Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    } else {
      // Create a DateTime with the desired time for notification
      final notificationTime = tz.TZDateTime.from(
        date.subtract(Duration(minutes: reminderMinutes)),
        tz.local,
      );

      _scheduleNotification(
        notificationTime,
        '${event['category']} Event',
        event['type'] ?? 'Event',
        reminderMinutes,
      );
    }
  }

  // Method to save event to database
  Future<void> _saveEventToDatabase(
      DateTime date, Map<String, String> event) async {
    try {
      // Ensure date is normalized
      final normalizedDate = normalizeDate(date);
      final category = event['category'] ?? 'Personal';
      final description = event['type'] ?? 'Event';
      final isAllDay = event['is_all_day'] == 'true';

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

      // Get event time for inclusion in description
      final eventHour = int.tryParse(event['event_hour'] ?? '9') ?? 9;
      final eventMinute = int.tryParse(event['event_minute'] ?? '0') ?? 0;
      final timeString = isAllDay
          ? '[ALL_DAY]'
          : '[${eventHour.toString().padLeft(2, '0')}:${eventMinute.toString().padLeft(2, '0')}]';

      // Add a timestamp to make each task unique
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      // Include color code in the description instead of using separate parameter
      final colorCodeString = '[COLOR-$taskType]';

      // Create a formatted description for this task (without DATE prefix)
      final taskDescription =
          '$timeString $colorCodeString $description #$timestamp';

      debugPrint('📝 Creating task: $taskDescription');

      // Fetch all existing tasks to find if we already have one for this date
      final existingTaskResult =
          await _calendarDatabaseService.getCalendarTasks(
        theme: 'animal',
      );

      // Variables to track if we found an existing task for this date
      String finalDescription = taskDescription;
      int existingTaskId = -1;
      bool existingTaskFound = false;

      debugPrint(
          '🔍 Searching for existing tasks on ${normalizedDate.toString()}');

      if (existingTaskResult['success'] == true &&
          existingTaskResult.containsKey('tasks')) {
        final tasks = existingTaskResult['tasks'] as List;
        debugPrint('📋 Retrieved ${tasks.length} tasks from database');

        // Iterate through all tasks to find one matching our date
        for (var task in tasks) {
          final taskDateStr = task['task_date'] as String;
          var taskDate = normalizeDate(DateTime.parse(taskDateStr));
          final description = task['task_description'] as String;
          final taskId = task['id'] as int;

          // Check for explicit DATE tag that matches our date
          DateTime? explicitDate;
          if (description.contains(RegExp(r'\[DATE-\d{4}-\d{2}-\d{2}\]'))) {
            final dateMatch = RegExp(r'\[DATE-(\d{4})-(\d{2})-(\d{2})\]')
                .firstMatch(description);
            if (dateMatch != null) {
              try {
                final year = int.parse(dateMatch.group(1)!);
                final month = int.parse(dateMatch.group(2)!);
                final day = int.parse(dateMatch.group(3)!);
                explicitDate = normalizeDate(DateTime(year, month, day));
              } catch (e) {
                debugPrint('Error parsing date from description: $e');
              }
            }
          }

          // Use explicit date from tag if available, otherwise use task date
          final actualDate = explicitDate ?? taskDate;

          // If this task is for our target date
          if (actualDate.year == normalizedDate.year &&
              actualDate.month == normalizedDate.month &&
              actualDate.day == normalizedDate.day) {
            debugPrint(
                '✅ Found existing task for ${normalizedDate.toString()}: $taskId');

            // Remove the DATE prefix if it exists
            String cleanedDescription = description;
            if (cleanedDescription
                .contains(RegExp(r'\[DATE-\d{4}-\d{2}-\d{2}\]'))) {
              cleanedDescription = cleanedDescription.replaceFirst(
                  RegExp(r'\[DATE-\d{4}-\d{2}-\d{2}\]\s*'), '');
            }

            // Append our new task to the existing one
            finalDescription = '$cleanedDescription::$taskDescription';
            existingTaskId = taskId;
            existingTaskFound = true;

            debugPrint(
                '🔄 Will update existing task with concatenated data: ${finalDescription.substring(0, min(50, finalDescription.length))}...');
            break;
          }
        }
      }

      // Calculate a unique date for storage by adding hour offset
      final Random random = Random();
      int hourOffset = random.nextInt(23) + 1; // 1 to 23 hours

      final modifiedDate = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        hourOffset, // Add random hours to make date unique but keep same day
      );

      debugPrint(
          '📅 Using modified date for storage: ${modifiedDate.toString()}');

      // If we found an existing task, update it
      if (existingTaskFound) {
        debugPrint('🔄 Updating existing task ID: $existingTaskId');

        final result = await _calendarDatabaseService.updateCalendarTask(
          taskId: existingTaskId,
          description: finalDescription,
        );

        if (result['success']) {
          debugPrint('✅ Task updated successfully');

          // Make sure we have this task ID in our map
          if (!taskIds.containsKey(normalizedDate)) {
            taskIds[normalizedDate] = {};
          }
          taskIds[normalizedDate]![timestamp] = existingTaskId;

          // Show success feedback
          if (_isUserLoggedIn() && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task updated in cloud'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          debugPrint('❌ Failed to update task: ${result['message']}');

          if (_isUserLoggedIn() && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update task in cloud'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
      // Otherwise create a new task
      else {
        debugPrint('➕ Creating new task record');

        final result = await _calendarDatabaseService.saveCalendarTask(
          taskDate: modifiedDate,
          taskType: taskType,
          description: finalDescription,
          colorCode: 'selected-color-$taskType',
        );

        if (result['success'] == true && result.containsKey('id') ||
            (result.containsKey('task') && result['task'] != null)) {
          // Get the task ID either directly or from the task object
          final taskId =
              result.containsKey('id') ? result['id'] : result['task']['id'];

          debugPrint('✅ New task created with ID: $taskId');

          // Store the task ID
          if (!taskIds.containsKey(normalizedDate)) {
            taskIds[normalizedDate] = {};
          }
          taskIds[normalizedDate]![timestamp] = taskId;

          // Show success feedback
          if (_isUserLoggedIn() && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Task synced to cloud'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          debugPrint('❌ Failed to save task: ${result['message']}');

          if (_isUserLoggedIn() && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to sync task to cloud'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error saving event to database: $e');
    }
  }

  // Helper function for min value
  int min(int a, int b) {
    return a < b ? a : b;
  }

  // Modified method to handle event deletion
  Future<void> _deleteEvent(DateTime date, int index) async {
    trackClick('animal_calendar_event_deleted');
    // Normalize the date to remove time components
    final normalizedDate = normalizeDate(date);

    // Get the event to be deleted for identifying which task to remove from the database
    Map<String, String>? eventToDelete;
    if (events.containsKey(normalizedDate) &&
        events[normalizedDate]!.length > index) {
      eventToDelete = events[normalizedDate]![index];
    }

    // Cancel notification before removing event
    if (eventToDelete != null &&
        eventToDelete.containsKey('reminder_minutes')) {
      // Create a DateTime with the reminder time for canceling the notification
      final reminderHour =
          int.tryParse(eventToDelete['reminder_hour'] ?? '9') ?? 9;
      final reminderMinute =
          int.tryParse(eventToDelete['reminder_minute'] ?? '0') ?? 0;
      final notificationTime = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        reminderHour,
        reminderMinute,
      );
      await _cancelNotification(notificationTime);
    }

    // Update local UI state first
    setState(() {
      if (events.containsKey(normalizedDate)) {
        events[normalizedDate]!.removeAt(index);
        if (events[normalizedDate]!.isEmpty) {
          events.remove(normalizedDate);
        }
      }
    });

    // Save updated events to local storage
    _saveEvents();
    _saveDates();

    // Delete from database if connected and logged in
    if (_isConnected &&
        _isUserLoggedIn() &&
        taskIds.containsKey(normalizedDate) &&
        taskIds[normalizedDate]!.isNotEmpty &&
        eventToDelete != null) {
      try {
        debugPrint('Deleting event from database for user: $_userName');

        // Find the database task for this date
        final taskId = taskIds[normalizedDate]!.values.first;

        // If this is the only event for this date, delete the entire record
        if (!events.containsKey(normalizedDate) ||
            events[normalizedDate]!.isEmpty) {
          final result = await _calendarDatabaseService.deleteCalendarTask(
            taskId: taskId,
          );

          if (result['success']) {
            debugPrint('Event deleted from database: $taskId');
            taskIds.remove(normalizedDate);
          } else {
            debugPrint(
                'Failed to delete event from database: ${result['message']}');
          }
        } else {
          // If there are still other events for this date, we need to update the record
          // by removing only this specific task from the concatenated description

          // Get the current database record
          final existingTaskResult =
              await _calendarDatabaseService.getCalendarTasks(
            theme: 'animal',
          );

          if (existingTaskResult['success'] == true &&
              existingTaskResult.containsKey('tasks')) {
            final tasks = existingTaskResult['tasks'] as List;

            for (var task in tasks) {
              final id = task['id'] as int;
              if (id == taskId) {
                final existingDescription = task['task_description'] as String;
                final taskDescriptions = existingDescription.split('::');

                // Find the task to delete based on matching description and time
                bool taskFound = false;
                final cleanType = eventToDelete['type'] ?? '';
                final eventHour = eventToDelete['event_hour'] ?? '';
                final eventMinute = eventToDelete['event_minute'] ?? '';
                final timePattern =
                    '[${eventHour.padLeft(2, '0')}:${eventMinute.padLeft(2, '0')}]';

                // Filter out the task that matches our event to delete
                final updatedTasks = taskDescriptions.where((taskDesc) {
                  // Skip empty tasks
                  if (taskDesc.trim().isEmpty) return true;

                  // Check if this task matches the one we want to delete
                  bool matchesTime = taskDesc.contains(timePattern);
                  bool matchesDescription = taskDesc.contains(cleanType);

                  // If this matches both the time and type, mark for removal
                  if (matchesTime && matchesDescription && !taskFound) {
                    taskFound = true;
                    return false; // Filter this one out
                  }
                  return true; // Keep all others
                }).toList();

                if (taskFound) {
                  // If we found the task to delete, update the database with the reduced task list
                  if (updatedTasks.isEmpty) {
                    // If no tasks left, delete the entire record
                    final result =
                        await _calendarDatabaseService.deleteCalendarTask(
                      taskId: taskId,
                    );

                    if (result['success']) {
                      debugPrint(
                          'No tasks left, deleted entire record: $taskId');
                      taskIds.remove(normalizedDate);
                    }
                  } else {
                    // Otherwise, update with the remaining tasks
                    final updatedDescription = updatedTasks.join('::');

                    final result =
                        await _calendarDatabaseService.updateCalendarTask(
                      taskId: taskId,
                      description: updatedDescription,
                    );

                    if (result['success']) {
                      debugPrint('Updated task in database: $taskId');
                    } else {
                      debugPrint(
                          'Failed to update task in database: ${result['message']}');
                    }
                  }
                }
                break;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error deleting event from database: $e');
      }
    }
  }

  // Updated _buildEventsList to filter events by current month
  Widget _buildEventsList() {
    final currentMonthEvents = events.entries
        .where((entry) => entry.key.month == _currentMonthIndex + 1)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: currentMonthEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No events for ${months[_currentMonthIndex]}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddEventDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _eventScrollController,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              itemCount: currentMonthEvents.length,
              itemBuilder: (context, dateIndex) {
                final date = currentMonthEvents[dateIndex].key;
                final dayEvents = currentMonthEvents[dateIndex].value;
                final dayOfWeek = [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun'
                ][date.weekday - 1];

                return Column(
                  children: [
                    if (dateIndex > 0)
                      Divider(
                          height: 32,
                          thickness: 1,
                          color: Colors.grey.shade200,
                          indent: 70,
                          endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Day indicator
                          SizedBox(
                            width: 50,
                            child: Column(
                              children: [
                                Text(
                                  dayOfWeek,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: date.day == DateTime.now().day &&
                                            date.month == DateTime.now().month
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: date.day == DateTime.now().day &&
                                                date.month ==
                                                    DateTime.now().month
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Event list for the day
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dayEvents.asMap().entries.map((entry) {
                                final eventIndex = entry.key;
                                final event = entry.value;

                                // Get the category from 'category' field, falling back to checking color code if needed
                                String category = event['category'] ?? '';

                                // If category is empty, try to extract from color code in description
                                if (category.isEmpty && event['type'] != null) {
                                  final description = event['type'] ?? '';
                                  final colorCodeMatch =
                                      RegExp(r'\[COLOR-(\d+)\]')
                                          .firstMatch(description);
                                  if (colorCodeMatch != null &&
                                      colorCodeMatch.group(1) != null) {
                                    final typeFromDesc =
                                        int.parse(colorCodeMatch.group(1)!);
                                    switch (typeFromDesc) {
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
                                    }
                                    debugPrint(
                                        'Extracted category $category from color code: COLOR-$typeFromDesc');
                                  }
                                }

                                // If still empty, default to 'Personal'
                                if (category.isEmpty) {
                                  category = 'Personal';
                                }

                                // Set title to category if it's missing
                                if (event['title'] == null ||
                                    event['title']!.isEmpty) {
                                  event['title'] = category;
                                }

                                debugPrint(
                                    'Event category: $category, title: ${event['title']}');

                                final backgroundColor =
                                    categoryColors[category] ?? Colors.grey;
                                final isAllDay = event['is_all_day'] == 'true';
                                final eventHour =
                                    int.tryParse(event['event_hour'] ?? '9') ??
                                        9;
                                final eventMinute = int.tryParse(
                                        event['event_minute'] ?? '0') ??
                                    0;

                                final eventTime = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  eventHour,
                                  eventMinute,
                                );

                                final now = DateTime.now();
                                final bool isExpired = isAllDay
                                    ? now.isAfter(DateTime(date.year,
                                        date.month, date.day, 23, 59))
                                    : now.isAfter(eventTime);

                                return GestureDetector(
                                  // When tapped, do nothing - just prevents the slide from being triggered too easily
                                  onTap: () {},
                                  child: Slidable(
                                    key: Key('${date.toString()}_$eventIndex'),
                                    endActionPane: ActionPane(
                                      motion: const ScrollMotion(),
                                      extentRatio: 0.25,
                                      children: [
                                        SlidableAction(
                                          onPressed: (context) {
                                            // First update the UI state
                                            setState(() {
                                              final normalizedDate =
                                                  normalizeDate(date);
                                              events[normalizedDate]!
                                                  .removeAt(eventIndex);
                                              if (events[normalizedDate]!
                                                  .isEmpty) {
                                                events.remove(normalizedDate);
                                              }
                                            });

                                            // Then perform the backend operations
                                            _deleteEvent(date, eventIndex);
                                          },
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete_outline,
                                          autoClose: true,
                                          padding: EdgeInsets.zero,
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.only(
                                          left: 8, top: 8, bottom: 8, right: 0),
                                      decoration: BoxDecoration(
                                        color: backgroundColor
                                            .withOpacity(isExpired ? 0.6 : 1.0),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: backgroundColor
                                                .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    event['title'] ?? '',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      decoration: isExpired
                                                          ? TextDecoration
                                                              .lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    _formatTime12Hour(event),
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              event['type'] ?? '',
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontSize: 14,
                                                decoration: isExpired
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                            if (event.containsKey(
                                                    'reminder_minutes') &&
                                                ((int.tryParse(event[
                                                                'reminder_minutes'] ??
                                                            '0') ??
                                                        0) >
                                                    0))
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isExpired
                                                          ? Icons.event_busy
                                                          : Icons
                                                              .notifications_active,
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      size: 14,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      isExpired
                                                          ? 'Event passed'
                                                          : 'Reminder set',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
        title: const Text('Animal Theme Calendar 2025'),
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
          // Main content (even when loading, show at least the UI structure)
          showFullCalendar
              ? _buildFullCalendarView()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Screenshot(
                          controller: screenshotController,
                          child: Container(
                            color: Colors.white,
                            child: _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : GridView.builder(
                                    padding: const EdgeInsets.all(6),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.55,
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
                      if (!_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16.0),
                          child: ElevatedButton.icon(
                            onPressed: _takeScreenshotAndShare,
                            icon: const Icon(Icons.share),
                            label: const Text('Download Calendar'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      if (!_isLoading)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 8.0),
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
                    ],
                  ),
                ),

          // Bottom loading indicator when refreshing data (not blocking the whole screen)
          if (_isLoadingData)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Loading calendar data...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Only show FAB when in full calendar view
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
        theme: 'animal',
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
            var taskDate = normalizeDate(DateTime.parse(taskDateStr));

            int taskType = task['task_type'] as int;
            final description = task['task_description'] as String;
            final taskId = task['id'] as int;

            // Check if the description has multiple tasks (separated by ::)
            final taskDescriptions = description.split('::');

            // Extract the actual date from the DATE tag if it exists in the first task
            DateTime actualDate = taskDate;
            if (taskDescriptions[0]
                .contains(RegExp(r'\[DATE-\d{4}-\d{2}-\d{2}\]'))) {
              final dateMatch = RegExp(r'\[DATE-(\d{4})-(\d{2})-(\d{2})\]')
                  .firstMatch(taskDescriptions[0]);
              if (dateMatch != null) {
                try {
                  final year = int.parse(dateMatch.group(1)!);
                  final month = int.parse(dateMatch.group(2)!);
                  final day = int.parse(dateMatch.group(3)!);
                  actualDate = normalizeDate(DateTime(year, month, day));
                  debugPrint(
                      'Found actual date in description: ${actualDate.toString()}');

                  // Remove the DATE tag from the first task description
                  taskDescriptions[0] = taskDescriptions[0].replaceFirst(
                      RegExp(r'\[DATE-\d{4}-\d{2}-\d{2}\]\s*'), '');
                } catch (e) {
                  debugPrint('Error parsing date from description: $e');
                }
              }
            }

            // Use the actual date instead of the storage date
            taskDate = actualDate;

            // Process each task separately
            for (String taskDescription in taskDescriptions) {
              // Skip empty tasks
              if (taskDescription.trim().isEmpty) continue;

              // Process this individual task
              int thisTaskType = taskType; // Start with the default task type

              // Check if color info is embedded in the description
              if (taskDescription.contains(RegExp(r'\[COLOR-\d+\]'))) {
                final colorMatch =
                    RegExp(r'\[COLOR-(\d+)\]').firstMatch(taskDescription);
                if (colorMatch != null && colorMatch.group(1) != null) {
                  final typeFromDesc = int.parse(colorMatch.group(1)!);
                  if (typeFromDesc >= 1 && typeFromDesc <= 4) {
                    // If found in description, prefer it over color_code field
                    thisTaskType = typeFromDesc;
                    debugPrint(
                        'Found color code in description: [COLOR-$typeFromDesc]');
                  }
                }
              }

              // Map task_type to category
              String category;
              switch (thisTaskType) {
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

              debugPrint(
                  'Mapped taskType $thisTaskType to category: $category');

              // Store in events map with normalized date
              if (!events.containsKey(taskDate)) {
                events[taskDate] = [];
              }

              // Parse time from description
              String eventTime = '9:00';
              bool isAllDay = false;
              if (taskDescription.contains('[ALL_DAY]')) {
                isAllDay = true;
              } else if (taskDescription.contains(RegExp(r'\[\d{2}:\d{2}\]'))) {
                final timeMatch =
                    RegExp(r'\[(\d{2}):(\d{2})\]').firstMatch(taskDescription);
                if (timeMatch != null) {
                  eventTime = '${timeMatch.group(1)}:${timeMatch.group(2)}';
                }
              }

              // Clean description - remove time, color code, and timestamp markers
              String cleanDescription = taskDescription
                  .replaceFirst(RegExp(r'\[\w+_DAY\]|\[\d{2}:\d{2}\]'), '')
                  .replaceFirst(RegExp(r'\[COLOR-\d+\]'), '')
                  .replaceFirst(RegExp(r'#\d+'), '')
                  .trim();

              // Extract hour and minute from time
              List<String> timeParts = eventTime.split(':');
              String eventHour = timeParts[0];
              String eventMinute = timeParts[1];

              // Extract task ID or timestamp for this individual task
              String taskIdKey = '';
              final timestampMatch =
                  RegExp(r'#(\d+)').firstMatch(taskDescription);
              if (timestampMatch != null && timestampMatch.group(1) != null) {
                taskIdKey = timestampMatch.group(1)!;
              }

              // Create event data map
              final eventData = {
                'category': category,
                'title':
                    category, // Also set title to category to ensure it's displayed correctly
                'type': cleanDescription,
                'is_all_day': isAllDay.toString(),
                'event_hour': eventHour,
                'event_minute': eventMinute,
                'task_id': taskId
                    .toString(), // Assign the main task ID to all subtasks
              };

              events[taskDate]!.add(eventData);
              processedCount++;
            }

            // Store the task ID with date - all tasks in this description share the same ID
            if (!taskIds.containsKey(taskDate)) {
              taskIds[taskDate] = {};
            }

            // Store the task ID under a key derived from the database ID
            taskIds[taskDate]![taskId.toString()] = taskId;
          } catch (e) {
            debugPrint('Error processing a task: $e');
          }
        }

        debugPrint('Processed $processedCount tasks successfully');

        // Save loaded database events to SharedPreferences for offline access
        if (processedCount > 0) {
          debugPrint(
              '📦 Saving loaded database tasks to SharedPreferences for offline access');
          await _saveEvents();
          await _saveDates();
          debugPrint(
              '✅ Database tasks saved to SharedPreferences successfully');
        }
      } catch (e) {
        debugPrint('Error processing tasks: $e');
      } finally {
        setState(() {
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading from database: $e');
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Method to update event in database - fix taskIds usage
  @pragma('vm:entry-point')
  Future<void> _updateEventInDatabase(DateTime eventDate, int index) async {
    if (!_isConnected || !_isUserLoggedIn()) return;

    try {
      // Check if we have this event in our taskIds
      final normalizedDate = normalizeDate(eventDate);
      if (taskIds.containsKey(normalizedDate) &&
          taskIds[normalizedDate]!.isNotEmpty) {
        // Get event details
        final event = events[normalizedDate]![index];
        final category = event['category'] ?? 'Personal';
        final description = event['type'] ?? 'Event';

        // Map category to task type
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

        // Get the first taskId for this date as a fallback
        final taskId = taskIds[normalizedDate]!.values.first;

        // Update task in database
        debugPrint('Updating event in database for user: $_userName');

        // Update existing task
        await _calendarDatabaseService.updateCalendarTask(
          taskId: taskId,
          taskType: taskType,
          description: description,
        );
      }
    } catch (e) {
      debugPrint('Error updating event in database: $e');
    }
  }

  // Helper method to force refresh
  void _forceRefresh() {
    if (mounted) {
      // Reload events from shared preferences
      _loadSavedDates().then((_) {
        debugPrint(
            'Events reloaded from storage: ${events.length} dates with events');
        setState(() {
          // Force rebuild of the UI
          debugPrint('Refreshing calendar grid with ${events.length} events');
        });
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

  // Save events to SharedPreferences
  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert DateTime keys to strings for JSON serialization
      final Map<String, dynamic> serializedEvents = {};
      events.forEach((date, eventsList) {
        final dateKey = date.toIso8601String();
        serializedEvents[dateKey] = eventsList;
      });

      final String eventsJson = json.encode(serializedEvents);

      // Save detailed events data
      await prefs.setString('animal.calendar_events', eventsJson);
      debugPrint(
          'Saved ${events.length} dates with events to SharedPreferences');

      // Also update the simplified data for the widget
      await _saveDates();
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
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

        // Save each event for this date
        for (int i = 0; i < eventsList.length; i++) {
          final event = eventsList[i];

          // Only save if it isn't already in the database
          final hasTaskId =
              taskIds.containsKey(eventDate) && taskIds[eventDate]!.isNotEmpty;

          // If we already have this event saved (has a task ID), then skip it
          if (hasTaskId && event.containsKey('task_id')) {
            debugPrint(
                'Skipping already synced event with task_id: ${event['task_id']}');
            continue;
          }

          debugPrint('Syncing event to database: ${event['type']}');

          // Use the _saveEventToDatabase method to ensure consistent saving
          await _saveEventToDatabase(eventDate, event);
        }
      }

      debugPrint('Sync with database completed');

      // Save synced database data to SharedPreferences for offline access
      debugPrint(
          '📦 Saving synced database data to SharedPreferences for offline access');
      await _saveEvents();
      await _saveDates();
      debugPrint('✅ Synced data saved to SharedPreferences successfully');

      _forceRefresh(); // Force a refresh after syncing
    } catch (e) {
      debugPrint('Error syncing with database: $e');
    }
  }

  // New simplified method to add event with proper reminder
  // ignore: unused_element
  void _addEventWithImprovedReminder(DateTime date, Map<String, String> event) {
    trackClick(
        'animal_calendar_event_added - ${event['category'] ?? 'Personal'}');

    // Normalize the date for storage
    final normalizedDate = normalizeDate(date);

    // Get event details
    final category = event['category'] ?? 'Personal';
    final description = event['type'] ?? 'Event';
    final isAllDay = event['is_all_day'] == 'true';

    // Calculate time
    final eventHour = int.tryParse(event['event_hour'] ?? '9') ?? 9;
    final eventMinute = int.tryParse(event['event_minute'] ?? '0') ?? 0;

    // Create a DateTime with the proper time
    final eventTime = DateTime(
      date.year,
      date.month,
      date.day,
      isAllDay ? 9 : eventHour, // Default to 9 AM for all-day events
      isAllDay ? 0 : eventMinute,
    );

    // Calculate appropriate reminder time based on category and description
    int reminderMinutes = _calculateReminderTime(event);

    setState(() {
      // Store the event
      if (!events.containsKey(normalizedDate)) {
        events[normalizedDate] = [];
      }

      // Add reminder information to the event
      final eventWithReminder = Map<String, String>.from(event);
      eventWithReminder['reminder_minutes'] = reminderMinutes.toString();

      // Add to events collection
      events[normalizedDate]!.add(eventWithReminder);

      // Save events to storage
      _saveEvents();
      _saveDates();
    });

    // Schedule the notification
    _scheduleNotification(
        eventTime, "$category Event", description, reminderMinutes);

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event added with reminder scheduled'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Cancel notification for event
  Future<void> _cancelNotification(DateTime eventDate) async {
    if (!_notificationsInitialized) return;

    try {
      final int notificationId = eventDate.millisecondsSinceEpoch ~/ 1000;
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('Notification canceled for ${eventDate.toString()}');
    } catch (e) {
      debugPrint('Error canceling notification: $e');
    }
  }

  // Helper method to get standardized color code from task type
  String getStandardizedColorCode(int taskType) {
    return 'selected-color-$taskType';
  }

  // Method to add event with exact notification time specified by user
  void _addEventWithExactNotification(DateTime date, Map<String, String> event,
      {bool scheduleNotification = true}) {
    trackClick(
        'animal_calendar_event_added_exact - ${event['category'] ?? 'Personal'}');
    // Normalize the date for storage
    final normalizedDate = normalizeDate(date);

    // Get event details
    final category = event['category'] ?? 'Personal';
    final description = event['type'] ?? 'Event';
    final isAllDay = event['is_all_day'] == 'true';
    final hasCustomNotification = event['has_custom_notification'] == 'true';

    // Make sure title matches category for consistent display
    event['title'] = category;

    // Get event time
    final eventHour = int.tryParse(event['event_hour'] ?? '9') ?? 9;
    final eventMinute = int.tryParse(event['event_minute'] ?? '0') ?? 0;

    // Create a DateTime with the proper time
    final eventTime = DateTime(
      date.year,
      date.month,
      date.day,
      isAllDay ? 9 : eventHour, // Default to 9 AM for all-day events
      isAllDay ? 0 : eventMinute,
    );

    // If custom notification is enabled, use the specified notification time
    DateTime? notificationTime;
    if (hasCustomNotification) {
      final notificationHour =
          int.tryParse(event['notification_hour'] ?? '9') ?? 9;
      final notificationMinute =
          int.tryParse(event['notification_minute'] ?? '0') ?? 0;

      notificationTime = DateTime(
        date.year,
        date.month,
        date.day,
        notificationHour,
        notificationMinute,
      );

      event['notification_time'] = notificationTime.toString();
    }

    setState(() {
      // Store the event
      if (!events.containsKey(normalizedDate)) {
        events[normalizedDate] = [];
      }

      // Add to events collection
      events[normalizedDate]!.add(event);

      // Save events to storage immediately
      _saveEvents(); // This now handles both events and widget data
    });

    // Schedule notification only if explicitly requested
    if (scheduleNotification &&
        hasCustomNotification &&
        notificationTime != null) {
      debugPrint(
          'Scheduling notification for exact time: ${notificationTime.toString()}');
      _scheduleExactTimeNotification(
          notificationTime, eventTime, "$category Event", description);
    }

    // Always save to database, regardless of notification status
    _saveEventToDatabase(date, event);

    // Show user feedback about cloud syncing if logged in
    if (_isUserLoggedIn() && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Syncing to cloud...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // Method to open notification settings
  Future<void> _openNotificationSettings() async {
    await openAppSettings();
  }

  // Check notification permissions
  Future<bool> _checkNotificationPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      // iOS doesn't provide a way to check permission status directly
      // We rely on the user allowing permissions during initialization
      return true;
    }
    return false;
  }

  // Request notifications permissions
  Future<void> _initializeNotificationPermissions() async {
    try {
      // Initialize timezone
      tz_init.initializeTimeZones();

      // Set to device timezone
      try {
        final String currentTimeZone = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(currentTimeZone));
      } catch (e) {
        // Fallback to UTC
        tz.setLocalLocation(tz.getLocation('UTC'));
      }

      // Request permissions
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // Create calendar channel
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'calendar_channel',
          'Calendar Notifications',
          description: 'Notifications for calendar events',
          importance: Importance.max,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
          playSound: true,
        ),
      );

      // Request permissions
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      // Request exact alarms permission for Android 12+
      if (Platform.isAndroid) {
        await androidPlugin?.requestExactAlarmsPermission();
      }

      debugPrint('Notification permissions requested');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  // Show events for a specific day
  void _showEventsForDay(int day) {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _currentMonthIndex + 1, day);
      _showEventDialog();
    });
  }

  // Helper method to format time to 12-hour format with AM/PM
  String _formatTime12Hour(Map<String, String> event) {
    if (event['is_all_day'] == 'true') {
      return 'All day';
    }

    int hour = int.tryParse(event['event_hour'] ?? '9') ?? 9;
    int minute = int.tryParse(event['event_minute'] ?? '0') ?? 0;
    String period = hour >= 12 ? 'PM' : 'AM';

    // Convert to 12-hour format
    hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$hour:${minute.toString().padLeft(2, '0')} $period';
  }
}
