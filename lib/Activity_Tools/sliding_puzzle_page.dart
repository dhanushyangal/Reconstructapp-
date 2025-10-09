import 'package:flutter/material.dart';
import 'dart:math';

class SlidingPuzzlePage extends StatefulWidget {
  static const routeName = '/sliding-puzzle';

  const SlidingPuzzlePage({super.key});

  @override
  State<SlidingPuzzlePage> createState() => _SlidingPuzzlePageState();
}

class _SlidingPuzzlePageState extends State<SlidingPuzzlePage>
    with TickerProviderStateMixin {
  late List<int> puzzleTiles; // Tiles in current order
  int movesCount = 0;
  bool gameStarted = false;
  bool gameComplete = false;
  bool showReference = true; // Toggle for showing/hiding reference

  // Animation properties

  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<Offset>> _animations = {};

  Map<int, Offset> _tileOffsets = {};
  int? _draggingTileIndex;
  
  Offset _dragOffset = Offset.zero;

  // Use a single image that will be split into tiles
  final String puzzleImagePath = 'assets/activity_tools/sliding-dog.png';

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

    puzzleTiles = List.generate(9, (index) => index + 1);

    // Reset animation controllers and offsets
    _animationControllers.clear();
    _animations.clear();
    _tileOffsets = {};
  }

  void shufflePuzzle() {
    // Reset variables
    movesCount = 0;
    gameComplete = false;
    _tileOffsets.clear();

    // Dispose existing animation controllers
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _animations.clear();

    // Create a random but solvable puzzle
    puzzleTiles = List.generate(9, (index) => index + 1);
    final random = Random();

    // Perform random valid moves to shuffle
    for (int i = 0; i < 100; i++) {
      // Find empty tile position
      final emptyIndex = puzzleTiles.indexOf(9);
      final row = emptyIndex ~/ 3;
      final col = emptyIndex % 3;

      // Get valid moves
      List<int> validMoves = [];

      // Check up
      if (row > 0) {
        validMoves.add(emptyIndex - 3);
      }
      // Check down
      if (row < 2) {
        validMoves.add(emptyIndex + 3);
      }
      // Check left
      if (col > 0) {
        validMoves.add(emptyIndex - 1);
      }
      // Check right
      if (col < 2) {
        validMoves.add(emptyIndex + 1);
      }

      // Select random valid move
      final moveIndex = validMoves[random.nextInt(validMoves.length)];

      // Swap
      final temp = puzzleTiles[emptyIndex];
      puzzleTiles[emptyIndex] = puzzleTiles[moveIndex];
      puzzleTiles[moveIndex] = temp;
    }

    setState(() {
      gameStarted = true;
    });
  }

  // Check if move is valid
  bool isValidMove(int index) {
    if (!gameStarted || gameComplete) return false;

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

  // Handle the start of a drag gesture
  void _onDragStart(int index, DragStartDetails details) {
    if (!isValidMove(index) || gameComplete) return;

    setState(() {
      _draggingTileIndex = index;
      _dragOffset = Offset.zero;
    });
  }

  // Handle drag update
  void _onDragUpdate(int index, DragUpdateDetails details, double tileSize) {
    if (_draggingTileIndex != index || !isValidMove(index) || gameComplete) {
      return;
    }

    final emptyIndex = puzzleTiles.indexOf(9);
    final row = index ~/ 3;
    final col = index % 3;
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    // Calculate allowed drag direction
    Offset newOffset = _dragOffset;

    if (row == emptyRow) {
      // Horizontal movement only
      double dx = details.delta.dx;

      // Restrict movement based on empty tile position
      if ((emptyCol > col && dx > 0) || (emptyCol < col && dx < 0)) {
        newOffset += Offset(dx / tileSize, 0);
      }
    } else if (col == emptyCol) {
      // Vertical movement only
      double dy = details.delta.dy;

      // Restrict movement based on empty tile position
      if ((emptyRow > row && dy > 0) || (emptyRow < row && dy < 0)) {
        newOffset += Offset(0, dy / tileSize);
      }
    }

    // Clamp offset to ensure tile doesn't move too far
    newOffset = Offset(
      newOffset.dx
          .clamp(emptyCol - col > 0 ? 0 : -1, emptyCol - col < 0 ? 0 : 1),
      newOffset.dy
          .clamp(emptyRow - row > 0 ? 0 : -1, emptyRow - row < 0 ? 0 : 1),
    );

    setState(() {
      _dragOffset = newOffset;
      _tileOffsets[index] = newOffset;
    });
  }

  // Handle the end of a drag gesture
  void _onDragEnd(int index, DragEndDetails details) {
    if (_draggingTileIndex != index || !isValidMove(index) || gameComplete) {
      return;
    }

    final emptyIndex = puzzleTiles.indexOf(9);
    final row = index ~/ 3;
    final col = index % 3;
    final emptyRow = emptyIndex ~/ 3;
    final emptyCol = emptyIndex % 3;

    // Check if the drag was significant enough to complete the move
    bool completedMove = false;

    if (row == emptyRow) {
      // Horizontal movement
      if ((emptyCol > col && _dragOffset.dx > 0.5) ||
          (emptyCol < col && _dragOffset.dx < -0.5)) {
        completedMove = true;
      }
    } else if (col == emptyCol) {
      // Vertical movement
      if ((emptyRow > row && _dragOffset.dy > 0.5) ||
          (emptyRow < row && _dragOffset.dy < -0.5)) {
        completedMove = true;
      }
    }

    setState(() {
      _draggingTileIndex = null;

      if (completedMove) {
        // Complete the move
        final temp = puzzleTiles[index];
        puzzleTiles[index] = puzzleTiles[emptyIndex];
        puzzleTiles[emptyIndex] = temp;

        // Increment move count
        movesCount++;

        // Check win condition
        checkWin();
      }

      // Clear all drag offsets
      _tileOffsets.clear();
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
      showWinDialog();
    }
  }

  void showWinDialog() {
    Future.delayed(Duration(milliseconds: 300), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: Text('You solved the puzzle in $movesCount moves!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  gameStarted = false;
                  showReference = true;
                });
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLandscape = screenSize.width > screenSize.height;
    final double puzzleSize = isLandscape
        ? screenSize.height * 0.7
        : min(screenSize.width * 0.9, 400);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sliding Puzzle'),
        actions: gameStarted
            ? [
                // Toggle reference button
                IconButton(
                  icon: Icon(
                    showReference ? Icons.visibility_off : Icons.visibility,
                    color: showReference ? Colors.blue : null,
                  ),
                  onPressed: () {
                    setState(() {
                      showReference = !showReference;
                    });
                  },
                  tooltip: showReference ? 'Hide Reference' : 'Show Reference',
                ),
                // Reset game button
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    shufflePuzzle();
                  },
                  tooltip: 'New Game',
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: gameStarted
            ? _buildGameScreen(puzzleSize, isLandscape)
            : _buildStartScreen(),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sliding Puzzle',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Show the full puzzle image on the start screen
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(puzzleImagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'When you play a sliding puzzle, your mind shifts focus to solving something simple yet engaging. It helps distract you from overwhelming thoughts and gives you a moment of calm and clarity.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: shufflePuzzle,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Start Game',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(double puzzleSize, bool isLandscape) {
    // Make sure we use the available layout effectively
    final Widget referenceGrid =
        _buildReferenceGrid(isLandscape ? puzzleSize * 0.5 : puzzleSize * 0.7);

    final Widget puzzleGrid = Container(
      width: puzzleSize,
      height: puzzleSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        color: Colors.black,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final gridSize = constraints.maxWidth;
        final actualTileSize = gridSize / 3;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2, // Minimal spacing
            crossAxisSpacing: 2, // Minimal spacing
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
            Offset offset = _tileOffsets[index] ?? Offset.zero;
            if (_animations.containsKey(index)) {
              return AnimatedBuilder(
                animation: _animations[index]!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _animations[index]!.value.dx * actualTileSize,
                      _animations[index]!.value.dy * actualTileSize,
                    ),
                    child: child,
                  );
                },
                child:
                    _buildTile(originalRow, originalCol, actualTileSize, index),
              );
            } else {
              return Transform.translate(
                offset: Offset(
                  offset.dx * actualTileSize,
                  offset.dy * actualTileSize,
                ),
                child:
                    _buildTile(originalRow, originalCol, actualTileSize, index),
              );
            }
          },
        );
      }),
    );

    // Game info widget
    final Widget gameInfo = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Moves: $movesCount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );

    // Show different layouts depending on orientation
    if (isLandscape) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              gameInfo,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  puzzleGrid,
                  if (showReference) const SizedBox(width: 24),
                  if (showReference) referenceGrid,
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            gameInfo,
            Center(child: puzzleGrid),
            if (showReference) const SizedBox(height: 24),
            if (showReference) Center(child: referenceGrid),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: shufflePuzzle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('New Game'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildReferenceGrid(double size) {
    return Column(
      children: [
        const Text(
          'Reference',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 2),
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: AssetImage(puzzleImagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // Build a draggable tile with precise image section
  Widget _buildTile(int row, int col, double tileSize, int index) {
    return GestureDetector(
      onTap: () => moveTile(index),
      onPanStart: (details) => _onDragStart(index, details),
      onPanUpdate: (details) => _onDragUpdate(index, details, tileSize),
      onPanEnd: (details) => _onDragEnd(index, details),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
