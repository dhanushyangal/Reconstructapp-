import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../services/tool_usage_service.dart';
import '../components/nav_logpage.dart';
import '../Reset_my_emotions/mind_tool_success_page.dart';

class BubbleWrapPopperPage extends StatefulWidget {
  const BubbleWrapPopperPage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/bubble-wrap-popper';

  @override
  _BubbleWrapPopperPageState createState() => _BubbleWrapPopperPageState();
}

class _BubbleWrapPopperPageState extends State<BubbleWrapPopperPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  final int rows = 10;
  final int cols = 9;
  late List<List<BubbleState>> bubbleStates;
  int poppedCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // List of colors for popped bubbles
  final List<Color> popColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
    Colors.yellow,
    Colors.cyan,
  ];
  
  // Progress bar animation
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: 0.75, // 75% progress for mind tools
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
    
    // Initialize all bubbles as unpopped
    bubbleStates = List.generate(
      rows,
      (i) => List.generate(
        cols,
        (j) => BubbleState(
          isPopped: false,
          color: Colors.grey[300]!,
        ),
      ),
    );

    // Pre-pop some bubbles for demonstration
    // Create a pattern of colored bubbles similar to the image
    // _createInitialPattern(random); // Commented out to start with all bubbles unpopped

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Bubble Wrap Popper',
        imagePath: 'assets/Mind_tools/bubble-popper.png',
        timestamp: DateTime.now(),
        routeName: BubbleWrapPopperPage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Save tool usage
  Future<void> _saveToolUsage() async {
    final toolUsageService = ToolUsageService();
    await toolUsageService.saveToolUsage(
      toolName: 'Bubble Wrap Popper',
      category: ToolUsageService.categoryResetEmotions,
      metadata: {
        'toolType': 'release_negative_thoughts',
        'bubblesPopped': poppedCount,
      },
    );
  }

  // Updated function to log activity for tracking using Supabase
  Future<void> _logActivity() async {
    try {
      final user = AuthService.instance.currentUser;
      final email = user?.email;
      final userName = user?.userMetadata?['name'] ??
          user?.userMetadata?['username'] ??
          user?.email?.split('@')[0];
      if (email == null) {
        debugPrint(
            'No authenticated user found for Bubble Wrap Popper activity');
        return;
      }
      final service = SupabaseDatabaseService();
      final today = DateTime.now();
      final result = await service.upsertMindToolActivity(
        email: email,
        userName: userName,
        date: today,
        toolType: 'bubble_wrap_popper',
      );
      debugPrint(
          'Bubble Wrap Popper activity upsert result: \\${result['message']}');
    } catch (e) {
      debugPrint('Error logging Bubble Wrap Popper activity: $e');
    }
  }

  Future<void> _onBubbleTap(int row, int col) async {
    try {
      await _audioPlayer.play(AssetSource('sounds/pop.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
    if (bubbleStates[row][col].isPopped) {
      setState(() {
        bubbleStates[row][col].isPopped = false;
        bubbleStates[row][col].color = Colors.grey[300]!;
        poppedCount--;
      });
    } else {
      setState(() {
        bubbleStates[row][col].isPopped = true;
        bubbleStates[row][col].color =
            popColors[math.Random().nextInt(popColors.length)];
        poppedCount++;
        // Track bubble pop action
        trackButtonTap('Bubble Pop', additionalDetails: 'row:$row col:$col');
      });
      await _logActivity();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Bubble Wrap Popper',
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
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                const Text(
                  'Never-ending Online Bubble Wrap Popper',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Having trouble focusing?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Working professionals, students and founders are loving our satisfying never-ending online bubble wrap. '
                  'It\'s perfect for when you need some downtime or just help to refocus.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Improved focus helps in better outputs.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // Bubble wrap grid
                Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 5,
                      crossAxisSpacing: 5,
                    ),
                    itemCount: rows * cols,
                    itemBuilder: (context, index) {
                      final row = index ~/ cols;
                      final col = index % cols;
                      return BubbleWidget(
                        isPopped: bubbleStates[row][col].isPopped,
                        color: bubbleStates[row][col].color,
                        onTap: () async => _onBubbleTap(row, col),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bubbles burst: $poppedCount',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _saveToolUsage();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MindToolSuccessPage(
                            toolName: 'Bubble Wrap Popper',
                            nextToolName: 'Build Self Love',
                            nextToolRoute: '/build-self-love',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF23C4F7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 4,
                      shadowColor: Color(0xFF23C4F7).withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BubbleState {
  bool isPopped;
  Color color;

  BubbleState({
    required this.isPopped,
    required this.color,
  });
}

class BubbleWidget extends StatelessWidget {
  final bool isPopped;
  final Color color;
  final Future<void> Function() onTap;

  const BubbleWidget({
    super.key,
    required this.isPopped,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => await onTap(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isPopped ? color : Colors.grey[300],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isPopped ? 0.1 : 0.3),
              spreadRadius: isPopped ? 0 : 1,
              blurRadius: isPopped ? 2 : 4,
              offset: Offset(0, isPopped ? 1 : 2),
            ),
          ],
          gradient: isPopped
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[200]!,
                    Colors.grey[400]!,
                  ],
                ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: null,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
