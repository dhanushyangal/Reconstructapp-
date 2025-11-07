import 'package:flutter/material.dart';
import 'dart:math';
import '../components/nav_logpage.dart';
import '../utils/activity_tracker_mixin.dart';
import '../services/tool_usage_service.dart';
import 'puzzle_success_page.dart';

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
  bool _hasTrackedUsage = false; // Track if we've recorded usage for this session

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

  // Get empty tile position based on theme
  int get emptyTilePosition {
    switch (widget.puzzleTheme) {
      case 'dog':
        return 2; // Position 3 (0-based index 2)
      case 'fox':
        return 0; // Position 1 (0-based index 0)
      case 'lion':
        return 0; // Position 1 (0-based index 0)
      case 'owl':
        return 15; // Position 16 (0-based index 0)
      default:
        return totalTiles - 1; // Last position (normal)
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

    // Create puzzle in solved state: [1, 2, 3, 4, 5, 6, 7, 8, 9] for 3x3
    puzzleTiles = List.generate(totalTiles, (index) => index + 1);
    
    // Move empty tile to its designated position for this theme
    final emptyTileValue = totalTiles;
    final targetEmptyPos = emptyTilePosition;
    
    if (targetEmptyPos != totalTiles - 1) {
      // Swap the tile at target position with the last tile (empty)
      final lastIndex = totalTiles - 1;
      final temp = puzzleTiles[targetEmptyPos];
      puzzleTiles[targetEmptyPos] = puzzleTiles[lastIndex];
      puzzleTiles[lastIndex] = temp;
    }
    
    final random = Random();

    // Perform random valid moves to shuffle - SUPER EASY difficulty
    // More moves = harder puzzle, fewer moves = easier puzzle
    final shuffleMoves = gridSize == 3 ? 10 : 15; // SUPER EASY: 3x3 gets 10 moves, 4x4 gets 15 moves
    
    int? lastMoveIndex;
    for (int i = 0; i < shuffleMoves; i++) {
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

      // Remove the last move to prevent immediate reversal (makes puzzle harder)
      if (lastMoveIndex != null && validMoves.contains(lastMoveIndex)) {
        validMoves.remove(lastMoveIndex);
      }

      // Select random valid move
      final moveIndex = validMoves.isNotEmpty 
          ? validMoves[random.nextInt(validMoves.length)]
          : emptyIndex;

      // Swap
      final temp = puzzleTiles[emptyIndex];
      puzzleTiles[emptyIndex] = puzzleTiles[moveIndex];
      puzzleTiles[moveIndex] = temp;
      
      // Remember this move to prevent reversal
      lastMoveIndex = emptyIndex;
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
    const double threshold = 0.3; // Lower threshold for easier sliding

    if (row == emptyRow) {
      // Horizontal movement
      if ((emptyCol > col && _dragOffset.dx > threshold) ||
          (emptyCol < col && _dragOffset.dx < -threshold)) {
        completedMove = true;
      }
    } else if (col == emptyCol) {
      // Vertical movement
      if ((emptyRow > row && _dragOffset.dy > threshold) ||
          (emptyRow < row && _dragOffset.dy < -threshold)) {
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

  // Handle empty tile drag start
  void _onEmptyTileDragStart(int emptyIndex, DragStartDetails details) {
    if (!gameStarted || gameComplete) return;
    
    setState(() {
      _dragOffset = Offset.zero;
    });
  }

  // Handle empty tile drag update
  void _onEmptyTileDragUpdate(int emptyIndex, DragUpdateDetails details, double tileSize) {
    if (!gameStarted || gameComplete) return;

    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;

    // Accumulate drag offset
    _dragOffset += Offset(details.delta.dx / tileSize, details.delta.dy / tileSize);

    // Determine which direction is being dragged and update adjacent tile
    setState(() {
      // Clear previous offsets
      _tileOffsets.clear();
      
      // Determine the dominant direction
      if (_dragOffset.dy.abs() > _dragOffset.dx.abs()) {
        // Vertical drag
        if (_dragOffset.dy < 0 && emptyRow > 0) {
          // Dragging up, move tile from above down
          final tileIndex = emptyIndex - gridSize;
          final offset = (-_dragOffset.dy).clamp(0.0, 1.0);
          _tileOffsets[tileIndex] = Offset(0, offset);
        } else if (_dragOffset.dy > 0 && emptyRow < gridSize - 1) {
          // Dragging down, move tile from below up
          final tileIndex = emptyIndex + gridSize;
          final offset = (-_dragOffset.dy).clamp(-1.0, 0.0);
          _tileOffsets[tileIndex] = Offset(0, offset);
        }
      } else {
        // Horizontal drag
        if (_dragOffset.dx < 0 && emptyCol > 0) {
          // Dragging left, move tile from left right
          final tileIndex = emptyIndex - 1;
          final offset = (-_dragOffset.dx).clamp(0.0, 1.0);
          _tileOffsets[tileIndex] = Offset(offset, 0);
        } else if (_dragOffset.dx > 0 && emptyCol < gridSize - 1) {
          // Dragging right, move tile from right left
          final tileIndex = emptyIndex + 1;
          final offset = (-_dragOffset.dx).clamp(-1.0, 0.0);
          _tileOffsets[tileIndex] = Offset(offset, 0);
        }
      }
    });
  }

  // Handle empty tile drag end
  void _onEmptyTileDragEnd(int emptyIndex, DragEndDetails details) {
    if (!gameStarted || gameComplete) return;

    final emptyRow = emptyIndex ~/ gridSize;
    final emptyCol = emptyIndex % gridSize;
    
    const double threshold = 0.3;
    int? tileToMove;

    // Determine which tile should move based on drag offset
    if (_dragOffset.dy.abs() > _dragOffset.dx.abs()) {
      // Vertical movement is dominant
      if (_dragOffset.dy < -threshold && emptyRow > 0) {
        // Dragged up, move tile from above down
        tileToMove = emptyIndex - gridSize;
      } else if (_dragOffset.dy > threshold && emptyRow < gridSize - 1) {
        // Dragged down, move tile from below up
        tileToMove = emptyIndex + gridSize;
      }
    } else {
      // Horizontal movement is dominant
      if (_dragOffset.dx < -threshold && emptyCol > 0) {
        // Dragged left, move tile from left right
        tileToMove = emptyIndex - 1;
      } else if (_dragOffset.dx > threshold && emptyCol < gridSize - 1) {
        // Dragged right, move tile from right left
        tileToMove = emptyIndex + 1;
      }
    }

    setState(() {
      if (tileToMove != null) {
        // Create smooth animation for the move
        _animateTileMovement(tileToMove, emptyIndex);
        
        // Complete the move
        final temp = puzzleTiles[tileToMove];
        puzzleTiles[tileToMove] = puzzleTiles[emptyIndex];
        puzzleTiles[emptyIndex] = temp;

        // Increment move count
        movesCount++;

        // Check win condition
        checkWin();
      }

      // Clear all drag offsets
      _dragOffset = Offset.zero;
      _tileOffsets.clear();
    });
  }

  void checkWin() {
    // Build the expected solved state for this puzzle theme
    List<int> solvedState = List.generate(totalTiles, (index) => index + 1);
    
    // Move empty tile to its designated position in the solved state
    final targetEmptyPos = emptyTilePosition;
    if (targetEmptyPos != totalTiles - 1) {
      final lastIndex = totalTiles - 1;
      final temp = solvedState[targetEmptyPos];
      solvedState[targetEmptyPos] = solvedState[lastIndex];
      solvedState[lastIndex] = temp;
    }
    
    // Compare current state with solved state
    bool isSolved = true;
    for (int i = 0; i < puzzleTiles.length; i++) {
      if (puzzleTiles[i] != solvedState[i]) {
        isSolved = false;
        break;
      }
    }

    if (isSolved) {
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
              onPressed: () async {
                Navigator.of(context).pop();
                // Save tool usage when clicking Next in win dialog
                await _saveToolUsage();
                _navigateToSuccessPage();
              },
              child: const Text('Next'),
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
      // Using default navigation handler from NavLogPage
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
        border: Border.all(color: Color(0xFFFAFAFA), width: 2),
        color: Color(0xFFFAFAFA),
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

            // Empty tile - draggable
            if (tile == totalTiles) {
              return GestureDetector(
                onPanStart: (details) => _onEmptyTileDragStart(index, details),
                onPanUpdate: (details) => _onEmptyTileDragUpdate(index, details, actualTileSize),
                onPanEnd: (details) => _onEmptyTileDragEnd(index, details),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade50,
                        Colors.grey.shade100,
                      ],
                    ),
                  border: Border.all(
                    color: Color(0xFFFAFAFA),
                    width: 1.5,
                  ),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.crop_square,
                      size: actualTileSize * 0.3,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }

            // Calculate the original position of this tile in the IMAGE grid (0-based)
            // The image is always a complete grid (0-8 for 3x3, 0-15 for 4x4)
            // We need to determine which part of the complete image this tile should show
            
            // Build the solved state to find where this tile belongs
            List<int> solvedState = List.generate(totalTiles, (index) => index + 1);
            final targetEmptyPos = emptyTilePosition;
            if (targetEmptyPos != totalTiles - 1) {
              final lastIndex = totalTiles - 1;
              final temp = solvedState[targetEmptyPos];
              solvedState[targetEmptyPos] = solvedState[lastIndex];
              solvedState[lastIndex] = temp;
            }
            
            // Find where this tile number appears in the solved state
            final tilePositionInSolved = solvedState.indexOf(tile);
            
            // This position in the solved state corresponds to this position in the image
            final originalRow = tilePositionInSolved ~/ this.gridSize;
            final originalCol = tilePositionInSolved % this.gridSize;

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
              onPressed: () async {
                // Always save tool usage when clicking Next, even if puzzle not solved
                await _saveToolUsage();
                _navigateToSuccessPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            color: isDragging ? Colors.blue.shade400 : Color(0xFFFAFAFA), 
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

  void _navigateToSuccessPage() {
    // Track the activity
    trackClick('sliding_puzzle_next');
    
    // Navigate to puzzle success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PuzzleSuccessPage(),
      ),
    );
  }

  // Save tool usage
  Future<void> _saveToolUsage() async {
    // Only track once per session to avoid duplicates
    if (_hasTrackedUsage) return;
    
    _hasTrackedUsage = true;
    final toolUsageService = ToolUsageService();
    // puzzleName already contains "Puzzle" (e.g., "Fox Sliding Puzzle"), so use it directly
    await toolUsageService.saveToolUsage(
      toolName: widget.puzzleName.trim(), // Trim any trailing spaces
      category: ToolUsageService.categoryClearMind,
      metadata: {
        'toolType': 'sliding_puzzle',
        'puzzleTheme': widget.puzzleTheme,
        'puzzleName': widget.puzzleName,
        'moves': movesCount,
        'completed': gameComplete,
      },
    );
  }

  String get pageName => widget.puzzleName;
}
