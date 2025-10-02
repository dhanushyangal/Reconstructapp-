import 'package:flutter/material.dart';
import '../../utils/activity_tracker_mixin.dart';
import '../../components/nav_logpage.dart';
import '../box_breathing_page.dart';
import 'deep_breathing_page.dart';
import 'intentional_breathing_page.dart';
import 'alternate_nose_breathing_page.dart';

class MasterBreathingPage extends StatefulWidget {
  const MasterBreathingPage({super.key});

  @override
  State<MasterBreathingPage> createState() => _MasterBreathingPageState();
}

class _MasterBreathingPageState extends State<MasterBreathingPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {

  // Animation controllers for progress bar
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Breathing exercises data
  final List<Map<String, dynamic>> _breathingExercises = [
    {
      'name': 'Box breathing',
      'image': 'assets/breathing/box_breathing.png',
    },
    {
      'name': 'Alternate nose breathing',
      'image': 'assets/breathing/alternate_nose_breathing.png',
    },
    {
      'name': 'Deep breathing',
      'image': 'assets/breathing/deep_breathing.png',
    },
    {
      'name': 'Intentional breathing',
      'image': 'assets/breathing/intentional_breathing.png',
    },
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
      begin: 0.25,
      end: 0.5, // 50% progress for master breathing page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Master your breathing',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose affirmations to build mental strength',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 56),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      children: [
                        _buildBreathingExerciseCard(context, _breathingExercises[0]),
                        _buildBreathingExerciseCard(context, _breathingExercises[1]),
                        _buildBreathingExerciseCard(context, _breathingExercises[2]),
                        _buildBreathingExerciseCard(context, _breathingExercises[3]),
                      ],
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

  Widget _buildBreathingExerciseCard(BuildContext context, Map<String, dynamic> exercise) {
    return GestureDetector(
      onTap: () {
        _navigateToBreathingExercise(exercise['name']);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      exercise['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      exercise['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBreathingExercise(String exerciseName) {
    // Track the activity
    trackClick('master_breathing_$exerciseName');

    // Navigate to specific breathing exercise
    if (exerciseName == 'Box breathing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BoxBreathingPage(),
        ),
      );
    } else if (exerciseName == 'Deep breathing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DeepBreathingPage(),
        ),
      );
    } else if (exerciseName == 'Intentional breathing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IntentionalBreathingPage(),
        ),
      );
    } else if (exerciseName == 'Alternate nose breathing') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AlternateNoseBreathingPage(),
        ),
      );
    } else {
      // Show coming soon dialog for other exercises
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.construction,
                  color: Colors.orange,
                  size: 28,
                ),
                SizedBox(width: 12),
                Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$exerciseName is currently under development.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'We\'re working hard to bring you this amazing feature soon!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF23C4F7),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Got it',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  String get pageName => 'Master your breathing';
}
