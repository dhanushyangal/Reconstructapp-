import 'package:flutter/material.dart';
import '../pages/vision_board_page.dart';
import '../Annual_calender/annual_calendar_page.dart';
import '../weekly_planners/weekly_planner_page.dart';
import '../Mind_tools/thought_shredder_page.dart';
import '../Mind_tools/make_me_smile_page.dart';
import '../Mind_tools/break_things_page.dart';
import '../Activity_Tools/memory_game_page.dart';
import '../Activity_Tools/riddle_quiz_page.dart';
import '../Annual_planner/annual_planner_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Mind_tools/bubble_wrap_popper_page.dart';
import '../Activity_Tools/sliding_puzzle_page.dart';
import '../Activity_Tools/color_me_now.dart';
import 'dart:convert';
import '../vision_journey/vision-board-travel-journey.dart';
import '../reset-emotions/reset-emotions-dashboard.dart';
import '../district-my-mind/distract-my-mind-journey.dart';
import '../utils/activity_tracker_mixin.dart';

// Class to represent a Recent Activity item
class RecentActivityItem {
  final String name;
  final String imagePath;
  final DateTime timestamp;
  final String routeName;

  RecentActivityItem({
    required this.name,
    required this.imagePath,
    required this.timestamp,
    required this.routeName,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imagePath': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'routeName': routeName,
    };
  }

  // Create from JSON for retrieval
  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    return RecentActivityItem(
      name: json['name'],
      imagePath: json['imagePath'],
      timestamp: DateTime.parse(json['timestamp']),
      routeName: json['routeName'],
    );
  }
}

class ActivityTracker {
  static const String _storageKey = 'recent_activities';
  static final ActivityTracker _instance = ActivityTracker._internal();

  factory ActivityTracker() => _instance;

  ActivityTracker._internal();

  // Tracks a new page visit
  Future<void> trackActivity(RecentActivityItem activity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<RecentActivityItem> activities = await getRecentActivities();

      // Remove previous instances of the same activity
      activities.removeWhere((item) => item.routeName == activity.routeName);

      // Add the new activity at the beginning
      activities.insert(0, activity);

      // Keep only the most recent activities
      if (activities.length > 10) {
        // Keep a few more than we display
        activities = activities.sublist(0, 10);
      }

      // Save to SharedPreferences
      List<Map<String, dynamic>> jsonList =
          activities.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Retrieves recent activities
  Future<List<RecentActivityItem>> getRecentActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? jsonData = prefs.getString(_storageKey);

      if (jsonData == null || jsonData.isEmpty) {
        return [];
      }

      List<dynamic> decodedData = jsonDecode(jsonData);
      return decodedData
          .map((item) => RecentActivityItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }
}

class ActiveDashboardPage extends StatefulWidget {
  const ActiveDashboardPage({super.key});

