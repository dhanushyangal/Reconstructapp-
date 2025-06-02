import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrimeFinderGame extends StatefulWidget {
  const PrimeFinderGame({Key? key}) : super(key: key);

  @override
  State<PrimeFinderGame> createState() => _PrimeFinderGameState();
}

class _PrimeFinderGameState extends State<PrimeFinderGame> {
  final List<int> _numbers = List.generate(100, (index) => index + 1);
  final List<int> _selectedNumbers = [];
  int _score = 0;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _score = prefs.getInt('prime_finder_score') ?? 0;
    });
  }

  Future<void> _saveScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prime_finder_score', _score);
  }

  bool _isPrime(int number) {
    if (number < 2) return false;
    for (int i = 2; i <= number ~/ 2; i++) {
      if (number % i == 0) return false;
    }
    return true;
  }

  void _checkSelection() {
    bool allCorrect = true;
    for (int number in _selectedNumbers) {
      if (!_isPrime(number)) {
        allCorrect = false;
        break;
      }
    }

    for (int number in _numbers) {
      if (_isPrime(number) && !_selectedNumbers.contains(number)) {
        allCorrect = false;
        break;
      }
    }

    if (allCorrect) {
      setState(() {
        _score += 50;
        _gameOver = true;
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
          content: Text('Not all prime numbers are selected correctly'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startNewGame() {
    setState(() {
      _selectedNumbers.clear();
      _gameOver = false;
    });
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
                ElevatedButton(
                  onPressed: _startNewGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E88E5),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('New Game'),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Game Instructions
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Select all prime numbers from 1 to 100',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E88E5),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          SizedBox(height: 24),

          // Number Grid
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
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _numbers.length,
                itemBuilder: (context, index) {
                  final number = _numbers[index];
                  final isSelected = _selectedNumbers.contains(number);

                  return GestureDetector(
                    onTap: _gameOver
                        ? null
                        : () {
                            setState(() {
                              if (isSelected) {
                                _selectedNumbers.remove(number);
                              } else {
                                _selectedNumbers.add(number);
                              }
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Color(0xFF1E88E5) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected ? Colors.white : Color(0xFF1E88E5),
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

          // Check Button
          if (!_gameOver)
            ElevatedButton(
              onPressed: _checkSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1E88E5),
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Check Selection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (_gameOver) ...[
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'You found all prime numbers!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
