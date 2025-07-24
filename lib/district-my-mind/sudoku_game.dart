import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';

class SudokuGame extends StatefulWidget {
  final VoidCallback onComplete;

  const SudokuGame({super.key, required this.onComplete});

  @override
  State<SudokuGame> createState() => _SudokuGameState();
}

class _SudokuGameState extends State<SudokuGame> with ActivityTrackerMixin {
  final List<List<int>> puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
  ];

  final List<List<int>> solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9]
  ];

  List<List<TextEditingController>> controllers = List.generate(
    9,
    (_) => List.generate(9, (_) => TextEditingController()),
  );

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (puzzle[i][j] != 0) {
          controllers[i][j].text = puzzle[i][j].toString();
        }
      }
    }
  }

  void _checkSolution() {
    trackClick('sudoku_check_solution');

    bool isCorrect = true;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        int? value = int.tryParse(controllers[i][j].text);
        if (value != solution[i][j]) {
          isCorrect = false;
          break;
        }
      }
      if (!isCorrect) break;
    }

    if (isCorrect) {
      trackClick('sudoku_completed');
      widget.onComplete();
    } else {
      trackClick('sudoku_incorrect_solution');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Some cells are incorrect. Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _giveHint() {
    trackClick('sudoku_hint_used');

    List<Map<String, int>> emptyCells = [];
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (controllers[i][j].text.isEmpty) {
          emptyCells.add({'row': i, 'col': j});
        }
      }
    }

    if (emptyCells.isNotEmpty) {
      var randomCell =
          emptyCells[DateTime.now().millisecondsSinceEpoch % emptyCells.length];
      controllers[randomCell['row']!][randomCell['col']!].text =
          solution[randomCell['row']!][randomCell['col']!].toString();
    }
  }

  void _resetGame() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (puzzle[i][j] == 0) {
          controllers[i][j].text = '';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sudoku Challenge',
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
          'Fill in the grid so that every row, column, and 3×3 box contains the digits 1 through 9.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF1976D2), width: 4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
              childAspectRatio: 1,
            ),
            itemCount: 81,
            itemBuilder: (context, index) {
              int row = index ~/ 9;
              int col = index % 9;
              bool isBoxRight = (col + 1) % 3 == 0 && col != 8;
              bool isBoxBottom = (row + 1) % 3 == 0 && row != 8;

              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: isBoxRight ? Color(0xFF1976D2) : Color(0xFF90CAF9),
                      width: isBoxRight ? 3 : 1,
                    ),
                    bottom: BorderSide(
                      color:
                          isBoxBottom ? Color(0xFF1976D2) : Color(0xFF90CAF9),
                      width: isBoxBottom ? 3 : 1,
                    ),
                  ),
                  color:
                      puzzle[row][col] != 0 ? Color(0xFFE3F2FD) : Colors.white,
                ),
                child: TextField(
                  controller: controllers[row][col],
                  enabled: puzzle[row][col] == 0,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: puzzle[row][col] != 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: puzzle[row][col] != 0
                        ? Color(0xFF1976D2)
                        : Colors.black,
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _giveHint,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Hint'),
            ),
            ElevatedButton(
              onPressed: _resetGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Reset'),
            ),
            ElevatedButton(
              onPressed: _checkSolution,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Check'),
            ),
            ElevatedButton(
              onPressed: widget.onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Skip'),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }
}
