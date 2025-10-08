import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../utils/activity_tracker_mixin.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../components/nav_logpage.dart';
import '../Reset_my_emotions/mind_tool_success_page.dart';

class MakeMeSmilePage extends StatefulWidget {
  const MakeMeSmilePage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/make-me-smile';

  @override
  _MakeMeSmilePageState createState() => _MakeMeSmilePageState();
}

class _MakeMeSmilePageState extends State<MakeMeSmilePage>
    with TickerProviderStateMixin, ActivityTrackerMixin {
  int currentSmiley = 1;
  final int maxSmileyChanges = 12;
  bool isSoundOn = false;
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  late AnimationController _cheerAnimationController;
  late Animation<double> _cheerAnimation;
  String currentMoodMessage = "Click an icon to feel better!";
  
  // Progress bar animation
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // List of mood messages that will be displayed randomly
  final List<String> moodMessages = [
    "You're doing great!",
    "Keep smiling!",
    "You're amazing!",
    "Sending positive vibes!",
    "You got this!"
  ];

  // Define smiley face emojis - using common smileys that work on most platforms
  final List<String> smileyEmojis = [
    "🙂", // neutral/slightly happy
    "😀", // happy
    "😃", // happier
    "😄", // very happy
    "😁", // grinning
    "😆", // laughing
    "😊", // smiling
    "😍", // heart eyes
    "🤩", // star-struck
    "😎", // cool
    "🥳", // partying
    "👍", // thumbs up
    "🎉", // celebration
  ];

  // Define emotion icons data - using simpler, widely-supported emojis
  final List<Map<String, dynamic>> emotionIcons = [
    {"name": "Love", "emoji": "❤️"},
    {"name": "Happy", "emoji": "😊"},
    {"name": "Gifts", "emoji": "🎁"},
    {"name": "Applause", "emoji": "👏"},
    {"name": "Thanks", "emoji": "🙏"},
    {"name": "Crown", "emoji": "👑"},
    {"name": "Strong", "emoji": "💪"},
    {"name": "Sun", "emoji": "☀️"},
    {"name": "Winner", "emoji": "🏆"},
    {"name": "Rainbow", "emoji": "🌈"},
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
      end: 0.75, // 75% progress for mind tools
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();

    // Set up the animation controller for the cheer animation
    _cheerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _cheerAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _cheerAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Set up the animation to go forward and back
    _cheerAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cheerAnimationController.reverse();
      }
    });

    // Track this page visit in recent activities
    _trackActivity();
  }

  @override
  void dispose() {
    _cheerAnimationController.dispose();
    _backgroundMusicPlayer.dispose();
    _effectPlayer.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

  // Updated function to log activity for tracking using Supabase
  Future<void> _logActivity() async {
    try {
      debugPrint('😊 Make Me Smile: Starting activity logging...');
      final user = AuthService.instance.currentUser;
      final email = user?.email;
      final userName = user?.userMetadata?['name'] ??
          user?.userMetadata?['username'] ??
          user?.email?.split('@')[0];

      debugPrint('👤 Make Me Smile: User email: $email, userName: $userName');
      if (email == null) {
        debugPrint('❌ Make Me Smile: No authenticated user found');
        return;
      }

      final service = SupabaseDatabaseService();
      final today = DateTime.now();
      debugPrint(
          '📅 Make Me Smile: Logging activity for date: ${today.toIso8601String().split('T')[0]}');

      final result = await service.upsertMindToolActivity(
        email: email,
        userName: userName,
        date: today,
        toolType: 'make_me_smile',
      );

      debugPrint(
          '✅ Make Me Smile activity upsert result: ${result['message']}');
      debugPrint('🎯 Make Me Smile activity logged successfully!');
    } catch (e) {
      debugPrint('❌ Error logging Make Me Smile activity: $e');
    }
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Smile Therapy',
        imagePath: 'assets/Mind_tools/make-me-smile.png',
        timestamp: DateTime.now(),
        routeName: MakeMeSmilePage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Function to change the smiley face and play sounds
  void changeSmiley() async {
    if (currentSmiley <= maxSmileyChanges) {
      setState(() {
        currentSmiley++;
        currentMoodMessage =
            moodMessages[math.Random().nextInt(moodMessages.length)];
      });
      // Track smiley change action
      trackButtonTap('Change Smiley',
          additionalDetails: 'smiley:$currentSmiley');
      await _logActivity();
      if (isSoundOn) {
        try {
          await _effectPlayer.play(AssetSource('sounds/make-me-smile.mp3'));
        } catch (e) {
          debugPrint('Error playing sound effect: $e');
        }
      }
      if (currentSmiley > maxSmileyChanges) {
        if (isSoundOn) {
          try {
            await _effectPlayer.play(AssetSource('sounds/make-me-smile.mp3'));
          } catch (e) {
            debugPrint('Error playing cheering sound: $e');
          }
        }
        _cheerAnimationController.forward();
      }
    }
  }

  // Toggle background music
  void toggleSound() {
    setState(() {
      isSoundOn = !isSoundOn;
    });

    if (isSoundOn) {
      _backgroundMusicPlayer.play(AssetSource('sounds/make-me-smile.mp3'));
      _backgroundMusicPlayer
          .setReleaseMode(ReleaseMode.loop); // Loop the background music
    } else {
      _backgroundMusicPlayer.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Make Me Smile',
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
              children: [
                const Text(
                  'Are you feeling low?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Everyone has moments when they feel low.\nShower yourself with some self-love and watch that smile come back!',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),

                // Smiley face container
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFF0F0F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        offset: Offset(-6, -6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(15),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        children: [
                          // Animated smiley face
                          AnimatedBuilder(
                              animation: _cheerAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: currentSmiley > maxSmileyChanges
                                      ? _cheerAnimation.value
                                      : 1.0,
                                  child: TweenAnimationBuilder(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(0,
                                            math.sin(value * math.pi * 2) * 3),
                                        child: child,
                                      );
                                    },
                                    child: EmojiDisplay(
                                      emoji: smileyEmojis[(currentSmiley - 1) %
                                          smileyEmojis.length],
                                      size: 80,
                                    ),
                                  ),
                                );
                              }),
                          const SizedBox(height: 15),
                          // Mood message
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              currentMoodMessage,
                              key: ValueKey<String>(currentMoodMessage),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),

                      // Sound toggle button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell(
                          onTap: toggleSound,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSoundOn ? Icons.volume_up : Icons.volume_off,
                              size: 20,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Emotion icons grid
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 12,
                    children: emotionIcons.map((icon) {
                      return GestureDetector(
                        onTap: changeSmiley,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFF0F0F0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              const BoxShadow(
                                color: Colors.white,
                                offset: Offset(-4, -4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              EmojiDisplay(
                                emoji: icon["emoji"]!,
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                icon["name"]!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 40),
                
                // Next button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MindToolSuccessPage(
                              toolName: 'Make Me Smile',
                              nextToolName: 'Build Self Love',
                              nextToolRoute: '/build-self-love',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF23C4F7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        elevation: 4,
                        shadowColor: Color(0xFF23C4F7).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Next'),
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

// Custom widget to display emojis
class EmojiDisplay extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiDisplay({
    super.key,
    required this.emoji,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: size,
          letterSpacing: 0,
          wordSpacing: 0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
