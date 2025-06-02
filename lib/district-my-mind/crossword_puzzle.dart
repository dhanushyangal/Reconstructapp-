import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrosswordPuzzleGame extends StatefulWidget {
  const CrosswordPuzzleGame({Key? key}) : super(key: key);

  @override
  State<CrosswordPuzzleGame> createState() => _CrosswordPuzzleGameState();
}

class _CrosswordPuzzleGameState extends State<CrosswordPuzzleGame> {
  final List<List<String>> _grid = [
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
  ];

  final List<Map<String, dynamic>> _clues = [
    {
      'number': 1,
      'direction': 'across',
      'clue': 'A feeling of joy and contentment',
      'answer': 'HAPPY',
      'startRow': 0,
      'startCol': 0,
    },
    {
      'number': 2,
      'direction': 'down',
      'clue': 'A facial expression showing pleasure',
      'answer': 'SMILE',
      'startRow': 0,
      'startCol': 2,
    },
    {
      'number': 3,
      'direction': 'across',
      'clue': 'A state of tranquility and harmony',
      'answer': 'PEACE',
      'startRow': 2,
      'startCol': 0,
    },
  ];

  int _selectedRow = -1;
  int _selectedCol = -1;
  int _score = 0;
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
    _initializeGrid();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('crossword_score') ?? 0;
    });
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crossword_score', _score);
  }

  void _initializeGrid() {
    for (var clue in _clues) {
      final answer = clue['answer'] as String;
      final startRow = clue['startRow'] as int;
      final startCol = clue['startCol'] as int;
      final direction = clue['direction'] as String;

      for (var i = 0; i < answer.length; i++) {
        if (direction == 'across') {
          _grid[startRow][startCol + i] = '';
        } else {
          _grid[startRow + i][startCol] = '';
        }
      }
    }
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                Text(
                  'Clues: ${_clues.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Crossword Grid
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
                  crossAxisCount: 9,
                ),
                itemCount: 81,
                itemBuilder: (context, index) {
                  final row = index ~/ 9;
                  final col = index % 9;
                  final isSelected = row == _selectedRow && col == _selectedCol;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRow = row;
                        _selectedCol = col;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(0xFF1E88E5).withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 0.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _grid[row][col],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: 24),

          // Clues List
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _clues.length,
              itemBuilder: (context, index) {
                final clue = _clues[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${clue['number']}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${clue['direction'].toUpperCase()}: ${clue['clue']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (_showHints) ...[
                              SizedBox(height: 4),
                              Text(
                                'Answer: ${clue['answer']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showHints = !_showHints;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_showHints ? 'Hide Hints' : 'Show Hints'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checkSolution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Check Solution'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkSolution() {
    bool isComplete = true;
    for (var clue in _clues) {
      final answer = clue['answer'] as String;
      final startRow = clue['startRow'] as int;
      final startCol = clue['startCol'] as int;
      final direction = clue['direction'] as String;

      for (var i = 0; i < answer.length; i++) {
        String cellValue;
        if (direction == 'across') {
          cellValue = _grid[startRow][startCol + i];
        } else {
          cellValue = _grid[startRow + i][startCol];
        }

        if (cellValue != answer[i]) {
          isComplete = false;
          break;
        }
      }
    }

    if (isComplete) {
      setState(() {
        _score += 50;
      });
      _saveScore();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Congratulations! +50 points'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not quite right. Keep trying!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
