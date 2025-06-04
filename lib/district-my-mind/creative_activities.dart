import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'activity_progress.dart';
import 'dart:ui';

class CreativeActivitiesPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const CreativeActivitiesPage({Key? key, this.onComplete}) : super(key: key);

  @override
  _CreativeActivitiesPageState createState() => _CreativeActivitiesPageState();
}

class _CreativeActivitiesPageState extends State<CreativeActivitiesPage>
    with SingleTickerProviderStateMixin {
  int creativeStep = 1;
  List<String> completedGames = [];
  String? selectedFeeling;
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Bird coloring variables
  Color currentColor = Colors.black;
  double currentStrokeWidth = 8.0;
  final List<DrawingPoint?> points = [];
  final Color bodyColor = Colors.white;
  final Color leaf1Color = Colors.green;
  final Color leaf2Color = Colors.green;
  final Color eyeColor = Colors.black;
  final List<Color> colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.white,
    Colors.black,
  ];
  final List<double> brushSizes = [2.0, 4.0, 8.0, 12.0, 16.0];
  final GlobalKey _drawingAreaKey = GlobalKey();

  // Sliding puzzle variables
  List<int> puzzleTiles = [];
  int emptyIndex = 15;
  bool isPuzzleSolved = false;
  int moveCount = 0;
  DateTime? puzzleStartTime;
  bool showSlideInlinePuzzle = true;

  // Memory matching variables
  List<String> cardEmojis = [
    '🐶',
    '🐱',
    '🐼',
    '🦁',
    '🐯',
    '🦊',
    '🐨',
    '🦒',
    '🦘',
    '🦥',
    '🦦',
    '🦨',
    '🦡'
  ];
  List<int> cardIndices = [];
  List<bool> flippedCards = [];
  List<bool> matchedCards = [];
  List<int> currentFlipped = [];
  int matchedPairs = 0;
  int memoryMoves = 0;

  // Statistics
  Map<String, dynamic> activityStats = {
    'coloring': {'completions': 0, 'timeSpent': 0},
    'sliding': {'completions': 0, 'bestTime': null, 'moves': 0},
    'matching': {'completions': 0, 'bestMoves': null},
  };

  @override
  void initState() {
    super.initState();
    _loadCompletedGames();
    _loadActivityStats();
    _initializePuzzle();
    _initializeMemoryGame();
    _setupAnimations();
    _preloadSounds();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _preloadSounds() async {
    await _audioPlayer.setSource(AssetSource('sounds/flip.mp3'));
    await _audioPlayer.setSource(AssetSource('sounds/match.mp3'));
    await _audioPlayer.setSource(AssetSource('sounds/complete.mp3'));
  }

  Future<void> _loadActivityStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      activityStats = Map<String, dynamic>.from(
        prefs.getString('creative_activities_stats') != null
            ? Map<String, dynamic>.from(
                Map<String, dynamic>.from(
                  prefs.getString('creative_activities_stats') as Map,
                ),
              )
            : activityStats,
      );
    });
  }

  Future<void> _saveActivityStats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'creative_activities_stats', activityStats.toString());
  }

  void _loadCompletedGames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      completedGames =
          prefs.getStringList('creative_activities_completed') ?? [];
    });
  }

  void _saveCompletedGames() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('creative_activities_completed', completedGames);
  }

  void _initializePuzzle() {
    puzzleTiles = List.generate(15, (index) => index + 1);
    puzzleTiles.shuffle();
    emptyIndex = 15;
    isPuzzleSolved = false;
  }

  void _initializeMemoryGame() {
    // Create pairs of cards
    cardIndices = [];
    for (int i = 0; i < 13; i++) {
      cardIndices.add(i);
      cardIndices.add(i);
    }
    cardIndices.shuffle();

    flippedCards = List.filled(26, false);
    matchedCards = List.filled(26, false);
    currentFlipped = [];
    matchedPairs = 0;
  }

  void _movePuzzleTile(int index) {
    if (!_canMoveTile(index)) return;

    setState(() {
      moveCount++;
      if (puzzleStartTime == null) {
        puzzleStartTime = DateTime.now();
      }

      if (index == emptyIndex - 1 && emptyIndex % 4 != 0) {
        // Left
        puzzleTiles.insert(index, puzzleTiles.removeAt(index - 1));
        emptyIndex = index;
      } else if (index == emptyIndex + 1 && index % 4 != 0) {
        // Right
        puzzleTiles.insert(index - 1, puzzleTiles.removeAt(index));
        emptyIndex = index;
      } else if (index == emptyIndex - 4) {
        // Up
        puzzleTiles.insert(index, puzzleTiles.removeAt(index - 1));
        emptyIndex = index;
      } else if (index == emptyIndex + 4) {
        // Down
        puzzleTiles.insert(index - 1, puzzleTiles.removeAt(index));
        emptyIndex = index;
      }

      _checkPuzzleSolved();
    });
  }

  bool _canMoveTile(int index) {
    if (index < 0 || index >= 16) return false;

    // Check if tile is adjacent to empty space
    return (index == emptyIndex - 1 && emptyIndex % 4 != 0) || // Left
        (index == emptyIndex + 1 && index % 4 != 0) || // Right
        (index == emptyIndex - 4) || // Up
        (index == emptyIndex + 4); // Down
  }

  void _checkPuzzleSolved() {
    bool solved = true;
    for (int i = 0; i < 15; i++) {
      if (puzzleTiles[i] != i + 1) {
        solved = false;
        break;
      }
    }
    if (solved && !isPuzzleSolved) {
      isPuzzleSolved = true;
      _updatePuzzleStats();
      _audioPlayer.play(AssetSource('sounds/complete.mp3'));
    }
  }

  void _updatePuzzleStats() {
    int timeSpent = DateTime.now().difference(puzzleStartTime!).inSeconds;
    setState(() {
      activityStats['sliding']['completions']++;
      if (activityStats['sliding']['bestTime'] == null ||
          timeSpent < activityStats['sliding']['bestTime']) {
        activityStats['sliding']['bestTime'] = timeSpent;
      }
      if (activityStats['sliding']['moves'] == 0 ||
          moveCount < activityStats['sliding']['moves']) {
        activityStats['sliding']['moves'] = moveCount;
      }
      _saveActivityStats();
    });
  }

  void _flipMemoryCard(int index) {
    if (flippedCards[index] ||
        matchedCards[index] ||
        currentFlipped.length >= 2) {
      return;
    }

    setState(() {
      flippedCards[index] = true;
      currentFlipped.add(index);

      if (currentFlipped.length == 2) {
        Future.delayed(Duration(milliseconds: 1000), () {
          _checkMemoryMatch();
        });
      }
    });
  }

  void _checkMemoryMatch() {
    if (currentFlipped.length != 2) return;

    int first = currentFlipped[0];
    int second = currentFlipped[1];

    setState(() {
      if (cardIndices[first] == cardIndices[second]) {
        // Match found
        matchedCards[first] = true;
        matchedCards[second] = true;
        matchedPairs++;
      } else {
        // No match
        flippedCards[first] = false;
        flippedCards[second] = false;
      }
      currentFlipped.clear();
    });
  }

  void _markComplete(String game) {
    setState(() {
      if (!completedGames.contains(game)) {
        completedGames.add(game);
        _saveCompletedGames();

        // Check if all games are completed
        if (completedGames.contains('coloring') &&
            completedGames.contains('sliding') &&
            completedGames.contains('matching')) {
          _navigateToProgress();
        }
      }
    });
  }

  void _navigateToProgress() {
    // First navigate to the progress page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProgressPage(
          activityType: 'creative',
        ),
      ),
    );

    // Then call the onComplete callback if provided
    if (widget.onComplete != null) {
      widget.onComplete!();
    }
  }

  void _setReminder(String game) {
    String reminderText = '';
    switch (game) {
      case 'coloring':
        reminderText = 'Relax & Color – 9 PM';
        break;
      case 'sliding':
        reminderText = 'Puzzle Break @ 2 PM';
        break;
      case 'matching':
        reminderText = 'Sharpen Memory @ 5 PM';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminder set for $reminderText!')),
    );
  }

  void _recordFeeling(String feeling) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('creative_activities_feeling', feeling);

    // Navigate to progress page
    _navigateToProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepper(),
            _buildStepTitle(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Colors.blue[800]),
          ),
          Expanded(
            child: Text(
              'Creative Activities',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStepCircle(1, 'Coloring'),
            _buildStepLine(),
            _buildStepCircle(2, 'Sliding Puzzle'),
            _buildStepLine(),
            _buildStepCircle(3, 'Memory Cards'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    bool isActive = creativeStep == step;
    return Container(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.blue[700] : Colors.blue[100],
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.blue[700],
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.blue[700] : Colors.blue[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.blue[200],
      margin: EdgeInsets.only(bottom: 40),
    );
  }

  Widget _buildStepTitle() {
    List<String> titles = ['Coloring Sheet', 'Sliding Puzzle', 'Memory Cards'];
    List<String> descriptions = [
      'Express yourself by coloring a digital mandala.',
      'Solve the sliding number puzzle by arranging tiles in order.',
      'Match pairs of cards to test your memory.'
    ];

    return Column(
      children: [
        Text(
          creativeStep <= 3 ? titles[creativeStep - 1] : 'Reflection',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 6,
          width: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              colors: [Colors.blue[300]!, Colors.blue[600]!],
            ),
          ),
        ),
        SizedBox(height: 16),
        if (creativeStep <= 3)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              descriptions[creativeStep - 1],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (creativeStep) {
      case 1:
        return _buildColoringGame();
      case 2:
        return _buildSlidingPuzzleGame();
      case 3:
        return _buildMemoryGame();
      case 4:
        return _buildReflectionSection();
      default:
        return _buildColoringGame();
    }
  }

  Widget _buildColoringGame() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Color the bird by selecting colors and brush size',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 16),
          // Drawing area
          Center(
            child: Container(
              key: _drawingAreaKey,
              width: 300,
              height: 400,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (details) {
                    final RenderBox renderBox = _drawingAreaKey.currentContext!
                        .findRenderObject() as RenderBox;
                    final Offset localPosition =
                        renderBox.globalToLocal(details.globalPosition);

                    // Get the position in the bird's coordinate system
                    final adjustedPosition = _adjustTouchPosition(
                        localPosition, constraints.biggest);

                    // If touching inside bird body area and not in leaves
                    if (_isInsideBirdBody(
                            adjustedPosition, constraints.biggest) &&
                        !_isInsideLeaves(
                            adjustedPosition, constraints.biggest)) {
                      setState(() {
                        points.add(DrawingPoint(
                          localPosition, // Use the original position for drawing
                          Paint()
                            ..color = currentColor
                            ..strokeWidth = currentStrokeWidth
                            ..strokeCap = StrokeCap.round
                            ..strokeJoin = StrokeJoin.round
                            ..style = PaintingStyle.stroke,
                        ));
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    final RenderBox renderBox = _drawingAreaKey.currentContext!
                        .findRenderObject() as RenderBox;
                    final Offset localPosition =
                        renderBox.globalToLocal(details.globalPosition);

                    // Get the position in the bird's coordinate system
                    final adjustedPosition = _adjustTouchPosition(
                        localPosition, constraints.biggest);

                    // If touching inside bird body area and not in leaves
                    if (_isInsideBirdBody(
                            adjustedPosition, constraints.biggest) &&
                        !_isInsideLeaves(
                            adjustedPosition, constraints.biggest)) {
                      setState(() {
                        points.add(DrawingPoint(
                          localPosition, // Use the original position for drawing
                          Paint()
                            ..color = currentColor
                            ..strokeWidth = currentStrokeWidth
                            ..strokeCap = StrokeCap.round
                            ..strokeJoin = StrokeJoin.round
                            ..style = PaintingStyle.stroke,
                        ));
                      });
                    }
                  },
                  onPanEnd: (details) {
                    // Add null to indicate the end of a stroke
                    setState(() {
                      points.add(null);
                    });
                  },
                  child: ClipRect(
                    child: Stack(
                      children: [
                        // Bird filled with colors
                        CustomPaint(
                          size: constraints.biggest,
                          painter: BirdColorPainter(
                            bodyColor: bodyColor,
                            leaf1Color: leaf1Color,
                            leaf2Color: leaf2Color,
                            eyeColor: eyeColor,
                          ),
                        ),
                        // Drawing layer with direct positioning
                        CustomPaint(
                          size: constraints.biggest,
                          painter: DrawingPainter(
                            drawingPoints: points,
                            birdBodyPath:
                                getTransformedBirdBodyPath(constraints.biggest),
                          ),
                        ),
                        // Bird outline (drawn on top so it's always visible)
                        CustomPaint(
                          size: constraints.biggest,
                          painter: BirdOutlinePainter(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 16),
          // Controls section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    points.clear();
                  });
                },
                icon: Icon(Icons.refresh),
                label: Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Brush size selection
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brushSizes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentStrokeWidth = brushSizes[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentStrokeWidth == brushSizes[index]
                            ? Colors.black
                            : Colors.grey,
                        width: currentStrokeWidth == brushSizes[index] ? 3 : 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: brushSizes[index],
                        height: brushSizes[index],
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Color palette
          Container(
            height: 60,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colorPalette.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = colorPalette[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorPalette[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor == colorPalette[index]
                            ? Colors.black
                            : Colors.grey,
                        width: currentColor == colorPalette[index] ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildActivityFooter('coloring'),
        ],
      ),
    );
  }

  Widget _buildSlidingPuzzleGame() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Sliding Puzzle - Arrange the image by moving the tiles',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 16),
          Container(
            height: 450, // Increased size
            child: SlidingPuzzleWidget(),
          ),
          _buildActivityFooter('sliding'),
        ],
      ),
    );
  }

  Widget _buildMemoryGame() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Click on cards to reveal them and find matching pairs!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 16),
          Container(
            constraints: BoxConstraints(
              maxHeight: 400,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.8,
              ),
              itemCount: 26,
              itemBuilder: (context, index) {
                bool isFlipped = flippedCards[index] || matchedCards[index];
                return GestureDetector(
                  onTap: () => _flipMemoryCard(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: matchedCards[index]
                          ? Colors.green[400]
                          : isFlipped
                              ? Colors.white
                              : Colors.blue[600],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Text(
                        isFlipped ? cardEmojis[cardIndices[index]] : '?',
                        style: TextStyle(
                          fontSize: 20,
                          color: isFlipped ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
          Text(
            matchedPairs == 13
                ? '🎉 Congratulations! All pairs found!'
                : 'Find all matching pairs of animals!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: matchedPairs == 13 ? Colors.green[600] : Colors.grey[700],
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _initializeMemoryGame();
              });
            },
            child: Text('Reset Game'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
          _buildActivityFooter('matching'),
        ],
      ),
    );
  }

  Widget _buildReflectionSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'How are you feeling now?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFeelingButton('😊', 'Better', 'better'),
              _buildFeelingButton('😐', 'A little better', 'little-better'),
              _buildFeelingButton('😟', 'Not much change', 'no-change'),
            ],
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Return to Activities'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
          SizedBox(height: 20),
          // Add a button to go to progress page
          ElevatedButton(
            onPressed: _navigateToProgress,
            child: Text('View Your Progress'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingButton(String emoji, String label, String value) {
    return GestureDetector(
      onTap: () => _recordFeeling(value),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityFooter(String gameType) {
    bool isCompleted = completedGames.contains(gameType);

    return Column(
      children: [
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: isCompleted,
              onChanged: (value) {
                if (value == true) {
                  _markComplete(gameType);
                }
              },
            ),
            Text('Mark as complete'),
          ],
        ),
        SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _setReminder(gameType),
          icon: Icon(Icons.notifications),
          label: Text(_getReminderText(gameType)),
        ),
        if (isCompleted) ...[
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (creativeStep < 3) {
                  creativeStep++;
                } else {
                  creativeStep = 4;
                }
              });
            },
            child: Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  String _getReminderText(String gameType) {
    switch (gameType) {
      case 'coloring':
        return 'Set Relax & Color – 9 PM Reminder';
      case 'sliding':
        return 'Set Puzzle Break @ 2 PM Reminder';
      case 'matching':
        return 'Set Sharpen Memory @ 5 PM Reminder';
      default:
        return 'Set Reminder';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Drawing helper methods
  // Transform position from screen coordinates to bird coordinate system
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    // Calculate scale and translation factors based on bird paths
    final double scale =
        math.min(containerSize.width / 500, containerSize.height / 600);
    final double translateX = (containerSize.width / scale - 460) / 2;
    final double translateY = (containerSize.height / scale - 565) / 2;

    // Apply inverse transformation to get bird coordinates
    final double birdX = position.dx / scale - translateX;
    final double birdY = position.dy / scale - translateY;

    return Offset(birdX, birdY);
  }

  // Check if touch is inside the bird body path
  bool _isInsideBirdBody(Offset position, Size containerSize) {
    // Apply same transformation to position as used in the getBirdPath method
    // We already transformed it in _adjustTouchPosition, so use that

    // Get the untransformed bird path
    final Path birdPath = getBirdPath();

    // Check if the adjusted position is inside the untransformed path
    return birdPath.contains(position);
  }

  // Check if touch is inside the leaves
  bool _isInsideLeaves(Offset position, Size containerSize) {
    // Since position is already in bird coordinates from _adjustTouchPosition
    // Check if inside leaf 1
    final leaf1Path = getLeaf1Path();
    if (leaf1Path.contains(position)) {
      return true;
    }

    // Check if inside leaf 2
    final leaf2Path = getLeaf2Path();
    if (leaf2Path.contains(position)) {
      return true;
    }

    // Check if inside eye
    final eyePath = getEyePath();
    if (eyePath.contains(position)) {
      return true;
    }

    return false;
  }

  // Get the transformed bird body path for clipping
  Path getTransformedBirdBodyPath(Size size) {
    final Path birdPath = getBirdPath();

    // Apply transformation to fit the path to our canvas size
    final double scale = math.min(size.width / 500, size.height / 600);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    return birdPath.transform(matrix.storage);
  }

  // Create the bird path
  Path getBirdPath() {
    // Define body path
    final Path bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    return bodyPath;
  }

  // Create the leaves and eye paths
  Path getLeaf1Path() {
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();
    return leaf1Path;
  }

  Path getLeaf2Path() {
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();
    return leaf2Path;
  }

  Path getEyePath() {
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();
    return eyePath;
  }
}

// Class to represent a drawing point with its properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

// Painter for coloring the bird parts with fill colors
class BirdColorPainter extends CustomPainter {
  final Color bodyColor;
  final Color leaf1Color;
  final Color leaf2Color;
  final Color eyeColor;

  BirdColorPainter({
    required this.bodyColor,
    required this.leaf1Color,
    required this.leaf2Color,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 500, size.height / 600);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    // Draw body with fill color
    final bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    // Fill body
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw leaf1 with fill color
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();

    // Fill leaf1
    final leaf1Paint = Paint()
      ..color = leaf1Color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf1Path, leaf1Paint);

    // Draw leaf2 with fill color
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();

    // Fill leaf2
    final leaf2Paint = Paint()
      ..color = leaf2Color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf2Path, leaf2Paint);

    // Draw eye with fill color
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();

    // Fill eye
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(eyePath, eyePaint);
  }

  @override
  bool shouldRepaint(covariant BirdColorPainter oldDelegate) => false;
}

// Painter for drawing the bird outline
class BirdOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 500, size.height / 600);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    // Draw body outline
    final bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    // Draw body outline
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(bodyPath, borderPaint);

    // Draw leaf1 outline
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();
    canvas.drawPath(leaf1Path, borderPaint);

    // Draw leaf2 outline
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();
    canvas.drawPath(leaf2Path, borderPaint);

    // Draw eye
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();
    canvas.drawPath(eyePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the user's strokes
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Path birdBodyPath;

  DrawingPainter({
    required this.drawingPoints,
    required this.birdBodyPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the bird body only
    canvas.clipPath(birdBodyPath);

    // Draw all the points
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        // Draw a line between consecutive points
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          drawingPoints[i]!.paint,
        );
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        // Draw a single point as a circle
        canvas.drawCircle(
          drawingPoints[i]!.offset,
          drawingPoints[i]!.paint.strokeWidth / 2,
          drawingPoints[i]!.paint,
        );
      }
    }

    // Restore the canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

class ColoringPainter extends CustomPainter {
  final List<Offset> points;
  final List<Color> colors;
  final double brushSize;

  ColoringPainter(this.points, this.colors, this.brushSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw mandala outline
    Paint outlinePaint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw circles
    canvas.drawCircle(Offset(150, 150), 140, outlinePaint);
    canvas.drawCircle(Offset(150, 150), 90, outlinePaint);
    canvas.drawCircle(Offset(150, 150), 45, outlinePaint);

    // Draw radial lines
    for (int i = 0; i < 12; i++) {
      double angle = (i * math.pi) / 6;
      Offset start = Offset(
        150 + 45 * math.cos(angle),
        150 + 45 * math.sin(angle),
      );
      Offset end = Offset(
        150 + 140 * math.cos(angle),
        150 + 140 * math.sin(angle),
      );
      canvas.drawLine(start, end, outlinePaint);
    }

    // Draw coloring points with smooth lines
    for (int i = 0; i < points.length; i++) {
      Paint colorPaint = Paint()
        ..color = colors[i]
        ..strokeCap = StrokeCap.round
        ..strokeWidth = brushSize;

      // For a single point, draw a dot
      if (i == 0 || points[i - 1] != points[i]) {
        canvas.drawCircle(points[i], brushSize / 2, colorPaint);
      }

      // Connect points with lines
      if (i > 0) {
        // Only draw line if points are close enough (to avoid jumps)
        double distance = (points[i] - points[i - 1]).distance;
        if (distance < 50) {
          // Reasonable threshold for connected strokes
          Paint linePaint = Paint()
            ..color = colors[i]
            ..strokeCap = StrokeCap.round
            ..strokeWidth = brushSize
            ..style = PaintingStyle.stroke;

          canvas.drawLine(points[i - 1], points[i], linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// Move this widget outside of the _CreativeActivitiesPageState class
class SlidingPuzzleWidget extends StatefulWidget {
  @override
  _SlidingPuzzleWidgetState createState() => _SlidingPuzzleWidgetState();
}

class _SlidingPuzzleWidgetState extends State<SlidingPuzzleWidget>
    with TickerProviderStateMixin {
  // Puzzle game variables
  late List<int> puzzleTiles; // Tiles in current order
  int movesCount = 0;
  bool gameComplete = false;
  DateTime? gameStartTime;
  bool showReference = true; // Show reference image by default

  // Animation properties
  Map<int, AnimationController> _animationControllers = {};
  Map<int, Animation<Offset>> _animations = {};
  Map<int, Offset> _tileOffsets = {};

  // Use a single image for the puzzle
  final String puzzleImagePath = 'assets/Activity_Tools/sliding-dog.png';

  @override
  void initState() {
    super.initState();
    initializePuzzle();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void initializePuzzle() {
    // Create a solved puzzle (1-8 + empty tile at 9)
    puzzleTiles = List.generate(9, (index) => index + 1);
    shufflePuzzle();
  }

  void shufflePuzzle() {
    // Reset variables
    movesCount = 0;
    gameComplete = false;
    gameStartTime = DateTime.now();
    _tileOffsets.clear();

    // Dispose existing animation controllers
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animations.clear();

    // Create a random but solvable puzzle
    puzzleTiles = List.generate(9, (index) => index + 1);
    final random = math.Random();

    // Perform random valid moves to shuffle
    for (int i = 0; i < 100; i++) {
      // Find empty tile position
      final emptyIndex = puzzleTiles.indexOf(9);
      final row = emptyIndex ~/ 3;
      final col = emptyIndex % 3;

      // Get valid moves
      List<int> validMoves = [];

      // Check up
      if (row > 0) validMoves.add(emptyIndex - 3);
      // Check down
      if (row < 2) validMoves.add(emptyIndex + 3);
      // Check left
      if (col > 0) validMoves.add(emptyIndex - 1);
      // Check right
      if (col < 2) validMoves.add(emptyIndex + 1);

      // Select random valid move
      final moveIndex = validMoves[random.nextInt(validMoves.length)];

      // Swap
      final temp = puzzleTiles[emptyIndex];
      puzzleTiles[emptyIndex] = puzzleTiles[moveIndex];
      puzzleTiles[moveIndex] = temp;
    }

    setState(() {});
  }

  // Check if move is valid
  bool isValidMove(int index) {
    if (gameComplete) return false;

    final emptyIndex = puzzleTiles.indexOf(9);
    final row = index ~/ 3;
    final col = index % 3;
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    // Check if the tile is adjacent to the empty space
    return (row == emptyRow && (col == emptyCol - 1 || col == emptyCol + 1)) ||
        (col == emptyCol && (row == emptyRow - 1 || row == emptyRow + 1));
  }

  // Handle tap movement
  void moveTile(int index) {
    if (!isValidMove(index)) return;

    final emptyIndex = puzzleTiles.indexOf(9);

    // Create animation for the tile movement
    _animateTileMovement(index, emptyIndex);

    setState(() {
      // Swap the tiles
      final temp = puzzleTiles[index];
      puzzleTiles[index] = puzzleTiles[emptyIndex];
      puzzleTiles[emptyIndex] = temp;

      // Clear any drag offsets
      _tileOffsets.clear();

      // Increment move count
      movesCount++;

      // Check win condition
      checkWin();
    });
  }

  // Create and run animation for tile movement
  void _animateTileMovement(int fromIndex, int toIndex) {
    // Dispose old controller if exists
    if (_animationControllers.containsKey(fromIndex)) {
      _animationControllers[fromIndex]?.dispose();
    }

    // Create new controller
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Calculate offset based on grid position
    final fromRow = fromIndex ~/ 3;
    final fromCol = fromIndex % 3;
    final toRow = toIndex ~/ 3;
    final toCol = toIndex % 3;

    final offsetX = toCol - fromCol;
    final offsetY = toRow - fromRow;

    // Create animation
    final animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(offsetX.toDouble(), offsetY.toDouble()),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    // Store animation
    _animationControllers[fromIndex] = controller;
    _animations[fromIndex] = animation;

    // Run animation
    controller.forward().then((_) {
      if (mounted) {
        controller.dispose();
        _animationControllers.remove(fromIndex);
        _animations.remove(fromIndex);
      }
    });
  }

  void checkWin() {
    // Check if puzzle is solved
    bool isSolved = true;
    for (int i = 0; i < puzzleTiles.length - 1; i++) {
      if (puzzleTiles[i] != i + 1) {
        isSolved = false;
        break;
      }
    }

    if (isSolved && puzzleTiles.last == 9) {
      gameComplete = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Game controls and stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Moves: $movesCount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            SizedBox(width: 10),
            if (gameStartTime != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Time: ${DateTime.now().difference(gameStartTime!).inSeconds}s',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            SizedBox(width: 10),
            // Reference toggle button
            IconButton(
              icon: Icon(
                showReference ? Icons.visibility : Icons.visibility_off,
                color: showReference ? Colors.blue[600] : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  showReference = !showReference;
                });
              },
              tooltip: showReference ? 'Hide Reference' : 'Show Reference',
              iconSize: 20,
              padding: EdgeInsets.all(0),
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 10),
            // Refresh button
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue[600]),
              onPressed: shufflePuzzle,
              tooltip: 'New Puzzle',
              iconSize: 20,
              padding: EdgeInsets.all(0),
              constraints: BoxConstraints(),
            ),
          ],
        ),
        SizedBox(height: 8),

        // Main game content
        Expanded(
          child: Row(
            children: [
              // Main puzzle grid
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 2),
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final gridSize = constraints.maxWidth;
                            final actualTileSize = gridSize / 3;

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 2,
                                crossAxisSpacing: 2,
                              ),
                              itemCount: 9,
                              itemBuilder: (context, index) {
                                final tile = puzzleTiles[index];

                                // Skip empty tile
                                if (tile == 9) {
                                  return Container(color: Colors.white);
                                }

                                // Calculate the original position of this tile (0-based)
                                final originalRow = (tile - 1) ~/ 3;
                                final originalCol = (tile - 1) % 3;

                                // Apply animation or drag offset
                                Offset offset =
                                    _tileOffsets[index] ?? Offset.zero;
                                if (_animations.containsKey(index)) {
                                  return AnimatedBuilder(
                                    animation: _animations[index]!,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(
                                          _animations[index]!.value.dx *
                                              actualTileSize,
                                          _animations[index]!.value.dy *
                                              actualTileSize,
                                        ),
                                        child: child,
                                      );
                                    },
                                    child: _buildTile(originalRow, originalCol,
                                        actualTileSize, index),
                                  );
                                } else {
                                  return Transform.translate(
                                    offset: Offset(
                                      offset.dx * actualTileSize,
                                      offset.dy * actualTileSize,
                                    ),
                                    child: _buildTile(originalRow, originalCol,
                                        actualTileSize, index),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Reference image (conditional)
              if (showReference)
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Reference',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: AssetImage(puzzleImagePath),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Success message when puzzle is complete
        if (gameComplete)
          Container(
            margin: EdgeInsets.only(top: 8),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🎉 Puzzle Complete!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
      ],
    );
  }

  // Build a tile with image section (no numbers overlay)
  Widget _buildTile(int row, int col, double tileSize, int index) {
    return GestureDetector(
      onTap: () => moveTile(index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRect(
          child: SizedBox(
            width: tileSize,
            height: tileSize,
            child: Stack(
              children: [
                Positioned(
                  left: -col * tileSize,
                  top: -row * tileSize,
                  width: tileSize * 3,
                  height: tileSize * 3,
                  child: Image.asset(
                    puzzleImagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback for when the image can't be loaded
                      return Center(
                        child: Text(
                          (row * 3 + col + 1).toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Number overlay removed as requested
              ],
            ),
          ),
        ),
      ),
    );
  }
}
