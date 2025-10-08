import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../components/nav_logpage.dart';
import '../Clear_my_mind/coloring_success_page.dart';

class FaceColorPage extends StatefulWidget {
  const FaceColorPage({super.key});

  @override
  State<FaceColorPage> createState() => _FaceColorPageState();
}

class _FaceColorPageState extends State<FaceColorPage> with TickerProviderStateMixin {
  // Current drawing properties
  Color currentColor = Colors.black;
  double currentStrokeWidth = 8.0;
  final List<DrawingPoint?> points = [];

  // Animation controllers for progress bar
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Fixed colors for face parts - now marked as static const for emphasis that they're permanent
  static const Color bodyColor = Colors.white;
  static const Color eyesColor = Colors.black;
  static const Color lipsColor = Colors.red;

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
  final Size faceCanvasSize = const Size(350, 450);

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
      end: 0.75, // 75% progress for face coloring page
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
      title: 'Face Coloring',
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
              setState(() => points.clear());
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
                width: faceCanvasSize.width,
                height: faceCanvasSize.height,
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
                      setState(() => points.add(null));
                    },
                    child: ClipRect(
                      child: Stack(
                        children: [
                          // Face filled with colors
                          CustomPaint(
                            size: constraints.biggest,
                            painter: FaceColorPainter(),
                          ),
                          // Drawing layer
                          CustomPaint(
                            size: constraints.biggest,
                            painter: DrawingPainter(
                              drawingPoints: points,
                              facePath:
                                  getTransformedFacePath(constraints.biggest),
                            ),
                          ),
                          // Face outline (always visible)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: FaceOutlinePainter(),
                          ),
                          // Permanent features (glasses and lips) drawn on top
                          CustomPaint(
                            size: constraints.biggest,
                            painter: FeaturesPainter(),
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
                    setState(() => currentStrokeWidth = brushSizes[index]);
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
                    setState(() => currentColor = colorPalette[index]);
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

    // Get the position in the face's coordinate system
    final adjustedPosition =
        _adjustTouchPosition(localPosition, constraints.biggest);

    // If touching inside face area and not in features
    if (_isInsideFacePath(adjustedPosition) &&
        !_isInsideProtectedFeatures(adjustedPosition)) {
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

  // Transform position from screen to face coordinate system
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    final double scale =
        math.min(containerSize.width / 420, containerSize.height / 509);
    final double translateX = (containerSize.width - 420 * scale) / 2;
    final double translateY = (containerSize.height - 509 * scale) / 2;

    final double faceX = (position.dx - translateX) / scale;
    final double faceY = (position.dy - translateY) / scale;

    return Offset(faceX, faceY);
  }

  // Check if touch is inside the face path
  bool _isInsideFacePath(Offset position) {
    final Path facePath = getFacePath();
    return facePath.contains(position);
  }

  // Check if touch is inside protected features (glasses, lips)
  bool _isInsideProtectedFeatures(Offset position) {
    // Check glasses
    if (getGlassesPath().contains(position)) return true;

    // Check lips
    if (getLipsPath().contains(position)) return true;

    return false;
  }

  // Get the transformed face path for clipping
  Path getTransformedFacePath(Size size) {
    final Path facePath = getFacePath();
    final double scale = math.min(size.width / 420, size.height / 509);

    final Matrix4 matrix = Matrix4.identity()
      ..scale(scale, scale)
      ..translate(
          (size.width / scale - 420) / 2, (size.height / scale - 509) / 2);

    return facePath.transform(matrix.storage);
  }

  // Create the face path from SVG
  Path getFacePath() {
    final facePath = Path();
    facePath.moveTo(5, 329.17);
    facePath.lineTo(5, 503.17);
    facePath.lineTo(415, 503.17);
    facePath.lineTo(415, 329.17);
    facePath.cubicTo(393.398, 317.729, 370.639, 325.985, 321, 353.17);
    facePath.cubicTo(296.061, 369.763, 281.079, 375.569, 245, 353.17);
    facePath.lineTo(245, 303.17);
    facePath.cubicTo(286.011, 325.443, 299.931, 310.089, 321, 271.17);
    facePath.cubicTo(381.622, 253.725, 390.568, 232.178, 367, 175.17);
    facePath.cubicTo(396.31, 138.453, 399.48, 117.87, 353, 81.1699);
    facePath.cubicTo(344.29, 31.1003, 334.97, 8.47639, 267, 31.1699);
    facePath.cubicTo(229.993, -5.5764, 207.371, -1.81965, 165, 31.1699);
    facePath.cubicTo(100.016, 11.4091, 91.0595, 33.1048, 93, 93.1699);
    facePath.cubicTo(38.7065, 102.111, 43.537, 129.312, 67, 187.17);
    facePath.cubicTo(47.295, 248.719, 56.2294, 268.584, 117, 271.17);
    facePath.cubicTo(126.698, 321.21, 145.882, 315.525, 181, 303.17);
    facePath.cubicTo(170.785, 363.456, 150.256, 371.526, 81, 329.17);
    facePath.lineTo(5, 329.17);
    facePath.close();
    return facePath;
  }

  // Create glasses path
  Path getGlassesPath() {
    final glassesPath = Path();

    // Glasses center
    glassesPath.moveTo(229, 196);
    glassesPath.lineTo(197, 196);
    glassesPath.lineTo(197, 186);
    glassesPath.lineTo(229, 186);
    glassesPath.lineTo(229, 196);
    glassesPath.close();

    // Left shade
    glassesPath.addOval(
        Rect.fromCenter(center: Offset(158, 191.5), width: 98, height: 105));

    // Right shade
    glassesPath.addOval(
        Rect.fromCenter(center: Offset(271, 193.5), width: 98, height: 97));

    // Eyebrows
    glassesPath.moveTo(248.863, 123.406);
    glassesPath.lineTo(260.185, 143.786);
    glassesPath.lineTo(255.815, 146.214);
    glassesPath.lineTo(247.094, 130.517);
    glassesPath.cubicTo(233.808, 138.265, 217.669, 138.05, 204.932, 135.971);
    glassesPath.cubicTo(198.137, 134.861, 192.176, 133.2, 187.916, 131.817);
    glassesPath.cubicTo(185.92, 131.169, 184.291, 130.58, 183.118, 130.135);
    glassesPath.lineTo(174.185, 146.214);
    glassesPath.lineTo(169.815, 143.786);
    glassesPath.lineTo(180.913, 123.809);
    glassesPath.lineTo(182.989, 124.704);
    glassesPath.lineTo(182.992, 124.705);
    glassesPath.lineTo(183.008, 124.712);
    glassesPath.lineTo(183.084, 124.744);
    glassesPath.cubicTo(183.153, 124.773, 183.26, 124.818, 183.403, 124.876);
    glassesPath.cubicTo(183.688, 124.992, 184.115, 125.163, 184.673, 125.377);
    glassesPath.cubicTo(185.787, 125.803, 187.419, 126.398, 189.46, 127.061);
    glassesPath.cubicTo(193.547, 128.388, 199.254, 129.978, 205.737, 131.036);
    glassesPath.cubicTo(218.811, 133.171, 234.517, 133.059, 246.604, 124.926);
    glassesPath.lineTo(248.863, 123.406);
    glassesPath.close();

    return glassesPath;
  }

  // Create lips path
  Path getLipsPath() {
    final lipsPath = Path();

    // Outer lips
    lipsPath.addOval(
        Rect.fromCenter(center: Offset(215, 257), width: 54, height: 52));

    // Inner lips
    lipsPath.addOval(
        Rect.fromCenter(center: Offset(215, 256.5), width: 28, height: 29));

    // Chin
    lipsPath.moveTo(181.689, 305.822);
    lipsPath.cubicTo(170.34, 297.325, 158.362, 284.553, 145.032, 267.542);
    lipsPath.lineTo(148.968, 264.458);
    lipsPath.cubicTo(162.192, 281.334, 173.853, 293.709, 184.686, 301.82);
    lipsPath.cubicTo(195.494, 309.913, 205.329, 313.651, 214.968, 313.526);
    lipsPath.cubicTo(224.618, 313.401, 234.472, 309.4, 245.307, 301.222);
    lipsPath.cubicTo(256.157, 293.033, 267.826, 280.777, 281.057, 264.427);
    lipsPath.lineTo(284.943, 267.573);
    lipsPath.cubicTo(271.619, 284.038, 259.65, 296.66, 248.319, 305.213);
    lipsPath.cubicTo(236.973, 313.777, 226.105, 318.382, 215.032, 318.526);
    lipsPath.cubicTo(203.949, 318.669, 193.06, 314.337, 181.689, 305.822);
    lipsPath.close();

    return lipsPath;
  }
}

// Class to represent a drawing point with its properties
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  DrawingPoint(this.offset, this.paint);
}

// Painter for coloring the face with fill colors
class FaceColorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 420, size.height / 509);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 420) / 2, (size.height / scale - 509) / 2);

    // Draw and fill face with white (base color)
    final facePath = getFacePath();
    final bodyPaint = Paint()
      ..color = _FaceColorPageState.bodyColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(facePath, bodyPaint);
  }

  Path getFacePath() {
    final facePath = Path();
    facePath.moveTo(5, 329.17);
    facePath.lineTo(5, 503.17);
    facePath.lineTo(415, 503.17);
    facePath.lineTo(415, 329.17);
    facePath.cubicTo(393.398, 317.729, 370.639, 325.985, 321, 353.17);
    facePath.cubicTo(296.061, 369.763, 281.079, 375.569, 245, 353.17);
    facePath.lineTo(245, 303.17);
    facePath.cubicTo(286.011, 325.443, 299.931, 310.089, 321, 271.17);
    facePath.cubicTo(381.622, 253.725, 390.568, 232.178, 367, 175.17);
    facePath.cubicTo(396.31, 138.453, 399.48, 117.87, 353, 81.1699);
    facePath.cubicTo(344.29, 31.1003, 334.97, 8.47639, 267, 31.1699);
    facePath.cubicTo(229.993, -5.5764, 207.371, -1.81965, 165, 31.1699);
    facePath.cubicTo(100.016, 11.4091, 91.0595, 33.1048, 93, 93.1699);
    facePath.cubicTo(38.7065, 102.111, 43.537, 129.312, 67, 187.17);
    facePath.cubicTo(47.295, 248.719, 56.2294, 268.584, 117, 271.17);
    facePath.cubicTo(126.698, 321.21, 145.882, 315.525, 181, 303.17);
    facePath.cubicTo(170.785, 363.456, 150.256, 371.526, 81, 329.17);
    facePath.lineTo(5, 329.17);
    facePath.close();
    return facePath;
  }

  @override
  bool shouldRepaint(covariant FaceColorPainter oldDelegate) => false;
}

