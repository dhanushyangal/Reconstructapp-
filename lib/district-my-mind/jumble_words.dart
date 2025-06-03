import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class JumbleWordsGame extends StatefulWidget {
  const JumbleWordsGame({Key? key}) : super(key: key);

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
    {
      'word': 'PEACE',
      'hint': 'A state of tranquility and harmony',
      'jumbled': 'ECAPE',
    },
    {
      'word': 'DREAM',
      'hint': 'A series of thoughts during sleep',
      'jumbled': 'MADER',
    },
    {
      'word': 'HOPE',
      'hint': 'A feeling of expectation and desire',
      'jumbled': 'EPOH',
    },
  ];

  int _currentWordIndex = 0;
  final TextEditingController _answerController = TextEditingController();
  int _score = 0;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('jumble_words_score') ?? 0;
    });
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('jumble_words_score', _score);
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
      _saveScore();
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
