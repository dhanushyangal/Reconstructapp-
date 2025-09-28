import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import 'self_love_success_page.dart';

class LoveYourselfQuizPage extends StatefulWidget {
  final String categoryName;

  const LoveYourselfQuizPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<LoveYourselfQuizPage> createState() => _LoveYourselfQuizPageState();
}

class _LoveYourselfQuizPageState extends State<LoveYourselfQuizPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  List<String?> _selectedAnswers = [];
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Quiz questions and answers
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'You\'re allowed to _____ what you feel.',
      'options': ['stop', 'feel', 'forget'],
      'correct': 'feel',
    },
    {
      'question': 'You\'re loved more than you ______.',
      'options': ['must', 'care', 'know'],
      'correct': 'know',
    },
    {
      'question': 'You are ______.',
      'options': ['nourished', 'valued', 'cared'],
      'correct': 'valued',
    },
    {
      'question': 'You ________ to do whatever you want to.',
      'options': ['deserve', 'require', 'can try'],
      'correct': 'deserve',
    },
    {
      'question': 'You\'re allowed to let go of ______ people.',
      'options': ['bored', 'old', 'toxic'],
      'correct': 'toxic',
    },
    {
      'question': 'You\'re highly capable of _______ the right decisions.',
      'options': ['forgetting', 'making', 'doing'],
      'correct': 'making',
    },
    {
      'question': 'You\'re _____ in prioritizing yourself over others.',
      'options': ['carefree', 'reckless', 'right'],
      'correct': 'right',
    },
    {
      'question': 'All that you ______for is coming to you.',
      'options': ['wish', 'need', 'do'],
      'correct': 'wish',
    },
    {
      'question': 'You speak with a _____ confidence.',
      'options': ['loud', 'strong', 'calm'],
      'correct': 'calm',
    },
    {
      'question': 'Your positive ________ fuels your life.',
      'options': ['strength', 'energy', 'vibe'],
      'correct': 'energy',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize selected answers list
    _selectedAnswers = List.filled(_quizQuestions.length, null);
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0, // 100% progress for quiz page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    super.dispose();
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showQuizResults();
    }
  }

  void _showQuizResults() {
    int correctAnswers = 0;
    for (int i = 0; i < _quizQuestions.length; i++) {
      if (_selectedAnswers[i] == _quizQuestions[i]['correct']) {
        correctAnswers++;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Quiz Complete!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You scored $correctAnswers out of ${_quizQuestions.length}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Great job! You\'ve completed the ${widget.categoryName} challenge.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToSuccessPage();
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Next',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToSuccessPage() {
    // Track the activity
    trackClick('quiz_complete_${widget.categoryName}');

    // Navigate to self love success page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelfLoveSuccessPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _quizQuestions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _quizQuestions.length - 1;

    return NavLogPage(
      title: 'Love Yourself Challenge | Day 1 Quiz',
      showBackButton: true,
      selectedIndex: 2, // Dashboard index
      onNavigationTap: (index) {
        // Navigate to different pages based on index
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(context, '/browse', (route) => false);
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(context, '/tracker', (route) => false);
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
            break;
        }
      },
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
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number and progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentQuestionIndex + 1} of ${_quizQuestions.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${_currentQuestionIndex + 1}/${_quizQuestions.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF23C4F7),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Question
                  Text(
                    currentQuestion['question'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 32),
                  
                  // Answer options
                  Expanded(
                    child: Column(
                      children: currentQuestion['options'].map<Widget>((option) {
                        final isSelected = _selectedAnswers[_currentQuestionIndex] == option;
                        return Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 12),
                          child: ElevatedButton(
                            onPressed: () => _selectAnswer(option),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected ? Color(0xFF23C4F7) : Colors.white,
                              foregroundColor: isSelected ? Colors.white : Colors.black87,
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected ? Color(0xFF23C4F7) : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              elevation: isSelected ? 4 : 1,
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  // Next/Submit button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedAnswers[_currentQuestionIndex] != null ? _nextQuestion : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedAnswers[_currentQuestionIndex] != null 
                            ? Color(0xFF23C4F7) 
                            : Colors.grey[300],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isLastQuestion ? 'Submit' : 'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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

  String get pageName => 'Love Yourself Quiz';
}
