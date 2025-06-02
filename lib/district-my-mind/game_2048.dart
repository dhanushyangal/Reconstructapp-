import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Game2048 extends StatefulWidget {
  const Game2048({Key? key}) : super(key: key);

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  List<List<int>> _grid = List.generate(
    5,
    (_) => List.generate(5, (_) => 0),
  );
  int _score = 0;
  bool _gameOver = false;
  bool _showSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
    _startNewGame();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('game_2048_score') ?? 0;
    });
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game_2048_score', _score);
  }

  void _startNewGame() {
    setState(() {
      _grid = List.generate(
        5,
        (_) => List.generate(5, (_) => 0),
      );
      _gameOver = false;
      _showSuccessMessage = false;
      _addNewNumber();
      _addNewNumber();
    });
  }

  void _addNewNumber() {
    List<Point> emptyCells = [];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_grid[i][j] == 0) {
          emptyCells.add(Point(i, j));
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      final randomCell =
          emptyCells[DateTime.now().millisecondsSinceEpoch % emptyCells.length];
      _grid[randomCell.x][randomCell.y] =
          DateTime.now().millisecondsSinceEpoch % 10 < 9 ? 2 : 4;
    }
  }

  void _moveLeft() {
    bool moved = false;
    for (int i = 0; i < 5; i++) {
      List<int> row = _grid[i].where((cell) => cell != 0).toList();
      for (int j = 0; j < row.length - 1; j++) {
        if (row[j] == row[j + 1]) {
          row[j] *= 2;
          _score += row[j];
          row.removeAt(j + 1);
          moved = true;
        }
      }
      while (row.length < 5) {
        row.add(0);
      }
      if (row.toString() != _grid[i].toString()) {
        moved = true;
      }
      _grid[i] = row;
    }
    if (moved) {
      _addNewNumber();
      _checkGameOver();
    }
  }

  void _moveRight() {
    bool moved = false;
    for (int i = 0; i < 5; i++) {
      List<int> row = _grid[i].where((cell) => cell != 0).toList();
      for (int j = row.length - 1; j > 0; j--) {
        if (row[j] == row[j - 1]) {
          row[j] *= 2;
          _score += row[j];
          row.removeAt(j - 1);
          moved = true;
        }
      }
      while (row.length < 5) {
        row.insert(0, 0);
      }
      if (row.toString() != _grid[i].toString()) {
        moved = true;
      }
      _grid[i] = row;
    }
    if (moved) {
      _addNewNumber();
      _checkGameOver();
    }
  }

  void _moveUp() {
    bool moved = false;
    for (int j = 0; j < 5; j++) {
      List<int> column = [];
      for (int i = 0; i < 5; i++) {
        if (_grid[i][j] != 0) {
          column.add(_grid[i][j]);
        }
      }
      for (int i = 0; i < column.length - 1; i++) {
        if (column[i] == column[i + 1]) {
          column[i] *= 2;
          _score += column[i];
          column.removeAt(i + 1);
          moved = true;
        }
      }
      while (column.length < 5) {
        column.add(0);
      }
      for (int i = 0; i < 5; i++) {
        if (_grid[i][j] != column[i]) {
          moved = true;
        }
        _grid[i][j] = column[i];
      }
    }
    if (moved) {
      _addNewNumber();
      _checkGameOver();
    }
  }

  void _moveDown() {
    bool moved = false;
    for (int j = 0; j < 5; j++) {
      List<int> column = [];
      for (int i = 0; i < 5; i++) {
        if (_grid[i][j] != 0) {
          column.add(_grid[i][j]);
        }
      }
      for (int i = column.length - 1; i > 0; i--) {
        if (column[i] == column[i - 1]) {
          column[i] *= 2;
          _score += column[i];
          column.removeAt(i - 1);
          moved = true;
        }
      }
      while (column.length < 5) {
        column.insert(0, 0);
      }
      for (int i = 0; i < 5; i++) {
        if (_grid[i][j] != column[i]) {
          moved = true;
        }
        _grid[i][j] = column[i];
      }
    }
    if (moved) {
      _addNewNumber();
      _checkGameOver();
    }
  }

  void _checkGameOver() {
    bool hasEmptyCell = false;
    bool hasPossibleMove = false;
    bool reached128 = false;

    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_grid[i][j] == 0) {
          hasEmptyCell = true;
        }
        if (_grid[i][j] >= 128) {
          reached128 = true;
        }
        if (j < 4 && _grid[i][j] == _grid[i][j + 1]) {
          hasPossibleMove = true;
        }
        if (i < 4 && _grid[i][j] == _grid[i + 1][j]) {
          hasPossibleMove = true;
        }
      }
    }

    if (reached128) {
      setState(() {
        _showSuccessMessage = true;
      });
      _saveScore();
    } else if (!hasEmptyCell && !hasPossibleMove) {
      setState(() {
        _gameOver = true;
      });
      _saveScore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Score Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: $_score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _startNewGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E88E5),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('New Game'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Game Grid
              Expanded(
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
                  child: GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 25,
                    itemBuilder: (context, index) {
                      final row = index ~/ 5;
                      final col = index % 5;
                      final value = _grid[row][col];

                      return Container(
                        decoration: BoxDecoration(
                          color: _getTileColor(value),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            value == 0 ? '' : value.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color:
                                  value <= 4 ? Color(0xFF776E65) : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              if (_gameOver) ...[
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Game Over!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              SizedBox(height: 24),

              // Game Instructions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Swipe to move tiles. Combine tiles with the same number to create a tile with the sum of the two tiles.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Success Message Modal
        if (_showSuccessMessage)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                margin: EdgeInsets.all(32),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉',
                      style: TextStyle(fontSize: 48),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Congratulations!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You\'ve successfully completed the 2048 game.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _showSuccessMessage = false;
                              _startNewGame();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E88E5),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Play Again'),
                        ),
                        SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Navigate to next game
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Continue'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0:
        return Color(0xFFCDC1B4);
      case 2:
        return Color(0xFFEEE4DA);
      case 4:
        return Color(0xFFEDE0C8);
      case 8:
        return Color(0xFFF2B179);
      case 16:
        return Color(0xFFF59563);
      case 32:
        return Color(0xFFF67C5F);
      case 64:
        return Color(0xFFF65E3B);
      case 128:
        return Color(0xFFEDCF72);
      case 256:
        return Color(0xFFEDCC61);
      case 512:
        return Color(0xFFEDC850);
      case 1024:
        return Color(0xFFEDC53F);
      case 2048:
        return Color(0xFFEDC22E);
      default:
        return Color(0xFF3C3A32);
    }
  }
}

class Point {
  final int x;
  final int y;

  Point(this.x, this.y);
}
