import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';

class BubbleWrapPopperPage extends StatefulWidget {
  const BubbleWrapPopperPage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/bubble-wrap-popper';

  @override
  _BubbleWrapPopperPageState createState() => _BubbleWrapPopperPageState();
}

class _BubbleWrapPopperPageState extends State<BubbleWrapPopperPage>
    with ActivityTrackerMixin {
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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Wrap Popper'),
      ),
      body: SingleChildScrollView(
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset all bubbles
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
                      poppedCount = 0;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Reset Bubbles'),
                ),
              ],
            ),
          ),
        ),
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
