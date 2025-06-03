import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class ActivityProgress extends StatefulWidget {
  final Map<String, int> progress;
  final String? activityType;

  const ActivityProgress({
    Key? key,
    required this.progress,
    this.activityType,
  }) : super(key: key);

  @override
  State<ActivityProgress> createState() => _ActivityProgressState();
}

class _ActivityProgressState extends State<ActivityProgress> {
  String _feeling = '';

  @override
  void initState() {
    super.initState();
    _loadFeeling();
  }

  Future<void> _loadFeeling() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _feeling = prefs.getString('creative_activities_feeling') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final activityName = widget.activityType == 'creative'
        ? 'Creative Activities'
        : (widget.activityType == 'word' ? 'Word Games' : 'Number Games');

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
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Activity Progress',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Great Work!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E88E5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Container(
                          height: 6,
                          width: 120,
                          margin: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF64B5F6),
                                Color(0xFF1E88E5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Text(
                          'You\'ve made progress in your journey to distract your mind.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40),

                        // Progress Circle
                        Container(
                          width: 200,
                          height: 200,
                          child: CustomPaint(
                            painter: ProgressCirclePainter(
                              progress: widget.progress[widget.activityType ??
                                      'creative_activities'] ??
                                  0,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.progress[widget.activityType ?? 'creative_activities'] ?? 0}%',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                  Text(
                                    'Complete',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),

                        // Activity Name
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
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
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE3F2FD),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        widget.activityType == 'creative'
                                            ? '🎨'
                                            : (widget.activityType == 'word'
                                                ? '🔤'
                                                : '🔢'),
                                        style: TextStyle(
                                          fontSize: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activityName,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E88E5),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        LinearProgressIndicator(
                                          value: (widget.progress[widget
                                                          .activityType ??
                                                      'creative_activities'] ??
                                                  0) /
                                              100,
                                          backgroundColor: Color(0xFFE3F2FD),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF1E88E5)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),

                        // Mood Improvement (if applicable)
                        if (_feeling.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                                  'Mood Improvement',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Text(
                                          _feeling == 'better'
                                              ? '😊'
                                              : (_feeling == 'little-better'
                                                  ? '😐'
                                                  : '😟'),
                                          style: TextStyle(fontSize: 48),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          _feeling == 'better'
                                              ? 'Better'
                                              : (_feeling == 'little-better'
                                                  ? 'A little better'
                                                  : 'Not much change'),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 40),

                        // Continue Button
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(
                                context,
                                widget.progress[widget.activityType ??
                                        'creative_activities'] ??
                                    0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1E88E5),
                            padding: EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

class ProgressCirclePainter extends CustomPainter {
  final int progress;

  ProgressCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle
    final backgroundPaint = Paint()
      ..color = Color(0xFFE3F2FD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Color(0xFF1E88E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (progress / 100);

    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
