import 'package:flutter/material.dart';
import 'activity_progress.dart';

class PrimeFinder extends StatefulWidget {
  final VoidCallback onComplete;

  const PrimeFinder({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<PrimeFinder> createState() => _PrimeFinderState();
}

class _PrimeFinderState extends State<PrimeFinder> {
  int correctCount = 0;
  List<bool> attempted = List.filled(101, false);

  bool isPrime(int n) {
    if (n <= 1) return false;
    if (n <= 3) return true;
    if (n % 2 == 0 || n % 3 == 0) return false;
    for (int i = 5; i * i <= n; i += 6) {
      if (n % i == 0 || n % (i + 2) == 0) return false;
    }
    return true;
  }

  void _handleCellTap(int number) {
    if (attempted[number]) return;

    setState(() {
      attempted[number] = true;
      if (isPrime(number)) {
        correctCount++;
      }
    });

    if (correctCount >= 10) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityProgressPage(
            activityType: 'prime',
          ),
        ),
      );
      widget.onComplete();
    }
  }

  void _navigateToProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityProgressPage(
          activityType: 'prime',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Prime Numbers Challenge',
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
          'Select all the prime numbers from 1 to 100. Get at least 10 correct to continue!',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF1976D2), width: 3),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 10,
              childAspectRatio: 1,
            ),
            itemCount: 100,
            itemBuilder: (context, index) {
              int number = index + 1;
              bool isAttempted = attempted[number];
              bool isCorrect = isAttempted && isPrime(number);
              bool isIncorrect = isAttempted && !isPrime(number);

              return GestureDetector(
                onTap: () => _handleCellTap(number),
                child: Container(
                  margin: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Color(0xFF43A047)
                        : isIncorrect
                            ? Color(0xFFE53935)
                            : Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF90CAF9),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCorrect || isIncorrect
                            ? Colors.white
                            : Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Correct: $correctCount/10',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: correctCount >= 10 ? Colors.green : Color(0xFF1E88E5),
          ),
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: _navigateToProgress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'View Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
