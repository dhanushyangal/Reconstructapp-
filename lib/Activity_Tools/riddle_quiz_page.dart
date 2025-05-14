import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking

class RiddleQuizPage extends StatefulWidget {
  const RiddleQuizPage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/riddle-quiz';

  @override
  RiddleQuizPageState createState() => RiddleQuizPageState();
}

class RiddleQuizPageState extends State<RiddleQuizPage> {
  // Controller for answer input
  final TextEditingController _answerController = TextEditingController();

  // Tracking state
  int _currentQuestionIndex = 0;
  String _selectedDifficulty = 'easy';
  int _score = 0;
  String? _feedback;
  Color _feedbackColor = Colors.black;
  bool _showResults = false;
  double _progressValue = 0.0;

  // List of questions filtered by difficulty
  List<RiddleQuestion> _filteredQuestions = [];

  // Focus node for the text field
  final FocusNode _answerFocusNode = FocusNode();

  // All riddle questions
  final List<RiddleQuestion> _allQuestions = [
    RiddleQuestion(
      question: "What has to be broken before you can use it?",
      correctAnswer: "Egg",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What can you break even if you never touch it?",
      correctAnswer: "A promise",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What has a head and a tail but no body?",
      correctAnswer: "A coin",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What building has the most stories?",
      correctAnswer: "A library",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What kind of coat is best put on wet?",
      correctAnswer: "A coat of paint",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What can travel around the world without leaving its corner?",
      correctAnswer: "A stamp",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What is cut of a table but never eaten?",
      correctAnswer: "A deck of cards",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What can you catch, but cannot throw?",
      correctAnswer: "A cold",
      difficulty: "easy",
    ),
    RiddleQuestion(
      question: "What can't be put in a saucepan?",
      correctAnswer: "Its lid",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What kind of band never plays music?",
      correctAnswer: "Rubberband",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What has a thumb and 4 fingers but is not a hand?",
      correctAnswer: "A glove",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What gets bigger when more is taken away?",
      correctAnswer: "A hole",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What has one eye but can't see?",
      correctAnswer: "A needle",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What month of the year has 28 days?",
      correctAnswer: "All of them",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What can't talk but will reply when spoken to?",
      correctAnswer: "Echo",
      difficulty: "medium",
    ),
    RiddleQuestion(
      question: "What can you keep after giving to someone?",
      correctAnswer: "A promise",
      difficulty: "hard",
    ),
    RiddleQuestion(
      question: "What invention lets you look through a wall?",
      correctAnswer: "window",
      difficulty: "hard",
    ),
    RiddleQuestion(
      question: "What goes up but never comes down?",
      correctAnswer: "age",
      difficulty: "hard",
    ),
    RiddleQuestion(
      question: "I have branches, but no fruit, tree or leaves. What am I?",
      correctAnswer: "A bank",
      difficulty: "hard",
    ),
    RiddleQuestion(
      question: "What has words but never speaks?",
      correctAnswer: "A book",
      difficulty: "hard",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filterQuestionsByDifficulty(_selectedDifficulty);
    _updateProgress();

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Mind-bending Riddles',
        imagePath: 'assets/Activity_Tools/riddles.png',
        timestamp: DateTime.now(),
        routeName: RiddleQuizPage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    super.dispose();
  }

  // Filter questions by difficulty
  void _filterQuestionsByDifficulty(String difficulty) {
    setState(() {
      _selectedDifficulty = difficulty;
      _filteredQuestions =
          _allQuestions.where((q) => q.difficulty == difficulty).toList();
      _currentQuestionIndex = 0;
      _score = 0;
      _feedback = null;
      _showResults = false;
      _answerController.clear();
      _updateProgress();
    });
  }

  // Update progress bar
  void _updateProgress() {
    if (_filteredQuestions.isEmpty) {
      setState(() {
        _progressValue = 0.0;
      });
      return;
    }

    setState(() {
      _progressValue = (_currentQuestionIndex + 1) / _filteredQuestions.length;
    });
  }

  // Check the user's answer
  void _checkAnswer() {
    if (_filteredQuestions.isEmpty) return;

    final currentQuestion = _filteredQuestions[_currentQuestionIndex];
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = currentQuestion.correctAnswer.toLowerCase();

    if (userAnswer == correctAnswer) {
      setState(() {
        _feedback = "Correct!";
        _feedbackColor = Colors.green;
        _score++;
      });

      // Move to next question after delay if answer is correct
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (_currentQuestionIndex < _filteredQuestions.length - 1) {
          setState(() {
            _currentQuestionIndex++;
            _feedback = null;
            _answerController.clear();
            _updateProgress();
          });
        } else {
          _showResultsScreen();
        }
      });
    } else {
      setState(() {
        _feedback = "Incorrect. Please try again!";
        _feedbackColor = Colors.red;
      });
    }
  }

  // Show the correct answer
  void _showAnswer() {
    if (_filteredQuestions.isEmpty) return;

    final currentQuestion = _filteredQuestions[_currentQuestionIndex];
    setState(() {
      _feedback = "The correct answer is: ${currentQuestion.correctAnswer}";
      _feedbackColor = Colors.blue;
    });
  }

  // Go to next question
  void _nextQuestion() {
    if (_currentQuestionIndex < _filteredQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _feedback = null;
        _answerController.clear();
        _updateProgress();
      });
    } else {
      _showResultsScreen();
    }
  }

  // Show results screen
  void _showResultsScreen() {
    setState(() {
      _showResults = true;
    });
  }

  // Share results
  void _shareResults(String platform) {
    final message =
        "🎯 I scored $_score/${_filteredQuestions.length} on the Riddle Quiz! Can you beat my score? Test your knowledge now! #RiddleChallenge";

    if (platform == 'twitter') {
      // Share to Twitter - just use Share.share without creating unused url
      Share.share(message, subject: 'My Riddle Quiz Score');
    } else if (platform == 'instagram') {
      // Share to Instagram (uses general share as direct Instagram sharing is limited)
      Share.share(message, subject: 'My Riddle Quiz Score');
    }
  }

  // Start quiz with new difficulty
  void _startNewQuiz(String difficulty) {
    _filterQuestionsByDifficulty(difficulty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind-bending Riddles'),
      ),
      body: SingleChildScrollView(
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
                      // Difficulty selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildDifficultyButton('easy', 'Easy'),
                          const SizedBox(width: 8),
                          _buildDifficultyButton('medium', 'Medium'),
                          const SizedBox(width: 8),
                          _buildDifficultyButton('hard', 'Hard'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _progressValue,
                          backgroundColor: Colors.grey[300],
                          color: Colors.blue,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Question or results
                      if (!_showResults) ...[
                        if (_filteredQuestions.isNotEmpty) ...[
                          Text(
                            _filteredQuestions[_currentQuestionIndex].question,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _answerController,
                            focusNode: _answerFocusNode,
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
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _checkAnswer(),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            alignment: WrapAlignment.spaceEvenly,
                            spacing: 8,
                            runSpacing: 12,
                            children: [
                              ElevatedButton(
                                onPressed: _checkAnswer,
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
                                onPressed: _showAnswer,
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
                                child: const Text('Show Answer'),
                              ),
                              ElevatedButton(
                                onPressed: _nextQuestion,
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
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                          if (_feedback != null) ...[
                            const SizedBox(height: 24),
                            Text(
                              _feedback!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _feedbackColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ] else ...[
                        // Results screen
                        Column(
                          children: [
                            const Text(
                              'Quiz Completed!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your score: $_score out of ${_filteredQuestions.length}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Next difficulty button
                            ElevatedButton(
                              onPressed: () {
                                if (_selectedDifficulty == 'easy') {
                                  _startNewQuiz('medium');
                                } else if (_selectedDifficulty == 'medium') {
                                  _startNewQuiz('hard');
                                } else {
                                  _startNewQuiz('easy');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                _selectedDifficulty == 'easy'
                                    ? 'Start Medium Level'
                                    : _selectedDifficulty == 'medium'
                                        ? 'Start Hard Level'
                                        : 'Start Easy Level Again',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Replace single share button with social media buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _shareResults('twitter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF1DA1F2), // Twitter blue
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Twitter'),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => _shareResults('instagram'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                        0xFFE1306C), // Instagram pink
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Instagram'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build difficulty buttons
  Widget _buildDifficultyButton(String difficulty, String label) {
    final isSelected = _selectedDifficulty == difficulty;

    return InkWell(
      onTap:
          !_showResults ? () => _filterQuestionsByDifficulty(difficulty) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// Class to hold riddle question data
class RiddleQuestion {
  final String question;
  final String correctAnswer;
  final String difficulty;

  RiddleQuestion({
    required this.question,
    required this.correctAnswer,
    required this.difficulty,
  });
}
