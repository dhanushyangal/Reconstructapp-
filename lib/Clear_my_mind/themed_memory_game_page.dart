import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking
import '../components/nav_logpage.dart';
import '../utils/activity_tracker_mixin.dart';
import 'memory_success_page.dart';

class ThemedMemoryGamePage extends StatefulWidget {
  const ThemedMemoryGamePage({
    super.key,
    required this.gameTheme,
    required this.gameName,
  });

  final String gameTheme;
  final String gameName;

  @override
  State<ThemedMemoryGamePage> createState() => _ThemedMemoryGamePageState();
}

class _ThemedMemoryGamePageState extends State<ThemedMemoryGamePage>
    with TickerProviderStateMixin, ActivityTrackerMixin {
  // Game state
  int movesCount = 0;
  int seconds = 0;
  int minutes = 0;
  int winCount = 0;
  Timer? timer;

  // Animation controllers
  late AnimationController _confettiController;

  // Progress bar animation
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Card selection
  int? firstCardIndex;
  int? secondCardIndex;

  // Colors
  final Color primaryColor = const Color(0xFF2196F3);
  final Color secondaryColor = const Color(0xFF64B5F6);
  final Color backgroundColor = Colors.white;
  final Color cardBackColor = Colors.black;
  final Color cardFrontColor = Colors.white;
  final Color successColor = const Color(0xFF1565C0);

  // Cards state
  List<Map<String, dynamic>> cards = [];

  // Get number of images per theme
  int get imageCount {
    switch (widget.gameTheme) {
      case 'animals':
        return 5;
      case 'everyday':
        return 6;
      case 'monuments':
        return 8;
      case 'people':
        return 10;
      default:
        return 6;
    }
  }

  // Get card back image based on theme
  String get cardBackImage {
    return 'assets/memory_game/cover_image/${widget.gameTheme}.png';
  }

  // Theme-specific items with numbered images
  List<Map<String, dynamic>> get themeItems {
    final String basePath = 'assets/memory_game/${widget.gameTheme}/';
    final List<Map<String, dynamic>> items = [];
    
    for (int i = 1; i <= imageCount; i++) {
      items.add({
        'image': '$basePath$i.png',
        'id': '$i',
      });
    }
    
    return items;
  }

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: 0.75, // 75% progress for themed memory game page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();

    // Track this page visit in recent activities
    _trackActivity();
    
    // Auto-start the game
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startGame();
    });
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: widget.gameName,
        imagePath: 'assets/clear_my_mind_memory_games/${widget.gameTheme}.png',
        timestamp: DateTime.now(),
        routeName: '/themed-memory-game-${widget.gameTheme}',
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _progressAnimationController?.dispose();
    timer?.cancel();
    super.dispose();
  }


  void startGame() {
    setState(() {
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


  void initializeCards() {
    // Use all available images for this theme
    final List<Map<String, dynamic>> allImages = List.from(themeItems);
    
    // Create pairs (duplicate each image)
    final List<Map<String, dynamic>> allItems = [...allImages, ...allImages];
    
    // Shuffle the cards
    allItems.shuffle();

    // Create card data
    cards = List.generate(allItems.length, (index) {
      return {
        'item': allItems[index],
        'isFlipped': false,
        'isMatched': false,
        'flipController': AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        ),
      };
    });
  }

  // Calculate optimal column count based on total cards (swapped: columns as rows, rows as columns)
  int _getColumnCount() {
    final int totalCards = cards.length;
    
    // Determine best column count for grid layout (now showing as rows vertically)
    // animals: 10 cards (5 pairs) -> 2 columns, 5 rows
    // everyday: 12 cards (6 pairs) -> 3 columns, 4 rows
    // monuments: 16 cards (8 pairs) -> 4 columns, 4 rows
    // people: 20 cards (10 pairs) -> 4 columns, 5 rows
    
    if (totalCards <= 10) {
      return 2; // 2 columns for 10 cards (5 rows)
    } else if (totalCards <= 12) {
      return 3; // 3 columns for 12 cards (4 rows)
    } else if (totalCards <= 16) {
      return 4; // 4 columns for 16 cards (4 rows)
    } else {
      return 4; // 4 columns for 20 cards (5 rows)
    }
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
        if (cards[firstCardIndex!]['item']['id'] ==
            cards[secondCardIndex!]['item']['id']) {
          // We have a match
          cards[firstCardIndex!]['isMatched'] = true;
          cards[secondCardIndex!]['isMatched'] = true;
          winCount++;

          // Reset selection
          firstCardIndex = null;
          secondCardIndex = null;

          // Check for win condition
          if (winCount == cards.length ~/ 2) {
            // Stop timer and play confetti animation
            timer?.cancel();
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
    return NavLogPage(
      title: widget.gameName,
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
          
          // Main game content
          Expanded(
            child: Container(
              color: Colors.white,
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

                  // Game grid - always show the game
                  Expanded(
                    child: Stack(
                      children: [
                        Center(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final availableHeight = constraints.maxHeight;
                              final columnCount = _getColumnCount();
                              final rowCount = (cards.length / columnCount).ceil();
                              
                              // Calculate maximum card size based on available space
                              final maxCardWidth = (availableWidth - 32 - (columnCount - 1) * 12) / columnCount;
                              final maxCardHeight = (availableHeight - 32 - (rowCount - 1) * 12) / rowCount;
                              final cardSize = min(maxCardWidth, maxCardHeight);
                              
                              // Calculate total grid width and height
                              final gridWidth = (cardSize * columnCount) + ((columnCount - 1) * 12);
                              final gridHeight = (cardSize * rowCount) + ((rowCount - 1) * 12);
                              
                              return Container(
                                width: gridWidth,
                                height: min(gridHeight, availableHeight - 32),
                          padding: const EdgeInsets.all(16.0),
                          child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnCount,
                              childAspectRatio: 1,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                            ),
                            itemCount: cards.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => handleCardTap(index),
                                child: _buildCard(index),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        if (winCount > 0 && winCount == cards.length ~/ 2) _buildConfetti(),
                      ],
                    ),
                  ),

                  // Win dialog below the game
                        if (winCount > 0 && winCount == cards.length ~/ 2)
                          Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                        vertical: 20,
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
                                  mainAxisSize: MainAxisSize.min,
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
                                    const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        // Reset win count first, then restart game
                                  setState(() {
                                        winCount = 0;
                                  });
                                        Future.microtask(() {
                                          if (mounted) {
                                            startGame();
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: successColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Play Again',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _navigateToSuccessPage();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: successColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ],
                          ),
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
    final item = cards[index]['item'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isFlipped ? pi : 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMatched
            ? successColor
            : (isFlipped ? cardFrontColor : Colors.white),
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
              ? ClipRRect(
                  key: ValueKey('front${item['id']}'),
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    item['image'],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image not found
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                )
              : ClipRRect(
                  key: const ValueKey('back'),
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    cardBackImage,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to question mark if cover image not found
                      return Icon(
                        Icons.question_mark,
                        color: Colors.white,
                        size: 32,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  void _navigateToSuccessPage() {
    // Track the activity
    trackClick('memory_game_next');
    
    // Navigate to memory success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MemorySuccessPage(),
      ),
    );
  }

  String get pageName => widget.gameName;
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
