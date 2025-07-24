import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jumble_words.dart';
import 'crossword_puzzle.dart';
import 'activity_progress.dart';
import '../utils/activity_tracker_mixin.dart';

class WordGames extends StatefulWidget {
  const WordGames({super.key});

  @override
  State<WordGames> createState() => _WordGamesState();
}

class _WordGamesState extends State<WordGames> with ActivityTrackerMixin {
  int currentStep = 1;
  final int totalSteps = 3;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _progress = prefs.getInt('word_games_progress') ?? 0;
    });
  }

  Future<void> _updateProgress(int progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('word_games_progress', progress);
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
  }

  void _showActivityProgress() {
    if (!mounted) return;
    trackClick('word_games_progress_viewed');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProgress(),
      ),
    ).then((value) {
      if (value != null && mounted) {
        Navigator.pop(context, value);
      }
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
                      onPressed: () => Navigator.pop(context, _progress),
                    ),
                    Expanded(
                      child: Text(
                        'Word Games',
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

              // Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStepIndicator(1, 'Riddles'),
                        _buildStepIndicator(2, 'Jumble Words'),
                        _buildStepIndicator(3, 'Crossword'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Riddles', style: _getStepTextStyle(1)),
                        Text('Jumble Words', style: _getStepTextStyle(2)),
                        Text('Crossword', style: _getStepTextStyle(3)),
                      ],
                    ),
                  ],
                ),
              ),

              // Game Content
              Expanded(
                child: _buildGameContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isCompleted = step < currentStep;
    final isCurrent = step == currentStep;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isCurrent
                    ? Colors.blue
                    : Colors.blue[200],
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: Colors.white)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: isCurrent ? Colors.white : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        if (step < totalSteps)
          Container(
            width: 80,
            height: 2,
            color: isCompleted ? Colors.green : Colors.blue[200],
          ),
      ],
    );
  }

  TextStyle _getStepTextStyle(int step) {
    if (step < currentStep) {
      return TextStyle(color: Colors.green, fontWeight: FontWeight.w500);
    } else if (step == currentStep) {
      return TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500);
    } else {
      return TextStyle(color: Colors.blue[400]);
    }
  }

  Widget _buildGameContent() {
    if (currentStep < 1 || currentStep > totalSteps) {
      return Container();
    }

    switch (currentStep) {
      case 1:
        return RiddlesGame(
          onComplete: () {
            _updateProgress(33).then((_) {
              if (mounted) {
                setState(() => currentStep = 2);
              }
            });
          },
        );
      case 2:
        return JumbleWords(
          onComplete: () {
            _updateProgress(66).then((_) {
              if (mounted) {
                setState(() => currentStep = 3);
              }
            });
          },
        );
      case 3:
        return CrosswordPuzzle(
          onComplete: () {
            _updateProgress(100).then((_) {
              if (mounted) {
                _showActivityProgress();
              }
            });
          },
        );
      default:
        return Container();
    }
  }
}

class RiddlesGame extends StatefulWidget {
  final VoidCallback onComplete;

  const RiddlesGame({
    super.key,
    required this.onComplete,
  });

  @override
  State<RiddlesGame> createState() => _RiddlesGameState();
}

