import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jumble_words.dart';
import 'crossword_puzzle.dart';

class WordGames extends StatefulWidget {
  const WordGames({Key? key}) : super(key: key);

  @override
  State<WordGames> createState() => _WordGamesState();
}

class _WordGamesState extends State<WordGames> {
  int _currentGame = 0; // 0: Jumble Words, 1: Crossword
  final PageController _pageController = PageController();
  int _jumbleWordsProgress = 0;
  int _crosswordProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jumbleWordsProgress = prefs.getInt('jumble_words_progress') ?? 0;
      _crosswordProgress = prefs.getInt('crossword_progress') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jumble_words_progress', _jumbleWordsProgress);
    await prefs.setInt('crossword_progress', _crosswordProgress);
    Navigator.pop(context, (_jumbleWordsProgress + _crosswordProgress) ~/ 2);
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
                        'Word Games',
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
                      child: _buildGameTab(
                          'Jumble Words', 0, _jumbleWordsProgress),
                    ),
                    Expanded(
                      child: _buildGameTab('Crossword', 1, _crosswordProgress),
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
                    JumbleWordsGame(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _jumbleWordsProgress = progress;
                        });
                        _saveProgress();
                      },
                    ),
                    CrosswordPuzzleGame(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _crosswordProgress = progress;
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

class JumbleWordsGame extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const JumbleWordsGame({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<JumbleWordsGame> createState() => _JumbleWordsGameState();
}

class _JumbleWordsGameState extends State<JumbleWordsGame> {
  final List<Map<String, dynamic>> _words = [
    {
      'word': 'HAPPY',
      'hint': 'A feeling of joy and contentment',
      'jumbled': 'PYHAP',
    },
    {
      'word': 'SMILE',
      'hint': 'A facial expression showing pleasure',
      'jumbled': 'MILES',
    },
    // Add more words here
  ];

  int _currentWordIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  int _score = 0;
  bool _showHint = false;

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
                  'Word ${_currentWordIndex + 1}/${_words.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Jumbled Word Display
          Container(
            padding: EdgeInsets.all(24),
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
            child: Column(
              children: [
                Text(
                  _words[_currentWordIndex]['jumbled'],
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                if (_showHint) ...[
                  SizedBox(height: 16),
                  Text(
                    'Hint: ${_words[_currentWordIndex]['hint']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          SizedBox(height: 24),

          // Answer Input
          TextField(
            controller: _answerController,
            decoration: InputDecoration(
              hintText: 'Enter your answer',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
            textCapitalization: TextCapitalization.characters,
          ),

          SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showHint = !_showHint;
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
                  child: Text(_showHint ? 'Hide Hint' : 'Show Hint'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checkAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Check Answer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    final answer = _answerController.text.trim().toUpperCase();
    if (answer == _words[_currentWordIndex]['word']) {
      setState(() {
        _score += 10;
        if (_currentWordIndex < _words.length - 1) {
          _currentWordIndex++;
          _answerController.clear();
          _showHint = false;
        }
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
          content: Text('Try again!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }
}

class CrosswordPuzzleGame extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const CrosswordPuzzleGame({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<CrosswordPuzzleGame> createState() => _CrosswordPuzzleGameState();
}

class _CrosswordPuzzleGameState extends State<CrosswordPuzzleGame> {
  // TODO: Implement crossword puzzle game
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Crossword Puzzle Coming Soon!',
        style: TextStyle(
          fontSize: 20,
          color: Color(0xFF1E88E5),
        ),
      ),
    );
  }
}
