import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking

class ColorMePage extends StatefulWidget {
  const ColorMePage({super.key});

  // Add route name to make navigation easier
  static const routeName = '/color-me';

  @override
  State<ColorMePage> createState() => _ColorMePageState();
}

class _ColorMePageState extends State<ColorMePage> {
  // Current drawing properties
  Color currentColor = Colors.black;
  double currentStrokeWidth = 8.0;

  // Store drawing points
  final List<DrawingPoint?> points = [];

  // Colors for bird parts
  final Color bodyColor = Colors.white;
  final Color leaf1Color = Colors.green;
  final Color leaf2Color = Colors.green;
  final Color eyeColor = Colors.black;

  // Available colors for selection
  final List<Color> colorPalette = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
    Colors.white,
    Colors.black,
  ];

  // Available brush sizes
  final List<double> brushSizes = [2.0, 4.0, 8.0, 12.0, 16.0];

  // Reference to the drawing area key
  final GlobalKey _drawingAreaKey = GlobalKey();

  // Fixed dimensions for the bird canvas
  final Size birdCanvasSize = const Size(300, 400);

  @override
  void initState() {
    super.initState();

    // Track this page visit in recent activities
    _trackActivity();
  }

  // Method to track activity
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Digital Coloring',
        imagePath: 'assets/Activity_Tools/coloring-sheet.png',
        timestamp: DateTime.now(),
        routeName: ColorMePage.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Me'),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear drawing',
            onPressed: () {
              setState(() {
                points.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing area
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                key: _drawingAreaKey,
                width: birdCanvasSize.width,
                height: birdCanvasSize.height,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: (details) {
                      final RenderBox renderBox =
                          _drawingAreaKey.currentContext!.findRenderObject()
                              as RenderBox;
                      final Offset localPosition =
                          renderBox.globalToLocal(details.globalPosition);

                      // Get the position in the bird's coordinate system
                      final adjustedPosition = _adjustTouchPosition(
                          localPosition, constraints.biggest);

                      // If touching inside body area and not in leaves
                      if (_isInsideBirdBody(
                              adjustedPosition, constraints.biggest) &&
                          !_isInsideLeaves(
                              adjustedPosition, constraints.biggest)) {
                        setState(() {
                          points.add(DrawingPoint(
                            localPosition, // Use the original position for drawing
                            Paint()
                              ..color = currentColor
                              ..strokeWidth = currentStrokeWidth
                              ..strokeCap = StrokeCap.round
                              ..strokeJoin = StrokeJoin.round
                              ..style = PaintingStyle.stroke,
                          ));
                        });
                      }
                    },
                    onPanUpdate: (details) {
                      final RenderBox renderBox =
                          _drawingAreaKey.currentContext!.findRenderObject()
                              as RenderBox;
                      final Offset localPosition =
                          renderBox.globalToLocal(details.globalPosition);

                      // Get the position in the bird's coordinate system
                      final adjustedPosition = _adjustTouchPosition(
                          localPosition, constraints.biggest);

                      // If touching inside body area and not in leaves
                      if (_isInsideBirdBody(
                              adjustedPosition, constraints.biggest) &&
                          !_isInsideLeaves(
                              adjustedPosition, constraints.biggest)) {
                        setState(() {
                          points.add(DrawingPoint(
                            localPosition, // Use the original position for drawing
                            Paint()
                              ..color = currentColor
                              ..strokeWidth = currentStrokeWidth
                              ..strokeCap = StrokeCap.round
                              ..strokeJoin = StrokeJoin.round
                              ..style = PaintingStyle.stroke,
                          ));
                        });
                      }
                    },
                    onPanEnd: (details) {
                      // Add null to indicate the end of a stroke
                      setState(() {
                        points.add(null);
                      });
                    },
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // Bird filled with colors
                          CustomPaint(
                            size: constraints.biggest,
                            painter: BirdColorPainter(
                              bodyColor: bodyColor,
                              leaf1Color: leaf1Color,
                              leaf2Color: leaf2Color,
                              eyeColor: eyeColor,
                            ),
                          ),
                          // Drawing layer with direct positioning
                          CustomPaint(
                            size: constraints.biggest,
                            painter: DrawingPainter(
                              drawingPoints: points,
                              birdBodyPath: getTransformedBirdBodyPath(
                                  constraints.biggest),
                            ),
                          ),
                          // Bird outline (drawn on top so it's always visible)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: BirdOutlinePainter(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Info text

          // Brush size selection
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brushSizes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentStrokeWidth = brushSizes[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentStrokeWidth == brushSizes[index]
                            ? Colors.black
                            : Colors.grey,
                        width: currentStrokeWidth == brushSizes[index] ? 3 : 1,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: brushSizes[index],
                        height: brushSizes[index],
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Color palette
          Container(
            height: 60,
            margin: const EdgeInsets.all(16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: colorPalette.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentColor = colorPalette[index];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorPalette[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentColor == colorPalette[index]
                            ? Colors.black
                            : Colors.grey,
                        width: currentColor == colorPalette[index] ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Transform position from screen coordinates to bird coordinate system
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    // Calculate scale and translation factors based on bird paths
    final double scale =
        math.min(containerSize.width / 500, containerSize.height / 600);
    final double translateX = (containerSize.width / scale - 460) / 2;
    final double translateY = (containerSize.height / scale - 565) / 2;

    // Apply inverse transformation to get bird coordinates
    final double birdX = position.dx / scale - translateX;
    final double birdY = position.dy / scale - translateY;

    return Offset(birdX, birdY);
  }

  // Check if touch is inside the bird body path
  bool _isInsideBirdBody(Offset position, Size containerSize) {
    // Apply same transformation to position as used in the getBirdPath method
    // We already transformed it in _adjustTouchPosition, so use that

    // Get the untransformed bird path
    final Path birdPath = getBirdPath();

    // Check if the adjusted position is inside the untransformed path
    return birdPath.contains(position);
  }

  // Check if touch is inside the leaves
  bool _isInsideLeaves(Offset position, Size containerSize) {
    // Since position is already in bird coordinates from _adjustTouchPosition
    // Check if inside leaf 1
    final leaf1Path = getLeaf1Path();
    if (leaf1Path.contains(position)) {
      return true;
    }

    // Check if inside leaf 2
    final leaf2Path = getLeaf2Path();
    if (leaf2Path.contains(position)) {
      return true;
    }

    // Check if inside eye
    final eyePath = getEyePath();
    if (eyePath.contains(position)) {
      return true;
    }

    return false;
  }

  // Get the transformed bird body path for clipping
  Path getTransformedBirdBodyPath(Size size) {
    final Path birdPath = getBirdPath();

    // Apply transformation to fit the path to our canvas size
    final double scale = math.min(size.width / 500, size.height / 600);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    return birdPath.transform(matrix.storage);
  }

  // Create the bird path
  Path getBirdPath() {
    // Define body path
    final Path bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    return bodyPath;
  }

  // Create the leaves and eye paths
  Path getLeaf1Path() {
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();
    return leaf1Path;
  }

  Path getLeaf2Path() {
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();
    return leaf2Path;
  }

  Path getEyePath() {
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();
    return eyePath;
  }
}

// Class to represent a drawing point with its properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

// Painter for coloring the bird parts with fill colors
class BirdColorPainter extends CustomPainter {
  final Color bodyColor;
  final Color leaf1Color;
  final Color leaf2Color;
  final Color eyeColor;

  BirdColorPainter({
    required this.bodyColor,
    required this.leaf1Color,
    required this.leaf2Color,
    required this.eyeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 500, size.height / 600);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    // Draw body with fill color
    final bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    // Fill body
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw leaf1 with fill color
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();

    // Fill leaf1
    final leaf1Paint = Paint()
      ..color = leaf1Color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf1Path, leaf1Paint);

    // Draw leaf2 with fill color
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();

    // Fill leaf2
    final leaf2Paint = Paint()
      ..color = leaf2Color
      ..style = PaintingStyle.fill;
    canvas.drawPath(leaf2Path, leaf2Paint);

    // Draw eye with fill color
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();

    // Fill eye
    final eyePaint = Paint()
      ..color = eyeColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(eyePath, eyePaint);
  }

  @override
  bool shouldRepaint(covariant BirdColorPainter oldDelegate) => false;
}

// Painter for drawing the bird outline
class BirdOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 500, size.height / 600);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 460) / 2, (size.height / scale - 565) / 2);

    // Draw body outline
    final bodyPath = Path();
    bodyPath.moveTo(131, 565);
    bodyPath.cubicTo(211.486, 550.724, 244.099, 525.773, 243, 401);
    bodyPath.lineTo(463, 401);
    bodyPath.lineTo(463, 345);
    bodyPath.lineTo(243, 345);
    bodyPath.cubicTo(314.242, 338.325, 357, 319, 357, 233);
    bodyPath.lineTo(357, 123);
    bodyPath.cubicTo(350.432, 43.1455, 331, 3, 243, 3);
    bodyPath.cubicTo(155, 3, 140.537, 61.1833, 131, 123);
    bodyPath.lineTo(243, 123);
    bodyPath.cubicTo(152.379, 134.663, 124.399, 177.736, 131, 345);
    bodyPath.lineTo(83, 345);
    bodyPath.lineTo(83, 401);
    bodyPath.lineTo(131, 401);
    bodyPath.lineTo(131, 565);
    bodyPath.close();

    // Draw body outline
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(bodyPath, borderPaint);

    // Draw leaf1 outline
    final leaf1Path = Path();
    leaf1Path.moveTo(35, 307);
    leaf1Path.cubicTo(66.3736, 331.82, 82.7771, 336.558, 111, 337);
    leaf1Path.cubicTo(114.435, 311.303, 107.346, 295.535, 79, 265);
    leaf1Path.cubicTo(49.917, 236.745, 33.6988, 227.977, 4.99996, 231);
    leaf1Path.cubicTo(-0.887, 267.713, 10.397, 282.47, 35, 307);
    leaf1Path.close();
    canvas.drawPath(leaf1Path, borderPaint);

    // Draw leaf2 outline
    final leaf2Path = Path();
    leaf2Path.moveTo(287, 437);
    leaf2Path.cubicTo(316.798, 408.935, 333.419, 404.463, 363, 405);
    leaf2Path.cubicTo(362.85, 436.539, 359.554, 453.901, 335, 483);
    leaf2Path.cubicTo(304.337, 504.982, 287.215, 513.764, 257, 513);
    leaf2Path.cubicTo(253.474, 482.935, 254.924, 466.166, 287, 437);
    leaf2Path.close();
    canvas.drawPath(leaf2Path, borderPaint);

    // Draw eye
    final eyePath = Path();
    eyePath.moveTo(274, 88.5);
    eyePath.cubicTo(274, 95.4036, 268.404, 101, 261.5, 101);
    eyePath.cubicTo(254.596, 101, 249, 95.4036, 249, 88.5);
    eyePath.cubicTo(249, 81.5964, 254.596, 76, 261.5, 76);
    eyePath.cubicTo(268.404, 76, 274, 81.5964, 274, 88.5);
    eyePath.close();
    canvas.drawPath(eyePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the user's strokes
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Path birdBodyPath;

  DrawingPainter({
    required this.drawingPoints,
    required this.birdBodyPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the bird body only
    canvas.clipPath(birdBodyPath);

    // Draw all the points
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        // Draw a line between consecutive points
        canvas.drawLine(
          drawingPoints[i]!.offset,
          drawingPoints[i + 1]!.offset,
          drawingPoints[i]!.paint,
        );
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        // Draw a single point as a circle
        canvas.drawCircle(
          drawingPoints[i]!.offset,
          drawingPoints[i]!.paint.strokeWidth / 2,
          drawingPoints[i]!.paint,
        );
      }
    }

    // Restore the canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
