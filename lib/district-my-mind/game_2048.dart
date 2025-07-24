import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';

class Game2048 extends StatefulWidget {
  final VoidCallback onComplete;

  const Game2048({super.key, required this.onComplete});

  @override
  State<Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<Game2048> with ActivityTrackerMixin {
  List<List<int>> board = List.generate(5, (_) => List.filled(5, 0));
  bool gameOver = false;
  bool reached128 = false;

  @override
  void initState() {
    super.initState();
    _addRandomTile();
    _addRandomTile();
  }

  void _addRandomTile() {
    List<Map<String, int>> empty = [];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (board[r][c] == 0) {
          empty.add({'row': r, 'col': c});
        }
      }
    }
    if (empty.isNotEmpty) {
      var random = empty[DateTime.now().millisecondsSinceEpoch % empty.length];
      board[random['row']!][random['col']!] =
          DateTime.now().millisecondsSinceEpoch % 10 < 9 ? 2 : 4;
    }
  }

  bool _canMove() {
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (board[r][c] == 0) return true;
        if (c < 4 && board[r][c] == board[r][c + 1]) return true;
        if (r < 4 && board[r][c] == board[r + 1][c]) return true;
      }
    }
    return false;
  }

  void _move(String direction) {
    bool moved = false;

    void slideRow(int row) {
      List<int> arr = board[row].where((x) => x != 0).toList();
      for (int i = 0; i < arr.length - 1; i++) {
        if (arr[i] == arr[i + 1]) {
          arr[i] *= 2;
          arr[i + 1] = 0;
          i++;
        }
      }
      arr = arr.where((x) => x != 0).toList();
      while (arr.length < 5) {
        arr.add(0);
      }
      for (int c = 0; c < 5; c++) {
        if (board[row][c] != arr[c]) {
          moved = true;
          board[row][c] = arr[c];
        }
      }
    }

    void slideCol(int col) {
      List<int> arr =
          List.generate(5, (i) => board[i][col]).where((x) => x != 0).toList();
      for (int i = 0; i < arr.length - 1; i++) {
        if (arr[i] == arr[i + 1]) {
          arr[i] *= 2;
          arr[i + 1] = 0;
          i++;
        }
      }
      arr = arr.where((x) => x != 0).toList();
      while (arr.length < 5) {
        arr.add(0);
      }
      for (int r = 0; r < 5; r++) {
        if (board[r][col] != arr[r]) {
          moved = true;
          board[r][col] = arr[r];
        }
      }
    }

    switch (direction) {
      case 'left':
        for (int r = 0; r < 5; r++) {
          slideRow(r);
        }
        break;
      case 'right':
        for (int r = 0; r < 5; r++) {
          board[r].reversed.toList();
          slideRow(r);
          board[r].reversed.toList();
        }
        break;
      case 'up':
        for (int c = 0; c < 5; c++) {
          slideCol(c);
        }
        break;
      case 'down':
        for (int c = 0; c < 5; c++) {
          List<int> col =
              List.generate(5, (i) => board[i][c]).reversed.toList();
          for (int r = 0; r < 5; r++) {
            board[r][c] = col[r];
          }
          slideCol(c);
          col = List.generate(5, (i) => board[i][c]).reversed.toList();
          for (int r = 0; r < 5; r++) {
            board[r][c] = col[r];
          }
        }
        break;
    }

    if (moved) {
      trackClick('2048_game_move - $direction');
      _addRandomTile();
      setState(() {});
    }

    _checkGame();
  }

  void _checkGame() {
    reached128 = false;
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (board[r][c] >= 128) {
          reached128 = true;
          widget.onComplete();
          return;
        }
      }
    }

    if (!_canMove()) {
      gameOver = true;
      widget.onComplete();
    }
  }

  Color _getTileColor(int value) {
    switch (value) {
      case 2:
        return Color(0xFFBBDEFB);
      case 4:
        return Color(0xFF90CAF9);
      case 8:
        return Color(0xFF64B5F6);
      case 16:
        return Color(0xFF42A5F5);
      case 32:
        return Color(0xFF1E88E5);
      case 64:
        return Color(0xFF1565C0);
      case 128:
        return Color(0xFF43A047);
      case 256:
        return Color(0xFF388E3C);
      case 512:
        return Color(0xFFFBC02D);
      case 1024:
        return Color(0xFFF57C00);
      case 2048:
        return Color(0xFFD32F2F);
      default:
        return Color(0xFFE3F2FD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '2048 Game',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E88E5),
          ),
        ),
        Container(
          height: 6,
          width: 180,
          margin: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(
          'Use your arrow keys to combine tiles and reach 128!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF1976D2), width: 3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _move('right');
              } else if (details.primaryVelocity! < 0) {
                _move('left');
              }
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _move('down');
              } else if (details.primaryVelocity! < 0) {
                _move('up');
              }
            },
            child: GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
              ),
              itemCount: 25,
              itemBuilder: (context, index) {
                int row = index ~/ 5;
                int col = index % 5;
                int value = board[row][col];

                return Container(
                  decoration: BoxDecoration(
                    color: _getTileColor(value),
                    border: Border.all(
                      color: Color(0xFF90CAF9),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      value == 0 ? '' : value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: value >= 8 ? Colors.white : Color(0xFF1976D2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (gameOver)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Game Over! Try again or continue.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (reached128)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '🎉 You reached 128!',
              style: TextStyle(
                fontSize: 18,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            widget.onComplete();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2196F3),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: Color(0xFF2196F3).withOpacity(0.4),
          ),
          child: SizedBox(
            width: 200,
            child: Text(
              'Next',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
