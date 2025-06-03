import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' show PointMode;

class DrawingActivity extends StatefulWidget {
  const DrawingActivity({Key? key}) : super(key: key);

  @override
  State<DrawingActivity> createState() => _DrawingActivityState();
}

class _DrawingActivityState extends State<DrawingActivity> {
  Color _selectedColor = Colors.blue;
  double _brushSize = 5.0;
  List<DrawingPoint?> _points = [];
  bool _isErasing = false;
  List<Color> _colorHistory = [];
  List<List<DrawingPoint?>> _undoHistory = [];

  @override
  void initState() {
    super.initState();
    _loadColorHistory();
  }

  Future<void> _loadColorHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final colorStrings = prefs.getStringList('drawing_color_history') ?? [];
    setState(() {
      _colorHistory = colorStrings
          .map((colorString) => Color(int.parse(colorString)))
          .toList();
      if (_colorHistory.isNotEmpty) {
        _selectedColor = _colorHistory.first;
      }
    });
  }

  Future<void> _saveColorHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final colorStrings =
        _colorHistory.map((color) => color.value.toString()).toList();
    await prefs.setStringList('drawing_color_history', colorStrings);
  }

  void _addToColorHistory(Color color) {
    setState(() {
      _colorHistory.remove(color);
      _colorHistory.insert(0, color);
      if (_colorHistory.length > 10) {
        _colorHistory.removeLast();
      }
    });
    _saveColorHistory();
  }

  void _undo() {
    if (_undoHistory.isNotEmpty) {
      setState(() {
        _points = _undoHistory.removeLast();
      });
    }
  }

  void _clearCanvas() {
    setState(() {
      _undoHistory.add(List.from(_points));
      _points.clear();
    });
  }

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
                    _undoHistory.add(List.from(_points));
                    _points.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = _isErasing ? Colors.white : _selectedColor
                          ..strokeCap = StrokeCap.round
                          ..strokeWidth = _brushSize,
                      ),
                    );
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

                // Color History
                if (_colorHistory.isNotEmpty) ...[
                  Container(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colorHistory.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColor = _colorHistory[index];
                                _isErasing = false;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: _colorHistory[index],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == _colorHistory[index]
                                      ? Colors.black
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                ],

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
                        onPressed: _undo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.grey[800],
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Undo'),
                      ),
                    ),
                    SizedBox(width: 16),
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
                        onPressed: _clearCanvas,
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

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
          _isErasing = false;
          _addToColorHistory(color);
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
