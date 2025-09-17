import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/offline_sync_service.dart';
import '../vision_bord/vision_board_page.dart';
import '../vision_bord/box_them_vision_board.dart';
import '../vision_bord/premium_them_vision_board.dart';
import '../vision_bord/post_it_theme_vision_board.dart';
import '../vision_bord/winter_warmth_theme_vision_board.dart';
import '../vision_bord/ruby_reds_theme_vision_board.dart';
import '../vision_bord/coffee_hues_theme_vision_board.dart';
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
import '../config/api_config.dart';
import '../utils/activity_tracker_mixin.dart';

class ActiveTasksPage extends StatefulWidget {
  const ActiveTasksPage({super.key});

  @override
  State<ActiveTasksPage> createState() => _ActiveTasksPageState();
}

class _ActiveTasksPageState extends State<ActiveTasksPage>
    with ActivityTrackerMixin {
  final AuthService _authService = AuthService();
  final OfflineSyncService _syncService = OfflineSyncService();
  bool _isLoading = true;
  bool _isOffline = false;
  bool _isCheckingConnectivity = false;
  bool _hasPendingSync = false;
  List<Map<String, dynamic>> _activeBoards = [];
  Timer? _connectivityCheckTimer;
  int _consecutiveFailedChecks = 0;

  String get pageName => 'Active Tasks';

  @override
  void initState() {
    super.initState();
    _setupConnectivityListener();
    _checkServerConnectivity(initialCheck: true);
    _loadUserInfo();
    _checkPendingOfflineData();
    _loadActiveTasks();

    // Setup periodic connectivity check
    _connectivityCheckTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isOffline) {
        // If offline, check more frequently
        _checkServerConnectivity(quiet: true);
      }
    });
  }

  @override
  void dispose() {
    _connectivityCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPendingOfflineData() async {
    final hasPendingData = await _syncService.hasOfflineData();
    if (mounted) {
      setState(() {
        _hasPendingSync = hasPendingData;
      });
    }
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        // Device is definitely offline
        setState(() {
          _isOffline = true;
        });
      } else {
        // Device has connectivity, but we need to check server reachability
        _checkServerConnectivity();
      }
    });
  }

  // DNS lookup to check if internet is generally available
  Future<bool> _checkGeneralConnectivity() async {
    for (String url in ApiConfig.externalConnectivityUrls) {
      try {
        final uri = Uri.parse(url);
        final host = uri.host;
        final List<InternetAddress> result = await InternetAddress.lookup(host)
            .timeout(Duration(seconds: ApiConfig.dnsLookupTimeout));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          debugPrint(
              'DNS lookup successful for $host - general internet connectivity available');
          return true;
        }
      } on SocketException catch (_) {
        continue; // Try next URL
      } catch (e) {
        debugPrint('Error during DNS lookup for $url: $e');
        continue; // Try next URL
      }
    }
    debugPrint('All DNS lookups failed - no general internet connectivity');
    return false;
  }

  // Check if a specific URL is reachable using HTTP HEAD request (lightweight)
  Future<bool> _isUrlReachable(String url, {int timeout = 5}) async {
    try {
      final client = http.Client();
      try {
        final response = await client
            .head(Uri.parse(url))
            .timeout(Duration(seconds: timeout));
        return response.statusCode >= 200 && response.statusCode < 400;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error checking URL $url: $e');
      return false;
    }
  }

  Future<void> _checkServerConnectivity(
      {bool initialCheck = false,
      bool quiet = false,
      bool forceNotification = false}) async {
    if (_isCheckingConnectivity && !forceNotification) return;

    setState(() {
      _isCheckingConnectivity = true;
    });

    try {
      // First check device connectivity
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _isOffline = true;
          _isCheckingConnectivity = false;
          _consecutiveFailedChecks++;
        });
        debugPrint('Device has no network connectivity, setting offline mode');
        return;
      }

      // Then check general internet connectivity using DNS lookup
      final hasInternet = await _checkGeneralConnectivity();
      if (!hasInternet) {
        setState(() {
          _isOffline = true;
          _isCheckingConnectivity = false;
          _consecutiveFailedChecks++;
        });
        debugPrint('General internet connectivity check failed');
        return;
      }

      // Record previous state to detect changes
      final wasOffline = _isOffline;
      bool isServerReachable = false;

      // Try multiple approaches to verify server connectivity
      try {
        final baseUrl = ApiConfig.baseUrl;

        // Try each endpoint in order until one succeeds
        for (String endpoint in ApiConfig.connectivityCheckEndpoints) {
          final fullUrl = '$baseUrl$endpoint';
          debugPrint('Checking server connectivity at: $fullUrl');

          final endpointReachable = await _isUrlReachable(fullUrl,
              timeout: ApiConfig.connectivityCheckTimeout);

          if (endpointReachable) {
            debugPrint('Server reached successfully via $endpoint');
            isServerReachable = true;
            break;
          } else {
            debugPrint('Failed to reach server via $endpoint');
          }
        }

        setState(() {
          _isOffline = !isServerReachable;
          _isCheckingConnectivity = false;
          if (isServerReachable) {
            _consecutiveFailedChecks = 0;
          } else {
            _consecutiveFailedChecks++;
          }
        });

        debugPrint(
            'Server connectivity check result: ${isServerReachable ? 'ONLINE' : 'OFFLINE'}');
        debugPrint('Consecutive failed checks: $_consecutiveFailedChecks');

        // If we were offline before but now online, trigger sync
        if (wasOffline && !_isOffline) {
          debugPrint('Connection restored, syncing offline data');
          if (!quiet || forceNotification) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection restored! Syncing data...'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
          await _syncOfflineData();
          await _loadActiveTasks();
        }
        // If we just went offline and it wasn't the initial check
        else if (!wasOffline && _isOffline && !initialCheck) {
          if (!quiet || forceNotification) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Connection to server lost. Working in offline mode.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        // Adjust the connectivity check timer frequency based on consecutive failures
        if (_consecutiveFailedChecks > ApiConfig.maxConsecutiveFailures) {
          _connectivityCheckTimer?.cancel();
          // Check less frequently after multiple failures
          _connectivityCheckTimer =
              Timer.periodic(const Duration(minutes: 5), (timer) {
            if (_isOffline) {
              _checkServerConnectivity(quiet: true);
            }
          });
          debugPrint(
              'Reduced connectivity check frequency after $_consecutiveFailedChecks consecutive failures');
        }
      } catch (e) {
        debugPrint('Error during server connectivity checks: $e');
        setState(() {
          _isOffline = true;
          _isCheckingConnectivity = false;
          _consecutiveFailedChecks++;
        });
      }
    } catch (e) {
      debugPrint('Error in connectivity check: $e');
      setState(() {
        _isOffline = true; // Default to offline on any error
        _isCheckingConnectivity = false;
        _consecutiveFailedChecks++;
      });
    }
  }

  Future<void> _syncOfflineData() async {
    // Check if we have pending data to sync
    if (!await _syncService.hasOfflineData()) {
      setState(() {
        _hasPendingSync = false;
      });
      return;
    }

    // Double-check connectivity before attempting sync
    if (_isOffline) {
      debugPrint(
          'Server unavailable, postponing sync until connection is restored');
      setState(() {
        _hasPendingSync = true;
      });
      return;
    }

    setState(() {
      _hasPendingSync = true;
    });

    try {
      debugPrint('Starting sync of offline data...');
      final success = await _syncService.syncMindToolsActivity().timeout(
          Duration(seconds: ApiConfig.syncOperationTimeout), onTimeout: () {
        debugPrint('Sync operation timed out');
        return false;
      });

      setState(() {
        _hasPendingSync = !success;
      });

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully synced offline data'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Failed to sync some offline data. Will retry later.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error syncing offline data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during data sync: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Make sure the pending sync flag is still set
      setState(() {
        _hasPendingSync = true;
      });
    }
  }

  Future<void> _loadUserInfo() async {
    final mysqlUserData = _authService.userData;

    if (mysqlUserData != null) {
      // _userId = mysqlUserData['id']?.toString() ?? 'mysql_user'; // Removed unused field
    }
  }

  Future<void> _loadActiveTasks() async {
    setState(() {
      _isLoading = true;
      _activeBoards = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.reload();

      final allKeys = prefs.getKeys();

      _checkVisionBoardTodos(allKeys, prefs);
      _checkAnnualCalendarEvents(allKeys, prefs);
      _checkAnnualPlannerTodos(allKeys, prefs);
      _checkWeeklyPlannerTodos(allKeys, prefs);

      if (_activeBoards.isEmpty || _activeBoards.length < 2) {
        _detectAdditionalTaskPatterns(allKeys, prefs);
      }

      _removeAllDuplicateBoards();
    } catch (e) {
      debugPrint('Error loading active tasks: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _checkVisionBoardTodos(Set<String> allKeys, SharedPreferences prefs) {
    if (_checkBoardHasTasks(allKeys, 'BoxThem_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Box Theme Vision Board',
        'icon': Icons.crop_square,
        'color': Colors.teal,
        'type': 'vision',
        'theme': 'box'
      });
    }

    if (_checkBoardHasTasks(allKeys, 'premium_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Premium Theme Vision Board',
        'icon': Icons.grade,
        'color': Colors.amber,
        'type': 'vision',
        'theme': 'premium'
      });
    }

    if (_checkBoardHasTasks(allKeys, 'postit_todos_', prefs)) {
      _activeBoards.add({
        'name': 'PostIt Theme Vision Board',
        'icon': Icons.sticky_note_2,
        'color': Colors.yellow,
        'type': 'vision',
        'theme': 'postit'
      });
    }

    if (_checkBoardHasTasks(allKeys, 'winterwarmth_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Winter Warmth Theme Vision Board',
        'icon': Icons.ac_unit,
        'color': Colors.blue,
        'type': 'vision',
        'theme': 'winter'
      });
    }

    if (_checkBoardHasTasks(allKeys, 'rubyreds_todos_', prefs)) {
      _activeBoards.add({
        'name': 'Ruby Reds Theme Vision Board',
        'icon': Icons.favorite,
        'color': Colors.red,
        'type': 'vision',
        'theme': 'ruby'
      });
    }

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
    final Set<String> addedCalendarThemes = {};

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
            break;
          }
        }
      }
    }

    if (addedCalendarThemes.length < 4) {
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
          return eventsMap.isNotEmpty;
        } else if (eventsMap is List) {
          return eventsMap.isNotEmpty;
        }
      } catch (e) {
        return eventsJson.length > 20;
      }
    }

    return false;
  }

  void _checkAdditionalCalendarFormats(
      Set<String> allKeys, SharedPreferences prefs, Set<String> addedThemes) {
    final calendarPatterns = [
      '.calendar_',
      'calendar.',
      'calendar_',
      'annual_calendar',
      'events_2025',
      'calendar_events',
      '2025_events'
    ];

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

    for (var pattern in calendarPatterns) {
      final matchingKeys = allKeys.where((key) =>
          key.contains(pattern) &&
          !key.startsWith('animal.') &&
          !key.startsWith('summer.') &&
          !key.startsWith('spaniel.') &&
          !key.startsWith('happy_couple.'));

      for (var key in matchingKeys) {
        if (key.contains('_todos_')) {
          continue;
        }

        _tryAddCalendarBoard(key, prefs, addedThemes);
      }
    }

    for (var month in months) {
      final monthKeys = allKeys.where((key) =>
          key.toLowerCase().contains(month) &&
          (key.contains('event') || key.contains('calendar')) &&
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
        String theme = _extractCalendarTheme(key);

        if (addedThemes.contains(theme)) return;

        String themeName = _extractCalendarThemeName(key);

        _activeBoards.add({
          'name': '$themeName 2025 Calendar',
          'icon': Icons.calendar_today,
          'color': _getCalendarColor(theme),
          'type': 'calendar',
          'theme': theme,
          'key': key
        });

        addedThemes.add(theme);
      }
    } catch (e) {
      if (data.length > 20) {
        String theme = _extractCalendarTheme(key);

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
      String name = key.split('.').first.split('_').first;

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

    final int hash = key.hashCode;
    final int hue = hash % 360;

    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.6, 0.5).toColor();
  }

  void _checkAnnualPlannerTodos(Set<String> allKeys, SharedPreferences prefs) {
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

    if (taskKeys.isEmpty) {
      return false;
    }

    if (requiredKeys != null && requiredKeys.isNotEmpty) {
      bool hasRequiredKey = false;
      for (var requiredKey in requiredKeys) {
        if (taskKeys.any((key) => key.contains(requiredKey))) {
          hasRequiredKey = true;
          break;
        }
      }
      if (!hasRequiredKey) {
        return false;
      }
    }

    Set<String> filteredKeys = taskKeys.toSet();
    if (excludeKeys != null && excludeKeys.isNotEmpty) {
      filteredKeys = filteredKeys
          .where((key) =>
              !excludeKeys.any((excludeKey) => key.contains(excludeKey)))
          .toSet();

      if (filteredKeys.isEmpty) {
        return false;
      }
    }

    for (var key in filteredKeys) {
      final tasksJson = prefs.getString(key);
      if (tasksJson != null && tasksJson.isNotEmpty) {
        try {
          final dynamic parsedData = jsonDecode(tasksJson);

          if (parsedData is List) {
            final tasks = parsedData;

            bool hasActiveTasks = false;

            final hasIncompleteTasks = tasks.any((task) =>
                task is Map &&
                task.containsKey('completed') &&
                task['completed'] == false);

            final hasTasksWithoutCompletedField = tasks.any((task) =>
                task is Map &&
                !task.containsKey('completed') &&
                (task.containsKey('text') ||
                    task.containsKey('content') ||
                    task.containsKey('title')));

            final hasTasksWithDoneField = tasks.any((task) =>
                task is Map &&
                task.containsKey('done') &&
                task['done'] == false);

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
            bool hasActiveTasks = false;

            parsedData.forEach((taskId, taskData) {
              if (taskData is Map) {
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
                  hasActiveTasks = true;
                }
              } else if (taskData is String && taskData.isNotEmpty) {
                hasActiveTasks = true;
              }
            });

            if (hasActiveTasks) {
              return true;
            }

            for (var categoryKey in parsedData.keys) {
              final categoryData = parsedData[categoryKey];
              if (categoryData is Map && categoryData.containsKey('tasks')) {
                final categoryTasks = categoryData['tasks'];
                if (categoryTasks is List && categoryTasks.isNotEmpty) {
                  return true;
                }
              } else if (categoryData is List) {
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
    final List<String> potentialTaskKeys = allKeys
        .where((key) =>
            (key.contains('todo') ||
                key.contains('task') ||
                key.contains('item') ||
                key.contains('event') ||
                key.contains('note')) &&
            !_isKeyAlreadyChecked(key))
        .toList();

    for (String key in potentialTaskKeys) {
      final value = prefs.getString(key);
      if (value != null && value.isNotEmpty) {
        try {
          final jsonData = jsonDecode(value);
          bool hasActiveTasks = false;

          if (jsonData is List && jsonData.isNotEmpty) {
            if (jsonData[0] is Map) {
              final Map firstItem = jsonData[0];

              if (firstItem.containsKey('completed')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('completed') &&
                    item['completed'] == false);
              } else if (firstItem.containsKey('done')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('done') &&
                    item['done'] == false);
              } else if (firstItem.containsKey('finished')) {
                hasActiveTasks = jsonData.any((item) =>
                    item is Map &&
                    item.containsKey('finished') &&
                    item['finished'] == false);
              } else if (firstItem.containsKey('text') ||
                  firstItem.containsKey('content') ||
                  firstItem.containsKey('title') ||
                  firstItem.containsKey('description')) {
                hasActiveTasks = true;
              }
            }
          } else if (jsonData is Map && jsonData.isNotEmpty) {
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

    for (String prefix in checkedPrefixes) {
      if (key.startsWith(prefix)) {
        return true;
      }
    }

    return false;
  }

  String _extractPrefix(String key) {
    final parts = key.split('_');
    if (parts.length >= 2) {
      if (parts[0].toLowerCase().contains('theme')) {
        return parts[0];
      } else if (parts.length >= 3 &&
          parts[1].toLowerCase().contains('theme')) {
        return '${parts[0]}_${parts[1]}';
      } else {
        return parts[0];
      }
    }

    return key.split('.').first;
  }

  void _addDynamicBoard(String prefix, String key, {bool isEvent = false}) {
    final String formattedName = _formatBoardName(prefix);

    String boardType = 'other';

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
    final String withSpaces = prefix
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim();

    final formatted = withSpaces
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');

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
            destinationPage = const VisionBoardPage();
        }
        break;

      case 'calendar':
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
            destinationPage = const AnnualCalenderPage();
        }
        break;

      case 'annual':
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
            destinationPage = const AnnualPlannerPage();
        }
        break;

      case 'weekly':
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
            destinationPage = const WeeklyPlannerPage();
        }
        break;

      default:
        _showDynamicBoardInfoDialog(board).then((_) {
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
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage!),
    ).then((_) {
      _loadActiveTasks();
    });
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
    if (AuthService.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active Boards')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Active boards are only available for signed-in users.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please sign in to use this feature.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                icon: Icon(Icons.login),
                label: Text('Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Boards'),
        actions: [
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () => _showConnectivityInfoDialog(),
                child: Tooltip(
                  message:
                      'Connection issue detected. Data is saved locally and will sync when connection is restored.',
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orangeAccent)),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Colors.orangeAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isOffline)
            IconButton(
              icon: _isCheckingConnectivity
                  ? CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                    )
                  : const Icon(Icons.sync),
              tooltip: 'Check connection and sync data',
              onPressed: _isCheckingConnectivity
                  ? null
                  : () async {
                      // Show checking indicator
                      setState(() {
                        _isCheckingConnectivity = true;
                      });

                      await _checkServerConnectivity(forceNotification: true);

                      if (!_isOffline) {
                        await _syncOfflineData();
                        await _performFullRefresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Connection restored! Data synced successfully.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Still unable to connect to server after $_consecutiveFailedChecks attempts. Your data is saved locally and will sync automatically when connection is restored.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _performFullRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Working Offline',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Connection to server unavailable. Your boards are accessible and changes will be saved locally until connection is restored.',
                          style: TextStyle(
                              color: Colors.orange.shade800, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Colors.orange.shade800, size: 16),
                        tooltip: 'Try to reconnect',
                        onPressed: () =>
                            _checkServerConnectivity(forceNotification: true),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints.tight(Size(24, 24)),
                      ),
                      Text(
                        'Reconnect',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (_hasPendingSync && !_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.cloud_upload,
                      color: Colors.blue.shade800, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have pending data to sync. Tap the upload icon to sync now.',
                      style:
                          TextStyle(color: Colors.blue.shade800, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.cloud_upload,
                        color: Colors.blue.shade800, size: 16),
                    tooltip: 'Sync now',
                    onPressed: _syncOfflineData,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tight(Size(24, 24)),
                  )
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _activeBoards.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.dashboard_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No active boards found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create a new board to get started',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _forceDeepScan,
                              child: const Text('Scan for existing boards'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _performFullRefresh,
                        child: ListView.builder(
                          itemCount: _activeBoards.length,
                          itemBuilder: (context, index) {
                            final board = _activeBoards[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: board['color'],
                                  child: Icon(
                                    board['icon'],
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(board['name']),
                                subtitle:
                                    Text(_getBoardTypeName(board['type'])),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () => _navigateToBoard(board),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullRefresh() async {
    await _checkServerConnectivity();
    await _checkPendingOfflineData();

    setState(() {
      _isLoading = true;
    });

    _activeBoards.clear();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();

      await prefs.reload();

      final allKeys = prefs.getKeys();

      _activeBoards = [];

      _checkVisionBoardTodos(allKeys, prefs);
      _checkAnnualCalendarEvents(allKeys, prefs);
      _checkAnnualPlannerTodos(allKeys, prefs);
      _checkWeeklyPlannerTodos(allKeys, prefs);

      if (_activeBoards.isEmpty || _activeBoards.length < 2) {
        _detectAdditionalTaskPatterns(allKeys, prefs);
      }

      if (_activeBoards.isEmpty) {
        await _forceDeepScan(showNotification: false);
      }

      _removeAllDuplicateBoards();

      if (!_isOffline && _hasPendingSync) {
        await _syncOfflineData();
      }

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

  Future<void> _forceDeepScan({bool showNotification = true}) async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final allKeys = prefs.getKeys();

    _activeBoards = [];

    for (var key in allKeys) {
      if (key == 'hasSeenOnboarding' ||
          key.startsWith('flutter.') ||
          key.isEmpty) {
        continue;
      }

      var value = prefs.get(key);
      if (value == null) continue;

      if (value is String && value.isNotEmpty) {
        try {
          final data = jsonDecode(value);

          if (data is List && data.isNotEmpty) {
            _addDynamicBoard(key.split('_').first, key);
          } else if (data is Map && data.isNotEmpty) {
            _addDynamicBoard(key.split('.').first, key, isEvent: true);
          }
        } catch (e) {
          if (value.length > 10) {
            _addDynamicBoard(key, key);
          }
        }
      } else if (value is bool || value is int || value is double) {
        continue;
      }
    }

    _scanForCalendarEntries(allKeys, prefs);

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

  void _scanForCalendarEntries(Set<String> allKeys, SharedPreferences prefs) {
    final Set<String> existingThemes = _activeBoards
        .where((board) => board['type'] == 'calendar')
        .map((board) => board['theme'] as String)
        .toSet();

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

    final directPatterns = [
      'animal.calendar_events',
      'summer.calendar_events',
      'spaniel.calendar_events',
      'happy_couple.calendar_events'
    ];

    for (var pattern in directPatterns) {
      final theme = pattern.split('.')[0];
      if (existingThemes.contains(theme)) continue;

      if (allKeys.contains(pattern)) {
        final eventsJson = prefs.getString(pattern);
        if (eventsJson != null && eventsJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(eventsJson);
            if ((decoded is Map && decoded.isNotEmpty) ||
                (decoded is List && decoded.isNotEmpty)) {
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

    for (var theme in calendarThemes) {
      if (existingThemes.contains(theme['key'])) continue;

      final themeKey = theme['key'] as String;
      final themeKeys = allKeys
          .where((key) =>
              key.toLowerCase().contains(themeKey.toLowerCase()) &&
              (key.contains('calendar') || key.contains('event')))
          .toList();

      if (themeKeys.isNotEmpty) {
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

          existingThemes.add(themeKey);
        }
      }
    }
  }

  String _capitalizeFirstLetter(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  void _removeAllDuplicateBoards() {
    final Set<String> boardTypes =
        _activeBoards.map((board) => board['type'] as String).toSet();

    for (final type in boardTypes) {
      final boards =
          _activeBoards.where((board) => board['type'] == type).toList();

      if (boards.length <= 1) continue;

      final Set<String> processedThemes = {};
      final List<Map<String, dynamic>> duplicatesToRemove = [];

      for (final board in boards) {
        final theme = board['theme'];

        if (processedThemes.contains(theme)) {
          duplicatesToRemove.add(board);
        } else {
          processedThemes.add(theme);
        }
      }

      for (final duplicate in duplicatesToRemove) {
        _activeBoards.remove(duplicate);
      }

      if (duplicatesToRemove.isNotEmpty) {
        debugPrint(
            "Removed ${duplicatesToRemove.length} duplicate $type entries");
      }
    }
  }

  String _getBoardTypeName(String type) {
    switch (type) {
      case 'vision':
        return 'Vision Board';
      case 'calendar':
        return 'Annual Calendar';
      case 'annual':
        return 'Annual Planner';
      case 'weekly':
        return 'Weekly Planner';
      default:
        return 'Other Board';
    }
  }

  // Show detailed connectivity information dialog
  Future<void> _showConnectivityInfoDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(_isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: _isOffline ? Colors.orangeAccent : Colors.green),
              const SizedBox(width: 10),
              Text(_isOffline ? 'Offline Mode' : 'Online Mode'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connection Status: ${_isOffline ? 'Offline' : 'Online'}'),
              const SizedBox(height: 8),
              Text('Failed Connection Attempts: $_consecutiveFailedChecks'),
              const SizedBox(height: 8),
              Text('Server URL: ${ApiConfig.baseUrl}'),
              const SizedBox(height: 16),
              const Text(
                'While offline, all your changes are saved locally on your device. '
                'When connection is restored, data will automatically sync with the server.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (_isOffline)
                const Text(
                  'Troubleshooting tips:\n'
                  '• Check your internet connection\n'
                  '• Make sure you have a stable network\n'
                  '• Our server might be temporarily unavailable\n'
                  '• Try again in a few minutes',
                  style: TextStyle(fontSize: 13),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (_isOffline)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkServerConnectivity(forceNotification: true);
                },
                child: Text('Try Reconnecting'),
              ),
          ],
        );
      },
    );
  }
}
