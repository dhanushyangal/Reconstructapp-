import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';

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
                           // Nose visualization
                           Container(
                             width: 320,
                             height: 320,
                             child: Stack(
                               children: [
                                 // Background with two-tone design
                                 Container(
                                   decoration: BoxDecoration(
                                     gradient: LinearGradient(
                                       begin: Alignment.centerLeft,
                                       end: Alignment.centerRight,
                                       colors: [
                                         Color(0xFFF5F5DC), // Light beige
                                         Color(0xFFE6F3FF), // Light blue-gray
                                       ],
                                       stops: [0.5, 0.5],
                                     ),
                                     borderRadius: BorderRadius.circular(160),
                                   ),
                                 ),
                                 
                                 // Nose shape
                                 Center(
                                   child: CustomPaint(
                                     size: Size(200, 200),
                                     painter: NosePainter(
                                       phase: _currentPhase,
                                       isRunning: _isRunning,
                                       phaseColor: _phaseColors[_currentPhase],
                                     ),
                                   ),
                                 ),
                                 
                                 // Breathing indicators
                                 if (_isRunning) _buildBreathingIndicators(),
                               ],
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

  Widget _buildBreathingIndicators() {
    return Stack(
      children: [
        // Left side indicator (down arrow for exhale)
        if (_currentPhase == 2)
          Positioned(
            left: 30,
            top: 160,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.blue,
                size: 24,
              ),
            ),
          ),
        
        // Right side indicator (up arrow for inhale)
        if (_currentPhase == 0)
          Positioned(
            right: 30,
            top: 160,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.green,
                size: 24,
              ),
            ),
          ),
        
        // Exhale text (only show during exhale phase)
        if (_currentPhase == 2)
          Positioned(
            right: 20,
            bottom: 30,
            child: Text(
              'Exhale',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        
        // Inhale text (only show during inhale phase)
        if (_currentPhase == 0)
          Positioned(
            left: 20,
            bottom: 30,
            child: Text(
              'Inhale',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  String get pageName => 'Alternate Nostril Breathing';
}

class NosePainter extends CustomPainter {
  final int phase;
  final bool isRunning;
  final Color phaseColor;

  NosePainter({
    required this.phase,
    required this.isRunning,
    required this.phaseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2E5C8A) // Navy blue color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Scale factors
    final w = size.width;
    final h = size.height;

    // Start from bottom left nostril
    path.moveTo(w * 0.15, h * 0.85);

    // Left nostril curve (bottom left)
    path.cubicTo(
      w * 0.05, h * 0.85,
      w * 0.02, h * 0.75,
      w * 0.08, h * 0.68,
    );

    // Left side going up
    path.cubicTo(
      w * 0.12, h * 0.62,
      w * 0.15, h * 0.50,
      w * 0.20, h * 0.35,
    );

    // Left top curve of nose bridge
    path.cubicTo(
      w * 0.23, h * 0.20,
      w * 0.30, h * 0.08,
      w * 0.38, h * 0.03,
    );

    // Top of nose bridge (rounded)
    path.cubicTo(
      w * 0.45, h * 0.00,
      w * 0.55, h * 0.00,
      w * 0.62, h * 0.03,
    );

    // Right top curve of nose bridge
    path.cubicTo(
      w * 0.70, h * 0.08,
      w * 0.77, h * 0.20,
      w * 0.80, h * 0.35,
    );

    // Right side going down
    path.cubicTo(
      w * 0.85, h * 0.50,
      w * 0.88, h * 0.62,
      w * 0.92, h * 0.68,
    );

    // Right nostril top curve
    path.cubicTo(
      w * 0.98, h * 0.75,
      w * 0.95, h * 0.85,
      w * 0.85, h * 0.85,
    );

    // Right nostril inner curve
    path.cubicTo(
      w * 0.78, h * 0.85,
      w * 0.72, h * 0.88,
      w * 0.65, h * 0.90,
    );

    // Bottom center curve
    path.cubicTo(
      w * 0.58, h * 0.92,
      w * 0.42, h * 0.92,
      w * 0.35, h * 0.90,
    );

    // Left nostril inner curve
    path.cubicTo(
      w * 0.28, h * 0.88,
      w * 0.22, h * 0.85,
      w * 0.15, h * 0.85,
    );

    canvas.drawPath(path, paint);

    // Draw nostrils with different colors based on phase
    final nostrilPaint = Paint()
      ..style = PaintingStyle.fill;

    // Left nostril (active during exhale)
    if (phase == 2) {
      nostrilPaint.color = Colors.blue.withOpacity(0.6);
      // Draw left nostril area
      final leftNostrilPath = Path();
      leftNostrilPath.moveTo(w * 0.15, h * 0.85);
      leftNostrilPath.cubicTo(w * 0.22, h * 0.88, w * 0.28, h * 0.88, w * 0.35, h * 0.90);
      leftNostrilPath.cubicTo(w * 0.42, h * 0.92, w * 0.50, h * 0.90, w * 0.50, h * 0.85);
      leftNostrilPath.cubicTo(w * 0.50, h * 0.80, w * 0.40, h * 0.78, w * 0.30, h * 0.80);
      leftNostrilPath.cubicTo(w * 0.20, h * 0.82, w * 0.15, h * 0.85, w * 0.15, h * 0.85);
      canvas.drawPath(leftNostrilPath, nostrilPaint);
    } else {
      nostrilPaint.color = Colors.grey.withOpacity(0.1);
      // Draw left nostril area
      final leftNostrilPath = Path();
      leftNostrilPath.moveTo(w * 0.15, h * 0.85);
      leftNostrilPath.cubicTo(w * 0.22, h * 0.88, w * 0.28, h * 0.88, w * 0.35, h * 0.90);
      leftNostrilPath.cubicTo(w * 0.42, h * 0.92, w * 0.50, h * 0.90, w * 0.50, h * 0.85);
      leftNostrilPath.cubicTo(w * 0.50, h * 0.80, w * 0.40, h * 0.78, w * 0.30, h * 0.80);
      leftNostrilPath.cubicTo(w * 0.20, h * 0.82, w * 0.15, h * 0.85, w * 0.15, h * 0.85);
      canvas.drawPath(leftNostrilPath, nostrilPaint);
    }

    // Right nostril (active during inhale)
    if (phase == 0) {
      nostrilPaint.color = Colors.green.withOpacity(0.6);
      // Draw right nostril area
      final rightNostrilPath = Path();
      rightNostrilPath.moveTo(w * 0.85, h * 0.85);
      rightNostrilPath.cubicTo(w * 0.78, h * 0.88, w * 0.72, h * 0.88, w * 0.65, h * 0.90);
      rightNostrilPath.cubicTo(w * 0.58, h * 0.92, w * 0.50, h * 0.90, w * 0.50, h * 0.85);
      rightNostrilPath.cubicTo(w * 0.50, h * 0.80, w * 0.60, h * 0.78, w * 0.70, h * 0.80);
      rightNostrilPath.cubicTo(w * 0.80, h * 0.82, w * 0.85, h * 0.85, w * 0.85, h * 0.85);
      canvas.drawPath(rightNostrilPath, nostrilPaint);
    } else {
      nostrilPaint.color = Colors.grey.withOpacity(0.1);
      // Draw right nostril area
      final rightNostrilPath = Path();
      rightNostrilPath.moveTo(w * 0.85, h * 0.85);
      rightNostrilPath.cubicTo(w * 0.78, h * 0.88, w * 0.72, h * 0.88, w * 0.65, h * 0.90);
      rightNostrilPath.cubicTo(w * 0.58, h * 0.92, w * 0.50, h * 0.90, w * 0.50, h * 0.85);
      rightNostrilPath.cubicTo(w * 0.50, h * 0.80, w * 0.60, h * 0.78, w * 0.70, h * 0.80);
      rightNostrilPath.cubicTo(w * 0.80, h * 0.82, w * 0.85, h * 0.85, w * 0.85, h * 0.85);
      canvas.drawPath(rightNostrilPath, nostrilPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is NosePainter &&
        (oldDelegate.phase != phase || oldDelegate.isRunning != isRunning);
  }
}