// Painter specifically for permanent features (glasses and lips)
class FeaturesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 420, size.height / 509);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 420) / 2, (size.height / scale - 509) / 2);

    // Draw and fill glasses with black
    final glassesPaint = Paint()
      ..color = _FaceColorPageState.eyesColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(getGlassesPath(), glassesPaint);

    // Draw and fill lips with red
    final lipsPaint = Paint()
      ..color = _FaceColorPageState.lipsColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(getLipsOuterPath(), lipsPaint);

    // Draw inner lips with black
    final innerLipsPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawPath(getLipsInnerPath(), innerLipsPaint);
  }

  Path getGlassesPath() {
    final glassesPath = Path();

    // Center part of glasses
    glassesPath.moveTo(229, 196);
    glassesPath.lineTo(197, 196);
    glassesPath.lineTo(197, 186);
    glassesPath.lineTo(229, 186);
    glassesPath.lineTo(229, 196);
    glassesPath.close();

    // Left lens
    glassesPath.addOval(
        Rect.fromCenter(center: Offset(158, 191.5), width: 98, height: 105));

    // Right lens
    glassesPath.addOval(
        Rect.fromCenter(center: Offset(271, 193.5), width: 98, height: 97));

    // Eyebrows
    glassesPath.moveTo(248.863, 123.406);
    glassesPath.lineTo(260.185, 143.786);
    glassesPath.lineTo(255.815, 146.214);
    glassesPath.lineTo(247.094, 130.517);
    glassesPath.cubicTo(233.808, 138.265, 217.669, 138.05, 204.932, 135.971);
    glassesPath.cubicTo(198.137, 134.861, 192.176, 133.2, 187.916, 131.817);
    glassesPath.cubicTo(185.92, 131.169, 184.291, 130.58, 183.118, 130.135);
    glassesPath.lineTo(174.185, 146.214);
    glassesPath.lineTo(169.815, 143.786);
    glassesPath.lineTo(180.913, 123.809);
    glassesPath.lineTo(182.989, 124.704);
    glassesPath.lineTo(182.992, 124.705);
    glassesPath.lineTo(183.008, 124.712);
    glassesPath.lineTo(183.084, 124.744);
    glassesPath.cubicTo(183.153, 124.773, 183.26, 124.818, 183.403, 124.876);
    glassesPath.cubicTo(183.688, 124.992, 184.115, 125.163, 184.673, 125.377);
    glassesPath.cubicTo(185.787, 125.803, 187.419, 126.398, 189.46, 127.061);
    glassesPath.cubicTo(193.547, 128.388, 199.254, 129.978, 205.737, 131.036);
    glassesPath.cubicTo(218.811, 133.171, 234.517, 133.059, 246.604, 124.926);
    glassesPath.lineTo(248.863, 123.406);
    glassesPath.close();

    return glassesPath;
  }

  Path getLipsOuterPath() {
    final lipsPath = Path();
    lipsPath.addOval(
        Rect.fromCenter(center: Offset(215, 257), width: 54, height: 52));
    return lipsPath;
  }

  Path getLipsInnerPath() {
    final lipsPath = Path();
    lipsPath.addOval(
        Rect.fromCenter(center: Offset(215, 256.5), width: 28, height: 29));
    return lipsPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the face outline
class FaceOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Scale to fit the canvas
    final double scale = math.min(size.width / 420, size.height / 509);
    canvas.scale(scale, scale);

    // Center the drawing
    canvas.translate(
        (size.width / scale - 420) / 2, (size.height / scale - 509) / 2);

    // Draw face outline
    final facePath = Path();
    facePath.moveTo(5, 329.17);
    facePath.lineTo(5, 503.17);
    facePath.lineTo(415, 503.17);
    facePath.lineTo(415, 329.17);
    facePath.cubicTo(393.398, 317.729, 370.639, 325.985, 321, 353.17);
    facePath.cubicTo(296.061, 369.763, 281.079, 375.569, 245, 353.17);
    facePath.lineTo(245, 303.17);
    facePath.cubicTo(286.011, 325.443, 299.931, 310.089, 321, 271.17);
    facePath.cubicTo(381.622, 253.725, 390.568, 232.178, 367, 175.17);
    facePath.cubicTo(396.31, 138.453, 399.48, 117.87, 353, 81.1699);
    facePath.cubicTo(344.29, 31.1003, 334.97, 8.47639, 267, 31.1699);
    facePath.cubicTo(229.993, -5.5764, 207.371, -1.81965, 165, 31.1699);
    facePath.cubicTo(100.016, 11.4091, 91.0595, 33.1048, 93, 93.1699);
    facePath.cubicTo(38.7065, 102.111, 43.537, 129.312, 67, 187.17);
    facePath.cubicTo(47.295, 248.719, 56.2294, 268.584, 117, 271.17);
    facePath.cubicTo(126.698, 321.21, 145.882, 315.525, 181, 303.17);
    facePath.cubicTo(170.785, 363.456, 150.256, 371.526, 81, 329.17);
    facePath.lineTo(5, 329.17);
    facePath.close();

    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawPath(facePath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter for drawing the user's strokes
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Path facePath;

  DrawingPainter({
    required this.drawingPoints,
    required this.facePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the face only
    canvas.clipPath(facePath);

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
