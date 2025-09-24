import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/nav_logpage.dart';
import '../pages/coloring_success_page.dart';

class FigureColorPage extends StatefulWidget {
  const FigureColorPage({super.key});

  @override
  State<FigureColorPage> createState() => _FigureColorPageState();
}

class _FigureColorPageState extends State<FigureColorPage> with TickerProviderStateMixin {
  // Current drawing properties
  Color currentColor = Colors.black;
  double currentStrokeWidth = 8.0;

  // Store drawing points
  final List<DrawingPoint?> points = [];

  // Animation controllers for progress bar
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Colors for figure parts
  final Color bodyColor = Colors.white;
  final Color eyeColor = Colors.black;
  final Color noseColor = Colors.black;

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

  // Fixed dimensions for the figure canvas
  final Size figureCanvasSize = const Size(300, 600);

  // Eyes and nose will always be black

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: 0.75, // 75% progress for figure coloring page
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

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Figure Coloring',
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
          
          // Clear button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
          ),
          
          // Drawing area
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                key: _drawingAreaKey,
                width: figureCanvasSize.width,
                height: figureCanvasSize.height,
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

                      // Get the position in the figure's coordinate system
                      final adjustedPosition = _adjustTouchPosition(
                          localPosition, constraints.biggest);

                      // If touching inside body area and not in features
                      if (_isInsideFigureBody(
                              adjustedPosition, constraints.biggest) &&
                          !_isInsideFeatures(
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

                      // Get the position in the figure's coordinate system
                      final adjustedPosition = _adjustTouchPosition(
                          localPosition, constraints.biggest);

                      // If touching inside body area and not in features
                      if (_isInsideFigureBody(
                              adjustedPosition, constraints.biggest) &&
                          !_isInsideFeatures(
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
                          // Figure filled with colors
                          CustomPaint(
                            size: constraints.biggest,
                            painter: FigureColorPainter(
                              bodyColor: bodyColor,
                              eyeColor: eyeColor,
                              noseColor: noseColor,
                            ),
                          ),
                          // Drawing layer with direct positioning
                          CustomPaint(
                            size: constraints.biggest,
                            painter: DrawingPainter(
                              drawingPoints: points,
                              figurePath:
                                  getTransformedFigurePath(constraints.biggest),
                            ),
                          ),
                          // Figure outline (drawn on top so it's always visible)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: FigureOutlinePainter(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Info text=

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

          // Next button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ColoringSuccessPage(
                        toolName: 'Figure Coloring',
                        nextToolName: 'Face Coloring',
                        nextToolRoute: '/face-coloring',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF23C4F7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Transform position from screen coordinates to figure coordinate system
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    // Calculate scale and translation factors based on figure paths
    final double scale =
        math.min(containerSize.width / 191, containerSize.height / 511);
    final double translateX = (containerSize.width - 191 * scale) / 2;
    final double translateY = (containerSize.height - 511 * scale) / 2;

    // Apply inverse transformation to get figure coordinates
    final double figureX = (position.dx - translateX) / scale;
    final double figureY = (position.dy - translateY) / scale;

    return Offset(figureX, figureY);
  }

  // Check if touch is inside the figure body path
  bool _isInsideFigureBody(Offset position, Size containerSize) {
    // Get the untransformed figure path
    final Path figurePath = getFigurePath();

    // Check if the adjusted position is inside the untransformed path
    return figurePath.contains(position);
  }

  // Check if touch is inside the features (eyes, nose)
  bool _isInsideFeatures(Offset position, Size containerSize) {
    // Check if inside eyes
    final eyePath = getEyesPath();
    if (eyePath.contains(position)) {
      return true;
    }

    // Check if inside nose
    final nosePath = getNosePath();
    if (nosePath.contains(position)) {
      return true;
    }

    return false;
  }

  // Get the transformed figure path for clipping
  Path getTransformedFigurePath(Size size) {
    final Path figurePath = getFigurePath();

    // Apply transformation to fit the path to our canvas size
    final double scale = math.min(size.width / 191, size.height / 511);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 191) / 2, (size.height / scale - 511) / 2);

    return figurePath.transform(matrix.storage);
  }

  // Create the figure path
  Path getFigurePath() {
    final Path bodyPath = Path();
    // Main figure outline from the SVG
    bodyPath.moveTo(9.13435, 435.757);
    bodyPath.lineTo(9.13435, 506);
    bodyPath.lineTo(22.108, 506);
    bodyPath.lineTo(22.108, 435.757);
    bodyPath.lineTo(50.9385, 435.757);
    bodyPath.lineTo(50.9385, 506);
    bodyPath.lineTo(59.5876, 506);
    bodyPath.lineTo(68.2367, 435.757);
    bodyPath.lineTo(97.0672, 435.757);
    bodyPath.lineTo(104.275, 506);
    bodyPath.lineTo(111.482, 506);
    bodyPath.lineTo(118.69, 435.757);
    bodyPath.lineTo(134.547, 435.757);
    bodyPath.lineTo(146.079, 506);
    bodyPath.lineTo(156.17, 506);
    bodyPath.lineTo(156.17, 53.4724);
    bodyPath.cubicTo(175.914, 57.2946, 183.53, 56.8096, 185, 46.7182);
    bodyPath.lineTo(156.17, 38.6133);
    bodyPath.lineTo(172.026, 23.7541);
    bodyPath.lineTo(156.17, 31.8591);
    bodyPath.lineTo(156.17, 17);
    bodyPath.lineTo(146.079, 31.8591);
    bodyPath.lineTo(127.339, 17);
    bodyPath.lineTo(134.547, 38.6133);
    bodyPath.lineTo(78.3274, 46.7182);
    bodyPath.cubicTo(78.3274, 46.7182, 50.9385, 46.7182, 50.9385, 61.5774);
    bodyPath.cubicTo(50.9385, 76.4365, 67.6314, 73.2587, 78.3274, 61.5774);
    bodyPath.lineTo(127.339, 79.1381);
    bodyPath.cubicTo(127.339, 79.1381, 111.482, 268.254, 104.275, 284.464);
    bodyPath.cubicTo(97.0672, 300.674, 78.3274, 324.989, 78.3274, 324.989);
    bodyPath.lineTo(32.1987, 357.409);
    bodyPath.cubicTo(4.2191, 370.92, 0.456353, 389.235, 9.13435, 435.757);
    bodyPath.close();

    return bodyPath;
  }

  // Create the eyes path
  Path getEyesPath() {
    final eyesPath = Path();
    // Eyes path from the SVG
    eyesPath.moveTo(124.456, 56.174);
    eyesPath.cubicTo(133.105, 64.279, 141.754, 56.174, 141.754, 56.174);

    // Make the path area larger for better hit detection
    eyesPath.addRect(Rect.fromLTRB(115, 45, 150, 70));

    return eyesPath;
  }

  // Create the nose path
  Path getNosePath() {
    final nosePath = Path();
    // Nose path from the SVG
    nosePath.moveTo(67.3537, 59.5511);
    nosePath.cubicTo(67.3537, 61.4162, 65.7402, 62.9282, 63.7499, 62.9282);
    nosePath.cubicTo(61.7595, 62.9282, 60.1461, 61.4162, 60.1461, 59.5511);
    nosePath.cubicTo(60.1461, 57.686, 61.7595, 56.174, 63.7499, 56.174);
    nosePath.cubicTo(65.7402, 56.174, 67.3537, 57.686, 67.3537, 59.5511);
    nosePath.close();

    // Add padding around the nose for better hit detection
    nosePath.addOval(
        Rect.fromCenter(center: Offset(63.75, 59.55), width: 15, height: 15));

    return nosePath;
  }
}

