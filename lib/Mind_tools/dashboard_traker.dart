import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';

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
  String? _authToken;
  // Add scroll controllers for each tracker
  final Map<String, ScrollController> _scrollControllers = {};
  // Track API server availability separately from network connectivity
  bool _isServerAvailable = true;

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

  // Check if network is available
  Future<bool> _checkNetworkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Check if server is reachable
  Future<bool> _checkServerReachable() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://reconstrect-api.onrender.com/api/health'),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Server health check failed: $e');
      return false;
    }
  }

  // Load activity data from API or fall back to local storage if offline
  Future<void> _loadActivityData() async {
    setState(() {
      _isLoading = true;
    });

    // Always load from local storage first to ensure we have data even offline
    await _loadFromLocalStorage();

    // Check network connectivity first
    final bool isNetworkAvailable = await _checkNetworkConnectivity();

    if (!isNetworkAvailable) {
      setState(() {
        _isOffline = true;
        _isServerAvailable = false;
        _isLoading = false;
      });
      debugPrint('Network is not available. Using local data only.');
      return;
    }

    // If network is available, try server health check
    final bool serverReachable = await _checkServerReachable();
    _isServerAvailable = serverReachable;

    try {
      // Then try to load from API to get the latest data
      if (serverReachable) {
        await _loadActivityFromApi();
        // If loading from API was successful, sync any locally stored offline data
        await _syncOfflineData();
      } else {
        debugPrint('Server is unreachable even though network is available');
      }

      setState(() {
        _isOffline = !serverReachable; // Only offline if server is unreachable
      });
    } catch (e) {
      debugPrint('Failed to load from API: $e');
      // Only set offline if it was a network error, not an auth or other error
      setState(() {
        _isServerAvailable = false;
        _isOffline = true;
      });
    }

    setState(() {
      _isLoading = false;
    });

    // Center the calendars after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerAllCalendars();
    });
  }

  Future<void> _loadActivityFromApi() async {
    final token = await _getAuthToken();

    if (token == null) {
      throw Exception('No auth token available');
    }

    final response = await http.get(
      Uri.parse('https://reconstrect-api.onrender.com/api/mind-tools/activity'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['success'] == true && responseData['data'] != null) {
        // Clear existing data
        for (final tracker in _activityData.keys) {
          _activityData[tracker] = {};
        }

        // Parse the data from API format to our app format
        final apiData = responseData['data'] as Map<String, dynamic>;

        for (final tracker in apiData.keys) {
          final trackerData = apiData[tracker] as Map<String, dynamic>;

          for (final dateStr in trackerData.keys) {
            try {
              final date = DateTime.parse(dateStr);
              final dateKey = DateTime(date.year, date.month, date.day);
              _activityData[tracker]?[dateKey] = trackerData[dateStr];
            } catch (e) {
              debugPrint('Error parsing date: $dateStr');
            }
          }
        }

        // If we get here, server is definitely available
        _isServerAvailable = true;
      } else {
        throw Exception('Invalid API response format');
      }
    } else if (response.statusCode == 401 || response.statusCode == 403) {
      // Auth errors don't mean we're offline
      _isServerAvailable = true;
      throw Exception('Authentication failed: ${response.statusCode}');
    } else {
      // Other errors could indicate server issues
      _isServerAvailable = false;
      throw Exception('Failed to load activity data: ${response.statusCode}');
    }
  }

  // Load data from SharedPreferences as fallback when offline
  Future<void> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('Loading activity data from local storage');

    // Load data for all trackers
    for (final tracker in _trackerNames.keys) {
      final activityDates = prefs.getStringList('${tracker}_activity') ?? [];
      debugPrint('Found ${activityDates.length} local activities for $tracker');

      Map<DateTime, int> data = {};
      for (var dateStr in activityDates) {
        try {
          final date = DateTime.parse(dateStr);
          final dateKey = DateTime(date.year, date.month, date.day);
          data[dateKey] = (data[dateKey] ?? 0) + 1;
        } catch (e) {
          debugPrint('Error parsing date: $dateStr');
        }
      }

      _activityData[tracker] = data;
    }
  }

  // Record a new activity - will be called directly by this page if needed
  Future<void> recordActivity(String trackerId) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Update local state
    setState(() {
      _activityData[trackerId]?[today] =
          (_activityData[trackerId]?[today] ?? 0) + 1;
    });

    // Save to local storage for offline capability
    await _saveActivityToLocalStorage(trackerId, today);

    // Check connectivity before trying API
    final isNetworkAvailable = await _checkNetworkConnectivity();

    if (isNetworkAvailable && _isServerAvailable) {
      try {
        await _sendActivityToApi(trackerId, today);
        // If successful, we're definitely not offline
        setState(() {
          _isOffline = false;
        });
      } catch (e) {
        debugPrint('Failed to send activity to API: $e');
        // Only update offline state if it looks like a connectivity issue
        final isNetworkStillAvailable = await _checkNetworkConnectivity();
        setState(() {
          _isOffline = !isNetworkStillAvailable;
          if (isNetworkStillAvailable) {
            _isServerAvailable = false;
          }
        });
        // Already saved to local storage above
      }
    } else if (!isNetworkAvailable) {
      setState(() {
        _isOffline = true;
      });
    }
  }

  // Save activity to local storage
  Future<void> _saveActivityToLocalStorage(
      String trackerId, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();

    // Use the static method to avoid code duplication
    await DashboardTrackerPage._saveActivityToLocalStorage(
        trackerId, date, prefs);
  }

  // Send activity to API
  Future<void> _sendActivityToApi(String trackerId, DateTime date) async {
    final token = await _getAuthToken();

    if (token == null) {
      throw Exception('No auth token available');
    }

    await DashboardTrackerPage._sendActivityToApi(trackerId, date, token);
  }

  // Sync offline data with server when back online
  Future<void> _syncOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSyncs = prefs.getStringList('pending_activity_syncs') ?? [];

    if (pendingSyncs.isEmpty) {
      debugPrint('No pending activities to sync');
      return;
    }

    debugPrint('Syncing ${pendingSyncs.length} pending activities to server');

    final token = await _getAuthToken();
    if (token == null) {
      debugPrint('No auth token available for syncing');
      return;
    }

    try {
      // Prepare activities array
      final activities = pendingSyncs.map((syncData) {
        return json.decode(syncData);
      }).toList();

      // Send batch sync request
      final response = await http.post(
        Uri.parse('https://reconstrect-api.onrender.com/api/mind-tools/sync'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'activities': activities,
        }),
      );

      if (response.statusCode == 200) {
        // Clear pending syncs if successful
        await prefs.setStringList('pending_activity_syncs', []);
        debugPrint(
            'Successfully synced ${activities.length} activities with server');

        // Show snackbar notification if context is available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced ${activities.length} activities'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // If sync successful, we're definitely online
        setState(() {
          _isOffline = false;
          _isServerAvailable = true;
        });
      } else {
        debugPrint('Failed to sync activities: ${response.statusCode}');
        throw Exception('Failed to sync activities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to sync offline data: $e');
      // Keep pending syncs for next attempt

      // Show error snackbar if context is available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to sync activities: ${e.toString().substring(0, math.min(50, e.toString().length))}...'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to manually trigger a sync
  Future<void> _manualSync() async {
    setState(() {
      _isLoading = true;
    });

    // First check network connectivity
    final isNetworkAvailable = await _checkNetworkConnectivity();
    if (!isNetworkAvailable) {
      setState(() {
        _isOffline = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network is not available. Cannot sync.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Check server health
      final serverReachable = await _checkServerReachable();
      if (!serverReachable) {
        setState(() {
          _isOffline = true;
          _isServerAvailable = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Server is currently unavailable. Try again later.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _syncOfflineData();
      await _loadActivityFromApi();

      setState(() {
        _isOffline = false;
        _isServerAvailable = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Manual sync failed: $e');
      // Only mark as offline if it's a network issue
      final isNetworkStillAvailable = await _checkNetworkConnectivity();
      setState(() {
        _isOffline = !isNetworkStillAvailable;
        if (isNetworkStillAvailable) {
          _isServerAvailable = false;
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Dashboard'),
        elevation: 0,
        actions: [
          if (_isOffline)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Tooltip(
                message:
                    'Offline Mode - Activities are saved locally and will sync when back online',
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orangeAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Manual sync button
          if (_isOffline)
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Try to sync offline data',
              onPressed: _manualSync,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadActivityData,
          ),
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
                    // Info banner when offline
                    if (_isOffline)
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
                                _isServerAvailable
                                    ? 'Network connection issue detected. Activities are being saved locally and will sync when you\'re back online.'
                                    : 'Server connection issue detected. Activities are being saved locally and will sync automatically when the server is available again.',
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
                    }).toList(),
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
                      child: Text(
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
                        ))
                    .toList(),
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

    // Check if today has activity
    int streak = data.containsKey(today) ? 1 : 0;

    // If no activity today, start checking from yesterday
    DateTime checkDate = data.containsKey(today)
        ? today.subtract(const Duration(days: 1))
        : today;

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
