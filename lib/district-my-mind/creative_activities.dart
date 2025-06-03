import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'activity_progress.dart';

class CreativeActivities extends StatefulWidget {
  const CreativeActivities({Key? key}) : super(key: key);

  @override
  State<CreativeActivities> createState() => _CreativeActivitiesState();
}

class _CreativeActivitiesState extends State<CreativeActivities> {
  int _currentStep = 1;
  int _progress = 0;
  bool _coloringComplete = false;
  bool _hiddenObjectsComplete = false;
  bool _matchingCardsComplete = false;
  final STORAGE_KEY_COMPLETED = 'creative_activities_completed';
  final STORAGE_KEY_FEELING = 'creative_activities_feeling';

  @override
  void initState() {
    super.initState();
    _loadSavedProgress();
  }

  Future<void> _loadSavedProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> completedActivities =
        prefs.getStringList(STORAGE_KEY_COMPLETED) ?? [];

    setState(() {
      _coloringComplete = completedActivities.contains('coloring');
      _hiddenObjectsComplete = completedActivities.contains('hiddenObjects');
      _matchingCardsComplete = completedActivities.contains('matchingCards');
      _calculateProgress();
    });
  }

  void _calculateProgress() {
    int completedCount = 0;
    if (_coloringComplete) completedCount++;
    if (_hiddenObjectsComplete) completedCount++;
    if (_matchingCardsComplete) completedCount++;

    _progress = (completedCount / 3 * 100).round();
  }

  Future<void> _markActivityComplete(String activity, bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> completedActivities =
        prefs.getStringList(STORAGE_KEY_COMPLETED) ?? [];

    if (complete && !completedActivities.contains(activity)) {
      completedActivities.add(activity);
    } else if (!complete && completedActivities.contains(activity)) {
      completedActivities.remove(activity);
    }

    await prefs.setStringList(STORAGE_KEY_COMPLETED, completedActivities);

    setState(() {
      if (activity == 'coloring') {
        _coloringComplete = complete;
      } else if (activity == 'hiddenObjects') {
        _hiddenObjectsComplete = complete;
      } else if (activity == 'matchingCards') {
        _matchingCardsComplete = complete;
      }
      _calculateProgress();
    });
  }

  Future<void> _recordFeeling(String feeling) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(STORAGE_KEY_FEELING, feeling);

    Navigator.pop(context); // Close the dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProgress(
          progress: {'creative_activities': _progress},
          activityType: 'creative',
        ),
      ),
    );
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _showReflectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How are you feeling now?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFeelingButton('😊', 'Better', 'better'),
                _buildFeelingButton('😐', 'A little better', 'little-better'),
                _buildFeelingButton('😟', 'Not much change', 'no-change'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeelingButton(String emoji, String label, String feelingValue) {
    return InkWell(
      onTap: () => _recordFeeling(feelingValue),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFE6F7FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 32)),
            SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
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
                      onPressed: () => Navigator.pop(context, _progress),
                    ),
                    Expanded(
                      child: Text(
                        'Creative Activities',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Stepper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepper(1, 'Coloring'),
                    Container(
                      width: 80,
                      height: 1,
                      color: Color(0xFFBBDEFB),
                    ),
                    _buildStepper(2, 'Hidden\nObjects'),
                    Container(
                      width: 80,
                      height: 1,
                      color: Color(0xFFBBDEFB),
                    ),
                    _buildStepper(3, 'Matching\nCards'),
                  ],
                ),
              ),

              SizedBox(height: 16),
              Text(
                _getStepTitle(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E88E5),
                ),
                textAlign: TextAlign.center,
              ),
              Container(
                height: 6,
                width: 180,
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
                _getStepDescription(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCurrentStep(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Coloring Sheet';
      case 2:
        return 'Find Missing Items';
      case 3:
        return 'Matching Cards';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 1:
        return 'Express yourself by coloring a digital mandala.';
      case 2:
        return 'Find all the hidden objects in the image.';
      case 3:
        return 'Match pairs of cards to test your memory.';
      default:
        return '';
    }
  }

  Widget _buildStepper(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = step == 1
        ? _coloringComplete
        : (step == 2 ? _hiddenObjectsComplete : _matchingCardsComplete);

    return Column(
      children: [
        GestureDetector(
          onTap: () => _goToStep(step),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isActive
                  ? Color(0xFF1E88E5)
                  : (isCompleted ? Color(0xFF81C784) : Color(0xFFE3F2FD)),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isActive || isCompleted
                      ? Colors.white
                      : Color(0xFF1E88E5),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Color(0xFF1E88E5) : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildColoringActivity();
      case 2:
        return _buildHiddenObjectsActivity();
      case 3:
        return _buildMatchingCardsActivity();
      default:
        return Container();
    }
  }

  Widget _buildColoringActivity() {
    return ColoringGame(
      onComplete: () {
        _markActivityComplete('coloring', true);
        _goToStep(2);
      },
    );
  }

  Widget _buildHiddenObjectsActivity() {
    return HiddenObjectsGame(
      onComplete: () {
        _markActivityComplete('hiddenObjects', true);
        _goToStep(3);
      },
    );
  }

  Widget _buildMatchingCardsActivity() {
    return MatchingCardsGame(
      onComplete: () {
        _markActivityComplete('matchingCards', true);
        Navigator.pop(context, _progress);
      },
    );
  }
}

class ColoringGame extends StatefulWidget {
  final VoidCallback onComplete;

  const ColoringGame({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<ColoringGame> createState() => _ColoringGameState();
}

class _ColoringGameState extends State<ColoringGame> {
  Color _selectedColor = Colors.blue;
  List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Color picker
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _colors.map((color) => _buildColorOption(color)).toList(),
          ),
          SizedBox(height: 24),

          // Canvas
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomPaint(
              painter: MandalaPainter(_selectedColor),
            ),
          ),
          SizedBox(height: 24),

          ElevatedButton(
            onPressed: widget.onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E88E5),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text('Complete Coloring'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class MandalaPainter extends CustomPainter {
  final Color color;

  MandalaPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw mandala pattern
    for (var i = 0; i < 8; i++) {
      final angle = (i * pi) / 4;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        ),
        paint,
      );
    }

    // Draw circles
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HiddenObjectsGame extends StatefulWidget {
  final VoidCallback onComplete;

  const HiddenObjectsGame({Key? key, required this.onComplete})
      : super(key: key);

  @override
  State<HiddenObjectsGame> createState() => _HiddenObjectsGameState();
}

class _HiddenObjectsGameState extends State<HiddenObjectsGame> {
  final List<String> _objects = ['📚', '☕', '✏️', '🔑', '👓'];
  final List<bool> _foundObjects = [false, false, false, false, false];
  int _foundCount = 0;

  void _findObject(int index) {
    if (!_foundObjects[index]) {
      setState(() {
        _foundObjects[index] = true;
        _foundCount++;
      });

      if (_foundCount == _objects.length) {
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Objects to find
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(
              _objects.length,
              (index) =>
                  _buildObjectItem(_objects[index], _foundObjects[index]),
            ),
          ),
          SizedBox(height: 24),

          // Game area
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: List.generate(
                _objects.length,
                (index) => Positioned(
                  left: (index * 60.0) % 240,
                  top: (index * 70.0) % 240,
                  child: GestureDetector(
                    onTap: () => _findObject(index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _foundObjects[index]
                            ? Colors.green.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _foundObjects[index] ? _objects[index] : '?',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectItem(String emoji, bool found) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: found ? Color(0xFF81C784) : Color(0xFFE6F7FF),
        borderRadius: BorderRadius.circular(20),
        border: found
            ? Border.all(color: Color(0xFF43A047), width: 2)
            : Border.all(color: Colors.transparent),
      ),
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: 24,
          color: found ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class MatchingCardsGame extends StatefulWidget {
  final VoidCallback onComplete;

  const MatchingCardsGame({Key? key, required this.onComplete})
      : super(key: key);

  @override
  State<MatchingCardsGame> createState() => _MatchingCardsGameState();
}

class _MatchingCardsGameState extends State<MatchingCardsGame> {
  final List<String> _emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊'];
  late List<CardData> _cards;
  CardData? _firstCard;
  CardData? _secondCard;
  int _matchedPairs = 0;

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    _cards = List.generate(
      12,
      (index) => CardData(
        emoji: _emojis[index % 6],
        isFlipped: false,
        isMatched: false,
      ),
    )..shuffle();
  }

  void _flipCard(int index) {
    if (_firstCard == null) {
      setState(() {
        _cards[index].isFlipped = true;
        _firstCard = _cards[index];
      });
    } else if (_secondCard == null && _cards[index] != _firstCard) {
      setState(() {
        _cards[index].isFlipped = true;
        _secondCard = _cards[index];
      });

      if (_firstCard!.emoji == _secondCard!.emoji) {
        _firstCard!.isMatched = true;
        _secondCard!.isMatched = true;
        _matchedPairs++;
        _firstCard = null;
        _secondCard = null;

        if (_matchedPairs == 6) {
          widget.onComplete();
        }
      } else {
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _firstCard!.isFlipped = false;
              _secondCard!.isFlipped = false;
              _firstCard = null;
              _secondCard = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Find matching pairs of animals!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
          SizedBox(height: 24),

          // Grid of cards
          Container(
            width: 300,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(
                _cards.length,
                (index) => _buildCard(index),
              ),
            ),
          ),
          SizedBox(height: 24),

          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeCards();
                _matchedPairs = 0;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1E88E5),
            ),
            child: Text('Reset Game'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(int index) {
    final card = _cards[index];
    return GestureDetector(
      onTap: card.isFlipped || card.isMatched ? null : () => _flipCard(index),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: card.isMatched
              ? Colors.green.withOpacity(0.3)
              : card.isFlipped
                  ? Colors.white
                  : Color(0xFF1E88E5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: card.isMatched ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            card.isFlipped || card.isMatched ? card.emoji : '?',
            style: TextStyle(
              fontSize: 24,
              color: card.isMatched ? Colors.green : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class CardData {
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardData({
    required this.emoji,
    required this.isFlipped,
    required this.isMatched,
  });
}
