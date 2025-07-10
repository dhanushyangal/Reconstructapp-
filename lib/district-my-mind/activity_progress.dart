import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../utils/activity_tracker_mixin.dart';

class ActivityProgress extends StatelessWidget {
  const ActivityProgress({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reconstruct - Activity Progress',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ActivityProgressPage(),
    );
  }
}

class ActivityProgressPage extends StatefulWidget {
  final String activityType;
  final String? feeling;

  const ActivityProgressPage({
    super.key,
    this.activityType = 'activity',
    this.feeling,
  });

  @override
  _ActivityProgressPageState createState() => _ActivityProgressPageState();
}

class _ActivityProgressPageState extends State<ActivityProgressPage>
    with TickerProviderStateMixin, ActivityTrackerMixin {
  late AnimationController _confettiController;
  late AnimationController _streakController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  final List<ConfettiParticle> _confettiParticles = [];
  final Random _random = Random();
  bool _confettiInitialized = false;

  String selectedFeeling = '';
  bool showFeedback = false;

  // Storage data
  List<String> completedGames = [];
  int streak = 0;
  Map<String, dynamic> reminders = {};
  List<String> allActivities = [];
  int totalMinutes = 0;
  int totalGamesPlayed = 0;
  List<String> riddlesSolved = [];
  List<String> jumbleSolved = [];

  // Activity configuration
  late String storageKeyPrefix;
  late String activityTypeText;
  late int activityMinutes;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _configureActivityType();
    _loadData();

    if (widget.feeling != null) {
      selectedFeeling = widget.feeling!;
      showFeedback = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_confettiInitialized) {
      _initializeConfetti();
      _confettiInitialized = true;
    }
  }

  void _setupAnimations() {
    _confettiController = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );

    _streakController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Interval(0.0, 0.2, curve: Curves.easeInOut),
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.linear,
    ));

    _confettiController.forward();
    _streakController.repeat();
  }

  void _initializeConfetti() {
    // Generate 100 confetti particles with random properties
    final screenWidth = MediaQuery.of(context).size.width;

    for (int i = 0; i < 100; i++) {
      _confettiParticles.add(ConfettiParticle(
        color: _getRandomConfettiColor(),
        size: 5 + _random.nextDouble() * 10,
        shape:
            _random.nextBool() ? ConfettiShape.circle : ConfettiShape.rectangle,
        position: Offset(
          _random.nextDouble() * screenWidth,
          -50 - _random.nextDouble() * 300, // Start above the screen
        ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 2, // Horizontal velocity
          1.5 + _random.nextDouble() * 3, // Vertical velocity (falling)
        ),
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  Color _getRandomConfettiColor() {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _configureActivityType() {
    switch (widget.activityType) {
      case 'word':
        storageKeyPrefix = 'word_games_';
        activityTypeText = 'word games';
        activityMinutes = 20;
        break;
      case 'number':
        storageKeyPrefix = 'number_games_';
        activityTypeText = 'number games';
        activityMinutes = 15;
        break;
      case 'creative':
        storageKeyPrefix = 'creative_activities_';
        activityTypeText = 'creative activities';
        activityMinutes = 25;
        break;
      default:
        storageKeyPrefix = 'distract_mind_';
        activityTypeText = 'activity';
        activityMinutes = 10;
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      completedGames =
          prefs.getStringList('${storageKeyPrefix}completed') ?? [];
      streak = prefs.getInt('${storageKeyPrefix}streak') ?? 0;
      reminders =
          json.decode(prefs.getString('${storageKeyPrefix}reminder') ?? '{}');
      allActivities = prefs.getStringList('distract_mind_all_activities') ?? [];
      totalMinutes =
          (prefs.getInt('distract_mind_total_minutes') ?? 0) + activityMinutes;
      totalGamesPlayed =
          prefs.getInt('${storageKeyPrefix}total_games_played') ?? 0;
      riddlesSolved =
          prefs.getStringList('${storageKeyPrefix}riddles_solved') ?? [];
      jumbleSolved =
          prefs.getStringList('${storageKeyPrefix}jumble_solved') ?? [];
    });

    // Update total minutes
    await prefs.setInt('distract_mind_total_minutes', totalMinutes);

    // Add to all activities if not already recorded today
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayActivity = '$today-${widget.activityType}';
    if (!allActivities.contains(todayActivity)) {
      allActivities.add(todayActivity);
      await prefs.setStringList('distract_mind_all_activities', allActivities);
    }
  }

  void _selectFeeling(String feeling) {
    setState(() {
      selectedFeeling = feeling;
      showFeedback = true;
    });

    _saveFeelingToStorage(feeling);
  }

  Future<void> _saveFeelingToStorage(String feeling) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${storageKeyPrefix}feeling', feeling);
  }

  String _getFeedbackText() {
    String baseText = "Thank you for sharing how you feel!";

    switch (selectedFeeling) {
      case 'better':
        return "$baseText We're glad the activity helped you feel better.";
      case 'little-better':
        return "$baseText It's great that you noticed some improvement.";
      case 'no-change':
        return "$baseText Different activities work differently for each person. Try another activity next time.";
      default:
        return baseText;
    }
  }

  List<Achievement> _getAchievements() {
    List<Achievement> achievements = [];

    // Streak achievements
    if (streak >= 3) {
      achievements.add(Achievement(
        icon: '🔥',
        title: 'On Fire!',
        description: '$streak day streak of mental distractions',
      ));
    } else if (streak == 2) {
      achievements.add(Achievement(
        icon: '🌱',
        title: 'Building Momentum',
        description: 'Two days in a row of mental exercises',
      ));
    }

    // Total activities achievements
    if (allActivities.length >= 10) {
      achievements.add(Achievement(
        icon: '🏆',
        title: 'Dedicated Mind',
        description: 'Completed ${allActivities.length} total activities',
      ));
    } else if (allActivities.length >= 5) {
      achievements.add(Achievement(
        icon: '🥈',
        title: 'Regular Practitioner',
        description: 'Completed ${allActivities.length} total activities',
      ));
    } else if (allActivities.isNotEmpty) {
      achievements.add(Achievement(
        icon: '🥉',
        title: 'Getting Started',
        description: 'Began your mental wellness journey',
      ));
    }

    // Word game specific achievements
    if (widget.activityType == 'word') {
      if (totalGamesPlayed >= 5) {
        achievements.add(Achievement(
          icon: '📚',
          title: 'Word Enthusiast',
          description: 'Played $totalGamesPlayed word games',
        ));
      }

      if (completedGames.contains('riddles') &&
          completedGames.contains('jumble') &&
          completedGames.contains('crossword')) {
        achievements.add(Achievement(
          icon: '🎯',
          title: 'Word Master',
          description: 'Completed all three word games',
        ));
      }
    }

    return achievements;
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _streakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6F7FF),
              Color(0xFFDCF2FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Confetti effect
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                _updateConfettiPositions();
                return CustomPaint(
                  size: Size(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height),
                  painter: ConfettiPainter(
                    particles: _confettiParticles,
                    opacity: _fadeAnimation.value,
                  ),
                );
              },
            ),
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildMainContent(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateConfettiPositions() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    for (var particle in _confettiParticles) {
      // Update position based on velocity
      particle.position = Offset(
        particle.position.dx + particle.velocity.dx,
        particle.position.dy + particle.velocity.dy,
      );

      // Update rotation angle
      particle.angle += particle.rotationSpeed;

      // Reset particles that went off screen
      if (particle.position.dy > screenHeight) {
        particle.position = Offset(
          _random.nextDouble() * screenWidth,
          -50 - _random.nextDouble() * 100,
        );
        particle.velocity = Offset(
          (_random.nextDouble() - 0.5) * 2,
          1.5 + _random.nextDouble() * 3,
        );
      }
    }
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(32.0),
      child: Text(
        'Reconstruct',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildGreatJobSection(),
          SizedBox(height: 32),
          _buildProgressCard(),
          SizedBox(height: 32),
          _buildMotivationalText(),
        ],
      ),
    );
  }

  Widget _buildGreatJobSection() {
    return Column(
      children: [
        Text(
          'Great Job!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 6,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[700]!],
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'You\'ve completed today\'s $activityTypeText!',
          style: TextStyle(
            fontSize: 18,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 32),
        _buildStreakBadge(),
      ],
    );
  }

  Widget _buildStreakBadge() {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating dashed border
              Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
              ),
              // Main badge
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      streak.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'day streak',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            SizedBox(height: 24),
            _buildStatsGrid(),
            if (widget.activityType == 'word') ...[
              SizedBox(height: 24),
              _buildGameStats(),
            ],
            SizedBox(height: 24),
            _buildFeelingSection(),
            if (showFeedback) ...[
              SizedBox(height: 24),
              _buildAchievementsSection(),
            ],
            SizedBox(height: 32),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                Icons.trending_up,
                allActivities.length.toString(),
                'Activities Completed',
                Colors.blue)),
        SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(Icons.access_time, totalMinutes.toString(),
                'Minutes Distracted', Colors.green)),
        SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
                Icons.notifications,
                reminders.length.toString(),
                'Active Reminders',
                Colors.orange)),
      ],
    );
  }

  Widget _buildStatCard(
      IconData icon, String value, String label, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats() {
    String riddlesStatus = completedGames.contains('riddles')
        ? 'Completed Today'
        : '${riddlesSolved.length}/3 Solved';
    String jumbleStatus = completedGames.contains('jumble')
        ? 'Completed Today'
        : '${jumbleSolved.length}/5 Solved';
    String crosswordStatus = completedGames.contains('crossword')
        ? 'Completed Today'
        : 'In Progress';

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Word Games Stats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildGameStatCard('🔤', 'Riddles', riddlesStatus)),
              SizedBox(width: 12),
              Expanded(
                  child:
                      _buildGameStatCard('🔀', 'Jumble Words', jumbleStatus)),
              SizedBox(width: 12),
              Expanded(
                  child:
                      _buildGameStatCard('🧩', 'Crossword', crosswordStatus)),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Total Games Played: $totalGamesPlayed',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameStatCard(String emoji, String title, String status) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'How are you feeling now?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildFeelingCard('😊', 'Better', 'better')),
              SizedBox(width: 12),
              Expanded(
                  child: _buildFeelingCard(
                      '😐', 'A little better', 'little-better')),
              SizedBox(width: 12),
              Expanded(
                  child:
                      _buildFeelingCard('😟', 'Not much change', 'no-change')),
            ],
          ),
          if (showFeedback) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getFeedbackText(),
                style: TextStyle(color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeelingCard(String emoji, String label, String feeling) {
    bool isSelected = selectedFeeling == feeling;

    return GestureDetector(
      onTap: () => _selectFeeling(feeling),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _getAchievements();

    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            achievements.isEmpty ? 'Achievements' : 'Achievements Unlocked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 16),
          if (achievements.isEmpty)
            Text(
              'Keep practicing to unlock achievements!',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            )
          else
            Column(
              children: achievements
                  .map((achievement) => _buildAchievementCard(achievement))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[100]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(achievement.icon, style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return ElevatedButton(
      onPressed: () {
        // Navigate back to activities page
        Navigator.of(context).pop();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Text(
        'Back to Activities',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildMotivationalText() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        'Remember, taking time for yourself is important. Even small breaks can have a big impact on your mental well-being.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Text(
        '© 2023 Reconstruct. All rights reserved.',
        style: TextStyle(
          color: Colors.grey[500],
          fontSize: 12,
        ),
      ),
    );
  }
}

// New class to represent a confetti particle
class ConfettiParticle {
  Offset position;
  Offset velocity;
  double size;
  Color color;
  ConfettiShape shape;
  double angle;
  double rotationSpeed;

  ConfettiParticle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.color,
    required this.shape,
    required this.angle,
    required this.rotationSpeed,
  });
}

// Enum for confetti shapes
enum ConfettiShape {
  circle,
  rectangle,
}

// Custom painter for drawing confetti
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double opacity;

  ConfettiPainter({required this.particles, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.angle);

      if (particle.shape == ConfettiShape.circle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.7,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) => true;
}

class Achievement {
  final String icon;
  final String title;
  final String description;

  Achievement({
    required this.icon,
    required this.title,
    required this.description,
  });
}
