import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../components/nav_logpage.dart';
import '../Plan_my_future/mind_tool_success_page.dart';

class BreakThingsPage extends StatefulWidget {
  const BreakThingsPage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/break-things';

  @override
  _BreakThingsPageState createState() => _BreakThingsPageState();
}

class _BreakThingsPageState extends State<BreakThingsPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int brokenCount = 0;

  // Grid setup
  final int rows = 3;
  final int cols = 5;

  // List of breakable items
  late List<BreakableItem> breakableItems;

  // Define different object types
  final List<String> objectTypes = ['glass', 'plate', 'watermelon', 'chair'];

  // Controllers for animations
  Map<int, AnimationController> animationControllers = {};
  
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

    // Initialize the grid of objects
    _initializeBreakableItems();

    // Track this page visit in recent activities
    _trackActivity();
  }

  void _initializeBreakableItems() {
    // Create a list of breakable items
    breakableItems = [];

    // Add 5 plates (first)
    for (int i = 0; i < 5; i++) {
      breakableItems.add(BreakableItem(
        type: 'plate',
        assetPath: 'assets/Mind_tools/plate.png',
        soundPath: 'sounds/plates-break.mp3',
        isBroken: false,
      ));
    }

    // Add 5 glasses (second)
    for (int i = 0; i < 5; i++) {
      breakableItems.add(BreakableItem(
        type: 'glass',
        assetPath: 'assets/Mind_tools/water_glass.png',
        soundPath: 'sounds/glass-break.mp3',
        isBroken: false,
      ));
    }

    // Add 5 watermelons (third)
    for (int i = 0; i < 5; i++) {
      breakableItems.add(BreakableItem(
        type: 'watermelon',
        assetPath: 'assets/Mind_tools/watermelon.png',
        soundPath: 'sounds/watermelon-break.mp3',
        isBroken: false,
      ));
    }

    // Add 5 chairs (fourth)
    for (int i = 0; i < 5; i++) {
      breakableItems.add(BreakableItem(
        type: 'chair',
        assetPath: 'assets/Mind_tools/chair.png',
        soundPath: 'sounds/chair-break.mp3',
        isBroken: false,
      ));
    }

    // Initialize animation controllers for each item
    for (int i = 0; i < breakableItems.length; i++) {
      animationControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  // Updated function to log activity for tracking using Supabase
  Future<void> _logActivity() async {
    try {
      debugPrint('🔥 Break Things: Starting activity logging...');
      final user = AuthService.instance.currentUser;
      final email = user?.email;
      final userName = user?.userMetadata?['name'] ??
          user?.userMetadata?['username'] ??
          user?.email?.split('@')[0];

      debugPrint('👤 Break Things: User email: $email, userName: $userName');
      if (email == null) {
        debugPrint('❌ Break Things: No authenticated user found');
        return;
      }

      final service = SupabaseDatabaseService();
      final today = DateTime.now();
      debugPrint(
          '📅 Break Things: Logging activity for date: ${today.toIso8601String().split('T')[0]}');

      final result = await service.upsertMindToolActivity(
        email: email,
        userName: userName,
        date: today,
        toolType: 'break_things',
      );

      debugPrint('✅ Break Things activity upsert result: ${result['message']}');
      debugPrint('🎯 Break Things activity logged successfully!');
    } catch (e) {
      debugPrint('❌ Error logging Break Things activity: $e');
    }
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Break Things',
        imagePath: 'assets/Mind_tools/break-things.png',
        timestamp: DateTime.now(),
        routeName: BreakThingsPage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  void _breakItem(int index) async {
    if (breakableItems[index].isBroken) return;
    try {
      await _audioPlayer.play(AssetSource(breakableItems[index].soundPath));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
    animationControllers[index]?.forward().then((_) {
      animationControllers[index]?.reset();
    });
    setState(() {
      breakableItems[index].isBroken = true;
      brokenCount++;
    });
    // Track break action
    trackButtonTap('Break Item', additionalDetails: breakableItems[index].type);
    await _logActivity();
  }

  Future<void> _resetAllItems() async {
    setState(() {
      for (var item in breakableItems) {
        item.isBroken = false;
      }
      brokenCount = 0;
    });
    
    // Navigate to success page after reset
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MindToolSuccessPage(
          toolName: 'Break Things',
          nextToolName: 'Build Self Love',
          nextToolRoute: '/build-self-love',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _progressAnimationController?.dispose();

    // Dispose all animation controllers
    for (var controller in animationControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Break Things',
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
                  'Click and break things!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Rage is an intruder that overtakes our bodies in response to a trigger.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'The heart races and adrenelin pumps through us releasing all that pent-up energy.',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '\'Break things\' and release that rage!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Grid of breakable items
                Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: breakableItems.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: animationControllers[index] ??
                            AnimationController(
                                vsync: this, duration: Duration.zero),
                        builder: (context, child) {
                          final animation = animationControllers[index];
                          final rotationValue = animation != null
                              ? math.sin(animation.value * math.pi * 2) * 0.2
                              : 0.0;

                          return Transform.scale(
                            scale: breakableItems[index].isBroken
                                ? 0.9
                                : 1.0 - (animation?.value ?? 0) * 0.1,
                            child: Transform.rotate(
                              angle: rotationValue,
                              child: GestureDetector(
                                onTap: () => _breakItem(index),
                                child: Opacity(
                                  opacity: breakableItems[index].isBroken
                                      ? 0.5
                                      : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          breakableItems[index].assetPath,
                                          fit: BoxFit.contain,
                                        ),
                                                                                 // TODO: Add broken assets when available
                                         // if (breakableItems[index].isBroken)
                                         //   Container(
                                         //     decoration: BoxDecoration(
                                         //       image: DecorationImage(
                                         //         image: AssetImage(
                                         //             'assets/Mind_tools/${breakableItems[index].type}_broken.png'),
                                         //         fit: BoxFit.contain,
                                         //       ),
                                         //     ),
                                         //   ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Things broken: $brokenCount / ${breakableItems.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _resetAllItems,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    child: const Text(
                      'Reset All Items',
                      style: TextStyle(fontSize: 16),
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

class BreakableItem {
  final String type;
  final String assetPath;
  final String soundPath;
  bool isBroken;

  BreakableItem({
    required this.type,
    required this.assetPath,
    required this.soundPath,
    required this.isBroken,
  });
}
