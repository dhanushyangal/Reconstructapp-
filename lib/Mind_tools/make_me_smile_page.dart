import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking

import 'dashboard_traker.dart'; // Import the dashboard tracker

class MakeMeSmilePage extends StatefulWidget {
  const MakeMeSmilePage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/make-me-smile';

  @override
  _MakeMeSmilePageState createState() => _MakeMeSmilePageState();
}

class _MakeMeSmilePageState extends State<MakeMeSmilePage>
    with TickerProviderStateMixin {
  int currentSmiley = 1;
  final int maxSmileyChanges = 12;
  bool isSoundOn = false;
  final AudioPlayer _backgroundMusicPlayer = AudioPlayer();
  final AudioPlayer _effectPlayer = AudioPlayer();
  late AnimationController _cheerAnimationController;
  late Animation<double> _cheerAnimation;
  String currentMoodMessage = "Click an icon to feel better!";

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
    super.dispose();
  }

  // Updated function to log activity for tracking using the centralized method
  Future<void> _logActivity() async {
    try {
      // Call the static method from DashboardTrackerPage
      // This ensures data is saved locally first, then synced to server when online
      await DashboardTrackerPage.recordToolActivity('make_me_smile');
      debugPrint(
          'Make Me Smile activity logged - saved locally and will sync when online');
    } catch (e) {
      debugPrint('Error logging Make Me Smile activity: $e');
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
        // Increase smiley number (will change the emoji)
        currentSmiley++;

        // Update the mood message
        currentMoodMessage =
            moodMessages[math.Random().nextInt(moodMessages.length)];
      });

      // Log activity for tracking
      _logActivity();

      // Play sound effect if sound is on
      if (isSoundOn) {
        try {
          await _effectPlayer.play(AssetSource('sounds/make-me-smile.mp3'));
        } catch (e) {
          debugPrint('Error playing sound effect: $e');
        }
      }

      // If we've reached the max changes, play a cheering sound and animate
      if (currentSmiley > maxSmileyChanges) {
        if (isSoundOn) {
          try {
            await _effectPlayer.play(AssetSource('sounds/make-me-smile.mp3'));
          } catch (e) {
            debugPrint('Error playing cheering sound: $e');
          }
        }

        // Play the cheer animation
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Me Smile'),
      ),
      body: SingleChildScrollView(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom widget to display emojis
class EmojiDisplay extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiDisplay({
    Key? key,
    required this.emoji,
    this.size = 32.0,
  }) : super(key: key);

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
