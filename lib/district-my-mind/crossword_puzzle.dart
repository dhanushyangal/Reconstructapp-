import 'package:flutter/material.dart';

class CrosswordPuzzle extends StatefulWidget {
  final VoidCallback onComplete;

  const CrosswordPuzzle({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CrosswordPuzzle> createState() => _CrosswordPuzzleState();
}

class _CrosswordPuzzleState extends State<CrosswordPuzzle> {
  final List<List<String>> grid = [
    ['1', '2', '3', '4', '5', 'x', '6', '7', '8', 'x'],
    ['9', '.', '.', '.', '.', '.', '.', '.', '.', 'x'],
    ['10', '.', '.', '.', '.', 'x', '11', '.', '.', '12'],
    ['13', '.', '.', '.', '.', 'x', '.', '.', '.', '.'],
    ['14', '.', '.', '.', '.', '15', '.', '.', '.', '.'],
    ['x', 'x', 'x', '16', '.', '.', '.', '.', 'x', 'x'],
    ['17', '18', '19', '.', '.', '.', '.', 'x', '20', '21'],
    ['22', '.', '.', '.', 'x', '23', '.', '.', '.', '.'],
    ['24', '.', '.', '.', '25', '.', '.', '.', '.', '.'],
    ['x', '26', '.', '.', '.', '.', '.', '.', '.', 'x']
  ];

  final Map<String, List<Map<String, dynamic>>> words = {
    'across': [
      {
        'number': 1,
        'clue': "Problem solving state of mind",
        'answer': "PUZZLE",
        'hint': "A game or toy that tests ingenuity or knowledge"
      },
      {
        'number': 9,
        'clue': "The organ responsible for thinking",
        'answer': "BRAIN",
        'hint': "The organ inside your head that controls your body"
      },
      {
        'number': 10,
        'clue': "Ability to pay attention",
        'answer': "FOCUS",
        'hint': "The center of interest or activity"
      },
      {
        'number': 13,
        'clue': "To acquire knowledge",
        'answer': "LEARN",
        'hint': "To gain knowledge or skill by studying or experience"
      },
      {
        'number': 14,
        'clue': "Your thoughts and consciousness",
        'answer': "MIND",
        'hint': "The element of a person that enables them to be aware"
      },
      {
        'number': 16,
        'clue': "Process of reasoning",
        'answer': "LOGIC",
        'hint': "Reasoning conducted according to strict principles"
      },
      {
        'number': 17,
        'clue': "Ability to recall information",
        'answer': "MEMORY",
        'hint': "The faculty by which the mind stores information"
      },
      {
        'number': 22,
        'clue': "To examine in detail",
        'answer': "ANALYZE",
        'hint': "To examine methodically and in detail"
      },
      {
        'number': 24,
        'clue': "To make something new",
        'answer': "CREATE",
        'hint': "To bring something into existence"
      },
      {
        'number': 26,
        'clue': "To grasp the meaning of something",
        'answer': "COMPREHEND",
        'hint': "To understand something fully"
      }
    ],
    'down': [
      {
        'number': 1,
        'clue': "Mental game or challenge",
        'answer': "PROBLEM",
        'hint': "A matter or situation regarded as unwelcome or harmful"
      },
      {
        'number': 2,
        'clue': "Thinking that combines ideas",
        'answer': "REASON",
        'hint': "The power of the mind to think and form judgments"
      },
      {
        'number': 3,
        'clue': "State of mental calm",
        'answer': "RELAX",
        'hint': "To become less tense or anxious"
      },
      {
        'number': 4,
        'clue': "To shift attention away",
        'answer': "DISTRACT",
        'hint': "To prevent someone from giving full attention to something"
      },
      {
        'number': 5,
        'clue': "Ability to do something well",
        'answer': "SKILL",
        'hint': "The ability to do something well"
      },
      {
        'number': 6,
        'clue': "To make better",
        'answer': "IMPROVE",
        'hint': "To make or become better"
      },
      {
        'number': 7,
        'clue': "To find an answer",
        'answer': "SOLVE",
        'hint': "To find an answer to a problem"
      },
      {
        'number': 8,
        'clue': "Coming up with new ideas",
        'answer': "IMAGINE",
        'hint': "To form a mental image or concept of something"
      },
      {
        'number': 11,
        'clue': "To understand clearly",
        'answer': "GRASP",
        'hint': "To understand something completely"
      },
      {
        'number': 12,
        'clue': "To make something better",
        'answer': "ENHANCE",
        'hint': "To intensify or improve the quality of something"
      },
      {
        'number': 15,
        'clue': "Mental challenge",
        'answer': "GAME",
        'hint': "An activity that one engages in for amusement"
      },
      {
        'number': 18,
        'clue': "Synonym for solution",
        'answer': "ANSWER",
        'hint': "A solution to a problem"
      },
      {
        'number': 19,
        'clue': "Type of thinking that's outside the box",
        'answer': "CREATIVE",
        'hint': "Relating to or involving the imagination"
      },
      {
        'number': 20,
        'clue': "Quick learning",
        'answer': "APTITUDE",
        'hint': "A natural ability to do something"
      },
      {
        'number': 21,
        'clue': "Focused attention",
        'answer': "CONCENTRATION",
        'hint': "The action or power of focusing one's attention"
      },
      {
        'number': 23,
        'clue': "To think deeply",
        'answer': "PONDER",
        'hint': "To think about something carefully"
      },
      {
        'number': 25,
        'clue': "Mental exercise",
        'answer': "QUIZ",
        'hint': "A test of knowledge"
      }
    ],
  };

  List<List<TextEditingController>> controllers = [];
  String selectedDirection = 'across';
  int? selectedNumber;
  String feedback = "";
  bool showHint = false;
  List<List<bool>> isCorrect = [];
  List<List<bool>> isError = [];

  @override
  void initState() {
    super.initState();
    initializeControllers();
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

  void initializeControllers() {
    controllers = List.generate(
      grid.length,
      (i) => List.generate(
        grid[i].length,
        (j) => TextEditingController(),
      ),
    );
    isCorrect = List.generate(
      grid.length,
      (i) => List.generate(grid[i].length, (j) => false),
    );
    isError = List.generate(
      grid.length,
      (i) => List.generate(grid[i].length, (j) => false),
    );
  }

  void checkAnswers() {
    bool allCorrect = true;
    bool allFilled = true;

    // Reset cell states
    setState(() {
      isCorrect = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => false),
      );
      isError = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => false),
      );
    });

