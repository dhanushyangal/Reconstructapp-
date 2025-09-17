import 'package:flutter/material.dart';
import '../vision_bord/vision_board_page.dart';
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
import '../utils/activity_tracker_mixin.dart';
import '../vision_bord_plan/vision_board_template_selection_page.dart';

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

  // Tool data organized by category
  final Map<String, List<Map<String, dynamic>>> _tools = {
    'vision': [
      {'name': 'Plan your annual goals', 'image': 'assets\Plan_my_future-images\annual.png'},
      {'name': 'Plan your Weekly goals', 'image': 'assets\Plan_my_future-images\weekly.png'},
      {
        'name': 'Plan your Monthly goals',
        'image': 'assets\Plan_my_future-images\monthly.png'
      },
      {'name': 'Plan your Daily goals', 'image': 'assets\Plan_my_future-images\daily.png'}
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8FAFF)],
          ),
        ),
        child: _buildHeroSection(),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 10),
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
              SizedBox(height: 30),

              // Main action buttons
              _buildActionButton(
                title: "Plan my future",
                subtitle: "Turn ideas into a clear path forward.",
                color: Color(0xFF81D0FF), // Light blue background
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
                color: Color(0xFF60BAFF), // Medium blue background
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
                color: Color(0xFF5AB8EE), // Darker blue background
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
              SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.black,
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
    with ActivityTrackerMixin, TickerProviderStateMixin {
  bool _isHovered = false;
  late PageController _pageController;
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.25, // 25% progress for category tools page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

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
          
          // Fixed text above images
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Take the first step — choose a tool.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 15),

           // Sliding tools view - moved to bottom
           Expanded(
             child: PageView.builder(
               controller: _pageController,
               itemCount: widget.tools.length,
               itemBuilder: (context, index) {
                 final tool = widget.tools[index];
                 return _buildToolSlide(tool, index);
               },
             ),
           ),

          // Progress bar at the bottom
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tool Selection Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                      builder: (context, child) {
                        return Text(
                          '${((_progressAnimation?.value ?? 0.0) * 100).toInt()}% Complete',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF23C4F7),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: AnimatedBuilder(
                      animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                      builder: (context, child) {
                        return LinearProgressIndicator(
                          value: _progressAnimation?.value ?? 0.0,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF23C4F7)),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Choose a tool to continue your journey and unlock more progress!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildToolSlide(Map<String, dynamic> tool, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
           // Tool image
           Expanded(
             flex: 3,
             child: Container(
               width: double.infinity,
               height: 300, // Fixed height for consistent sizing
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
           ),
          
           SizedBox(height: 20),
          
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
                   padding: EdgeInsets.symmetric(vertical: 12),
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(25),
                     side: BorderSide(color: Colors.grey.shade300),
                   ),
                   elevation: _isHovered ? 9 : 2,
                 ),
                 child: Text(
                   tool['name'] as String,
                   style: TextStyle(
                     fontSize: 16,
                     fontWeight: FontWeight.bold,
                     color: Colors.black,
                   ),
                 ),
               ),
             ),
           ),
           SizedBox(height: 50),
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
      case 'Plan your annual goals':
        return '/vision-board';
      case 'Plan your Weekly goals':
        return '/weekly-planner';
      case 'Plan your Monthly goals':
        return '/annual-planner';
      case 'Plan your Daily goals':
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
      case 'Plan your annual goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisionBoardTemplateSelectionPage()),
        );
        break;
      case 'Plan your Weekly goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WeeklyPlannerPage()),
        );
        break;
      case 'Plan your Monthly goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnualPlannerPage()),
        );
        break;
      case 'Plan your Daily goals':
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
