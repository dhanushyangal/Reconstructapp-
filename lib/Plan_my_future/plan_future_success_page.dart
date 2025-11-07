import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import '../services/tool_usage_service.dart';
import '../pages/active_dashboard_page.dart';
import '../pages/active_tasks_page.dart';

class PlanFutureSuccessPage extends StatefulWidget {
  final String toolType; // 'annual_goals', 'weekly_goals', 'monthly_goals', 'daily_goals'
  final String toolName;

  const PlanFutureSuccessPage({
    super.key,
    required this.toolType,
    required this.toolName,
  });

  @override
  State<PlanFutureSuccessPage> createState() => _PlanFutureSuccessPageState();
}

class _PlanFutureSuccessPageState extends State<PlanFutureSuccessPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;
  int _starCount = 0;
  final ToolUsageService _toolUsageService = ToolUsageService();

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 1.0, // 100% progress for success page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
    
    // Load star count immediately
    _loadStarCount();
    
    // Reload star count after a short delay to ensure latest count is shown
    // (in case tool usage was just saved)
    Future.delayed(Duration(milliseconds: 500), () {
      _loadStarCount();
    });
  }
  
  Future<void> _loadStarCount() async {
    final count = await _toolUsageService.getUniqueToolsCountForToday(
      ToolUsageService.categoryPlanFuture,
    );
    if (mounted) {
      setState(() {
        _starCount = count;
      });
    }
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    super.dispose();
  }

  String _getSuccessMessage() {
    switch (widget.toolType) {
      case 'annual_goals':
        return "Well done! You've got a clear vision for your future.";
      case 'weekly_goals':
        return "Excellent! You've planned your week ahead.";
      case 'monthly_goals':
        return "Great! You've set your monthly targets.";
      case 'daily_goals':
        return "Perfect! You've organized your daily goals.";
      default:
        return "Well done! You've got a clear vision for your future.";
    }
  }

  String _getSubtitleMessage() {
    switch (widget.toolType) {
      case 'annual_goals':
        return "Now, let's break it down into monthly targets for easy progress.";
      case 'weekly_goals':
        return "Now, let's organize your daily tasks for better productivity.";
      case 'monthly_goals':
        return "Now, let's plan your daily activities to stay on track.";
      case 'daily_goals':
        return "Now, let's review your weekly goals for consistency.";
      default:
        return "Now, let's break it down into monthly targets for easy progress.";
    }
  }

  String _getNextToolText() {
    switch (widget.toolType) {
      case 'annual_goals':
        return "Plan your monthly goals";
      case 'weekly_goals':
        return "Plan your daily goals";
      case 'monthly_goals':
        return "Plan your daily goals";
      case 'daily_goals':
        return "Plan your weekly goals";
      default:
        return "Plan your monthly goals";
    }
  }

  String _getAlternativeToolText() {
    switch (widget.toolType) {
      case 'annual_goals':
        return "Your Annual Goals";
      case 'weekly_goals':
        return "Your Weekly Goals";
      case 'monthly_goals':
        return "Your Monthly Goals";
      case 'daily_goals':
        return "Your Daily Goals";
      default:
        return "Your Annual Goals";
    }
  }

  void _navigateToNextTool() {
    // Track the activity
    trackClick('plan_future_success_continue');
    
    // Navigate to Plan my future CategoryToolsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryToolsPage(
          category: 'vision',
          categoryName: 'Plan my future',
          tools: [
            {
              'name': 'Plan your annual goals',
              'image': 'assets/Plan_my_future-images/annual.png'
            },
            {
              'name': 'Plan your Weekly goals',
              'image': 'assets/Plan_my_future-images/weekly.png'
            },
            {
              'name': 'Plan your Monthly goals',
              'image': 'assets/Plan_my_future-images/monthly.png'
            },
            {
              'name': 'Plan your Daily goals',
              'image': 'assets/Plan_my_future-images/daily.png'
            },
          ],
        ),
      ),
    );
  }

  void _navigateToAlternativeTool() {
    // Track the activity
    trackClick('plan_future_success_alternative_tool');
    
    // Navigate to Active Tasks Page to view saved goals
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ActiveTasksPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Great Job!',
      showBackButton: true,
      selectedIndex: 2, // Dashboard index
      // Using default navigation handler from NavLogPage
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
          
          // Main content
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main success message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      _getSuccessMessage(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // "You collected" text
                  Text(
                    "You collected",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Star count display (light green with white border as per image)
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/tracker',
                        (route) => false,
                      );
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.lightGreen,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$_starCount',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              _starCount == 1 ? 'star' : 'stars',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Subtitle message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Text(
                      _getSubtitleMessage(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Primary action button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _navigateToNextTool,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Color(0xFF23C4F7), // Light blue border
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          _getNextToolText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // OR separator
                  Text(
                    "OR",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Secondary action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "try add more cards to ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: _navigateToAlternativeTool,
                          child: Text(
                            _getAlternativeToolText(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF23C4F7),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get pageName => 'Plan Future Success';
}

