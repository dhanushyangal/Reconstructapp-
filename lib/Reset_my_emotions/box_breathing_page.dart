import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';

class BoxBreathingPage extends StatefulWidget {
  const BoxBreathingPage({super.key});

  @override
  State<BoxBreathingPage> createState() => _BoxBreathingPageState();
}

class _BoxBreathingPageState extends State<BoxBreathingPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  // Animation controllers
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;
  AnimationController? _breathingAnimationController;
  Animation<double>? _breathingAnimation;
  
  // Exercise state
  bool _isRunning = false;
  int _currentPhase = 0; // 0: Breathe In, 1: Hold, 2: Breathe Out, 3: Hold
  int _exerciseCount = 0;
  int _breathingCycles = 0;
  Timer? _phaseTimer;
  
  // Breathing phases
  final List<String> _phases = ['Breathe In', 'Hold', 'Breathe Out', 'Hold'];
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
      end: 0.75, // 75% progress for box breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize breathing animation
    _breathingAnimationController = AnimationController(
      duration: Duration(seconds: 12), // 12 seconds for one complete cycle (3 seconds each phase)
      vsync: this,
    );
    _breathingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingAnimationController!,
      curve: Curves.linear,
    ));
    
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
    trackClick('box_breathing_start');
    
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
    trackClick('box_breathing_stop');
    
    // Stop animations
    _breathingAnimationController!.stop();
    _breathingAnimationController!.reset();
    _phaseTimer?.cancel();
    
    // Exercise count is already updated in real-time, no need to update here
  }

  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(Duration(seconds: 3), (timer) {
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
      title: 'Box Breathing Tool',
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Title
                  Text(
                    'Box Breathing Tool',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.08, // Responsive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03), // Responsive spacing
                  
                  // Square with animated dot
                  Container(
                    width: MediaQuery.of(context).size.width * 0.5, // Responsive width
                    height: MediaQuery.of(context).size.width * 0.5, // Square aspect ratio
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Stack(
                      children: [
                        // Animated dot
                        AnimatedBuilder(
                          animation: _breathingAnimation ?? const AlwaysStoppedAnimation(0.0),
                          builder: (context, child) {
                            return _buildAnimatedDot();
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03), // Responsive spacing
                  
                  // Current phase text
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.05, 
                      vertical: MediaQuery.of(context).size.height * 0.015,
                    ),
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
                        fontSize: MediaQuery.of(context).size.width * 0.05, // Responsive font size
                        fontWeight: FontWeight.bold,
                        color: _phaseColors[_currentPhase],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025), // Responsive spacing
                  
                  // Exercise stats
                  Text(
                    'Total Breathing Cycles: $_exerciseCount',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                      color: Colors.grey[600],
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.025), // Responsive spacing
                  
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
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.08, 
                              vertical: MediaQuery.of(context).size.height * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Start',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                            ),
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: _stopExercise,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.08, 
                              vertical: MediaQuery.of(context).size.height * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Stop',
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.04, // Responsive font size
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02), // Bottom spacing
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot() {
    // Get the square size dynamically
    final squareSize = MediaQuery.of(context).size.width * 0.5;
    final dotSize = squareSize * 0.06; // Responsive dot size
    final borderWidth = 2.0;
    
    if (!_isRunning) {
      // Static position when not running (bottom-left corner)
      return Positioned(
        left: -dotSize / 2,
        top: squareSize - dotSize / 2 - borderWidth,
        child: Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      );
    }

    // Calculate position based on animation progress
    final progress = _breathingAnimation?.value ?? 0.0;
    double x, y;
    
    if (progress < 0.25) {
      // Moving up (left side) - Breathe In
      final phaseProgress = progress * 4;
      x = -dotSize / 2;
      y = (squareSize - dotSize / 2 - borderWidth) - ((squareSize + borderWidth) * phaseProgress);
    } else if (progress < 0.5) {
      // Moving right (top side) - Hold
      final phaseProgress = (progress - 0.25) * 4;
      x = -dotSize / 2 + ((squareSize + borderWidth) * phaseProgress);
      y = -dotSize / 2;
    } else if (progress < 0.75) {
      // Moving down (right side) - Breathe Out
      final phaseProgress = (progress - 0.5) * 4;
      x = squareSize - dotSize / 2 - borderWidth;
      y = -dotSize / 2 + ((squareSize + borderWidth) * phaseProgress);
    } else {
      // Moving left (bottom side) - Hold
      final phaseProgress = (progress - 0.75) * 4;
      x = (squareSize - dotSize / 2 - borderWidth) - ((squareSize + borderWidth) * phaseProgress);
      y = squareSize - dotSize / 2 - borderWidth;
    }

    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: _phaseColors[_currentPhase],
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _phaseColors[_currentPhase].withOpacity(0.5),
              blurRadius: dotSize * 0.5,
              spreadRadius: dotSize * 0.1,
            ),
          ],
        ),
      ),
    );
  }

  String get pageName => 'Box Breathing Tool';
}