class _RiddlesGameState extends State<RiddlesGame> {
  final List<Map<String, String>> riddles = [
    {
      "riddle": "What has to be broken before you can use it?",
      "answer": "EGG",
      "hint": "I come from a chicken"
    },
    {
      "riddle": "What can you break even if you never touch it?",
      "answer": "PROMISE",
      "hint": "I'm something you make to someone"
    },
    {
      "riddle": "What has a head and a tail but no body?",
      "answer": "COIN",
      "hint": "You use me to buy things"
    },
    {
      "riddle": "What building has the most stories?",
      "answer": "LIBRARY",
      "hint": "I contain many books"
    },
    {
      "riddle": "What kind of coat is best put on wet?",
      "answer": "PAINT",
      "hint": "I'm used to color walls"
    },
    {
      "riddle": "What can travel around the world without leaving its corner?",
      "answer": "STAMP",
      "hint": "I'm used on letters"
    },
    {
      "riddle": "What is cut of a table but never eaten?",
      "answer": "DECK",
      "hint": "I'm used to play cards"
    },
    {
      "riddle": "What can you catch, but cannot throw?",
      "answer": "COLD",
      "hint": "I'm an illness"
    },
    {
      "riddle": "What can't be put in a saucepan?",
      "answer": "LID",
      "hint": "I cover the top"
    },
    {
      "riddle": "What kind of band never plays music?",
      "answer": "RUBBER",
      "hint": "I'm stretchy"
    },
    {
      "riddle": "What has a thumb and 4 fingers but is not a hand?",
      "answer": "GLOVE",
      "hint": "I'm worn on your hand"
    },
    {
      "riddle": "What gets bigger when more is taken away?",
      "answer": "HOLE",
      "hint": "I'm an empty space"
    },
    {
      "riddle": "What has one eye but can't see?",
      "answer": "NEEDLE",
      "hint": "I'm used for sewing"
    },
    {
      "riddle": "What month of the year has 28 days?",
      "answer": "ALL OF THEM",
      "hint": "Think about all months"
    },
    {
      "riddle": "What can't talk but will reply when spoken to?",
      "answer": "ECHO",
      "hint": "I repeat what you say"
    },
    {
      "riddle": "What can you keep after giving to someone?",
      "answer": "PROMISE",
      "hint": "I'm a commitment"
    },
    {
      "riddle": "What invention lets you look through a wall?",
      "answer": "WINDOW",
      "hint": "I'm made of glass"
    },
    {
      "riddle": "What goes up but never comes down?",
      "answer": "AGE",
      "hint": "I increase with time"
    },
    {
      "riddle": "I have branches, but no fruit, tree or leaves. What am I?",
      "answer": "BANK",
      "hint": "I handle money"
    },
    {
      "riddle": "What has words but never speaks?",
      "answer": "BOOK",
      "hint": "I contain stories"
    }
  ];

  late List<Map<String, String>> gameRiddles;
  int currentRiddleIndex = 0;
  String currentRiddle = "";
  String currentAnswer = "";
  String currentHint = "";
  final TextEditingController _answerController = TextEditingController();
  String feedback = "";
  bool showHint = false;
  Color feedbackColor = Colors.black;
  int score = 0;

  @override
  void initState() {
    super.initState();
    initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void initializeGame() {
    gameRiddles = List.from(riddles)..shuffle();
    gameRiddles = gameRiddles.take(5).toList();
    currentRiddleIndex = 0;
    loadCurrentRiddle();
  }

  void loadCurrentRiddle() {
    final currentRiddleData = gameRiddles[currentRiddleIndex];
    currentRiddle = currentRiddleData["riddle"]!;
    currentAnswer = currentRiddleData["answer"]!;
    currentHint = currentRiddleData["hint"]!;
    _answerController.clear();
    feedback = "";
    showHint = false;
  }

  void checkAnswer() {
    final userAnswer = _answerController.text.trim().toUpperCase();

    if (userAnswer.isEmpty) {
      setState(() {
        feedback = "Please enter your answer.";
        feedbackColor = Colors.orange;
      });
      return;
    }

    if (userAnswer == currentAnswer) {
      setState(() {
        feedback = "Correct! Great job! 🎉";
        feedbackColor = Colors.green;
        score++;
      });

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          currentRiddleIndex++;
          if (currentRiddleIndex < gameRiddles.length) {
            setState(() {
              loadCurrentRiddle();
            });
          } else {
            widget
                .onComplete(); // Directly call onComplete without showing dialog
          }
        }
      });
    } else {
      setState(() {
        feedback = "Incorrect. Try again!";
        feedbackColor = Colors.red;
      });
    }
  }

  void skipRiddle() {
    setState(() {
      currentRiddleIndex++;
      if (currentRiddleIndex < gameRiddles.length) {
        loadCurrentRiddle();
      } else {
        widget.onComplete(); // Directly call onComplete without showing dialog
      }
    });
  }

  void toggleHint() {
    setState(() {
      showHint = !showHint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Mind-bending Riddles',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Prepare to have your wits challenged with these cunning, brain-teasing riddles that are sure to keep you guessing!\n\nThere are 20 fun riddles in all, designed to make you do some mental gymnastics :).',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Main quiz container
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (currentRiddleIndex + 1) / gameRiddles.length,
                        backgroundColor: Colors.grey[300],
                        color: Colors.blue,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Riddle content
                    if (gameRiddles.isNotEmpty) ...[
                      Text(
                        gameRiddles[currentRiddleIndex]["riddle"]!,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          hintText: 'Type your answer',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => checkAnswer(),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: checkAnswer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Check Answer'),
                          ),
                          ElevatedButton(
                            onPressed: toggleHint,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Show Hint'),
                          ),
                          ElevatedButton(
                            onPressed: skipRiddle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Skip'),
                          ),
                        ],
                      ),
                      if (showHint) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            gameRiddles[currentRiddleIndex]["hint"]!,
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      if (feedback.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          feedback,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: feedbackColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
