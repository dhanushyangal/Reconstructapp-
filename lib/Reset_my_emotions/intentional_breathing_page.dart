import 'package:flutter/material.dart';
import 'dart:math';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';

class IntentionalBreathingPage extends StatefulWidget {
  const IntentionalBreathingPage({super.key});

  @override
  State<IntentionalBreathingPage> createState() => _IntentionalBreathingPageState();
}

class _IntentionalBreathingPageState extends State<IntentionalBreathingPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  // Animation controllers
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;
  AnimationController? _breathingAnimationController;
  
  // Exercise state
  bool _isRunning = false;
  int _exerciseCount = 0;
  
  // Breathing phases
  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Relax'];
  final List<Color> _phaseColors = [
    Colors.green,
    Colors.orange,
    Colors.blue,
    Colors.purple,
  ];

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
      end: 0.75, // 75% progress for intentional breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize breathing animation - 12 seconds total (8 to grow + 4 to shrink)
    _breathingAnimationController = AnimationController(
      duration: Duration(seconds: 12), // 12 seconds for full cycle
      vsync: this,
    );
    
    // Start the progress animation
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    _breathingAnimationController?.dispose();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
    });
    
    // Track the activity
    trackClick('intentional_breathing_start');
    
    // Start the breathing animation
    _breathingAnimationController!.forward(from: 0);
  }

  void _stopExercise() {
    setState(() {
      _isRunning = false;
    });
    
    // Track the activity
    trackClick('intentional_breathing_stop');
    
    // Stop animations
    _breathingAnimationController!.stop();
    _breathingAnimationController!.reset();
    
    // Increment exercise count
    setState(() {
      _exerciseCount++;
    });
  }

  int _getCurrentPhase() {
    final progress = _breathingAnimationController?.value ?? 0.0;
    if (progress < 0.6667) {
      return 0; // Inhale (growing sticks)
    } else {
      return 2; // Exhale (shrinking sticks)
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Intentional Breathing',
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  
                  // Breathing exercise container
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           // Breathing animation
                           Container(
                             width: 320,
                             height: 320,
                             child: AnimatedBuilder(
                               animation: _isRunning ? _breathingAnimationController! : const AlwaysStoppedAnimation(0.0),
                               builder: (context, child) {
                                 return CustomPaint(
                                   painter: StarPainter(
                                     _isRunning ? _getStickCount(_breathingAnimationController!.value) : 1,
                                     _isRunning ? _breathingAnimationController!.value : 0.0,
                                   ),
                                   size: const Size(320, 320),
                                 );
                               },
                             ),
                           ),
                          
                          SizedBox(height: 20),
                          
                          // Current phase text
                          if (_isRunning)
                            AnimatedBuilder(
                              animation: _breathingAnimationController!,
                              builder: (context, child) {
                                final currentPhase = _getCurrentPhase();
                                return Container(
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _phaseColors[currentPhase].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _phaseColors[currentPhase],
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    _phases[currentPhase],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _phaseColors[currentPhase],
                                    ),
                                  ),
                                );
                              },
                            ),
                          
                          SizedBox(height: 20),
                          
                          // Exercise stats
                          Text(
                            'Total Breathing Exercises: $_exerciseCount',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Control buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isRunning)
                                ElevatedButton(
                                  onPressed: _startExercise,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Start',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed: _stopExercise,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Stop',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                            ],
                          ),
                          
                          SizedBox(height: 20),
                        ],
                      ),
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

  int _getStickCount(double progress) {
    // Total duration is 12 seconds
    // First 8 seconds: add 1 stick per second (1 to 8 sticks)
    // Next 4 seconds: remove 2 sticks per second (8 to 0 sticks)
    
    if (progress <= 0.6667) {
      // 0 to 8 seconds: grow from 1 to 8 sticks
      // progress 0 to 0.6667 maps to 1 to 8 sticks
      return 1 + (progress / 0.6667 * 7).floor();
    } else {
      // 8 to 12 seconds: shrink from 8 to 0 sticks (remove 2 per second)
      // progress 0.6667 to 1.0 maps to 8 to 0 sticks
      double shrinkProgress = (progress - 0.6667) / 0.3333;
      return 8 - (shrinkProgress * 8).floor();
    }
  }

  String get pageName => 'Intentional Breathing';
}

class StarPainter extends CustomPainter {
  final int sticks;
  final double progress;

  StarPainter(this.sticks, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double stickLength = size.width / 2.8;
    final Offset center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < sticks; i++) {
      // Each stick rotates around the center point
      final double angle = (2 * pi / (sticks == 0 ? 1 : sticks)) * i +
          (progress * pi * 2); // rotation
      
      // Calculate both ends of the stick from the center
      final Offset startPoint = center - Offset(cos(angle), sin(angle)) * (stickLength / 2);
      final Offset endPoint = center + Offset(cos(angle), sin(angle)) * (stickLength / 2);
      
      canvas.drawLine(startPoint, endPoint, paint);
    }
    
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) {
    return oldDelegate.sticks != sticks ||
        oldDelegate.progress != progress;
  }
}
