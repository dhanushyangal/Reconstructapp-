import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking

class MemoryGamePage extends StatefulWidget {
  const MemoryGamePage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/memory-game';

  @override
  State<MemoryGamePage> createState() => _MemoryGamePageState();
}

class _MemoryGamePageState extends State<MemoryGamePage>
    with TickerProviderStateMixin {
  // Game state
  bool gameStarted = false;
  int movesCount = 0;
  int seconds = 0;
  int minutes = 0;
  int winCount = 0;
  Timer? timer;
  String difficulty = 'Medium'; // Easy, Medium, Hard
  int gridSize = 4; // 4x4 default

  // Animation controllers
  late AnimationController _confettiController;

  // Card selection
  int? firstCardIndex;
  int? secondCardIndex;

  // List of emojis for the cards
  final List<String> emojiItems = [
    '🐝', // bee
    '🐊', // crocodile
    '🦜', // macaw
    '🦍', // gorilla
    '🐅', // tiger
    '🐒', // monkey
    '🦎', // chameleon
    '🐟', // fish (piranha)
    '🐍', // snake (anaconda)
    '🦥', // sloth
    '🦚', // peacock (cockatoo)
    '🦉', // owl (toucan)
    '🦋', // butterfly
    '🐢', // turtle
    '🦁', // lion
    '🐘', // elephant
    '🦒', // giraffe
    '🦓', // zebra
  ];

  // Colors
  final Color primaryColor = const Color(0xFF2196F3);
  final Color secondaryColor = const Color(0xFF64B5F6);
  final Color backgroundColor = Colors.white;
  final Color cardBackColor = Colors.black;
  final Color cardFrontColor = Colors.white;
  final Color successColor = const Color(0xFF1565C0);

  // Cards state
  List<Map<String, dynamic>> cards = [];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Memory Game',
        imagePath: 'assets/Activity_Tools/memory-game.png',
        timestamp: DateTime.now(),
        routeName: MemoryGamePage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    timer?.cancel();
    super.dispose();
  }

  void _setDifficulty(String newDifficulty) {
    setState(() {
      difficulty = newDifficulty;
      switch (newDifficulty) {
        case 'Easy':
          gridSize = 2; // 2x2 grid
          break;
        case 'Medium':
          gridSize = 4; // 4x4 grid
          break;
        case 'Hard':
          gridSize = 6; // 6x6 grid
          break;
      }
    });
  }

  void startGame() {
    setState(() {
      gameStarted = true;
      movesCount = 0;
      seconds = 0;
      minutes = 0;
      winCount = 0;
      firstCardIndex = null;
      secondCardIndex = null;

      // Generate the cards
      initializeCards();
    });

    // Reset confetti animation
    _confettiController.reset();

    // Start the timer
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        seconds += 1;
        if (seconds >= 60) {
          minutes += 1;
          seconds = 0;
        }
      });
    });
  }

  void stopGame() {
    setState(() {
      gameStarted = false;
    });
    timer?.cancel();
  }

  void initializeCards() {
    // Pick random emojis
    final int pairsCount = (gridSize * gridSize) ~/ 2;
    final List<String> randomEmojis = [];

    final List<String> tempEmojis = List.from(emojiItems);
    tempEmojis.shuffle();

    for (int i = 0; i < pairsCount; i++) {
      if (i < tempEmojis.length) {
        randomEmojis.add(tempEmojis[i]);
      }
    }

    // Create pairs and shuffle
    final List<String> allEmojis = [...randomEmojis, ...randomEmojis];
    allEmojis.shuffle();

    // Create card data
    cards = List.generate(allEmojis.length, (index) {
      return {
        'emoji': allEmojis[index],
        'isFlipped': false,
        'isMatched': false,
        'flipController': AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        ),
      };
    });
  }

  void handleCardTap(int index) {
    // Don't do anything if the card is already matched or flipped
    if (cards[index]['isMatched'] || cards[index]['isFlipped']) {
      return;
    }

    // Don't do anything if we're waiting for cards to flip back
    if (secondCardIndex != null) {
      return;
    }

    setState(() {
      // Flip the card
      cards[index]['isFlipped'] = true;

      // If this is the first card
      if (firstCardIndex == null) {
        firstCardIndex = index;
      }
      // If this is the second card
      else {
        secondCardIndex = index;
        movesCount++;

        // Check for a match
        if (cards[firstCardIndex!]['emoji'] ==
            cards[secondCardIndex!]['emoji']) {
          // We have a match
          cards[firstCardIndex!]['isMatched'] = true;
          cards[secondCardIndex!]['isMatched'] = true;
          winCount++;

          // Reset selection
          firstCardIndex = null;
          secondCardIndex = null;

          // Check for win condition
          if (winCount == cards.length ~/ 2) {
            stopGame();
            // Play confetti animation
            _confettiController.forward();
          }
        } else {
          // No match, flip cards back after delay
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() {
                cards[firstCardIndex!]['isFlipped'] = false;
                cards[secondCardIndex!]['isFlipped'] = false;
                firstCardIndex = null;
                secondCardIndex = null;
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Game'),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              backgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            // Stats container (time and moves)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Moves: $movesCount',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Game grid or start screen
            Expanded(
              child: gameStarted
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridSize,
                          childAspectRatio: 1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => handleCardTap(index),
                            child: _buildCard(index),
                          );
                        },
                      ),
                    )
                  : Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (winCount > 0)
                                Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        successColor,
                                        successColor.withBlue(220),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: successColor.withOpacity(0.4),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        '🎉 You Won! 🎉',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Moves: $movesCount',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Time: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              const Text(
                                'Match all the emoji pairs',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Test your memory by finding matching pairs of emojis',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Difficulty:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildDifficultyButton('Easy', '2×2'),
                                        _buildDifficultyButton('Medium', '4×4'),
                                        _buildDifficultyButton('Hard', '6×6'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton(
                                onPressed: startGame,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 48,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                  shadowColor: primaryColor.withOpacity(0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.play_arrow),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Game',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (winCount > 0) _buildConfetti(),
                      ],
                    ),
            ),

            // Stop button
            if (gameStarted)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: stopGame,
                  icon: const Icon(Icons.stop),
                  label: const Text(
                    'Stop Game',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyButton(String level, String gridText) {
    final bool isSelected = difficulty == level;
    return GestureDetector(
      onTap: () => _setDifficulty(level),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              gridText,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: ConfettiPainter(_confettiController.value),
        );
      },
    );
  }

  Widget _buildCard(int index) {
    final isFlipped = cards[index]['isFlipped'];
    final isMatched = cards[index]['isMatched'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isFlipped ? pi : 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: isMatched
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  successColor.withOpacity(0.7),
                  successColor,
                ],
              )
            : (isFlipped
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardFrontColor,
                      cardFrontColor.withOpacity(0.9),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      cardBackColor,
                      cardBackColor.withOpacity(0.8),
                    ],
                  )),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isMatched
                ? successColor.withOpacity(0.4)
                : (isFlipped
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.3))),
            blurRadius: 8,
            offset: isFlipped ? const Offset(0, 4) : const Offset(2, 6),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isFlipped
              ? Text(
                  cards[index]['emoji'],
                  key: ValueKey('front${cards[index]['emoji']}'),
                  style: const TextStyle(fontSize: 40),
                )
              : Icon(
                  Icons.question_mark,
                  key: const ValueKey('back'),
                  color: Colors.white,
                  size: 40,
                ),
        ),
      ),
    );
  }
}

// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors = [
    Colors.blue,
    Colors.lightBlue,
    Colors.white,
    Colors.blueAccent,
    Colors.black,
    Colors.blue.shade800,
  ];
  final Random random = Random();

  ConfettiPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Number of confetti pieces
    final int particleCount = 100;

    for (int i = 0; i < particleCount; i++) {
      // Random color for each piece
      paint.color = colors[random.nextInt(colors.length)];

      // Random position within the canvas
      final double x = random.nextDouble() * size.width;
      final double initialY = -50.0; // Start above the screen

      // Calculate y based on progress (falling down effect)
      final double gravity = 9.8;
      final double time = progress * 2; // Adjust for speed
      final double distance = 0.5 * gravity * time * time;
      final double y = initialY + distance + (random.nextDouble() * 200);

      // Size of confetti piece - varies randomly
      final double pieceSize = 5 + random.nextDouble() * 10;

      // Draw the confetti piece as a rectangle/square with rotation
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * pi * 2);

      // Different shapes for variety
      if (i % 3 == 0) {
        // Rectangle
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: pieceSize,
            height: pieceSize * 2,
          ),
          paint,
        );
      } else if (i % 3 == 1) {
        // Circle
        canvas.drawCircle(
          Offset.zero,
          pieceSize / 2,
          paint,
        );
      } else {
        // Diamond
        final path = Path()
          ..moveTo(0, -pieceSize / 2)
          ..lineTo(pieceSize / 2, 0)
          ..lineTo(0, pieceSize / 2)
          ..lineTo(-pieceSize / 2, 0)
          ..close();
        canvas.drawPath(path, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
