import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class CreativeActivities extends StatefulWidget {
  const CreativeActivities({Key? key}) : super(key: key);

  @override
  State<CreativeActivities> createState() => _CreativeActivitiesState();
}

class _CreativeActivitiesState extends State<CreativeActivities> {
  int _currentActivity = 0; // 0: Coloring, 1: Drawing
  final PageController _pageController = PageController();
  int _coloringProgress = 0;
  int _drawingProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _coloringProgress = prefs.getInt('coloring_progress') ?? 0;
      _drawingProgress = prefs.getInt('drawing_progress') ?? 0;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('coloring_progress', _coloringProgress);
    await prefs.setInt('drawing_progress', _drawingProgress);
    Navigator.pop(context, (_coloringProgress + _drawingProgress) ~/ 2);
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
                        'Creative Activities',
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

              // Activity Selection Tabs
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          _buildActivityTab('Coloring', 0, _coloringProgress),
                    ),
                    Expanded(
                      child: _buildActivityTab('Drawing', 1, _drawingProgress),
                    ),
                  ],
                ),
              ),

              // Activity Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentActivity = index;
                    });
                  },
                  children: [
                    ColoringActivity(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _coloringProgress = progress;
                        });
                        _saveProgress();
                      },
                    ),
                    DrawingActivity(
                      onProgressUpdate: (progress) {
                        setState(() {
                          _drawingProgress = progress;
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

  Widget _buildActivityTab(String title, int index, int progress) {
    final isSelected = _currentActivity == index;
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

class ColoringActivity extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const ColoringActivity({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<ColoringActivity> createState() => _ColoringActivityState();
}

class _ColoringActivityState extends State<ColoringActivity> {
  Color _selectedColor = Colors.blue;
  double _brushSize = 5.0;
  List<DrawingPoint?> _points = [];
  bool _isErasing = false;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = _isErasing ? Colors.white : _selectedColor
                          ..strokeCap = StrokeCap.round
                          ..strokeWidth = _brushSize,
                      ),
                    );
                    _updateProgress();
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = _isErasing ? Colors.white : _selectedColor
                          ..strokeCap = StrokeCap.round
                          ..strokeWidth = _brushSize,
                      ),
                    );
                    _updateProgress();
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(null);
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Tools
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Color Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorButton(Colors.red),
                    _buildColorButton(Colors.blue),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.yellow),
                    _buildColorButton(Colors.purple),
                    _buildColorButton(Colors.orange),
                  ],
                ),

                SizedBox(height: 16),

                // Brush Size Slider
                Row(
                  children: [
                    Icon(Icons.brush, color: Color(0xFF1E88E5)),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _brushSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _brushSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isErasing = !_isErasing;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isErasing ? Colors.red : Colors.grey[200],
                          foregroundColor:
                              _isErasing ? Colors.white : Colors.grey[800],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            Text(_isErasing ? 'Drawing Mode' : 'Eraser Mode'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _points.clear();
                            _progress = 0;
                            widget.onProgressUpdate(_progress);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E88E5),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Clear Canvas'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    // Calculate progress based on number of points drawn
    final newProgress = (_points.length * 100 / 1000).clamp(0, 100).toInt();
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
      });
      widget.onProgressUpdate(_progress);
    }
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isErasing = false;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class DrawingActivity extends StatefulWidget {
  final Function(int) onProgressUpdate;

  const DrawingActivity({Key? key, required this.onProgressUpdate})
      : super(key: key);

  @override
  State<DrawingActivity> createState() => _DrawingActivityState();
}

class _DrawingActivityState extends State<DrawingActivity> {
  Color _selectedColor = Colors.blue;
  double _brushSize = 5.0;
  List<DrawingPoint?> _points = [];
  bool _isErasing = false;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Canvas
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = _isErasing ? Colors.white : _selectedColor
                          ..strokeCap = StrokeCap.round
                          ..strokeWidth = _brushSize,
                      ),
                    );
                    _updateProgress();
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = _isErasing ? Colors.white : _selectedColor
                          ..strokeCap = StrokeCap.round
                          ..strokeWidth = _brushSize,
                      ),
                    );
                    _updateProgress();
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(null);
                  });
                },
                child: CustomPaint(
                  painter: DrawingPainter(_points),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Tools
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Color Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildColorButton(Colors.red),
                    _buildColorButton(Colors.blue),
                    _buildColorButton(Colors.green),
                    _buildColorButton(Colors.yellow),
                    _buildColorButton(Colors.purple),
                    _buildColorButton(Colors.orange),
                  ],
                ),

                SizedBox(height: 16),

                // Brush Size Slider
                Row(
                  children: [
                    Icon(Icons.brush, color: Color(0xFF1E88E5)),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _brushSize.round().toString(),
                        onChanged: (value) {
                          setState(() {
                            _brushSize = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isErasing = !_isErasing;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isErasing ? Colors.red : Colors.grey[200],
                          foregroundColor:
                              _isErasing ? Colors.white : Colors.grey[800],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            Text(_isErasing ? 'Drawing Mode' : 'Eraser Mode'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _points.clear();
                            _progress = 0;
                            widget.onProgressUpdate(_progress);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E88E5),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Clear Canvas'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    // Calculate progress based on number of points drawn
    final newProgress = (_points.length * 100 / 1000).clamp(0, 100).toInt();
    if (newProgress != _progress) {
      setState(() {
        _progress = newProgress;
      });
      widget.onProgressUpdate(_progress);
    }
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isErasing = false;
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class DrawingPoint {
  Offset offset;
  Paint paint;

  DrawingPoint(this.offset, this.paint);
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(
            points[i]!.offset, points[i + 1]!.offset, points[i]!.paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(
            PointMode.points, [points[i]!.offset], points[i]!.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
