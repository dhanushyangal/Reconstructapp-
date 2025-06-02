import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_2048.dart';
import 'prime_finder.dart';

class NumberGames extends StatefulWidget {
  const NumberGames({Key? key}) : super(key: key);

  @override
  State<NumberGames> createState() => _NumberGamesState();
}

class _NumberGamesState extends State<NumberGames> {
  int _currentGame = 0; // 0: Sudoku, 1: 2048, 2: Prime Finder
  final PageController _pageController = PageController();
  int _sudokuProgress = 0;
  int _game2048Progress = 0;
  int _primeFinderProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sudokuProgress = prefs.getInt('sudoku_progress') ?? 0;
      _game2048Progress = prefs.getInt('game_2048_progress') ?? 0;
      _primeFinderProgress = prefs.getInt('prime_finder_progress') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('sudoku_progress', _sudokuProgress);
    await prefs.setInt('game_2048_progress', _game2048Progress);
    await prefs.setInt('prime_finder_progress', _primeFinderProgress);
    Navigator.pop(context,
        (_sudokuProgress + _game2048Progress + _primeFinderProgress) ~/ 3);
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
                      onPressed: () => _saveProgress(),
                    ),
                    Expanded(
                      child: Text(
                        'Number Games',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // For balance
                  ],
                ),
              ),

              // Game Selection Tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildGameTab('Sudoku', 0, _sudokuProgress),
                    ),
                    Expanded(
                      child: _buildGameTab('2048', 1, _game2048Progress),
                    ),
                    Expanded(
                      child: _buildGameTab(
                          'Prime Finder', 2, _primeFinderProgress),
                    ),
                  ],
                ),
              ),

              // Game Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentGame = index;
                    });
                  },
                  children: [
                    SudokuGame(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _sudokuProgress = progress;
                        });
                        _saveProgress();
                      },
                    ),
                    Game2048(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _game2048Progress = progress;
                        });
                        _saveProgress();
                      },
                    ),
                    PrimeFinderGame(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _primeFinderProgress = progress;
                        });
                        _saveProgress();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameTab(String title, int index, int progress) {
    final isSelected = _currentGame == index;
    return InkWell(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSelected ? Colors.white : Color(0xFF1E88E5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SudokuGame extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const SudokuGame({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> {
  List<List<int>> _board = List.generate(
    9,
    (_) => List.generate(9, (_) => 0),
  );
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _generateNewGame();
  }

  void _generateNewGame() {
    // TODO: Implement Sudoku game generation
    setState(() {
      _board = List.generate(
        9,
        (_) => List.generate(9, (_) => 0),
      );
      _progress = 0;
      widget.onProgressUpdate(_progress);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Game Board
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 9,
                  mainAxisSpacing: 1,
                  crossAxisSpacing: 1,
                ),
                itemCount: 81,
                itemBuilder: (context, index) {
                  final row = index ~/ 9;
                  final col = index % 9;
                  return Container(
                    decoration: BoxDecoration(
                      color: _getCellColor(row, col),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _board[row][col] == 0
                            ? ''
                            : _board[row][col].toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 24),

          // Number Pad
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    9,
                    (index) => _buildNumberButton(index + 1),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _generateNewGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E88E5),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('New Game'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement check solution
                          setState(() {
                            _progress = 50; // Example progress
                            widget.onProgressUpdate(_progress);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Check'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement number selection
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Color(0xFF1E88E5),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),
        ),
      ),
    );
  }

  Color _getCellColor(int row, int col) {
    final boxRow = row ~/ 3;
    final boxCol = col ~/ 3;
    return (boxRow + boxCol) % 2 == 0 ? Colors.white : Colors.grey[50]!;
  }
}

class Game2048 extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const Game2048({Key? key, required this.onProgressUpdate}) : super(key: key);

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> {
  List<List<int>> _board = List.generate(5, (_) => List.generate(5, (_) => 0));
  int _score = 0;
  int _progress = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _addNewTile();
    _addNewTile();
  }

  void _addNewTile() {
    List<Offset> emptyTiles = [];
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_board[i][j] == 0) {
          emptyTiles.add(Offset(i.toDouble(), j.toDouble()));
        }
      }
    }
    if (emptyTiles.isNotEmpty) {
      final random =
          emptyTiles[DateTime.now().millisecondsSinceEpoch % emptyTiles.length];
      _board[random.dx.toInt()][random.dy.toInt()] = 2;
    }
  }

  void _moveLeft() {
    bool moved = false;
    for (int i = 0; i < 5; i++) {
      List<int> row = _board[i].where((cell) => cell != 0).toList();
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
      if (row.toString() != _board[i].toString()) {
        moved = true;
      }
      _board[i] = row;
    }
    if (moved) {
      _addNewTile();
      _checkGameOver();
      _updateProgress();
    }
  }

  void _moveRight() {
    bool moved = false;
    for (int i = 0; i < 5; i++) {
      List<int> row = _board[i].where((cell) => cell != 0).toList();
      for (int j = row.length - 1; j > 0; j--) {
        if (row[j] == row[j - 1]) {
          row[j] *= 2;
          _score += row[j];
          row.removeAt(j - 1);
          row.insert(0, 0);
          moved = true;
        }
      }
      while (row.length < 5) {
        row.insert(0, 0);
      }
      if (row.toString() != _board[i].toString()) {
        moved = true;
      }
      _board[i] = row;
    }
    if (moved) {
      _addNewTile();
      _checkGameOver();
      _updateProgress();
    }
  }

  void _moveUp() {
    bool moved = false;
    for (int j = 0; j < 5; j++) {
      List<int> column = [];
      for (int i = 0; i < 5; i++) {
        if (_board[i][j] != 0) {
          column.add(_board[i][j]);
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
        if (_board[i][j] != column[i]) {
          moved = true;
        }
        _board[i][j] = column[i];
      }
    }
    if (moved) {
      _addNewTile();
      _checkGameOver();
      _updateProgress();
    }
  }

  void _moveDown() {
    bool moved = false;
    for (int j = 0; j < 5; j++) {
      List<int> column = [];
      for (int i = 0; i < 5; i++) {
        if (_board[i][j] != 0) {
          column.add(_board[i][j]);
        }
      }
      for (int i = column.length - 1; i > 0; i--) {
        if (column[i] == column[i - 1]) {
          column[i] *= 2;
          _score += column[i];
          column.removeAt(i - 1);
          column.insert(0, 0);
          moved = true;
        }
      }
      while (column.length < 5) {
        column.insert(0, 0);
      }
      for (int i = 0; i < 5; i++) {
        if (_board[i][j] != column[i]) {
          moved = true;
        }
        _board[i][j] = column[i];
      }
    }
    if (moved) {
      _addNewTile();
      _checkGameOver();
      _updateProgress();
    }
  }

  void _checkGameOver() {
    bool hasEmpty = false;
    bool hasMove = false;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_board[i][j] == 0) {
          hasEmpty = true;
        }
        if (j < 4 && _board[i][j] == _board[i][j + 1]) {
          hasMove = true;
        }
        if (i < 4 && _board[i][j] == _board[i + 1][j]) {
          hasMove = true;
        }
      }
    }
    if (!hasEmpty && !hasMove) {
      setState(() {
        _gameOver = true;
      });
    }
  }

  void _updateProgress() {
    int maxTile = 0;
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 5; j++) {
        if (_board[i][j] > maxTile) {
          maxTile = _board[i][j];
        }
      }
    }
    final newProgress = (maxTile * 100 / 128).clamp(0, 100).toInt();
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
      });
      widget.onProgressUpdate(_progress);
    }
  }

  void _resetGame() {
    setState(() {
      _board = List.generate(5, (_) => List.generate(5, (_) => 0));
      _score = 0;
      _progress = 0;
      _gameOver = false;
      widget.onProgressUpdate(_progress);
    });
    _addNewTile();
    _addNewTile();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Score and Progress
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

          // Game Board
          Expanded(
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _moveDown();
                } else {
                  _moveUp();
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  _moveRight();
                } else {
                  _moveLeft();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: 25,
                  itemBuilder: (context, index) {
                    final row = index ~/ 5;
                    final col = index % 5;
                    final value = _board[row][col];
                    return Container(
                      decoration: BoxDecoration(
                        color: _getTileColor(value),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          value == 0 ? '' : value.toString(),
                          style: TextStyle(
                            fontSize: value > 1000 ? 20 : 24,
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
          ),

          if (_gameOver)
            Container(
              margin: EdgeInsets.only(top: 24),
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
      ),
    );
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 0:
        return Colors.grey[300]!;
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

class PrimeFinderGame extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const PrimeFinderGame({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<PrimeFinderGame> createState() => _PrimeFinderGameState();
}

class _PrimeFinderGameState extends State<PrimeFinderGame> {
  int _currentNumber = 2;
  int _score = 0;
  int _progress = 0;
  bool _isPrime = false;

  @override
  void initState() {
    super.initState();
    _generateNewNumber();
  }

  void _generateNewNumber() {
    setState(() {
      _currentNumber = 2 + (DateTime.now().millisecondsSinceEpoch % 98);
      _isPrime = _checkPrime(_currentNumber);
    });
  }

  bool _checkPrime(int number) {
    if (number < 2) return false;
    for (int i = 2; i <= number ~/ 2; i++) {
      if (number % i == 0) return false;
    }
    return true;
  }

  void _checkAnswer(bool userAnswer) {
    if (userAnswer == _isPrime) {
      setState(() {
        _score += 10;
        _progress = (_score * 100 / 100).clamp(0, 100).toInt();
        widget.onProgressUpdate(_progress);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Correct! +10 points'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wrong! Try again'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _generateNewNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                Text(
                  'Progress: $_progress%',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Number Display
          Container(
            padding: EdgeInsets.all(32),
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
            child: Text(
              _currentNumber.toString(),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
            ),
          ),

          SizedBox(height: 32),

          // Question
          Text(
            'Is this number prime?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
          ),

          SizedBox(height: 32),

          // Answer Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Yes',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _checkAnswer(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
