import 'package:flutter/material.dart';
import 'dart:math';
import '../components/nav_logpage.dart';
import '../utils/activity_tracker_mixin.dart';

class EnhancedSlidingPuzzlePage extends StatefulWidget {
  static const routeName = '/enhanced-sliding-puzzle';
  
  final String puzzleTheme;
  final String puzzleName;

  const EnhancedSlidingPuzzlePage({
    super.key,
    required this.puzzleTheme,
    required this.puzzleName,
  });

  @override
  State<EnhancedSlidingPuzzlePage> createState() => _EnhancedSlidingPuzzlePageState();
}

class _EnhancedSlidingPuzzlePageState extends State<EnhancedSlidingPuzzlePage>
    with TickerProviderStateMixin, ActivityTrackerMixin {
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

  // Progress bar animation
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;


  // Puzzle configuration based on theme
  int get gridSize {
    switch (widget.puzzleTheme) {
      case 'dog':
      case 'fox':
        return 3; // 3x3 grid
      case 'lion':
      case 'owl':
        return 4; // 4x4 grid
      default:
        return 3;
    }
  }

  int get totalTiles => gridSize * gridSize;

  int get emptyTilePosition {
    switch (widget.puzzleTheme) {
      case 'dog':
        return 2; // 3rd card (0-based index)
      case 'fox':
        return 0; // 1st card (0-based index)
      case 'lion':
        return 0; // 1st card (0-based index)
      case 'owl':
        return 15; // 16th card (0-based index)
      default:
        return 8; // Last card for 3x3
    }
  }

  // Get puzzle image path based on theme
  String get puzzleImagePath {
    switch (widget.puzzleTheme) {
      case 'fox':
        return 'assets/clear_my_mind_sliding_puzzles/fox.png';
      case 'dog':
        return 'assets/clear_my_mind_sliding_puzzles/dog.png';
      case 'lion':
        return 'assets/clear_my_mind_sliding_puzzles/lion.png';
      case 'owl':
        return 'assets/clear_my_mind_sliding_puzzles/owl.png';
      default:
        return 'assets/clear_my_mind_sliding_puzzles/fox.png';
    }
  }

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
      end: 0.75, // 75% progress for enhanced sliding puzzle page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
    
    initializePuzzle();
    
    // Auto-start the puzzle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      shufflePuzzle();
    });
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _progressAnimationController?.dispose();
    super.dispose();
  }

  void initializePuzzle() {
    puzzleTiles = List.generate(totalTiles, (index) => index + 1);

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

    // Create puzzle with empty tile in the specified position
    puzzleTiles = List.generate(totalTiles, (index) => index + 1);
    
    // Set empty tile to the specified position based on theme
    final emptyTileValue = totalTiles;
    final targetEmptyPosition = emptyTilePosition;
    
    // Move empty tile to target position
    if (puzzleTiles[targetEmptyPosition] != emptyTileValue) {
      final currentEmptyIndex = puzzleTiles.indexOf(emptyTileValue);
      final temp = puzzleTiles[currentEmptyIndex];
      puzzleTiles[currentEmptyIndex] = puzzleTiles[targetEmptyPosition];
      puzzleTiles[targetEmptyPosition] = temp;
    }
    
    final random = Random();

    // Perform random valid moves to shuffle while keeping empty tile in target position
    for (int i = 0; i < 100; i++) {
      // Find empty tile position
      final emptyIndex = puzzleTiles.indexOf(emptyTileValue);
      final row = emptyIndex ~/ gridSize;
      final col = emptyIndex % gridSize;

      // Get valid moves
      List<int> validMoves = [];

      // Check up
      if (row > 0) {
        validMoves.add(emptyIndex - gridSize);
      }
      // Check down
      if (row < gridSize - 1) {
        validMoves.add(emptyIndex + gridSize);
      }
      // Check left
      if (col > 0) {
        validMoves.add(emptyIndex - 1);
      }
      // Check right
      if (col < gridSize - 1) {
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

    final emptyIndex = puzzleTiles.indexOf(totalTiles);
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    // Check if the tile is adjacent to the empty space
    return (row == emptyRow && (col == emptyCol - 1 || col == emptyCol + 1)) ||
        (col == emptyCol && (row == emptyRow - 1 || row == emptyRow + 1));
  }

  // Handle tap movement
  void moveTile(int index) {
    if (!isValidMove(index)) return;

    final emptyIndex = puzzleTiles.indexOf(totalTiles);

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
    final fromRow = fromIndex ~/ gridSize;
    final fromCol = fromIndex % gridSize;
    final toRow = toIndex ~/ gridSize;
    final toCol = toIndex % gridSize;

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

    final emptyIndex = puzzleTiles.indexOf(totalTiles);
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    // Calculate allowed drag direction with smooth animation
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

    final emptyIndex = puzzleTiles.indexOf(totalTiles);
    final row = index ~/ gridSize;
    final col = index % gridSize;
    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

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
        // Create smooth animation for the completed move
        _animateTileMovement(index, emptyIndex);
        
        // Complete the move
        final temp = puzzleTiles[index];
        puzzleTiles[index] = puzzleTiles[emptyIndex];
        puzzleTiles[emptyIndex] = temp;

        // Increment move count
        movesCount++;

        // Check win condition
        checkWin();
      }

      // Clear all drag offsets with animation
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

    if (isSolved && puzzleTiles.last == totalTiles) {
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
          content: Text('You solved the ${widget.puzzleName} puzzle in $movesCount moves!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shufflePuzzle();
              },
              child: const Text('Play Again'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to puzzle selection
              },
              child: const Text('Back to Puzzles'),
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

    return NavLogPage(
      title: widget.puzzleName,
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
            child: _buildGameScreen(puzzleSize, isLandscape),
          ),
        ],
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
        final containerSize = constraints.maxWidth;
        final actualTileSize = containerSize / this.gridSize;

        return GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            mainAxisSpacing: 2, // Minimal spacing
            crossAxisSpacing: 2, // Minimal spacing
          ),
          itemCount: totalTiles,
          itemBuilder: (context, index) {
            final tile = puzzleTiles[index];

            // Skip empty tile - keep it simple
            if (tile == totalTiles) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
              );
            }

            // Calculate the original position of this tile (0-based)
            final originalRow = (tile - 1) ~/ this.gridSize;
            final originalCol = (tile - 1) % this.gridSize;

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
    final bool isDragging = _draggingTileIndex == index;
    
    return GestureDetector(
      onTap: () => moveTile(index),
      onPanStart: (details) => _onDragStart(index, details),
      onPanUpdate: (details) => _onDragUpdate(index, details, tileSize),
      onPanEnd: (details) => _onDragEnd(index, details),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isDragging ? Colors.blue.shade400 : Colors.black, 
            width: isDragging ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDragging 
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.black26,
              blurRadius: isDragging ? 8 : 2,
              offset: isDragging 
                  ? const Offset(0, 4)
                  : const Offset(0, 1),
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
                  width: tileSize * this.gridSize,
                  height: tileSize * this.gridSize,
                  child: Image.asset(
                    puzzleImagePath,
                    fit: BoxFit.cover,
                  ),
                ),
                // Add a subtle overlay when dragging
                if (isDragging)
                  Container(
                    color: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get pageName => widget.puzzleName;
}
