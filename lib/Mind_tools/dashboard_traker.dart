import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';

class DashboardTrackerPage extends StatefulWidget {
  const DashboardTrackerPage({super.key});

  // Static method to record activity from any Mind_tools page
  // This method ensures activities are saved locally first for offline support
  static Future<void> recordToolActivity(String trackerId) async {
    // Get shared preferences
    final prefs = await SharedPreferences.getInstance();

    // Record datetime for today
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // ALWAYS save to local storage first to ensure offline capability
    await _saveActivityToLocalStorage(trackerId, today, prefs);

    // Get auth token
    final authToken = prefs.getString('auth_token');

    // Try to send to API if token exists, but only as a "best effort"
    // The activity is already safely stored in SharedPreferences
    if (authToken != null) {
      try {
        await _sendActivityToApi(trackerId, today, authToken);
        debugPrint('Successfully sent activity to server');
      } catch (e) {
        debugPrint('Failed to send activity to API from static method: $e');
        // Activity already saved to local storage and will sync later
        debugPrint('Activity saved locally and will sync when online');
      }
    } else {
      debugPrint('No auth token available, activity saved locally only');
    }
  }

  // Static helper method to save to localStorage
  static Future<void> _saveActivityToLocalStorage(
      String trackerId, DateTime date, SharedPreferences prefs) async {
    // Save both to the legacy format (for backward compatibility)
    // and to the new pending syncs format (for server syncing)

    // 1. Save to legacy format - individual tracker lists
    final List<String> activities =
        prefs.getStringList('${trackerId}_activity') ?? [];

    // Add new activity
    final dateStr = date.toIso8601String();
    activities.add(dateStr);

    // Save back to storage
    await prefs.setStringList('${trackerId}_activity', activities);
    debugPrint('Activity saved locally for $trackerId at $dateStr');

    // 2. Also save pending syncs for when we're back online
    final pendingSyncs = prefs.getStringList('pending_activity_syncs') ?? [];
    final syncData = json.encode({
      'tracker_type': trackerId,
      'activity_date': dateStr,
    });

    if (!pendingSyncs.contains(syncData)) {
      pendingSyncs.add(syncData);
      await prefs.setStringList('pending_activity_syncs', pendingSyncs);
      debugPrint('Activity added to pending syncs');
    }
  }

  // Static helper method to send to API
  static Future<void> _sendActivityToApi(
      String trackerId, DateTime date, String token) async {
    final response = await http.post(
      Uri.parse('https://reconstrect-api.onrender.com/api/mind-tools/activity'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'tracker_type': trackerId,
        'activity_date': date.toIso8601String(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to record activity: ${response.statusCode}');
    }
  }

  @override
  State<DashboardTrackerPage> createState() => _DashboardTrackerPageState();
}

class _DashboardTrackerPageState extends State<DashboardTrackerPage> {
  final Map<String, Map<DateTime, int>> _activityData = {
    'thought_shredder': {},
    'make_me_smile': {},
    'bubble_wrap_popper': {},
    'break_things': {},
    // Add more trackers here as needed
  };
  bool _isLoading = true;
  bool _isOffline = false;
  bool _isBackgroundLoading = false;
  String? _authToken;
  // Add scroll controllers for each tracker
  final Map<String, ScrollController> _scrollControllers = {};

  final Map<String, String> _trackerNames = {
    'thought_shredder': 'Thought Shredder',
    'make_me_smile': 'Make Me Smile',
    'bubble_wrap_popper': 'Bubble Wrap Popper',
    'break_things': 'Break Things',
    // Add more trackers here as needed
  };

  @override
  void initState() {
    super.initState();
    // Initialize scroll controllers for each tracker
    for (final tracker in _trackerNames.keys) {
      _scrollControllers[tracker] = ScrollController();
    }
    _loadActivityData();
  }

  @override
  void dispose() {
    // Dispose all scroll controllers
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get the auth token from local storage
  Future<String?> _getAuthToken() async {
    if (_authToken != null) return _authToken;

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    return _authToken;
  }

  // Hybrid sync: local + Supabase
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
      _isBackgroundLoading = false;
    });

    // For guest users, show empty state with sign-in prompt
    if (AuthService.isGuest) {
      debugPrint('👤 Guest user detected - showing sign-in prompt');
      setState(() {
        _isLoading = false;
        _isOffline = false;
        // Clear any existing data for guest users
        for (final tracker in _trackerNames.keys) {
          _activityData[tracker] = {};
        }
      });
      return;
    }

    debugPrint('🔄 Starting activity data load...');
    bool loadedFromSupabase = false;

    try {
      debugPrint('🔄 Syncing pending local activities to Supabase...');
      await _syncPendingLocalToSupabase(); // Try to sync any pending local activity first

      debugPrint('🌐 Loading data from Supabase...');
      await _loadActivityFromApi();
      loadedFromSupabase = true;
      setState(() {
        _isOffline = false;
      });
      debugPrint('✅ Successfully loaded data from Supabase');
    } catch (e) {
      debugPrint('❌ Failed to load from Supabase: $e');
      setState(() {
        _isOffline = true;
      });
    }

    if (!loadedFromSupabase) {
      debugPrint('📱 Falling back to local storage...');
      await _loadFromLocalStorage();
    } else {
      // Even if we loaded from Supabase, merge any local data that wasn't synced
      debugPrint('🔄 Merging local data with Supabase data...');
      await _mergeLocalDataWithSupabase();
    }

    // Debug final state
    for (final tracker in _trackerNames.keys) {
      final data = _activityData[tracker] ?? {};
      final count = data.length;
      debugPrint('📊 Final $tracker activity days: $count');

      // Debug each day's data
      data.forEach((date, activityCount) {
        debugPrint('📅 Final $tracker: $date -> $activityCount activities');
      });

      if (count == 0) {
        debugPrint('⚠️ $tracker has NO activity data loaded!');
      }
    }

    setState(() {
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerAllCalendars();
    });
  }

