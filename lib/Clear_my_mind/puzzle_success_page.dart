import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import '../services/tool_usage_service.dart';
import 'digital_coloring_page.dart';
import 'sliding_puzzles_page.dart';
import 'memory_games_page.dart';

class PuzzleSuccessPage extends StatefulWidget {
  const PuzzleSuccessPage({super.key});

  @override
  State<PuzzleSuccessPage> createState() => _PuzzleSuccessPageState();
}

class _PuzzleSuccessPageState extends State<PuzzleSuccessPage>
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
      ToolUsageService.categoryClearMind,
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
    return "Puzzle complete!\nTime to boost your focus.";
  }

  String _getSubtitleMessage() {
    return "Push yourself with a tough challenge for\nthat extra lift.";
  }

  String _getNextToolText() {
    return "Try Memory Games";
  }

  String _getAlternativeToolText() {
    // Cycle through different clear mind tools
    final tools = ['Sliding puzzle', 'Digital coloring sheet'];
    final randomIndex = DateTime.now().millisecondsSinceEpoch % tools.length;
    return tools[randomIndex];
  }

  void _navigateToNextTool() {
    // Track the activity
    trackClick('puzzle_success_continue');

    // Navigate to Memory Games page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemoryGamesPage(),
      ),
    );
  }

  void _navigateToAlternativeTool() {
    // Track the activity
    trackClick('puzzle_success_alternative_tool');

    // Get a random clear mind tool
    final tools = ['Sliding puzzle', 'Digital coloring sheet'];
    final randomIndex = DateTime.now().millisecondsSinceEpoch % tools.length;
    final selectedTool = tools[randomIndex];

    // Navigate to specific clear mind tool
    Widget nextPage;
    switch (selectedTool) {
      case 'Sliding puzzle':
        // Navigate back to sliding puzzles page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SlidingPuzzlesPage(),
          ),
        );
        return;
      case 'Digital coloring sheet':
        nextPage = const DigitalColoringPage();
        break;
      default:
        nextPage = const DigitalColoringPage();
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
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
                  
                  // Star count display (yellow with orange border as per image)
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
                        color: Colors.yellow,
                        border: Border.all(
                          color: Colors.orange,
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
                          "try a different ",
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

  String get pageName => 'Puzzle Success';
}
