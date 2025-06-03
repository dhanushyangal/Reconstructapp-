import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'word_games.dart';
import 'number_games.dart';
import 'creative_activities.dart';
import 'activity_progress.dart';

class DistractMyMindJourney extends StatefulWidget {
  const DistractMyMindJourney({Key? key}) : super(key: key);

  @override
  State<DistractMyMindJourney> createState() => _DistractMyMindJourneyState();
}

class _DistractMyMindJourneyState extends State<DistractMyMindJourney> {
  int _currentStep = 1;
  String? _selectedReason;
  final TextEditingController _feelingsController = TextEditingController();
  Map<String, int> _activityProgress = {};

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedReason = prefs.getString('distract_mind_reason');
      _feelingsController.text =
          prefs.getString('distract_mind_feelings') ?? '';
      _activityProgress = {
        'word_games': prefs.getInt('word_games_progress') ?? 0,
        'number_games': prefs.getInt('number_games_progress') ?? 0,
        'creative_activities':
            prefs.getInt('creative_activities_progress') ?? 0,
      };
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('distract_mind_reason', _selectedReason ?? '');
    await prefs.setString('distract_mind_feelings', _feelingsController.text);
    await prefs.setInt(
        'word_games_progress', _activityProgress['word_games'] ?? 0);
    await prefs.setInt(
        'number_games_progress', _activityProgress['number_games'] ?? 0);
    await prefs.setInt('creative_activities_progress',
        _activityProgress['creative_activities'] ?? 0);
  }

  void _selectReason(String reason) {
    setState(() {
      _selectedReason = reason;
    });
    _saveData();
  }

  void _goToStep(int step) {
    if (step == 2) {
      _saveData();
    }
    setState(() {
      _currentStep = step;
    });
  }

  Future<void> _navigateToActivity(String activityType) async {
    Widget activity;
    switch (activityType) {
      case 'word_games':
        activity = WordGames();
        break;
      case 'number_games':
        activity = NumberGames();
        break;
      case 'creative_activities':
        activity = const CreativeActivities();
        break;
      default:
        return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => activity),
    );

    if (result != null && result is int) {
      setState(() {
        _activityProgress[activityType] = result;
      });
      _saveData();
    }
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Color(0xFF1E88E5)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Reconstruct',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.bar_chart, color: Color(0xFF1E88E5)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ActivityProgress(
                              progress: _activityProgress,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    if (_currentStep == 1) ...[
                      // Step 1: Welcome and Emotion Check-in
                      Text(
                        'Journey 3: Distract Your Mind',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Container(
                        height: 6,
                        width: 120,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF64B5F6),
                              Color(0xFF1E88E5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Text(
                        'Taking a mental break can help reset your thoughts and improve your focus.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Why do you need a distraction today?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      SizedBox(height: 20),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildReasonCard(
                              '😢', 'Going through grief', 'grief'),
                          _buildReasonCard('😣', 'Stress relief', 'stress'),
                          _buildReasonCard('😐', 'Bored', 'boredom'),
                          _buildReasonCard(
                              '💼', 'Need break from work', 'work'),
                        ],
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Optional: Share how you\'re feeling (just for you)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _feelingsController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Type here...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: () => _goToStep(2),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E88E5),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                    ] else if (_currentStep == 2) ...[
                      // Step 2: Activity Picker
                      Text(
                        'What type of activity do you prefer?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Container(
                        height: 6,
                        width: 120,
                        margin: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF64B5F6),
                              Color(0xFF1E88E5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Text(
                        'Choose an activity that matches your mood right now.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      Container(
                        height: 400, // Fixed height for the stack container
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: _buildActivityCard(
                                '🔤',
                                'Word Games',
                                'Engage your brain with word puzzles and riddles',
                                () => _navigateToActivity('word_games'),
                                _activityProgress['word_games'] ?? 0,
                              ),
                            ),
                            Positioned(
                              top: 140,
                              left: 0,
                              right: 0,
                              child: _buildActivityCard(
                                '🔢',
                                'Number Games',
                                'Focus your mind with number puzzles and challenges',
                                () => _navigateToActivity('number_games'),
                                _activityProgress['number_games'] ?? 0,
                              ),
                            ),
                            Positioned(
                              top: 280,
                              left: 0,
                              right: 0,
                              child: _buildActivityCard(
                                '🎨',
                                'Creative',
                                'Express yourself through coloring and creative activities',
                                () =>
                                    _navigateToActivity('creative_activities'),
                                _activityProgress['creative_activities'] ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonCard(String emoji, String title, String reason) {
    final isSelected = _selectedReason == reason;
    return GestureDetector(
      onTap: () => _selectReason(reason),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: isSelected
              ? Border.all(color: Color(0xFF1E88E5), width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 32),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    String emoji,
    String title,
    String description,
    VoidCallback onTap,
    int progress,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: TextStyle(fontSize: 40),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
              ),
              SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
              ),
              SizedBox(height: 6),
              Text(
                '$progress% Complete',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feelingsController.dispose();
    super.dispose();
  }
}