  @override
  _ActiveDashboardPageState createState() => _ActiveDashboardPageState();
}

class _ActiveDashboardPageState extends State<ActiveDashboardPage>
    with ActivityTrackerMixin {
  String? _selectedCategory;
  List<RecentActivityItem> _recentActivities = [];
  bool _isLoadingActivities = true;

  // Tool data organized by category
  final Map<String, List<Map<String, dynamic>>> _tools = {
    'vision': [
      {'name': 'Start guided journey', 'image': 'assets/journey.png'},
      {'name': 'Vision Boards', 'image': 'assets/vision-board-plain.jpg'},
      {'name': 'Weekly Planners', 'image': 'assets/weakly_planer.png'},
      {
        'name': 'To do List',
        'image': 'assets/watercolor_theme_annual_planner.png'
      },
      {'name': 'Fun Calendars', 'image': 'assets/calendar.jpg'}
    ],
    'mind': [
      {'name': 'Reset Emotions', 'image': 'assets/journey.png'},
      {
        'name': 'Thought Shredder',
        'image': 'assets/Mind_tools/thought-shredder.png'
      },
      {'name': 'Smile Therapy', 'image': 'assets/Mind_tools/make-me-smile.png'},
      {'name': 'Break Things', 'image': 'assets/Mind_tools/break-things.png'},
      {
        'name': 'Bubble Wrap Popper',
        'image': 'assets/Mind_tools/bubble-popper.png'
      }
    ],
    'activity': [
      {'name': 'Start Guided Journey', 'image': 'assets/journey.png'},
      {
        'name': 'Digital Coloring',
        'image': 'assets/activity_tools/coloring-sheet.png'
      },
      {'name': 'Memory Game', 'image': 'assets/activity_tools/memory-game.png'},
      {'name': 'Riddles', 'image': 'assets/activity_tools/riddles.png'},
      {
        'name': 'Sliding Puzzle',
        'image': 'assets/activity_tools/sliding-puzzle.png'
      }
    ]
  };

  @override
  void initState() {
    super.initState();
    _loadRecentActivities();
  }

  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    final activities = await ActivityTracker().getRecentActivities();

    setState(() {
      _recentActivities = activities;
      _isLoadingActivities = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFE8FAFF)],
                ),
              ),
              child: _buildHeroSection(),
            ),

            // Quick links section
            _buildQuickLinksSection(),

            // Tools section (based on selected category)
            _buildToolsSection(),

            // Recent activity section
            _buildRecentActivitySection(),

            SizedBox(height: 30), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        children: [
          Text(
            "What's on your mind?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),

          // Dropdown for categories
          Container(
            width: 450,
            padding: EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Color(0xFF23C4F7)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text("Select...", style: TextStyle(color: Colors.grey)),
                value: _selectedCategory,
                icon: Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem(
                      value: 'vision', child: Text('Plan my future')),
                  DropdownMenuItem(
                      value: 'mind', child: Text('Reset my emotions')),
                  DropdownMenuItem(
                      value: 'activity', child: Text('distract my mind')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildQuickLinkButton('Box breathing'),
          _buildQuickLinkButton('Coloring sheets'),
          _buildQuickLinkButton('Memory game', isNew: true),
          _buildQuickLinkButton('Sliding puzzle'),
          _buildQuickLinkButton('To do list'),
          _buildQuickLinkButton('2025 interactive calendars'),
        ],
      ),
    );
  }

  Widget _buildQuickLinkButton(String text, {bool isNew = false}) {
    return OutlinedButton(
      onPressed: () {
        // Navigate based on the button text
        switch (text) {
          case 'Box breathing':
            // TODO: Add Box breathing page navigation when available
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Box breathing coming soon')),
            );
            break;
          case 'Coloring sheets':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ColorMeNowPage()),
            );
            break;
          case 'Memory game':
            Navigator.pushNamed(context, MemoryGamePage.routeName);
            break;
          case 'Sliding puzzle':
            Navigator.pushNamed(context, SlidingPuzzlePage.routeName);
            break;
          case 'To do list':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AnnualPlannerPage()),
            );
            break;
          case '2025 interactive calendars':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AnnualCalenderPage()),
            );
            break;
          default:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('This feature is not available yet')),
            );
            break;
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide(color: Colors.grey.shade400),
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      ),
      child: isNew
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: TextStyle(fontSize: 14, color: Colors.black)),
                SizedBox(width: 5),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Color(0xFF23C4F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'New',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          : Text(text, style: TextStyle(fontSize: 14, color: Colors.black)),
    );
  }

  Widget _buildToolsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          if (_selectedCategory != null)
            ..._buildToolCards()
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Your mind tools will show here...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildToolCards() {
    final toolsList = _tools[_selectedCategory!] ?? [];

    return [
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: toolsList.length,
        itemBuilder: (context, index) {
          final tool = toolsList[index];
          return GestureDetector(
            onTap: () {
              // Navigate based on category and tool name
              if (_selectedCategory == 'vision') {
                _handleVisionToolNavigation(tool['name'] as String);
              } else if (_selectedCategory == 'mind') {
                _handleMindToolNavigation(tool['name'] as String);
              } else if (_selectedCategory == 'activity') {
                _handleActivityToolNavigation(tool['name'] as String);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(9)),
                      child: Image.asset(
                        tool['image'] as String,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: ${tool['image']}');
                          return Center(
                            child: Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      tool['name'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildRecentActivitySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Recent Activity",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          _isLoadingActivities
              ? Center(child: CircularProgressIndicator())
              : _recentActivities.isEmpty
                  ? Center(
                      child: Text(
                        'No recent activity...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : Column(
                      children: _recentActivities
                          .take(4) // Show only 4 most recent activities
                          .map((activity) => _buildActivityItem(activity))
                          .toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivityItem activity) {
    // Format the timestamp
    final now = DateTime.now();
    final difference = now.difference(activity.timestamp);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo =
          '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      timeAgo =
          '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      timeAgo =
          '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      timeAgo = 'Just now';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, activity.routeName);
        },
        child: Row(
          children: [
            // Activity image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                activity.imagePath,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: ${activity.imagePath}');
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey[400]),
                  );
                },
              ),
            ),
            SizedBox(width: 16),

            // Activity details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Restore the navigation methods but add a case for 'Start guided journey'
  void _handleVisionToolNavigation(String toolName) {
    switch (toolName) {
      case 'Start guided journey':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const VisionBoardTravelJourneyPage()),
        );
        break;
      case 'Vision Boards':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisionBoardPage()),
        );
        break;
      case 'Weekly Planners':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeeklyPlannerPage()),
        );
        break;
      case 'To do List':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnualPlannerPage()),
        );
        break;
      case 'Fun Calendars':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnualCalenderPage()),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisionBoardPage()),
        );
        break;
    }
  }

  // Fix the onTap handler to use the existing methods again
  void _handleMindToolNavigation(String toolName) {
    switch (toolName) {
      case 'Reset Emotions':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ResetEmotionsDashboard()),
        );
        break;
      case 'Thought Shredder':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ThoughtShredderPage()),
        );
        break;
      case 'Smile Therapy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MakeMeSmilePage()),
        );
        break;
      case 'Break Things':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BreakThingsPage()),
        );
        break;
      case 'Bubble Wrap Popper':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BubbleWrapPopperPage()),
        );
        break;
      case 'Decide For Me':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decide For Me coming soon')),
        );
        break;
      default:
        break;
    }
  }

  void _handleActivityToolNavigation(String toolName) {
    switch (toolName) {
      case 'Start Guided Journey':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DistractMyMindJourney()),
        );
        break;
      case 'Digital Coloring':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ColorMeNowPage()),
        );
        break;
      case 'Memory Game':
        Navigator.pushNamed(context, MemoryGamePage.routeName);
        break;
      case 'Riddles':
        Navigator.pushNamed(context, RiddleQuizPage.routeName);
        break;
      case 'Sliding Puzzle':
        Navigator.pushNamed(context, SlidingPuzzlePage.routeName);
        break;
      default:
        break;
    }
  }

  @override
  String get pageName => 'Dashboard';
}