// Class to represent a drawing point with its properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

// Painter for coloring the figure parts with fill colors
class FigureColorPainter extends CustomPainter {
  final Color bodyColor;
  final Color eyeColor;
  final Color noseColor;

  FigureColorPainter({
    required this.bodyColor,
    required this.eyeColor,
    required this.noseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 191, size.height / 511);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 191) / 2, (size.height / scale - 511) / 2);

    // Draw body with fill color
    final bodyPath = Path();
    bodyPath.moveTo(9.13435, 435.757);
    bodyPath.lineTo(9.13435, 506);
    bodyPath.lineTo(22.108, 506);
    bodyPath.lineTo(22.108, 435.757);
    bodyPath.lineTo(50.9385, 435.757);
    bodyPath.lineTo(50.9385, 506);
    bodyPath.lineTo(59.5876, 506);
    bodyPath.lineTo(68.2367, 435.757);
    bodyPath.lineTo(97.0672, 435.757);
    bodyPath.lineTo(104.275, 506);
    bodyPath.lineTo(111.482, 506);
    bodyPath.lineTo(118.69, 435.757);
    bodyPath.lineTo(134.547, 435.757);
    bodyPath.lineTo(146.079, 506);
    bodyPath.lineTo(156.17, 506);
    bodyPath.lineTo(156.17, 53.4724);
    bodyPath.cubicTo(175.914, 57.2946, 183.53, 56.8096, 185, 46.7182);
    bodyPath.lineTo(156.17, 38.6133);
    bodyPath.lineTo(172.026, 23.7541);
    bodyPath.lineTo(156.17, 31.8591);
    bodyPath.lineTo(156.17, 17);
    bodyPath.lineTo(146.079, 31.8591);
    bodyPath.lineTo(127.339, 17);
    bodyPath.lineTo(134.547, 38.6133);
    bodyPath.lineTo(78.3274, 46.7182);
    bodyPath.cubicTo(78.3274, 46.7182, 50.9385, 46.7182, 50.9385, 61.5774);
    bodyPath.cubicTo(50.9385, 76.4365, 67.6314, 73.2587, 78.3274, 61.5774);
    bodyPath.lineTo(127.339, 79.1381);
    bodyPath.cubicTo(127.339, 79.1381, 111.482, 268.254, 104.275, 284.464);
    bodyPath.cubicTo(97.0672, 300.674, 78.3274, 324.989, 78.3274, 324.989);
    bodyPath.lineTo(32.1987, 357.409);
    bodyPath.cubicTo(4.2191, 370.92, 0.456353, 389.235, 9.13435, 435.757);
    bodyPath.close();

    // Fill body
    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw eyes
    final eyesPath = Path();
    eyesPath.moveTo(124.456, 56.174);
    eyesPath.cubicTo(133.105, 64.279, 141.754, 56.174, 141.754, 56.174);

    // Fill eyes - always use _permanentEyeColor instead of eyeColor
    final eyesPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyesPath, eyesPaint);

    // Draw nose
    final nosePath = Path();
    nosePath.moveTo(67.3537, 59.5511);
    nosePath.cubicTo(67.3537, 61.4162, 65.7402, 62.9282, 63.7499, 62.9282);
    nosePath.cubicTo(61.7595, 62.9282, 60.1461, 61.4162, 60.1461, 59.5511);
    nosePath.cubicTo(60.1461, 57.686, 61.7595, 56.174, 63.7499, 56.174);
    nosePath.cubicTo(65.7402, 56.174, 67.3537, 57.686, 67.3537, 59.5511);
    nosePath.close();

    // Fill nose - always use _permanentNoseColor instead of noseColor
    final nosePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(nosePath, nosePaint);
  }

  @override
  bool shouldRepaint(covariant FigureColorPainter oldDelegate) => false;
}

