import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/nav_logpage.dart';
import '../pages/coloring_success_page.dart';

class ElephantColorPage extends StatefulWidget {
  const ElephantColorPage({super.key});

  @override
  State<ElephantColorPage> createState() => _ElephantColorPageState();
}

class _ElephantColorPageState extends State<ElephantColorPage> with TickerProviderStateMixin {
  // Current drawing properties
  Color currentColor = Colors.black;
  double currentStrokeWidth = 8.0;

  // Store drawing points
  final List<DrawingPoint?> points = [];

  // Animation controllers for progress bar
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Fixed colors for elephant parts - changed to static const to emphasize they're permanent
  static const Color bodyColor = Colors.white;
  static const Color earsColor = Colors.blue; // Blue color for ears
  static const Color tuskColor = Color(0xFFF9AEDA); // Pink color for tusk
  static const Color eyeColor = Colors.black;

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

  // Fixed dimensions for the elephant canvas
  final Size elephantCanvasSize = const Size(400, 300);

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
      end: 0.75, // 75% progress for elephant coloring page
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
      title: 'Elephant Coloring',
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
                width: elephantCanvasSize.width,
                height: elephantCanvasSize.height,
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
                      _handleDrawingGesture(
                          details.globalPosition, constraints);
                    },
                    onPanUpdate: (details) {
                      _handleDrawingGesture(
                          details.globalPosition, constraints);
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
                          // Elephant base color
                          CustomPaint(
                            size: constraints.biggest,
                            painter: ElephantBasePainter(),
                          ),
                          // Drawing layer with direct positioning
                          CustomPaint(
                            size: constraints.biggest,
                            painter: DrawingPainter(
                              drawingPoints: points,
                              elephantBodyPath: getTransformedElephantBodyPath(
                                  constraints.biggest),
                              protectedPaths: getTransformedProtectedPaths(
                                  constraints.biggest),
                            ),
                          ),
                          // Protected areas (ears, tusk, eyes) drawn on top to ensure they're always visible
                          CustomPaint(
                            size: constraints.biggest,
                            painter: ProtectedAreasPainter(),
                          ),
                          // Elephant outline (drawn on top so it's always visible)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: ElephantOutlinePainter(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

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
                        toolName: 'Elephant Coloring',
                        nextToolName: 'Bird Coloring',
                        nextToolRoute: '/bird-coloring',
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

  void _handleDrawingGesture(
      Offset globalPosition, BoxConstraints constraints) {
    final RenderBox renderBox =
        _drawingAreaKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(globalPosition);

    // Only process if touch is within the container bounds
    if (localPosition.dx < 0 ||
        localPosition.dy < 0 ||
        localPosition.dx > constraints.biggest.width ||
        localPosition.dy > constraints.biggest.height) {
      return;
    }

    // Get the position in the elephant's coordinate system
    final adjustedPosition =
        _adjustTouchPosition(localPosition, constraints.biggest);

    // Get the transformed paths
    final elephantBodyPath = getElephantBodyPath();
    final List<Path> protectedPaths = [
      getEarsPath(),
      getTuskPath(),
      getEyesPath(),
      getFrontLegPath(),
      getBackLegsPath(),
      getTrunkLegGapPath(), // Added the trunk-leg gap area
    ];

    // Check if inside body but not in protected areas
    if (elephantBodyPath.contains(adjustedPosition) &&
        !protectedPaths.any((path) => path.contains(adjustedPosition))) {
      setState(() {
        points.add(DrawingPoint(
          localPosition, // Use original position for drawing
          Paint()
            ..color = currentColor
            ..strokeWidth = currentStrokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke,
        ));
      });
    }
  }

  // Transform position from screen coordinates to elephant coordinate system
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    // Calculate scale and translation factors based on elephant paths
    final double scale =
        math.min(containerSize.width / 411, containerSize.height / 308);
    final double translateX = (containerSize.width / scale - 411) / 2;
    final double translateY = (containerSize.height / scale - 308) / 2;

    // Apply inverse transformation to get elephant coordinates
    final double elephantX = position.dx / scale - translateX;
    final double elephantY = position.dy / scale - translateY;

    return Offset(elephantX, elephantY);
  }

  // Get list of transformed protected paths
  List<Path> getTransformedProtectedPaths(Size size) {
    final double scale = math.min(size.width / 411, size.height / 308);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 411) / 2, (size.height / scale - 308) / 2);

    return [
      getEarsPath().transform(matrix.storage),
      getTuskPath().transform(matrix.storage),
      getEyesPath().transform(matrix.storage),
      getFrontLegPath().transform(matrix.storage),
      getBackLegsPath().transform(matrix.storage),
      getTrunkLegGapPath()
          .transform(matrix.storage), // Added the trunk-leg gap area
    ];
  }

  // Get the transformed elephant body path for clipping
  Path getTransformedElephantBodyPath(Size size) {
    final Path elephantPath = getElephantBodyPath();

    // Apply transformation to fit the path to our canvas size
    final double scale = math.min(size.width / 411, size.height / 308);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 411) / 2, (size.height / scale - 308) / 2);

    return elephantPath.transform(matrix.storage);
  }

  // Create the elephant body path
  Path getElephantBodyPath() {
    final Path bodyPath = Path();
    bodyPath.moveTo(313.789, 303);
    bodyPath.lineTo(323, 240);
    bodyPath.lineTo(357.789, 297);
    bodyPath.lineTo(405.789, 297);
    bodyPath.lineTo(397.789, 47);
    bodyPath.cubicTo(379.314, 16.7741, 364.468, 8.329, 331.789, 5);
    bodyPath.lineTo(105.789, 5);
    bodyPath.cubicTo(79.6853, 11.1094, 64.7804, 9.96394, 41.7893, 69);
    bodyPath.lineTo(41.7893, 151);
    bodyPath.cubicTo(36.7877, 162.033, -6.21068, 131, 7.78932, 151);
    bodyPath.cubicTo(21.7893, 171, 41.7893, 185, 41.7893, 185);
    bodyPath.lineTo(41.7893, 251);
    bodyPath.cubicTo(44.5021, 288.032, 57.7978, 297.081, 91.7893, 303);
    bodyPath.lineTo(175.789, 303);
    bodyPath.lineTo(191.789, 231);
    bodyPath.lineTo(211.789, 303);
    bodyPath.lineTo(313.789, 303);
    bodyPath.close();
    return bodyPath;
  }

  // Create the ears path
  Path getEarsPath() {
    final Path earsPath = Path();
    earsPath.moveTo(135, 7);
    earsPath.cubicTo(295, 7.00006, 301, 187, 135, 203);
    earsPath.lineTo(135, 7);
    earsPath.close();
    return earsPath;
  }

  // Create the tusk path
  Path getTuskPath() {
    final Path tuskPath = Path();
    tuskPath.moveTo(14, 146);
    tuskPath.cubicTo(57.6481, 176.757, 84.2423, 179.703, 134, 169.301);
    tuskPath.lineTo(134, 200.369);
    tuskPath.cubicTo(70.6439, 208.975, 43.9305, 197.876, 14, 146);
    tuskPath.close();
    return tuskPath;
  }

  // Create the eyes path
  Path getEyesPath() {
    final Path eyesPath = Path();
    eyesPath
        .addOval(Rect.fromCircle(center: const Offset(82.5, 130), radius: 10));
    return eyesPath;
  }

  // Create the front leg path
  Path getFrontLegPath() {
    final Path frontLegPath = Path();
    // Make the leg width match the stroke width of 15
    double legWidth = 7.5; // Half the stroke width
    frontLegPath
        .addRect(Rect.fromLTRB(135 - legWidth, 203, 135 + legWidth, 303));
    return frontLegPath;
  }

  // Create the back legs path
  Path getBackLegsPath() {
    final Path backLegsPath = Path();
    // Horizontal leg
    backLegsPath.addRect(Rect.fromLTRB(188, 228.5, 321, 233.5));
    // Vertical leg
    backLegsPath.addRect(Rect.fromLTRB(252, 231, 257, 303));
    return backLegsPath;
  }

  // Create a path for the gap between trunk and leg
  Path getTrunkLegGapPath() {
    final Path gapPath = Path();
    // Define a polygon for the gap area between trunk and leg
    gapPath.moveTo(134.525, 203);
    gapPath.lineTo(134.525, 268);
    gapPath.lineTo(91.7893, 303);
    gapPath.lineTo(175.789, 303);
    gapPath.lineTo(191.789, 231);
    gapPath.lineTo(134.525, 203);
    gapPath.close();
    return gapPath;
  }
}

