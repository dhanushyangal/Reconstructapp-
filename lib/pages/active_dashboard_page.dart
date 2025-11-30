import 'package:flutter/material.dart';
import '../vision_bord/vision_board_page.dart';
import '../Mind_tools/thought_shredder_page.dart';
import '../Mind_tools/make_me_smile_page.dart';
import '../Mind_tools/break_things_page.dart';
import '../Activity_Tools/memory_game_page.dart';
import '../Activity_Tools/riddle_quiz_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Mind_tools/bubble_wrap_popper_page.dart';
import '../Activity_Tools/sliding_puzzle_page.dart';
import '../Activity_Tools/color_me_now.dart';
import 'dart:convert';
import '../utils/activity_tracker_mixin.dart';
import '../Plan_my_future/Annual_bord_plan/Annual_board_template_selection_page.dart';
import '../Plan_my_future/weekly_planners_plan/weekly_planner_template_selection_page.dart';
import '../Plan_my_future/Monthly_planner_plan/Monthly_planner_template_selection_page.dart';
import '../Plan_my_future/Daily_notes_plan/daily_notes_template_selection_page.dart';
import '../components/nav_logpage.dart';
import '../Reset_my_emotions/release_negative_thoughts_page.dart';
import '../Clear_my_mind/digital_coloring_page.dart';
import '../Clear_my_mind/sliding_puzzles_page.dart';
import '../Clear_my_mind/memory_games_page.dart';
import '../Reset_my_emotions/affirmation_card_page.dart';
import '../Reset_my_emotions/breathing/master_breathing_page.dart';
import '../Christmas/christmas_cutout_selection_page.dart';

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
      {'name': 'Plan your annual goals', 'image': 'assets/Plan_my_future-images/annual.png'},
      {'name': 'Plan your Weekly goals', 'image': 'assets/Plan_my_future-images/weekly.png'},
      {
        'name': 'Plan your Monthly goals',
        'image': 'assets/Plan_my_future-images/monthly.png'
      },
      {'name': 'Plan your Daily goals', 'image': 'assets/Plan_my_future-images/daily.png'},
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
    'reset_emotions': [
      {
        'name': 'Release negative thoughts',
        'image': 'assets/Reset_my_emotions-images/Release_negative_thoughts.png',
        'subcategory': true
      },
      {
        'name': 'Build positive self-talk',
        'image': 'assets/Reset_my_emotions-images/build_self_love.png',
        'subcategory': true
      },
      {
        'name': 'Master your breathing',
        'image': 'assets/Reset_my_emotions-images/master_your_breathing.png',
        'subcategory': true
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
    ],
    'clear_mind': [
      {
        'name': 'Digital coloring sheets',
        'image': 'assets/Clear_my_mind/Digital_coloring_sheets.png',
        'subcategory': true
      },
      {
        'name': 'Sliding puzzles',
        'image': 'assets/Clear_my_mind/Sliding_puzzle.png',
        'subcategory': true
      },
      {
        'name': 'Memory games',
        'image': 'assets/Clear_my_mind/Memory_game.png',
        'subcategory': true
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
            "Your daily mental\nfitness routine",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Begin your journey to a stronger mind",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
              SizedBox(height: 30),

          // Main action buttons
          _buildActionButton(
            title: "Reset my emotions",
            subtitle: "Release what's heavy and feel lighter.",
                color: Color(0xFF91D7FF), // Light blue background
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryToolsPage(
                    category: 'reset_emotions',
                    categoryName: 'Reset my emotions',
                    tools: _tools['reset_emotions']!,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildActionButton(
            title: "Clear my mind",
            subtitle: "Get a fresh start for renewed focus",
                color: Color(0xFFFFE886), // Light blue background
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryToolsPage(
                    category: 'clear_mind',
                    categoryName: 'Clear my mind',
                    tools: _tools['clear_mind']!,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildActionButton(
            title: "Plan my future",
            subtitle: "Turn goals into a clear path forward.",
                color: Color(0xFFB4DF8C), // Light blue background
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
            title: "Christmas",
            subtitle: "Choose a Christmas cutout to color.",
                color: Color(0xFFFFB6C1), // Light pink background
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChristmasCutoutSelectionPage(),
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
    return NavLogPage(
      title: widget.categoryName,
      showBackButton: true,
      selectedIndex: 2, // Dashboard index
      onNavigationTap: (index) {
        // Navigate to different pages based on index
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(context, '/browse', (route) => false);
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(context, '/tracker', (route) => false);
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
            break;
        }
      },
      body: Column(
        children: [
          // Progress bar at the top
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
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
                ),
                SizedBox(width: 16),
                AnimatedBuilder(
                  animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    return Text(
                      '${((_progressAnimation?.value ?? 0.0) * 100).toInt()}%',
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
          ),
          
          // Category name header with better styling
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Text(
          widget.categoryName,
          style: TextStyle(
                fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
                height: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          
          // Fixed text above images with better styling
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Take the first step — choose a tool.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),

           // Enhanced sliding tools view
           Expanded(
             child: Container(
               padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
             child: PageView.builder(
                 controller: _pageController,
               itemCount: widget.tools.length,
               itemBuilder: (context, index) {
                 final tool = widget.tools[index];
                 return _buildToolSlide(tool, index);
               },
               ),
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
           // Tool image with enhanced styling
           Expanded(
             flex: 3,
             child: Container(
               width: double.infinity,
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(20),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.grey.withOpacity(0.2),
                     spreadRadius: 0,
                     blurRadius: 8,
                     offset: Offset(0, 4),
                   ),
                 ],
               ),
               child: ClipRRect(
                 borderRadius: BorderRadius.circular(20),
                 child: Image.asset(
                   tool['image'] as String,
                   fit: BoxFit.contain,
                   width: double.infinity,
                   height: double.infinity,
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
          
           // Enhanced action button with better styling
           Container(
               width: double.infinity,
             padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(20),
               border: Border.all(
                 color: Colors.grey[300] ?? Colors.grey,
                 width: 1,
               ),
             ),
               child: MouseRegion(
                 onEnter: (_) => setState(() => _isHovered = true),
                 onExit: (_) => setState(() => _isHovered = false),
                 child: ElevatedButton(
                   onPressed: () {
                     _navigateToTool(tool['name'] as String);
                   },
                   style: ElevatedButton.styleFrom(
                   backgroundColor: _isHovered ? Colors.grey[50] : Colors.transparent,
                     foregroundColor: Colors.black,
                     padding: EdgeInsets.symmetric(vertical: 12),
                     shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(16),
                     ),
                   elevation: 0,
                   shadowColor: Colors.transparent,
                   ),
                   child: Text(
                     tool['name'] as String,
                     style: TextStyle(
                     fontSize: 15,
                     fontWeight: FontWeight.w600,
                     color: Colors.black87,
                     letterSpacing: 0.3,
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
    } else if (widget.category == 'reset_emotions') {
      _handleResetEmotionsToolNavigation(toolName);
    } else if (widget.category == 'activity') {
      _handleActivityToolNavigation(toolName);
    } else if (widget.category == 'clear_mind') {
      _handleClearMindToolNavigation(toolName);
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
        return '/daily-notes-template';
      case 'Thought Shredder':
        return '/thought-shredder';
      case 'Smile Therapy':
        return '/make-me-smile';
      case 'Break Things':
        return '/break-things';
      case 'Bubble Wrap Popper':
        return '/bubble-wrap-popper';
      case 'Release negative thoughts':
        return '/release-negative-thoughts';
      case 'Build positive self-talk':
        return '/build-self-love';
      case 'Master your breathing':
        return '/master-breathing';
      case 'Digital Coloring':
        return '/color-me-now';
      case 'Memory Game':
        return '/memory-game';
      case 'Riddles':
        return '/riddle-quiz';
      case 'Sliding Puzzle':
        return '/sliding-puzzle';
      case 'Digital coloring sheets':
        return '/digital-coloring';
      case 'Sliding puzzles':
        return '/sliding-puzzles';
      case 'Memory games':
        return '/memory-games';
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
          MaterialPageRoute(builder: (context) => const WeeklyPlannerTemplateSelectionPage()),
        );
        break;
      case 'Plan your Monthly goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AnnualPlannerTemplateSelectionPage()),
        );
        break;
      case 'Plan your Daily goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DailyNotesTemplateSelectionPage()),
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

  void _handleResetEmotionsToolNavigation(String toolName) {
    switch (toolName) {
      case 'Release negative thoughts':
        // Navigate to the new Release Negative Thoughts page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ReleaseNegativeThoughtsPage(),
          ),
        );
        break;
      case 'Build positive self-talk':
        // Navigate to the new Build positive self-talke page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BuildSelfLovePage(),
          ),
        );
        break;
      case 'Master your breathing':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MasterBreathingPage(),
          ),
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

  void _handleClearMindToolNavigation(String toolName) {
    switch (toolName) {
      case 'Digital coloring sheets':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DigitalColoringPage()),
        );
        break;
      case 'Sliding puzzles':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SlidingPuzzlesPage()),
        );
        break;
      case 'Memory games':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MemoryGamesPage()),
        );
        break;
      default:
        break;
    }
  }

  void _showComingSoonDialog(String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.construction,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$featureName is currently under development.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'We\'re working hard to bring you this amazing feature soon!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String get pageName => widget.categoryName;
}