  // Load activity data from API for all trackers
  Future<void> _loadActivityFromApi() async {
    final user = AuthService.instance.currentUser;
    final email = user?.email;
    final userName = user?.userMetadata?['name'] ??
        user?.userMetadata?['username'] ??
        user?.email?.split('@')[0];
    if (email == null) {
      throw Exception('No authenticated user available');
    }

    // Still try to get token for external API calls (optional)
    final token = await _getAuthToken();

    final service = SupabaseDatabaseService();
    final currentYear = DateTime.now().year;

    // 1. Load Thought Shredder from Supabase
    try {
      debugPrint(
          '🔍 Loading thought_shredder data from Supabase for user: $email');
      final tsResult = await service.fetchThoughtShredderActivity(
          email: email, year: currentYear);
      if (tsResult['success'] == true && tsResult['data'] != null) {
        final List<dynamic> rows = tsResult['data'];
        Map<DateTime, int> tsData = {};
        for (final row in rows) {
          try {
            final date = DateTime.parse(row['shred_date']);
            final dateKey = DateTime(date.year, date.month, date.day);
            tsData[dateKey] = (row['shred_count'] ?? 1);
          } catch (e) {
            debugPrint(
                'Error parsing Thought Shredder date: ${row['shred_date']}');
          }
        }
        _activityData['thought_shredder'] = tsData;
        debugPrint('✅ thought_shredder: loaded ${tsData.length} activity days');
      } else {
        debugPrint(
            '⚠️ Failed to load Thought Shredder data from Supabase: ${tsResult['message'] ?? 'Unknown error'}');
        _activityData['thought_shredder'] = {};
      }
    } catch (e) {
      debugPrint('❌ Error loading thought_shredder: $e');
      _activityData['thought_shredder'] = {};
    }

    // 2. Load break_things, bubble_wrap_popper, and make_me_smile from Supabase
    for (final tool in [
      'break_things',
      'bubble_wrap_popper',
      'make_me_smile'
    ]) {
      try {
        debugPrint('🔍 Loading $tool data from Supabase for user: $email');
        final result = await service.fetchMindToolActivity(
            email: email, toolType: tool, year: currentYear);
        debugPrint(
            '📊 $tool result: ${result['success']}, data count: ${result['data']?.length ?? 0}');

        if (result['success'] == true && result['data'] != null) {
          final List<dynamic> rows = result['data'];
          Map<DateTime, int> toolData = {};
          for (final row in rows) {
            try {
              final date = DateTime.parse(row['activity_date']);
              final dateKey = DateTime(date.year, date.month, date.day);
              final activityCount = (row['activity_count'] ?? 1) as int;

              // Aggregate multiple rows for the same date (in case upsert created duplicates)
              toolData[dateKey] = (toolData[dateKey] ?? 0) + activityCount;
              debugPrint(
                  '✅ $tool: $dateKey -> ${toolData[dateKey]} total activities (added $activityCount)');
            } catch (e) {
              debugPrint(
                  '❌ Error parsing $tool date: ${row['activity_date']}, error: $e');
            }
          }
          _activityData[tool] = toolData;
          debugPrint('📈 $tool total activity days loaded: ${toolData.length}');

          // Debug final aggregated data
          toolData.forEach((date, count) {
            debugPrint('📊 $tool final: $date -> $count activities');
          });
        } else {
          debugPrint(
              '⚠️ Failed to load $tool data from Supabase: ${result['message'] ?? 'Unknown error'}');
          _activityData[tool] = {};
        }
      } catch (e) {
        debugPrint('❌ Error loading $tool: $e');
        _activityData[tool] = {};
      }
    }

    // 3. Load other trackers from API (existing logic) - OPTIONAL
    try {
      final response = await http.get(
        Uri.parse(
            'https://reconstrect-api.onrender.com/api/mind-tools/activity'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          // Parse the data from API format to our app format
          final apiData = responseData['data'] as Map<String, dynamic>;

          for (final tracker in apiData.keys) {
            if (tracker == 'thought_shredder' ||
                tracker == 'break_things' ||
                tracker == 'bubble_wrap_popper' ||
                tracker == 'make_me_smile') continue; // Already loaded
            final trackerData = apiData[tracker] as Map<String, dynamic>;

            Map<DateTime, int> trackerMap = {};
            for (final dateStr in trackerData.keys) {
              try {
                final date = DateTime.parse(dateStr);
                final dateKey = DateTime(date.year, date.month, date.day);
                trackerMap[dateKey] = trackerData[dateStr];
              } catch (e) {
                debugPrint('Error parsing date: $dateStr');
              }
            }
            _activityData[tracker] = trackerMap;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ External API failed (non-critical): $e');
      // Don't throw - this is optional for other trackers that might exist
    }
  }

  // Merge any local data that wasn't synced with the Supabase data
  Future<void> _mergeLocalDataWithSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('🔄 Merging local data with Supabase data...');

    for (final tracker in _trackerNames.keys) {
      final activityDates = prefs.getStringList('${tracker}_activity') ?? [];
      if (activityDates.isEmpty) continue;

      Map<DateTime, int> localData = {};
      for (var dateStr in activityDates) {
        try {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);
          localData[dateKey] = (localData[dateKey] ?? 0) + 1;
        } catch (e) {
          debugPrint('❌ Error parsing local date: $dateStr, error: $e');
        }
      }

      // Merge local data with existing Supabase data
      final existingData = _activityData[tracker] ?? {};
      for (final entry in localData.entries) {
        final dateKey = entry.key;
        final localCount = entry.value;
        final existingCount = existingData[dateKey] ?? 0;
        // Take the maximum to avoid duplicates
        existingData[dateKey] = math.max(existingCount, localCount);
      }

      _activityData[tracker] = existingData;
      debugPrint(
          '🔗 $tracker: merged ${localData.length} local days with Supabase data');
    }
  }

  // Load from local storage for all 4 tools
  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('📱 Loading activity data from local storage (offline mode)');
    for (final tracker in _trackerNames.keys) {
      final activityDates = prefs.getStringList('${tracker}_activity') ?? [];
      debugPrint(
          '📊 Found ${activityDates.length} local activities for $tracker');
      Map<DateTime, int> data = {};
      for (var dateStr in activityDates) {
        try {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);
          data[dateKey] = (data[dateKey] ?? 0) + 1;
        } catch (e) {
          debugPrint('❌ Error parsing local date: $dateStr, error: $e');
        }
      }
      _activityData[tracker] = data;
      debugPrint(
          '✅ $tracker: loaded ${data.length} unique days from local storage');
    }
  }

  // Sync any pending local activity to Supabase for all 4 tools
  Future<void> _syncPendingLocalToSupabase() async {
    final prefs = await SharedPreferences.getInstance();
    final user = AuthService.instance.currentUser;
    final email = user?.email;
    final userName = user?.userMetadata?['name'] ??
        user?.userMetadata?['username'] ??
        user?.email?.split('@')[0];
    if (email == null) return;
    final service = SupabaseDatabaseService();
    // For each tool, check pending syncs
    for (final tracker in _trackerNames.keys) {
      final pendingKey = '${tracker}_pending_syncs';
      final pendingSyncs = prefs.getStringList(pendingKey) ?? [];
      if (pendingSyncs.isEmpty) continue;
      debugPrint('Syncing ${pendingSyncs.length} pending for $tracker');
      for (final dateStr in pendingSyncs) {
        final date = DateTime.parse(dateStr);
        if (tracker == 'thought_shredder') {
          await service.upsertThoughtShredderActivity(
              email: email, userName: userName, date: date);
        } else {
          await service.upsertMindToolActivity(
              email: email, userName: userName, date: date, toolType: tracker);
        }
      }
      await prefs.setStringList(pendingKey, []); // Clear after sync
    }
  }

  // Method to center all calendars
  void _centerAllCalendars() {
    final now = DateTime.now();
    final currentMonth = now.month;

    // Approximate scroll positions based on month (around 70 pixels per month)
    for (final controller in _scrollControllers.values) {
      if (controller.hasClients) {
        final position = (currentMonth - 1) * 70.0;
        controller.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  // Manual sync button for offline mode
  Future<void> _manualSync() async {
    setState(() {
      _isBackgroundLoading = true;
    });
    try {
      await _syncPendingLocalToSupabase();
      await _loadActivityFromApi();
      setState(() {
        _isOffline = false;
      });
    } catch (e) {
      debugPrint('Manual sync failed: $e');
      setState(() {
        _isOffline = true;
      });
      await _loadFromLocalStorage();
    }
    setState(() {
      _isBackgroundLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Dashboard'),
        elevation: 0,
        actions: [
          if (AuthService.isGuest)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: 'Sign In',
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
            )
          else ...[
            if (_isBackgroundLoading)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_isOffline)
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync with database',
                onPressed: _manualSync,
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _loadActivityData,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (AuthService.isGuest)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              color: Colors.blue.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign in to track your activities',
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create an account to save and sync your activity data across devices.',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      )
                    else if (_isOffline)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You\'re offline. Tap the sync button to try again when you\'re back online.',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Tracker cards
                    ..._trackerNames.keys.map((trackerId) {
                      return _buildTrackerCard(trackerId);
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrackerCard(String trackerId) {
    final Map<DateTime, int> trackerData = _activityData[trackerId] ?? {};
    final bool hasData = trackerData.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _trackerNames[trackerId] ?? 'Activity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Removed the "+" button
              ],
            ),
            const SizedBox(height: 12),
            _buildGitHubStyleCalendar(trackerId),
            const SizedBox(height: 10),
            _buildLegend(),
            const SizedBox(height: 10),
            hasData
                ? _buildStats(trackerData)
                : Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      child: AuthService.isGuest
                          ? Column(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 32,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to start tracking',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your activity data will be saved and synced',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'No activity data recorded yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGitHubStyleCalendar(String trackerId) {
    final DateTime now = DateTime.now();
    final int currentYear = now.year;

    // Start exactly on January 1st
    final DateTime startOfYear = DateTime(currentYear, 1, 1);

    // Find first Sunday on or before January 1st
    final DateTime firstSunday = startOfYear.weekday == DateTime.sunday
        ? startOfYear
        : startOfYear.subtract(Duration(days: startOfYear.weekday));

    // Calendar dimensions - reduced for a more compact view
    final int totalWeeks = 53;
    final double cellSize = 15.0; // Reduced from 18.0
    final double cellSpacing = 2.0; // Reduced from 3.0
    final double weekWidth = cellSize + cellSpacing;
    final double weeksWidth = totalWeeks * weekWidth;

    // Build month labels
    final Map<int, String> monthLabels =
        _calculateMonthPositions(firstSunday, totalWeeks, currentYear);

    return SizedBox(
      height: 160, // Reduced from 190
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Days of week labels column (fixed) - more compact
          SizedBox(
            width: 20, // Reduced width
            child: Column(
              children: [
                const SizedBox(height: 25), // Space for month labels
                ...['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Container(
                          height: cellSize + cellSpacing,
                          alignment: Alignment.center,
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 8, // Reduced font size
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        )),
              ],
            ),
          ),

          // Calendar grid with month labels - both scroll together
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollControllers[trackerId],
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: weeksWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month labels row - more compact
                    SizedBox(
                      height: 18, // Reduced height
                      child: Stack(
                        children: monthLabels.entries.map((entry) {
                          return Positioned(
                            left: entry.key * weekWidth,
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 8, // Reduced font size
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Activity grid
                    SizedBox(
                      height: 7 * (cellSize + cellSpacing),
                      child: CustomPaint(
                        painter: CalendarGridPainter(
                          startDate: firstSunday,
                          totalWeeks: totalWeeks,
                          cellSize: cellSize,
                          spacing: cellSpacing,
                          activityData: _activityData[trackerId] ?? {},
                          showFullYear: true,
                          currentYear: currentYear,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, String> _calculateMonthPositions(
      DateTime firstDate, int totalWeeks, int currentYear) {
    final Map<int, String> monthLabels = {};
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    DateTime currentDate = firstDate;
    int lastMonth = -1;

    for (int week = 0; week < totalWeeks; week++) {
      final month = currentDate.month;

      // Only add label if it's from the current year (ignore previous year's December)
      if (month != lastMonth && currentDate.year == currentYear) {
        monthLabels[week] = months[month - 1];
        lastMonth = month;
      }

      // Move to next week
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return monthLabels;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Less', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(width: 4),
          _buildActivityCell(0),
          _buildActivityCell(1),
          _buildActivityCell(3),
          _buildActivityCell(5),
          _buildActivityCell(7),
          const SizedBox(width: 4),
          Text('More', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActivityCell(int level) {
    Color cellColor = _getColorForLevel(level);

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: cellColor,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            if (level > 0)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              )
          ],
        ),
      ),
    );
  }

  Color _getColorForLevel(int level) {
    if (level == 0) {
      return Colors.grey.shade200;
    } else if (level == 1) {
      return const Color(0xFFB5E5C3);
    } else if (level <= 3) {
      return const Color(0xFF7BC89A);
    } else if (level <= 5) {
      return const Color(0xFF4A9F68);
    } else {
      return const Color(0xFF2E6C47);
    }
  }

  Widget _buildStats(Map<DateTime, int> data) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalDays = data.keys.length;
    final int currentStreak = _calculateCurrentStreak(data);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('Current Streak', '$currentStreak days',
              Icons.local_fire_department, Colors.orange),
          _statItem('Total Days', totalDays.toString(), Icons.calendar_month,
              Colors.blue),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _calculateCurrentStreak(Map<DateTime, int> data) {
    if (data.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int streak = 0;
    DateTime checkDate = today;

    // Start from today and work backwards
    while (data.containsKey(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

class CalendarGridPainter extends CustomPainter {
  final DateTime startDate;
  final int totalWeeks;
  final double cellSize;
  final double spacing;
  final Map<DateTime, int> activityData;
  final bool showFullYear;
  final int currentYear;

  CalendarGridPainter({
    required this.startDate,
    required this.totalWeeks,
    required this.cellSize,
    required this.spacing,
    required this.activityData,
    required this.currentYear,
    this.showFullYear = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    for (int week = 0; week < totalWeeks; week++) {
      for (int day = 0; day < 7; day++) {
        final date = startDate.add(Duration(days: week * 7 + day));

        // Skip future dates unless showing full year
        if (date.isAfter(now) && !showFullYear) {
          continue;
        }

        // Get activity level (only for current year)
        int activityLevel = 0;
        if (date.year == currentYear) {
          final dateKey = DateTime(date.year, date.month, date.day);
          activityLevel = activityData[dateKey] ?? 0;
        }

        // Determine cell color based on activity level
        Color cellColor;
        if (date.year != currentYear) {
          // Use a very light grey for dates from previous/next year
          cellColor = Colors.grey.shade100;
        } else if (activityLevel == 0) {
          cellColor = Colors.grey.shade200;
        } else if (activityLevel == 1) {
          cellColor = const Color(0xFFB5E5C3);
        } else if (activityLevel <= 3) {
          cellColor = const Color(0xFF7BC89A);
        } else if (activityLevel <= 5) {
          cellColor = const Color(0xFF4A9F68);
        } else {
          cellColor = const Color(0xFF2E6C47);
        }

        // Draw cell
        final x = week * (cellSize + spacing);
        final y = day * (cellSize + spacing);

        final rect = Rect.fromLTWH(x, y, cellSize, cellSize);
        final paint = Paint()..color = cellColor;

        // Add subtle highlight effect for active cells
        if (activityLevel > 0) {
          final shadowPaint = Paint()
            ..color = Colors.black.withOpacity(0.05)
            ..style = PaintingStyle.fill;

          final shadowRect = Rect.fromLTWH(x, y + 0.5, cellSize, cellSize);
          canvas.drawRRect(
            RRect.fromRectAndRadius(shadowRect, const Radius.circular(2.0)),
            shadowPaint,
          );
        }

        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2.0)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
