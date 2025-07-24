import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sudoku_game.dart';
import 'game_2048.dart';
import 'prime_finder.dart';
import '../utils/activity_tracker_mixin.dart';

class NumberGames extends StatefulWidget {
  const NumberGames({super.key});

  @override
  State<NumberGames> createState() => _NumberGamesState();
}

class _NumberGamesState extends State<NumberGames> with ActivityTrackerMixin {
  int _currentStep = 1;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _progress = prefs.getInt('number_games_progress') ?? 0;
    });
  }

  Future<void> _updateProgress(int progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('number_games_progress', progress);
    setState(() {
      _progress = progress;
    });
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
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
                      icon: Icon(Icons.arrow_back, color: Color(0xFF1E88E5)),
                      onPressed: () => Navigator.pop(context, _progress),
                    ),
                    Expanded(
                      child: Text(
                        'Number Games',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Steps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStep(1, 'Sudoku'),
                    _buildStepLine(),
                    _buildStep(2, '2048'),
                    _buildStepLine(),
                    _buildStep(3, 'Prime'),
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
                        if (_currentStep == 1)
                          SudokuGame(
                            onComplete: () {
                              _updateProgress(33);
                              _goToStep(2);
                            },
                          )
                        else if (_currentStep == 2)
                          Game2048(
                            onComplete: () {
                              _updateProgress(66);
                              _goToStep(3);
                            },
                          )
                        else if (_currentStep == 3)
                          PrimeFinder(
                            onComplete: () {
                              _updateProgress(100);
                              Navigator.pop(context, 100);
                            },
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

  Widget _buildStep(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? Color(0xFF1E88E5)
                : isCompleted
                    ? Color(0xFF43A047)
                    : Color(0xFFE3F2FD),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color:
                    isActive || isCompleted ? Colors.white : Color(0xFF1E88E5),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xFF1E88E5) : Color(0xFF90CAF9),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 24,
      height: 2,
      margin: EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
