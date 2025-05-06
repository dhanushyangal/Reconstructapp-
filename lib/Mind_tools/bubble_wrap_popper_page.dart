import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

import 'dashboard_traker.dart'; // Import the dashboard tracker

class BubbleWrapPopperPage extends StatefulWidget {
  const BubbleWrapPopperPage({super.key});

  @override
  _BubbleWrapPopperPageState createState() => _BubbleWrapPopperPageState();
}

class _BubbleWrapPopperPageState extends State<BubbleWrapPopperPage> {
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
  }

  // Updated function to log activity for tracking using the centralized method
  Future<void> _logActivity() async {
    try {
      // Call the static method from DashboardTrackerPage
      // This ensures data is saved locally first, then synced to server when online
      await DashboardTrackerPage.recordToolActivity('bubble_wrap_popper');
      debugPrint(
          'Bubble Wrap Popper activity logged - saved locally and will sync when online');
    } catch (e) {
      debugPrint('Error logging Bubble Wrap Popper activity: $e');
    }
  }

  void _onBubbleTap(int row, int col) async {
    try {
      // Play bubble pop sound whether popping or unpopping
      await _audioPlayer.play(AssetSource('sounds/pop.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }

    setState(() {
      // Toggle the bubble state
      if (bubbleStates[row][col].isPopped) {
        // If already popped, revert to unpopped
        bubbleStates[row][col].isPopped = false;
        bubbleStates[row][col].color = Colors.grey[300]!;
        poppedCount--; // Decrement the count
      } else {
        // If unpopped, pop it
        bubbleStates[row][col].isPopped = true;
        // Select a random color for the popped bubble
        bubbleStates[row][col].color =
            popColors[math.Random().nextInt(popColors.length)];
        poppedCount++; // Increment the count

        // Log activity when popping a bubble
        _logActivity();
      }
    });
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
                        onTap: () => _onBubbleTap(row, col),
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
  final VoidCallback onTap;

  const BubbleWidget({
    super.key,
    required this.isPopped,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
