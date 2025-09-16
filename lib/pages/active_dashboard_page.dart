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
import '../district-my-mind/distract-my-mind-journey.dart';
import '../utils/activity_tracker_mixin.dart';
import '../vision_bord/vision_board_template_selection_page.dart';

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
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.0, // Starting point - no progress yet
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF23C4F7)),
          ),
        ),
      ),
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
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
          SizedBox(height: 8),
          Text(
            "Select any one and proceed",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),

          // Main action buttons
          _buildActionButton(
            title: "Plan my future",
            subtitle: "Turn ideas into a clear path forward.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryToolsPage(
                    category: 'vision',
                    categoryName: 'Plan my future',
                    tools: _tools['vision']!,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildActionButton(
            title: "Reset my emotions",
            subtitle: "Release what's heavy and feel lighter.",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryToolsPage(
                    category: 'mind',
                    categoryName: 'Reset my emotions',
                    tools: _tools['mind']!,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildActionButton(
            title: "Clear my mind",
            subtitle: "Get a fresh start for renewed focus",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryToolsPage(
                    category: 'activity',
                    categoryName: 'Clear my mind',
                    tools: _tools['activity']!,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Color(0xFFE8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF23C4F7).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF23C4F7),
              size: 20,
            ),
          ],
        ),
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
          _buildQuickLinkButton('Thought Shredder'),
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
          case 'Thought Shredder':
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ThoughtShredderPage()),
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


  String get pageName => 'Dashboard';
}

class CategoryToolsPage extends StatefulWidget {
  final String category;
  final String categoryName;
  final List<Map<String, dynamic>> tools;

  const CategoryToolsPage({
    super.key,
    required this.category,
    required this.categoryName,
    required this.tools,
  });

  @override
  _CategoryToolsPageState createState() => _CategoryToolsPageState();
}

class _CategoryToolsPageState extends State<CategoryToolsPage>
    with ActivityTrackerMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Top padding
          SizedBox(height: 70),
          
          // Fixed text above images
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.transparent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.categoryName,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Take the first step — choose a tool.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),

           // Sliding tools view - moved to bottom
           Expanded(
             child: PageView.builder(
               itemCount: widget.tools.length,
               itemBuilder: (context, index) {
                 final tool = widget.tools[index];
                 return _buildToolSlide(tool, index);
               },
             ),
           ),

        ],
      ),
    );
  }

  Widget _buildToolSlide(Map<String, dynamic> tool, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
           // Tool image
           Container(
             height: 500,
             width: double.infinity,
             decoration: BoxDecoration(
               borderRadius: BorderRadius.circular(20),
               boxShadow: [
                 BoxShadow(
                   color: Colors.grey.withOpacity(0.2),
                   spreadRadius: 2,
                   blurRadius: 10,
                   offset: Offset(0, 5),
                 ),
               ],
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(20),
               child: Image.asset(
                 tool['image'] as String,
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) {
                   return Container(
                     color: Colors.grey[200],
                     child: Icon(
                       Icons.image_not_supported,
                       size: 80,
                       color: Colors.grey[400],
                     ),
                   );
                 },
               ),
             ),
           ),
          
           SizedBox(height: 30),
          
           // Action button
           Container(
             width: double.infinity,
             child: MouseRegion(
               onEnter: (_) => setState(() => _isHovered = true),
               onExit: (_) => setState(() => _isHovered = false),
               child: ElevatedButton(
                 onPressed: () {
                   _navigateToTool(tool['name'] as String);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: _isHovered ? Colors.grey[100] : Colors.white,
                   foregroundColor: Colors.black,
                   padding: EdgeInsets.symmetric(vertical: 15),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(25),
                     side: BorderSide(color: Colors.grey.shade300),
                   ),
                   elevation: _isHovered ? 4 : 2,
                 ),
                 child: Text(
                   tool['name'] as String,
                   style: TextStyle(
                     fontSize: 18,
                     fontWeight: FontWeight.bold,
                     color: Colors.black,
                   ),
                 ),
               ),
             ),
           ),
        ],
      ),
    );
  }

  void _navigateToTool(String toolName) {
    // Track the activity
    final activity = RecentActivityItem(
      name: toolName,
      imagePath: widget.tools.firstWhere((t) => t['name'] == toolName)['image'],
      timestamp: DateTime.now(),
      routeName: _getRouteName(toolName),
    );
    ActivityTracker().trackActivity(activity);

    // Navigate based on category and tool name
    if (widget.category == 'vision') {
      _handleVisionToolNavigation(toolName);
    } else if (widget.category == 'mind') {
      _handleMindToolNavigation(toolName);
    } else if (widget.category == 'activity') {
      _handleActivityToolNavigation(toolName);
    }
  }

  String _getRouteName(String toolName) {
    // Return appropriate route names for navigation
    switch (toolName) {
      case 'Start guided journey':
        return widget.category == 'vision' ? '/vision-journey' : '/distract-journey';
      case 'Vision Boards':
        return '/vision-board';
      case 'Weekly Planners':
        return '/weekly-planner';
      case 'To do List':
        return '/annual-planner';
      case 'Fun Calendars':
        return '/annual-calendar';
      case 'Thought Shredder':
        return '/thought-shredder';
      case 'Smile Therapy':
        return '/make-me-smile';
      case 'Break Things':
        return '/break-things';
      case 'Bubble Wrap Popper':
        return '/bubble-wrap-popper';
      case 'Digital Coloring':
        return '/color-me-now';
      case 'Memory Game':
        return '/memory-game';
      case 'Riddles':
        return '/riddle-quiz';
      case 'Sliding Puzzle':
        return '/sliding-puzzle';
      default:
        return '/dashboard';
    }
  }

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
          MaterialPageRoute(builder: (context) => const VisionBoardTemplateSelectionPage()),
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

  void _handleMindToolNavigation(String toolName) {
    switch (toolName) {
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

  String get pageName => widget.categoryName;
}