// Painter for drawing the figure outline
class FigureOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 191, size.height / 511);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 191) / 2, (size.height / scale - 511) / 2);

    // Draw body outline
    final bodyPath = Path();
    bodyPath.moveTo(9.13435, 435.757);
    bodyPath.lineTo(9.13435, 506);
    bodyPath.lineTo(22.108, 506);
    bodyPath.lineTo(22.108, 435.757);
    bodyPath.lineTo(50.9385, 435.757);
    bodyPath.lineTo(50.9385, 506);
    bodyPath.lineTo(59.5876, 506);
    bodyPath.lineTo(68.2367, 435.757);
    bodyPath.lineTo(97.0672, 435.757);
    bodyPath.lineTo(104.275, 506);
    bodyPath.lineTo(111.482, 506);
    bodyPath.lineTo(118.69, 435.757);
    bodyPath.lineTo(134.547, 435.757);
    bodyPath.lineTo(146.079, 506);
    bodyPath.lineTo(156.17, 506);
    bodyPath.lineTo(156.17, 53.4724);
    bodyPath.cubicTo(175.914, 57.2946, 183.53, 56.8096, 185, 46.7182);
    bodyPath.lineTo(156.17, 38.6133);
    bodyPath.lineTo(172.026, 23.7541);
    bodyPath.lineTo(156.17, 31.8591);
    bodyPath.lineTo(156.17, 17);
    bodyPath.lineTo(146.079, 31.8591);
    bodyPath.lineTo(127.339, 17);
    bodyPath.lineTo(134.547, 38.6133);
    bodyPath.lineTo(78.3274, 46.7182);
    bodyPath.cubicTo(78.3274, 46.7182, 50.9385, 46.7182, 50.9385, 61.5774);
    bodyPath.cubicTo(50.9385, 76.4365, 67.6314, 73.2587, 78.3274, 61.5774);
    bodyPath.lineTo(127.339, 79.1381);
    bodyPath.cubicTo(127.339, 79.1381, 111.482, 268.254, 104.275, 284.464);
    bodyPath.cubicTo(97.0672, 300.674, 78.3274, 324.989, 78.3274, 324.989);
    bodyPath.lineTo(32.1987, 357.409);
    bodyPath.cubicTo(4.2191, 370.92, 0.456353, 389.235, 9.13435, 435.757);
    bodyPath.close();

    // Draw body outline
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(bodyPath, borderPaint);

    // Draw eyes
    final eyesPath = Path();
    eyesPath.moveTo(124.456, 56.174);
    eyesPath.cubicTo(133.105, 64.279, 141.754, 56.174, 141.754, 56.174);

    final eyesPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(eyesPath, eyesPaint);

    // Draw nose
    final nosePath = Path();
    nosePath.moveTo(67.3537, 59.5511);
    nosePath.cubicTo(67.3537, 61.4162, 65.7402, 62.9282, 63.7499, 62.9282);
    nosePath.cubicTo(61.7595, 62.9282, 60.1461, 61.4162, 60.1461, 59.5511);
    nosePath.cubicTo(60.1461, 57.686, 61.7595, 56.174, 63.7499, 56.174);
    nosePath.cubicTo(65.7402, 56.174, 67.3537, 57.686, 67.3537, 59.5511);
    nosePath.close();

    final nosePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(nosePath, nosePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the user's strokes
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Path figurePath;

  DrawingPainter({
    required this.drawingPoints,
    required this.figurePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the figure body only
    canvas.clipPath(figurePath);

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
