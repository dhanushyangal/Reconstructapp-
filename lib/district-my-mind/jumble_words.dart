import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';

class JumbleWords extends StatefulWidget {
  final VoidCallback onComplete;

  const JumbleWords({
    super.key,
    required this.onComplete,
  });

  @override
  State<JumbleWords> createState() => _JumbleWordsState();
}

class _JumbleWordsState extends State<JumbleWords> with ActivityTrackerMixin {
  final List<Map<String, String>> wordList = [
    {
      "word": "PUZZLE",
      "hint": "A game or toy that tests ingenuity or knowledge"
    },
    {
      "word": "BRAIN",
      "hint": "The organ inside your head that controls your body"
    },
    {"word": "FOCUS", "hint": "The center of interest or activity"},
    {"word": "THINK", "hint": "To use your mind to consider something"},
    {
      "word": "LEARN",
      "hint": "To gain knowledge or skill by studying or experience"
    },
  ];

  late List<Map<String, String>> gameWords;
  int currentWordIndex = 0;
  String currentWord = "";
  String currentHint = "";
  int score = 0;
  final TextEditingController _answerController = TextEditingController();
  String feedback = "";
  bool showHint = false;

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
    gameWords = List.from(wordList)..shuffle();
    gameWords = gameWords.take(5).toList();
    currentWordIndex = 0;
    score = 0;
    loadCurrentWord();
  }

  void loadCurrentWord() {
    final currentWordData = gameWords[currentWordIndex];
    currentWord = currentWordData["word"]!;
    currentHint = currentWordData["hint"]!;
    _answerController.clear();
    feedback = "";
    showHint = false;
  }

  String shuffleWord(String word) {
    List<String> letters = word.split('');
    while (letters.join() == word) {
      letters.shuffle();
    }
    return letters.join();
  }

  void checkAnswer() {
    final userAnswer = _answerController.text.trim().toUpperCase();

    if (userAnswer.isEmpty) {
      setState(() {
        feedback = "Please enter your answer.";
      });
      return;
    }

    trackClick('jumble_words_answer_submitted - $userAnswer');

    if (userAnswer == currentWord) {
      trackClick('jumble_words_correct_answer - $currentWord');
      setState(() {
        feedback = "Correct! Great job! 🎉";
        score++;
      });

      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          currentWordIndex++;
          if (currentWordIndex < gameWords.length) {
            setState(() {
              loadCurrentWord();
            });
          } else {
            widget.onComplete();
          }
        }
      });
    } else {
      trackClick('jumble_words_incorrect_answer - $userAnswer');
      setState(() {
        feedback = "Incorrect. Try rearranging the letters.";
      });
    }
  }

  void clearAnswer() {
    setState(() {
      _answerController.clear();
      feedback = "";
    });
  }

  void skipWord() {
    setState(() {
      currentWordIndex++;
      if (currentWordIndex < gameWords.length) {
        loadCurrentWord();
      } else {
        widget.onComplete();
      }
    });
  }

  void toggleHint() {
    trackClick('jumble_words_hint_toggled');
    setState(() {
      showHint = !showHint;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (currentWordIndex + 1) / gameWords.length,
            backgroundColor: Colors.blue[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 24),

          // Word Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Word ${currentWordIndex + 1} of ${gameWords.length}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: toggleHint,
                            child: Text("Need a hint?"),
                          ),
                          TextButton(
                            onPressed: skipWord,
                            child: Text("Skip word"),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (showHint) ...[
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentHint,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shuffleWord(currentWord),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _answerController,
                    decoration: InputDecoration(
                      hintText: "Type your answer here",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => checkAnswer(),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: clearAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[700],
                        ),
                        child: Text("Clear"),
                      ),
                      ElevatedButton(
                        onPressed: checkAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("Check Answer"),
                      ),
                    ],
                  ),
                  if (feedback.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        feedback,
                        style: TextStyle(
                          color: feedback.contains("Correct")
                              ? Colors.green
                              : feedback.contains("Please")
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
