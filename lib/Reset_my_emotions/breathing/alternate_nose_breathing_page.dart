import 'package:flutter/material.dart';
import 'dart:async';
import '../../utils/activity_tracker_mixin.dart';
import '../../components/nav_logpage.dart';
import '../../Reset_my_emotions/breathing_success_page.dart';

class AlternateNoseBreathingPage extends StatefulWidget {
  const AlternateNoseBreathingPage({super.key});

  @override
  State<AlternateNoseBreathingPage> createState() => _AlternateNoseBreathingPageState();
}

class _AlternateNoseBreathingPageState extends State<AlternateNoseBreathingPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  // Animation controllers
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;
  AnimationController? _breathingAnimationController;
  
  // Exercise state
  bool _isRunning = false;
  int _currentPhase = 0; // 0: Inhale, 1: Hold, 2: Exhale, 3: Hold
  int _exerciseCount = 0;
  int _breathingCycles = 0;
  Timer? _phaseTimer;
  
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
      end: 0.75, // 75% progress for alternate nose breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize breathing animation
    _breathingAnimationController = AnimationController(
      duration: Duration(seconds: 16), // 16 seconds for one complete cycle (4 seconds each phase)
      vsync: this,
    );
    
    // Add listener to track breathing cycles
    _breathingAnimationController!.addListener(() {
      if (_breathingAnimationController!.isCompleted) {
        setState(() {
          _breathingCycles++;
          _exerciseCount = _breathingCycles; // Update exercise count in real-time
        });
        // Reset and repeat for continuous breathing
        _breathingAnimationController!.reset();
        _breathingAnimationController!.forward();
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
    });
    
    // Track the activity
    trackClick('alternate_nose_breathing_start');
    
    // Start the breathing animation
    _breathingAnimationController!.forward();
    
    // Start phase timer
    _startPhaseTimer();
  }

  void _stopExercise() {
    setState(() {
      _isRunning = false;
      _currentPhase = 0;
    });
    
    // Track the activity
    trackClick('alternate_nose_breathing_stop');
    
    // Stop animations
    _breathingAnimationController!.stop();
    _breathingAnimationController!.reset();
    _phaseTimer?.cancel();
    
    // Exercise count is already updated in real-time, no need to update here
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_isRunning) {
        setState(() {
          _currentPhase = (_currentPhase + 1) % _phases.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Alternate Nostril Breathing',
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
                           // Triangle visualization
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
                                   // Background with blue gradient
                                   Container(
                                     decoration: BoxDecoration(
                                       gradient: LinearGradient(
                                         begin: Alignment.topCenter,
                                         end: Alignment.bottomCenter,
                                         colors: [
                                           Colors.blue[50]!,
                                           Colors.blue[100]!,
                                         ],
                                       ),
                                       borderRadius: BorderRadius.circular(12),
                                     ),
                                   ),
                                   
                                   // Triangle shape
                                   Center(
                                     child: CustomPaint(
                                       size: Size(240, 240),
                                       painter: TrianglePainter(
                                         phase: _currentPhase,
                                         isRunning: _isRunning,
                                         phaseColor: _phaseColors[_currentPhase],
                                       ),
                                     ),
                                   ),
                                   
                                   // Breathing indicators
                                   if (_isRunning) _buildBreathingIndicators(),
                                   
                                   // Tap to start overlay
                                   if (!_isRunning)
                                     Container(
                                       width: 320,
                                       height: 320,
                                       decoration: BoxDecoration(
                                         color: Colors.white.withOpacity(0.9),
                                         borderRadius: BorderRadius.circular(12),
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

  Widget _buildBreathingIndicators() {
    return Stack(
      children: [
        // Left side indicator (up arrow for inhale - left side of triangle)
        if (_currentPhase == 0)
          Positioned(
            left: 20,
            top: 140,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[300]!.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.blue[300],
                size: 36,
              ),
            ),
          ),
        
        // Right side indicator (down arrow for exhale - right side of triangle)
        if (_currentPhase == 2)
          Positioned(
            right: 20,
            top: 140,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue[500]!.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue[500],
                size: 36,
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToSuccessPage() {
    // Track the activity
    trackClick('alternate_nose_breathing_next');
    
    // Navigate to breathing success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BreathingSuccessPage(),
      ),
    );
  }

  String get pageName => 'Alternate Nostril Breathing';
}

class TrianglePainter extends CustomPainter {
  final int phase;
  final bool isRunning;
  final Color phaseColor;

  TrianglePainter({
    required this.phase,
    required this.isRunning,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final triangleSize = size.width * 0.6;
    
    // Create triangle path
    final trianglePath = Path();
    
    // Triangle vertices
    final topPoint = Offset(center.dx, center.dy - triangleSize / 2);
    final leftPoint = Offset(center.dx - triangleSize / 2, center.dy + triangleSize / 2);
    final rightPoint = Offset(center.dx + triangleSize / 2, center.dy + triangleSize / 2);
    
    // Draw triangle outline
    trianglePath.moveTo(topPoint.dx, topPoint.dy);
    trianglePath.lineTo(leftPoint.dx, leftPoint.dy);
    trianglePath.lineTo(rightPoint.dx, rightPoint.dy);
    trianglePath.close();
    
    // Draw triangle outline
    final outlinePaint = Paint()
      ..color = Colors.blue[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(trianglePath, outlinePaint);
    
    // Create vertical divider line
    final dividerPaint = Paint()
      ..color = Colors.blue[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(center.dx, topPoint.dy),
      Offset(center.dx, leftPoint.dy),
      dividerPaint,
    );
    
    // Fill left half (solid) - active during inhale
    if (phase == 0 || phase == 1) {
      final leftHalfPath = Path();
      leftHalfPath.moveTo(topPoint.dx, topPoint.dy);
      leftHalfPath.lineTo(center.dx, topPoint.dy);
      leftHalfPath.lineTo(center.dx, leftPoint.dy);
      leftHalfPath.lineTo(leftPoint.dx, leftPoint.dy);
      leftHalfPath.close();
      
      final leftFillPaint = Paint()
        ..color = Colors.blue[300]!.withOpacity(0.8)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(leftHalfPath, leftFillPaint);
    }
    
    // Fill right half (outline only) - active during exhale
    if (phase == 2 || phase == 3) {
      final rightHalfPath = Path();
      rightHalfPath.moveTo(center.dx, topPoint.dy);
      rightHalfPath.lineTo(rightPoint.dx, rightPoint.dy);
      rightHalfPath.lineTo(center.dx, leftPoint.dy);
      rightHalfPath.close();
      
      final rightFillPaint = Paint()
        ..color = Colors.blue[500]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

      canvas.drawPath(rightHalfPath, rightFillPaint);
    }
    
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is TrianglePainter &&
        (oldDelegate.phase != phase || oldDelegate.isRunning != isRunning);
  }
}



