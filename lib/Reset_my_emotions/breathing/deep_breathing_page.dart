import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/activity_tracker_mixin.dart';
import '../../components/nav_logpage.dart';
import '../../Reset_my_emotions/breathing_success_page.dart';

class DeepBreathingPage extends StatefulWidget {
  const DeepBreathingPage({super.key});

  @override
  State<DeepBreathingPage> createState() => _DeepBreathingPageState();
}

class _DeepBreathingPageState extends State<DeepBreathingPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  // Animation controllers
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;
  AnimationController? _breathingAnimationController;
  Animation<double>? _breathingAnimation;
  
  // Exercise state
  bool _isRunning = false;
  int _currentPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _exerciseCount = 0;
  int _breathingCycles = 0;
  Timer? _phaseTimer;
  double _lastProgress = 0.0;
  
  // Breathing phases
  final List<String> _phases = ['Inhale', 'Hold', 'Exhale', 'Hold'];
  final List<Color> _phaseColors = [
    Colors.blue[300]!,
    Colors.blue[400]!,
    Colors.blue[500]!,
    Colors.blue[600]!,
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
      end: 0.75, // 75% progress for deep breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize breathing animation - 10 seconds for ball animation
    _breathingAnimationController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );
    
    _breathingAnimation = CurvedAnimation(
      parent: _breathingAnimationController!,
      curve: Curves.linear,
    );
    
    // Add listener to track breathing cycles and phase changes
    _breathingAnimationController!.addListener(() {
      if (_isRunning) {
        final progress = _breathingAnimationController!.value;
        
        // Track phase changes
        int newPhase;
        if (progress < 0.25) {
          newPhase = 0; // Inhale
        } else if (progress < 0.5) {
          newPhase = 1; // Hold
        } else if (progress < 0.75) {
          newPhase = 2; // Exhale
        } else {
          newPhase = 3; // Hold
        }
        
        if (newPhase != _currentPhase) {
          setState(() {
            _currentPhase = newPhase;
          });
        }
        
        // Track cycle completion - when progress resets from near 1.0 to 0.0
        if (_lastProgress > 0.9 && progress < 0.1) {
          setState(() {
            _breathingCycles++;
            _exerciseCount = _breathingCycles; // Update exercise count in real-time
          });
        }
        _lastProgress = progress;
      }
    });
    
    // Start the progress animation
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    _breathingAnimationController?.dispose();
    _phaseTimer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _currentPhase = 0;
      _lastProgress = 0.0;
    });
    
    // Track the activity
    trackClick('deep_breathing_start');
    
    // Start the breathing animation (repeat)
    _breathingAnimationController!.repeat();
  }

  void _stopExercise() {
    setState(() {
      _isRunning = false;
      _currentPhase = 0;
    });
    
    // Track the activity
    trackClick('deep_breathing_stop');
    
    // Stop animations
    _breathingAnimationController!.stop();
    _breathingAnimationController!.reset();
    _phaseTimer?.cancel();
    
    // Exercise count is already updated in real-time, no need to update here
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Deep Breathing',
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
                           // Breathing ball animation
                           GestureDetector(
                             onTap: () {
                               if (!_isRunning) {
                                 _startExercise();
                               }
                             },
                             child: Container(
                               width: 350,
                               height: 350,
                               decoration: BoxDecoration(
                                 color: Colors.white,
                                 borderRadius: BorderRadius.circular(20),
                               ),
                               child: Stack(
                                 children: [
                                   _isRunning
                                       ? AnimatedBuilder(
                                           animation: _breathingAnimation!,
                                           builder: (context, child) {
                                             double progress = _breathingAnimation!.value;
                                             bool goingUp = progress < 0.5;
                                             double t = goingUp ? (progress / 0.5) : ((progress - 0.5) / 0.5);
                                             
                                             return CustomPaint(
                                               size: Size(350, 350),
                                               painter: StairsAndBallPainter(progress, t, goingUp, isRunning: true),
                                             );
                                           },
                                         )
                                       : CustomPaint(
                                           size: Size(350, 350),
                                           painter: StairsAndBallPainter(0, 0, true, isRunning: false),
                                         ),
                                   
                                   // Tap to start overlay
                                   if (!_isRunning)
                                     Container(
                                       width: 350,
                                       height: 350,
                                       decoration: BoxDecoration(
                                         color: Colors.white.withOpacity(0.9),
                                         borderRadius: BorderRadius.circular(20),
                                         border: Border.all(
                                           color: Colors.blue[300]!,
                                           width: 3,
                                         ),
                                         boxShadow: [
                                           BoxShadow(
                                             color: Colors.blue[100]!,
                                             blurRadius: 10,
                                             spreadRadius: 2,
                                           ),
                                         ],
                                       ),
                                       child: Center(
                                         child: Column(
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Icon(
                                               Icons.touch_app,
                                               size: 40,
                                               color: Colors.blue[600],
                                             ),
                                             SizedBox(height: 8),
                                             Text(
                                               'Tap to Start',
                                               style: TextStyle(
                                                 fontSize: 20,
                                                 fontWeight: FontWeight.bold,
                                                 color: Colors.blue[600],
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ),
                                 ],
                               ),
                             ),
                           ),
                          
                          SizedBox(height: 20),
                          
                          // Current phase text
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: _phaseColors[_currentPhase].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _phaseColors[_currentPhase],
                                width: 2,
                              ),
                            ),
                            child: Text(
                              _phases[_currentPhase],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _phaseColors[_currentPhase],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Exercise stats
                          Text(
                            'Total Breathing Cycles: $_exerciseCount',
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
                              if (_isRunning)
                                ElevatedButton(
                                  onPressed: _stopExercise,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[800],
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
                                )
                              else
                                ElevatedButton(
                                  onPressed: _navigateToSuccessPage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'Next',
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

  void _navigateToSuccessPage() {
    // Track the activity
    trackClick('deep_breathing_next');
    
    // Navigate to breathing success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BreathingSuccessPage(),
      ),
    );
  }

  String get pageName => 'Deep Breathing';
}

class StairsAndBallPainter extends CustomPainter {
  final double progress;
  final double t;
  final bool goingUp;
  final bool isRunning;

  StairsAndBallPainter(this.progress, this.t, this.goingUp, {required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    double stepWidth = size.width / 6;
    double stepHeight = size.height / 8;
    double ballRadius = 20;

    // Center the steps and move them down
    double stepsOriginX = (size.width - (stepWidth * 5)) / 2;
    double stepsOriginY = size.height * 0.85; // Move steps down from 0.8 to 0.85

    if (!isRunning) {
      // Draw static steps when not running
      Path steps = Path()..moveTo(stepsOriginX, stepsOriginY);
      for (int i = 0; i < 5; i++) {
        steps.relativeLineTo(0, -stepHeight);
        steps.relativeLineTo(stepWidth, 0);
      }
      canvas.drawPath(steps, paint);

      // Draw static ball at the bottom - positioned on the first step
      canvas.drawCircle(
          Offset(stepsOriginX + stepWidth * 0.3, stepsOriginY) - Offset(0, ballRadius + 43), 
          ballRadius, 
          Paint()..color = Colors.blue[300]!..style = PaintingStyle.fill);
    } else if (goingUp) {
      // Draw steps
      Path steps = Path()..moveTo(stepsOriginX, stepsOriginY);
      for (int i = 0; i < 5; i++) {
        steps.relativeLineTo(0, -stepHeight);
        steps.relativeLineTo(stepWidth, 0);
      }
      canvas.drawPath(steps, paint);

      // Ball jumping step by step - only 4 steps instead of 5
      int stepIndex = (t * 4).floor().clamp(0, 3);
      double localT = (t * 4) - stepIndex;

      // Start and end corners for this jump - adjust for better step alignment
      double startX = stepsOriginX + stepIndex * stepWidth + stepWidth * 0.3; // Move ball more to the right on each step
      double startY = stepsOriginY - stepIndex * stepHeight;
      double endX = stepsOriginX + (stepIndex + 1) * stepWidth + stepWidth * 0.3; // Land more on the step
      double endY = stepsOriginY - (stepIndex + 1) * stepHeight;

      // Linear path
      double x = startX + (endX - startX) * localT;
      double y = startY + (endY - startY) * localT;

      // Add arc (parabola) - more realistic jump
      double jumpHeight = stepHeight * 1.2;
      y -= jumpHeight * (4 * localT * (1 - localT));

      // Draw ball aligned to step
      canvas.drawCircle(
          Offset(x, y) - Offset(0, ballRadius + 43), 
          ballRadius, 
          Paint()..color = Colors.blue[300]!..style = PaintingStyle.fill);
    } else {
      // Draw slant (aligned with steps) - match the step positions exactly
      Path slide = Path()
        ..moveTo(stepsOriginX, stepsOriginY)
        ..lineTo(stepsOriginX + stepWidth * 5, stepsOriginY - 5 * stepHeight);
      canvas.drawPath(slide, paint);

      // Ball sliding down - follow the slant line properly
      double x = stepsOriginX + stepWidth * 5 - (stepWidth * 5 * t);
      double y = stepsOriginY - 5 * stepHeight + (5 * stepHeight * t);

      canvas.drawCircle(
          Offset(x, y) - Offset(0, ballRadius), 
          ballRadius, 
          Paint()..color = Colors.blue[300]!..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