// Class to represent a drawing point with its properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

// Painter for the elephant base color (white body)
class ElephantBasePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 411, size.height / 308);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 411) / 2, (size.height / scale - 308) / 2);

    // Draw body with white fill color
    final bodyPath = Path();
    bodyPath.moveTo(313.789, 303);
    bodyPath.lineTo(323, 240);
    bodyPath.lineTo(357.789, 297);
    bodyPath.lineTo(405.789, 297);
    bodyPath.lineTo(397.789, 47);
    bodyPath.cubicTo(379.314, 16.7741, 364.468, 8.329, 331.789, 5);
    bodyPath.lineTo(105.789, 5);
    bodyPath.cubicTo(79.6853, 11.1094, 64.7804, 9.96394, 41.7893, 69);
    bodyPath.lineTo(41.7893, 151);
    bodyPath.cubicTo(36.7877, 162.033, -6.21068, 131, 7.78932, 151);
    bodyPath.cubicTo(21.7893, 171, 41.7893, 185, 41.7893, 185);
    bodyPath.lineTo(41.7893, 251);
    bodyPath.cubicTo(44.5021, 288.032, 57.7978, 297.081, 91.7893, 303);
    bodyPath.lineTo(175.789, 303);
    bodyPath.lineTo(191.789, 231);
    bodyPath.lineTo(211.789, 303);
    bodyPath.lineTo(313.789, 303);
    bodyPath.close();

    // Fill entire body with white first
    final bodyPaint = Paint()
      ..color = _ElephantColorPageState.bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bodyPath, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for protected areas that should be drawn on top and can't be colored
class ProtectedAreasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 411, size.height / 308);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 411) / 2, (size.height / scale - 308) / 2);

    // Draw ears with blue fill
    final earsPath = Path();
    earsPath.moveTo(135, 7);
    earsPath.cubicTo(295, 7.00006, 301, 187, 135, 203);
    earsPath.lineTo(135, 7);
    earsPath.close();

    final earsPaint = Paint()
      ..color = _ElephantColorPageState.earsColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(earsPath, earsPaint);

    // Draw tusk with pink fill
    final tuskPath = Path();
    tuskPath.moveTo(14, 146);
    tuskPath.cubicTo(57.6481, 176.757, 84.2423, 179.703, 134, 169.301);
    tuskPath.lineTo(134, 200.369);
    tuskPath.cubicTo(70.6439, 208.975, 43.9305, 197.876, 14, 146);
    tuskPath.close();

    final tuskPaint = Paint()
      ..color = _ElephantColorPageState.tuskColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(tuskPath, tuskPaint);

    // Draw eyes with black fill
    final eyesPath = Path();
    eyesPath
        .addOval(Rect.fromCircle(center: const Offset(82.5, 130), radius: 10));

    final eyesPaint = Paint()
      ..color = _ElephantColorPageState.eyeColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(eyesPath, eyesPaint);

    // Draw front leg
    final frontLegPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    canvas.drawLine(
        const Offset(135, 203), const Offset(135, 303), frontLegPaint);

    // Draw back legs
    final backLegsPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawLine(
        const Offset(188, 231), const Offset(254.5, 231), backLegsPaint);
    canvas.drawLine(
        const Offset(321, 231), const Offset(254.5, 231), backLegsPaint);
    canvas.drawLine(
        const Offset(254.5, 231), const Offset(254.5, 303), backLegsPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the elephant outline
class ElephantOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 411, size.height / 308);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 411) / 2, (size.height / scale - 308) / 2);

    // Define the border paint style
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Draw body outline
    final bodyPath = Path();
    bodyPath.moveTo(313.789, 303);
    bodyPath.lineTo(323, 240);
    bodyPath.lineTo(357.789, 297);
    bodyPath.lineTo(405.789, 297);
    bodyPath.lineTo(397.789, 47);
    bodyPath.cubicTo(379.314, 16.7741, 364.468, 8.329, 331.789, 5);
    bodyPath.lineTo(105.789, 5);
    bodyPath.cubicTo(79.6853, 11.1094, 64.7804, 9.96394, 41.7893, 69);
    bodyPath.lineTo(41.7893, 151);
    bodyPath.cubicTo(36.7877, 162.033, -6.21068, 131, 7.78932, 151);
    bodyPath.cubicTo(21.7893, 171, 41.7893, 185, 41.7893, 185);
    bodyPath.lineTo(41.7893, 251);
    bodyPath.cubicTo(44.5021, 288.032, 57.7978, 297.081, 91.7893, 303);
    bodyPath.lineTo(175.789, 303);
    bodyPath.lineTo(191.789, 231);
    bodyPath.lineTo(211.789, 303);
    bodyPath.lineTo(313.789, 303);
    bodyPath.close();
    canvas.drawPath(bodyPath, borderPaint);

    // Draw ears outline
    final earsPath = Path();
    earsPath.moveTo(135, 7);
    earsPath.cubicTo(295, 7.00006, 301, 187, 135, 203);
    earsPath.lineTo(135, 7);
    earsPath.close();
    canvas.drawPath(earsPath, borderPaint);

    // Draw trunk outline
    final trunkPath = Path();
    trunkPath.moveTo(134.525, 203);
    trunkPath.cubicTo(128.435, 212.491, 114.797, 210.146, 86.5249, 203);
    trunkPath.cubicTo(69.1628, 273.038, 75.1267, 277.118, 134.525, 268);
    canvas.drawPath(trunkPath, borderPaint);

    // Draw tusk outline
    final tuskPath = Path();
    tuskPath.moveTo(14, 146);
    tuskPath.cubicTo(57.6481, 176.757, 84.2423, 179.703, 134, 169.301);
    tuskPath.lineTo(134, 200.369);
    tuskPath.cubicTo(70.6439, 208.975, 43.9305, 197.876, 14, 146);
    tuskPath.close();
    canvas.drawPath(tuskPath, borderPaint);

    // Draw eyes outline
    final eyesPath = Path();
    eyesPath
        .addOval(Rect.fromCircle(center: const Offset(82.5, 130), radius: 10));
    canvas.drawPath(eyesPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the user's strokes
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Path elephantBodyPath;
  final List<Path> protectedPaths;

  DrawingPainter({
    required this.drawingPoints,
    required this.elephantBodyPath,
    required this.protectedPaths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the elephant body only
    canvas.clipPath(elephantBodyPath);

    // Draw all the points, but first check if they're in protected areas
    for (int i = 0; i < drawingPoints.length - 1; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        // Check if either point is in a protected area
        bool pointInProtectedArea = false;
        for (final path in protectedPaths) {
          if (path.contains(drawingPoints[i]!.offset) ||
              path.contains(drawingPoints[i + 1]!.offset)) {
            pointInProtectedArea = true;
            break;
          }
        }

        // Only draw if not in protected area
        if (!pointInProtectedArea) {
          // Draw a line between consecutive points
          canvas.drawLine(
            drawingPoints[i]!.offset,
            drawingPoints[i + 1]!.offset,
            drawingPoints[i]!.paint,
          );
        }
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        // Check if point is in protected area
        bool pointInProtectedArea = false;
        for (final path in protectedPaths) {
          if (path.contains(drawingPoints[i]!.offset)) {
            pointInProtectedArea = true;
            break;
          }
        }

        // Only draw if not in protected area
        if (!pointInProtectedArea) {
          // Draw a single point as a circle
          canvas.drawCircle(
            drawingPoints[i]!.offset,
            drawingPoints[i]!.paint.strokeWidth / 2,
            drawingPoints[i]!.paint,
          );
        }
      }
    }

    // Restore the canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
