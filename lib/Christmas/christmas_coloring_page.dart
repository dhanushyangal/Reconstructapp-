import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import 'christmas_svg_parser.dart';
import 'christmas_success_page.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint(this.offset, this.paint);
}

class ChristmasColoringPage extends StatefulWidget {
  final String cutoutName;
  final String svgPath;
  final Size viewBox;
  final Color backgroundColor;

  const ChristmasColoringPage({
    super.key,
    required this.cutoutName,
    required this.svgPath,
    required this.viewBox,
    required this.backgroundColor,
  });

  @override
  State<ChristmasColoringPage> createState() => _ChristmasColoringPageState();
}

class _ChristmasColoringPageState extends State<ChristmasColoringPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  // Current drawing properties
  Color currentColor = Colors.red;
  double currentStrokeWidth = 8.0;

  // Store drawing points
  final List<DrawingPoint?> points = [];

  // Animation controllers for progress bar
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

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
  final List<double> brushSizes = [4.0, 8.0, 12.0, 16.0, 20.0];

  // Reference to the drawing area key
  final GlobalKey _drawingAreaKey = GlobalKey();
  
  // Screenshot controller for capturing the drawing
  final ScreenshotController _screenshotController = ScreenshotController();

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
      end: 0.75, // 75% progress for coloring page
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

  // Get transformed path for current canvas size (recalculate each time)
  Path getTransformedCutoutPath(Size canvasSize) {
    // Always parse from widget's svgPath to ensure we get the correct path
    final path = ChristmasSVGParser.parseSVGPath(widget.svgPath, viewBox: widget.viewBox);
    final transformedPath = ChristmasSVGParser.transformPath(
      path,
      canvasSize,
      widget.viewBox,
    );
    
    return transformedPath;
  }

  // Check if touch is inside the cutout path
  bool _isInsideCutout(Offset position, Size containerSize) {
    final transformedPath = getTransformedCutoutPath(containerSize);
    return transformedPath.contains(position);
  }

  // Adjust touch position to canvas coordinates
  Offset _adjustTouchPosition(Offset position, Size containerSize) {
    // Position is already in local coordinates from GestureDetector
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: widget.cutoutName,
      showBackButton: true,
      selectedIndex: 2, // Dashboard index
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
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                key: _drawingAreaKey,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanStart: (details) {
                        final RenderBox renderBox =
                            _drawingAreaKey.currentContext!.findRenderObject()
                                as RenderBox;
                        final Offset localPosition =
                            renderBox.globalToLocal(details.globalPosition);
                        
                        final adjustedPosition = _adjustTouchPosition(localPosition, constraints.biggest);
                        
                        if (_isInsideCutout(adjustedPosition, constraints.biggest)) {
                          setState(() {
                            points.add(DrawingPoint(
                              localPosition,
                              Paint()
                                ..color = currentColor
                                ..strokeWidth = currentStrokeWidth
                                ..strokeCap = StrokeCap.round
                                ..strokeJoin = StrokeJoin.round
                                ..style = PaintingStyle.stroke
                                ..blendMode = BlendMode.srcOver,
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
                        
                        final adjustedPosition = _adjustTouchPosition(localPosition, constraints.biggest);
                        
                        if (_isInsideCutout(adjustedPosition, constraints.biggest)) {
                          setState(() {
                            points.add(DrawingPoint(
                              localPosition,
                              Paint()
                                ..color = currentColor
                                ..strokeWidth = currentStrokeWidth
                                ..strokeCap = StrokeCap.round
                                ..strokeJoin = StrokeJoin.round
                                ..style = PaintingStyle.stroke
                                ..blendMode = BlendMode.srcOver,
                            ));
                          });
                        }
                      },
                      onPanEnd: (details) {
                        setState(() {
                          points.add(null);
                        });
                      },
                      child: Stack(
                        children: [
                          // Base fill (white)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: ChristmasCutoutBasePainter(
                              svgPath: widget.svgPath,
                              viewBox: widget.viewBox,
                            ),
                          ),
                          // Drawing layer (clipped to path)
                          CustomPaint(
                            size: constraints.biggest,
                            painter: DrawingPainter(
                              points: points,
                              cutoutPath: getTransformedCutoutPath(constraints.biggest),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            ),
          ),
          
          // Color palette and brush size selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Color selection
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Color: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        _showColorPicker(context);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: currentColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.color_lens,
                          color: currentColor == Colors.white || currentColor == Colors.yellow
                              ? Colors.black
                              : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Brush size selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'Brush Size: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...brushSizes.map((size) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentStrokeWidth = size;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 6),
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: currentStrokeWidth == size ? currentColor.withOpacity(0.3) : Colors.grey[200],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: currentStrokeWidth == size ? Colors.black : Colors.grey,
                                width: currentStrokeWidth == size ? 3 : 1,
                              ),
                            ),
                            child: Container(
                              width: size,
                              height: size,
                              decoration: BoxDecoration(
                                color: currentStrokeWidth == size ? currentColor : Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Download and Next buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Download/Share button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _captureAndShowImage(context),
                    icon: Icon(Icons.download, size: 20),
                    label: Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Next button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChristmasSuccessPage(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get pageName => widget.cutoutName;

  Future<void> _captureAndShowImage(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Capture the screenshot
      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image')),
        );
        return;
      }

      // Save to temporary file
      final directory = await getTemporaryDirectory();
      final fileName = '${widget.cutoutName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final imagePath = '${directory.path}/$fileName';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      Navigator.pop(context); // Close loading dialog

      // Show the image preview dialog with share option
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Coloring',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      label: Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await Share.shareXFiles(
                            [XFile(imagePath)],
                            text: 'Check out my ${widget.cutoutName} coloring!',
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error sharing: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.share),
                      label: Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF23C4F7),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showColorPicker(BuildContext context) {
    HSVColor hsvColor = HSVColor.fromColor(currentColor);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updatePreviewColor(HSVColor newColor) {
              // Only update the preview in the modal, not the actual currentColor
              setModalState(() {
                hsvColor = newColor;
              });
            }
            
            void applyColor() {
              // Apply the color and close
              setState(() {
                currentColor = hsvColor.toColor();
              });
              Navigator.pop(context);
            }
            
            return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Select Color',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        // Color wheel (Hue and Saturation)
                        Expanded(
                          flex: 3,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = constraints.biggest;
                              return GestureDetector(
                                onPanUpdate: (details) {
                                  // Use localPosition which is already in local coordinates
                                  final localPosition = details.localPosition;
                                  
                                  final x = localPosition.dx.clamp(0.0, size.width);
                                  final y = localPosition.dy.clamp(0.0, size.height);
                                  
                                  final hue = (x / size.width * 360).clamp(0.0, 360.0);
                                  // Top = high saturation, high brightness
                                  // Bottom = high saturation, low brightness (darker)
                                  final normalizedY = y / size.height; // 0 at top, 1 at bottom
                                  final saturation = hsvColor.saturation; // Use current saturation from slider
                                  final brightness = (1.0 - normalizedY).clamp(0.1, 1.0); // Invert: top is bright, bottom is dark
                                  
                                  final newColor = HSVColor.fromAHSV(
                                    1.0,
                                    hue,
                                    saturation,
                                    brightness,
                                  );
                                  updatePreviewColor(newColor);
                                },
                                onTapDown: (details) {
                                  // Use localPosition which is already in local coordinates
                                  final localPosition = details.localPosition;
                                  
                                  final x = localPosition.dx.clamp(0.0, size.width);
                                  final y = localPosition.dy.clamp(0.0, size.height);
                                  
                                  final hue = (x / size.width * 360).clamp(0.0, 360.0);
                                  // Top = high saturation, high brightness
                                  // Bottom = high saturation, low brightness (darker)
                                  final normalizedY = y / size.height; // 0 at top, 1 at bottom
                                  final saturation = hsvColor.saturation; // Use current saturation from slider
                                  final brightness = (1.0 - normalizedY).clamp(0.1, 1.0); // Invert: top is bright, bottom is dark
                                  
                                  final newColor = HSVColor.fromAHSV(
                                    1.0,
                                    hue,
                                    saturation,
                                    brightness,
                                  );
                                  updatePreviewColor(newColor);
                                },
                                child: CustomPaint(
                                  painter: ColorWheelPainter(1.0), // Brightness is now controlled by Y position
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey, width: 2),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        // Saturation slider (since brightness is now controlled by Y position in color wheel)
                        Row(
                          children: [
                            Text('Saturation: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Slider(
                                value: hsvColor.saturation,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (value) {
                                  final newColor = hsvColor.withSaturation(value);
                                  updatePreviewColor(newColor);
                                },
                                activeColor: hsvColor.toColor(),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Select color button (clickable preview)
                        GestureDetector(
                          onTap: applyColor,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              color: hsvColor.toColor(),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                'Select Color',
                                style: TextStyle(
                                  color: hsvColor.value > 0.5 ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Painter for base fill of Christmas cutout
class ChristmasCutoutBasePainter extends CustomPainter {
  final String svgPath;
  final Size viewBox;

  ChristmasCutoutBasePainter({
    required this.svgPath,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = ChristmasSVGParser.parseSVGPath(svgPath, viewBox: viewBox);
    final transformedPath = ChristmasSVGParser.transformPath(path, size, viewBox);
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(transformedPath, paint);
  }

  @override
  bool shouldRepaint(covariant ChristmasCutoutBasePainter oldDelegate) {
    return oldDelegate.svgPath != svgPath || 
           oldDelegate.viewBox.width != viewBox.width || 
           oldDelegate.viewBox.height != viewBox.height;
  }
}

/// Painter for outline of Christmas cutout
class ChristmasCutoutOutlinePainter extends CustomPainter {
  final String svgPath;
  final Size viewBox;

  ChristmasCutoutOutlinePainter({
    required this.svgPath,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = ChristmasSVGParser.parseSVGPath(svgPath, viewBox: viewBox);
    final transformedPath = ChristmasSVGParser.transformPath(path, size, viewBox);
    
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawPath(transformedPath, paint);
  }

  @override
  bool shouldRepaint(covariant ChristmasCutoutOutlinePainter oldDelegate) {
    return oldDelegate.svgPath != svgPath || 
           oldDelegate.viewBox.width != viewBox.width || 
           oldDelegate.viewBox.height != viewBox.height;
  }
}

/// Custom painter for drawing
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;
  final Path cutoutPath;

  DrawingPainter({
    required this.points,
    required this.cutoutPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create a layer for drawing with proper clipping
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Apply clipping to keep drawing inside the cutout path only
    canvas.clipPath(cutoutPath);

    // Draw all the points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Draw a line between consecutive points
        canvas.drawLine(
          points[i]!.offset,
          points[i + 1]!.offset,
          points[i]!.paint,
        );
      } else if (points[i] != null && points[i + 1] == null) {
        // Draw a single point as a circle
        canvas.drawCircle(
          points[i]!.offset,
          points[i]!.paint.strokeWidth / 2,
          points[i]!.paint,
        );
      }
    }

    // Restore the canvas
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}

/// Painter for color wheel (Hue horizontally, Brightness vertically)
class ColorWheelPainter extends CustomPainter {
  final double brightness;

  ColorWheelPainter(this.brightness);

  @override
  void paint(Canvas canvas, Size size) {
    // Draw using a more efficient approach with gradients
    // Create vertical gradients for each column (hue changes horizontally)
    // Top = bright colors, Bottom = dark colors
    for (int i = 0; i < size.width.toInt(); i += 2) {
      final hue = (i / size.width * 360).clamp(0.0, 360.0);
      
      // Create vertical gradient: top is bright, bottom is dark
      // Top: full brightness, full saturation
      // Bottom: low brightness (0.1), full saturation (for dark rich colors)
      final topColor = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
      final bottomColor = HSVColor.fromAHSV(1.0, hue, 1.0, 0.1).toColor();
      
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topColor, bottomColor],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(i.toDouble(), 0, 2, size.height));
      
      canvas.drawRect(Rect.fromLTWH(i.toDouble(), 0, 2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ColorWheelPainter oldDelegate) {
    return false; // The wheel doesn't depend on brightness slider anymore
  }
}
