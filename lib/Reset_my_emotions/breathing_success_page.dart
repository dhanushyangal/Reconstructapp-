import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import '../services/tool_usage_service.dart';
import '../pages/active_dashboard_page.dart';
import 'affirmation_card_page.dart';

class BreathingSuccessPage extends StatefulWidget {
  const BreathingSuccessPage({super.key});

  @override
  State<BreathingSuccessPage> createState() => _BreathingSuccessPageState();
}

class _BreathingSuccessPageState extends State<BreathingSuccessPage>
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
      ToolUsageService.categoryResetEmotions,
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
    return "Awesome, you're in charge of your emotions";
  }

  String _getSubtitleMessage() {
    return "Next, let's lift your mood and welcome those happy endorphins.";
  }

  String _getNextToolText() {
    return "Clear your mind";
  }

  String _getAlternativeToolText() {
    return "Affirmation cards";
  }

  void _navigateToNextTool() {
    // Track the activity
    trackClick('breathing_success_continue');

    // Navigate to Clear my mind CategoryToolsPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryToolsPage(
          category: 'clear_mind',
          categoryName: 'Clear my mind',
          tools: [
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
          ],
        ),
      ),
    );
  }

  void _navigateToAlternativeTool() {
    // Track the activity
    trackClick('breathing_success_alternative_tool');

    // Navigate to Build Self Love page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuildSelfLovePage(),
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
                  
                  // Star count display
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
                        color: Colors.red,
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
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          "try a different tool to ",
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

  String get pageName => 'Breathing Success';
}
