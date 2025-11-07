import 'package:flutter/material.dart';
import '../../utils/activity_tracker_mixin.dart';
import '../../services/tool_usage_service.dart';
import '../../components/nav_logpage.dart';
import '../../Reset_my_emotions/breathing_success_page.dart';

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
  int _breathingCycles = 0;
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
      end: 0.75, // 75% progress for intentional breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize breathing animation - 15 seconds for one complete cycle
    _breathingAnimationController = AnimationController(
      duration: Duration(seconds: 15), // 15 seconds for full cycle (3.75 seconds each phase)
      vsync: this,
    );
    
    // Add listener to track breathing cycles and phase changes
    _breathingAnimationController!.addListener(() {
      if (_isRunning) {
        final progress = _breathingAnimationController!.value;
        
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
    super.dispose();
  }

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _lastProgress = 0.0;
    });
    
    // Track the activity
    trackClick('intentional_breathing_start');
    
    // Start the breathing animation (repeat)
    _breathingAnimationController!.repeat();
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
    
    // Exercise count is already updated in real-time, no need to update here
  }

  int _getCurrentPhase() {
    final progress = _breathingAnimationController?.value ?? 0.0;
    if (progress < 0.25) {
      return 0; // Inhale
    } else if (progress < 0.5) {
      return 1; // Hold
    } else if (progress < 0.75) {
      return 2; // Exhale
    } else {
      return 3; // Hold
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Intentional Breathing',
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
                           // Breathing circle animation
                           GestureDetector(
                             onTap: () {
                               if (!_isRunning) {
                                 _startExercise();
                               }
                             },
                             child: Container(
                               width: 320,
                               height: 320,
                               child: Stack(
                                 children: [
                                   AnimatedBuilder(
                                     animation: _isRunning ? _breathingAnimationController! : const AlwaysStoppedAnimation(0.0),
                                     builder: (context, child) {
                                       return CustomPaint(
                                         painter: BreathingCirclePainter(
                                           _isRunning ? _breathingAnimationController!.value : 0.0,
                                           _isRunning ? _getCurrentPhase() : 0,
                                         ),
                                         size: const Size(320, 320),
                                       );
                                     },
                                   ),
                                   
                                   // Tap to start overlay
                                   if (!_isRunning)
                                     Container(
                                       width: 320,
                                       height: 320,
                                       decoration: BoxDecoration(
                                         color: Colors.white.withOpacity(0.9),
                                         borderRadius: BorderRadius.circular(160),
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
    trackClick('intentional_breathing_next');
    
    // Save tool usage
    _saveToolUsage();
    
    // Navigate to breathing success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BreathingSuccessPage(),
      ),
    );
  }

  // Save tool usage
  Future<void> _saveToolUsage() async {
    final toolUsageService = ToolUsageService();
    await toolUsageService.saveToolUsage(
      toolName: 'Intentional Breathing',
      category: ToolUsageService.categoryResetEmotions,
      metadata: {
        'toolType': 'master_your_breathing',
        'breathingCycles': _breathingCycles,
      },
    );
  }

  String get pageName => 'Intentional Breathing';
}

class BreathingCirclePainter extends CustomPainter {
  final double progress;
  final int currentPhase;

  BreathingCirclePainter(this.progress, this.currentPhase);

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    
    // Calculate circle radius based on breathing phase
    double radius;
    String phaseText;
    Color circleColor;
    
    if (progress < 0.25) {
      // Inhale phase - circle expands
      double inhaleProgress = progress / 0.25;
      radius = 40 + (inhaleProgress * 80); // From 40 to 120
      phaseText = 'Inhale';
      circleColor = Colors.blue[300]!;
    } else if (progress < 0.5) {
      // Hold phase - circle stays large
      radius = 120;
      phaseText = 'Hold';
      circleColor = Colors.blue[400]!;
    } else if (progress < 0.75) {
      // Exhale phase - circle contracts
      double exhaleProgress = (progress - 0.5) / 0.25;
      radius = 120 - (exhaleProgress * 80); // From 120 to 40
      phaseText = 'Exhale';
      circleColor = Colors.blue[500]!;
    } else {
      // Hold phase - circle stays small
      radius = 40;
      phaseText = 'Hold';
      circleColor = Colors.blue[600]!;
    }
    
    // Draw outer circle (permanent, fixed size)
    final Paint outerRingPaint = Paint()
      ..color = Colors.blue[400]!.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    
    canvas.drawCircle(center, 120, outerRingPaint);
    
    // Draw blue fill between outer and inner circles
    final Paint fillPaint = Paint()
      ..color = circleColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 120, fillPaint);
    
    // Draw inner circle (moves with breathing - filled with white to create the gap)
    final Paint circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, circlePaint);
    
    // Draw inner circle border
    final Paint borderPaint = Paint()
      ..color = circleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawCircle(center, radius, borderPaint);
    
    // Draw phase text in the center
    final textPainter = TextPainter(
      text: TextSpan(
        text: phaseText,
        style: TextStyle(
          color: circleColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant BreathingCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.currentPhase != currentPhase;
  }
}