    // Check across words
    for (var word in words['across']!) {
      final number = word['number'] as int;
      final answer = word['answer'] as String;

      // Find starting position
      int startRow = -1;
      int startCol = -1;
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          if (grid[i][j] == number.toString()) {
            startRow = i;
            startCol = j;
            break;
          }
        }
        if (startRow != -1) break;
      }

      // Check each letter
      if (startRow != -1 && startCol != -1) {
        for (int i = 0; i < answer.length; i++) {
          if (startCol + i >= grid[startRow].length) break;
          final controller = controllers[startRow][startCol + i];
          final userLetter = controller.text.toUpperCase();
          final correctLetter = answer[i];

          if (userLetter.isEmpty) {
            allFilled = false;
            setState(() {
              isError[startRow][startCol + i] = true;
            });
          } else if (userLetter == correctLetter) {
            setState(() {
              isCorrect[startRow][startCol + i] = true;
            });
          } else {
            allCorrect = false;
            setState(() {
              isError[startRow][startCol + i] = true;
            });
          }
        }
      }
    }

    // Check down words
    for (var word in words['down']!) {
      final number = word['number'] as int;
      final answer = word['answer'] as String;

      // Find starting position
      int startRow = -1;
      int startCol = -1;
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          if (grid[i][j] == number.toString()) {
            startRow = i;
            startCol = j;
            break;
          }
        }
        if (startRow != -1) break;
      }

      // Check each letter
      if (startRow != -1 && startCol != -1) {
        for (int i = 0; i < answer.length; i++) {
          if (startRow + i >= grid.length) break;
          final controller = controllers[startRow + i][startCol];
          final userLetter = controller.text.toUpperCase();
          final correctLetter = answer[i];

          if (userLetter.isEmpty) {
            allFilled = false;
            setState(() {
              isError[startRow + i][startCol] = true;
            });
          } else if (userLetter == correctLetter) {
            setState(() {
              isCorrect[startRow + i][startCol] = true;
            });
          } else {
            allCorrect = false;
            setState(() {
              isError[startRow + i][startCol] = true;
            });
          }
        }
      }
    }

    setState(() {
      if (allCorrect && allFilled) {
        feedback = "🎉 Congratulations! All answers are correct!";
        widget.onComplete();
      } else if (!allFilled) {
        feedback = "Please fill in all the cells before checking your answers.";
      } else {
        feedback = "Some answers are incorrect. Keep trying!";
      }
    });
  }

  void resetPuzzle() {
    for (var row in controllers) {
      for (var controller in row) {
        controller.clear();
      }
    }
    setState(() {
      feedback = "";
      showHint = false;
      isCorrect = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => false),
      );
      isError = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => false),
      );
    });
  }

  void solvePuzzle() {
    // Clear all cells first to avoid conflicts
    for (var row in controllers) {
      for (var controller in row) {
        controller.clear();
      }
    }

    // Fill in across words
    for (var word in words['across']!) {
      final number = word['number'] as int;
      final answer = word['answer'] as String;

      // Find starting position
      int startRow = -1;
      int startCol = -1;
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          if (grid[i][j] == number.toString()) {
            startRow = i;
            startCol = j;
            break;
          }
        }
        if (startRow != -1) break;
      }

      if (startRow != -1 && startCol != -1) {
        // Fill in letters
        for (int i = 0; i < answer.length; i++) {
          if (startCol + i < controllers[startRow].length) {
            controllers[startRow][startCol + i].text = answer[i];
          }
        }
      }
    }

    // Fill in down words
    for (var word in words['down']!) {
      final number = word['number'] as int;
      final answer = word['answer'] as String;

      // Find starting position
      int startRow = -1;
      int startCol = -1;
      for (int i = 0; i < grid.length; i++) {
        for (int j = 0; j < grid[i].length; j++) {
          if (grid[i][j] == number.toString()) {
            startRow = i;
            startCol = j;
            break;
          }
        }
        if (startRow != -1) break;
      }

      if (startRow != -1 && startCol != -1) {
        // Fill in letters
        for (int i = 0; i < answer.length; i++) {
          if (startRow + i < controllers.length) {
            controllers[startRow + i][startCol].text = answer[i];
          }
        }
      }
    }

    setState(() {
      feedback = "Puzzle solved!";
      isCorrect = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => true),
      );
      isError = List.generate(
        grid.length,
        (i) => List.generate(grid[i].length, (j) => false),
      );
    });
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
                      icon: Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Crossword Puzzle',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Crossword Grid
                        Center(
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width - 32,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 24,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: List.generate(
                                grid.length,
                                (i) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    grid[i].length,
                                    (j) => Container(
                                      width: 35,
                                      height: 35,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        color: grid[i][j] == 'x'
                                            ? Colors.black
                                            : isCorrect[i][j]
                                                ? Colors.green[50]
                                                : isError[i][j]
                                                    ? Colors.red[50]
                                                    : Colors.white,
                                      ),
                                      child: grid[i][j] == 'x'
                                          ? null
                                          : Stack(
                                              children: [
                                                if (grid[i][j] != '.')
                                                  Positioned(
                                                    top: 2,
                                                    left: 2,
                                                    child: Text(
                                                      grid[i][j],
                                                      style: TextStyle(
                                                        fontSize: 8,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ),
                                                Center(
                                                  child: TextField(
                                                    controller: controllers[i]
                                                        [j],
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: isCorrect[i][j]
                                                          ? Colors.green[700]
                                                          : isError[i][j]
                                                              ? Colors.red[700]
                                                              : Colors
                                                                  .blue[900],
                                                    ),
                                                    maxLength: 1,
                                                    textCapitalization:
                                                        TextCapitalization
                                                            .characters,
                                                    decoration: InputDecoration(
                                                      counterText: "",
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Clues Section
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Clues",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Across",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                ...words['across']!.map((word) => ListTile(
                                      dense: true,
                                      title: Text(
                                        "${word['number']}. ${word['clue']}",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedDirection = 'across';
                                          selectedNumber =
                                              word['number'] as int;
                                          showHint = false;
                                        });
                                      },
                                    )),
                                SizedBox(height: 16),
                                Text(
                                  "Down",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                ...words['down']!.map((word) => ListTile(
                                      dense: true,
                                      title: Text(
                                        "${word['number']}. ${word['clue']}",
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      onTap: () {
                                        setState(() {
                                          selectedDirection = 'down';
                                          selectedNumber =
                                              word['number'] as int;
                                          showHint = false;
                                        });
                                      },
                                    )),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Controls
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: checkAnswers,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: Text("Check Answers"),
                            ),
                            ElevatedButton(
                              onPressed: resetPuzzle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200]!,
                                foregroundColor: Colors.grey[700]!,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: Text("Reset"),
                            ),
                            ElevatedButton(
                              onPressed: solvePuzzle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: Text("Solve Puzzle"),
                            ),
                          ],
                        ),

                        // Feedback
                        if (feedback.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              feedback,
                              style: TextStyle(
                                color: feedback.contains("Congratulations")
                                    ? Colors.green
                                    : feedback.contains("Please")
                                        ? Colors.orange
                                        : Colors.red,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
