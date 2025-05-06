import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

import 'dashboard_traker.dart'; // Import the dashboard tracker

class ThoughtShredderPage extends StatefulWidget {
  const ThoughtShredderPage({super.key});

  @override
  _ThoughtShredderPageState createState() => _ThoughtShredderPageState();
}

class _ThoughtShredderPageState extends State<ThoughtShredderPage>
    with TickerProviderStateMixin {
  final TextEditingController _thoughtController = TextEditingController();
  bool _isShredding = false;
  late AnimationController _animationController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  String _currentText = '';
  final int _numStrips = 40; // Increased number of strips for better effect
  final List<double> _stripOffsets = [];
  final List<Color> _stripColors = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Main animation controller for shredding
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // Slightly longer animation
    );

    // Shaking animation controller
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Create a shaking animation
    _shakeAnimation =
        Tween<double>(begin: -5.0, end: 5.0).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _animationController.addListener(() {
      setState(() {}); // Ensure we update the UI during animation
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isShredding = false;
          _thoughtController.clear();
        });

        // Record activity in SharedPreferences
        _recordActivity();
      }
    });

    // Initialize random offsets and colors for the shredding strips
    final random = math.Random();
    for (int i = 0; i < _numStrips; i++) {
      _stripOffsets.add(random.nextDouble() * 30);

      // Add random colors with red tint for shredded pieces
      _stripColors.add(Color.fromRGBO(
        200 + random.nextInt(55), // Higher red component
        50 + random.nextInt(150),
        50 + random.nextInt(150),
        0.7 + random.nextDouble() * 0.3,
      ));
    }
  }

  // Updated method to record activity using the static method from DashboardTrackerPage
  Future<void> _recordActivity() async {
    // Call the static method from DashboardTrackerPage to record the activity
    // This ensures data is saved locally first, then synced to server when online
    await DashboardTrackerPage.recordToolActivity('thought_shredder');
    debugPrint(
        'Recorded thought shredder activity - saved locally and will sync when online');
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _animationController.dispose();
    _shakeController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startShredding() async {
    if (_thoughtController.text.trim().isNotEmpty) {
      // Start playing the shredding sound
      try {
        await _audioPlayer.play(AssetSource('sounds/shredder-sound.mp3'));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }

      setState(() {
        _currentText = _thoughtController.text;
        _isShredding = true;
      });

      // Start with a shake animation
      _shakeController.forward();
      _shakeController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _shakeController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _shakeController.forward();
        }
      });

      // Wait a bit before starting the shredding
      await Future.delayed(const Duration(milliseconds: 300));

      // Stop the shaking once shredding really starts
      _shakeController.stop();

      // Start main animation
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thought Shredder'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'What are you thinking about?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'The average person has about 60,000 thoughts a day. 80% of these thoughts were found to be negative, '
                'and 95% were exactly the same repetitive thoughts as the day before. Break the cycle of overthinking, go ahead and shred your thoughts!',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isShredding
                  ? AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(
                              _shakeController.isAnimating
                                  ? _shakeAnimation.value
                                  : 0,
                              0),
                          child: _buildShreddingAnimation(),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      height: 300,
                      child: TextField(
                        controller: _thoughtController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(
                          hintText: 'Share your thoughts...',
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isShredding ? null : _startShredding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    elevation: 4,
                    shadowColor: Colors.redAccent,
                  ),
                  child: const Text('SHRED YOUR THOUGHTS!'),
                ),
              ),
              const SizedBox(height: 10),
              if (!_isShredding)
                const Text(
                  'Click to hear the satisfying sound of shredding away negative thoughts!',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShreddingAnimation() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRect(
        child: CustomPaint(
          painter: ShreddingPainter(
            text: _currentText,
            progress: _animationController.value,
            numStrips: _numStrips,
            stripOffsets: _stripOffsets,
            stripColors: _stripColors,
          ),
          child: SizedBox.expand(),
        ),
      ),
    );
  }
}

class ShreddingPainter extends CustomPainter {
  final String text;
  final double progress;
  final int numStrips;
  final List<double> stripOffsets;
  final List<Color> stripColors;

  ShreddingPainter({
    required this.text,
    required this.progress,
    required this.numStrips,
    required this.stripOffsets,
    required this.stripColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stripWidth = size.width / numStrips;
    final random = math.Random();

    // Create a TextPainter to measure and layout the text
    final textStyle = TextStyle(fontSize: 16, color: Colors.black);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: size.width);

    // Draw background for the strips
    Paint stripPaint = Paint();

    // First pass: Draw the original text in the background if early in animation
    if (progress < 0.3) {
      canvas.save();
      final fadeFactor = 1.0 - (progress * 3.3); // Fade out quickly
      if (fadeFactor > 0) {
        textPainter.paint(canvas, Offset.zero);
      }
      canvas.restore();
    }

    // Second pass: Draw the vertical strips with the text and colors
    for (int i = 0; i < numStrips; i++) {
      final stripRect = Rect.fromLTWH(
        i * stripWidth,
        0,
        stripWidth,
        size.height,
      );

      // Save the canvas state
      canvas.save();

      // Apply clipping to only show this strip
      canvas.clipRect(stripRect);

      // Calculate the vertical offset based on animation progress
      double verticalOffset = 0;
      double horizontalJitter = 0;
      double rotation = 0;

      if (progress > 0.1) {
        // Start moving after 10% of the animation
        final effectiveProgress = (progress - 0.1) / 0.9;

        // Exponential movement for acceleration effect
        double accelerationFactor = math.pow(effectiveProgress, 2.0).toDouble();

        verticalOffset = accelerationFactor *
            (size.height + 300) *
            (1 + stripOffsets[i] / 10);

        // Add horizontal jitter as it falls
        horizontalJitter = math.sin(effectiveProgress * math.pi * (2 + i % 3)) *
            (5 + stripOffsets[i] % 5) *
            effectiveProgress;

        // Add rotation as it falls
        rotation = (random.nextDouble() - 0.5) *
            effectiveProgress *
            0.2 *
            (1 + (i % 3));
      }

      // Apply a rotation transformation
      if (rotation != 0) {
        final stripCenter = Offset(stripRect.left + stripRect.width / 2,
            stripRect.top + stripRect.height / 2 + verticalOffset / 2);

        canvas.translate(stripCenter.dx, stripCenter.dy);
        canvas.rotate(rotation);
        canvas.translate(-stripCenter.dx, -stripCenter.dy);
      }

      // Draw colored background for the strip if we're into the animation
      if (progress > 0.15) {
        final effectiveProgress = math.min(1.0, (progress - 0.15) / 0.85);
        stripPaint.color = stripColors[i].withOpacity(effectiveProgress * 0.3);

        canvas.drawRect(
            Rect.fromLTWH(stripRect.left, stripRect.top + verticalOffset,
                stripRect.width, stripRect.height),
            stripPaint);
      }

      // Draw the text with the offset and jitter
      textPainter.paint(canvas, Offset(horizontalJitter, verticalOffset));

      // Restore the canvas state
      canvas.restore();

      // Draw strip divider lines for visual effect
      if (progress < 0.5 && i > 0) {
        final linePaint = Paint()
          ..color = Colors.black.withOpacity(0.1 * (1 - progress))
          ..strokeWidth = 0.5;

        canvas.drawLine(Offset(i * stripWidth, 0),
            Offset(i * stripWidth, size.height), linePaint);
      }
    }

    // Third pass: Add falling paper bits for extra effect
    if (progress > 0.3) {
      final bitsPaint = Paint();
      final numBits = 100;
      final bitSize = 3.0;
      final effectiveProgress = (progress - 0.3) / 0.7;

      for (int i = 0; i < numBits; i++) {
        // Random position
        final x = random.nextDouble() * size.width;
        final fallSpeed = 0.5 + random.nextDouble() * 1.5;
        final y = -10.0 + (size.height + 100) * effectiveProgress * fallSpeed;

        // Skip bits that would be off screen
        if (y < 0 || y > size.height) continue;

        // Random color with red tint
        final color = Color.fromRGBO(
          200 + random.nextInt(55),
          100 + random.nextInt(100),
          100 + random.nextInt(100),
          0.6 + random.nextDouble() * 0.4,
        );

        bitsPaint.color = color;

        // Draw small rectangle with rotation
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(random.nextDouble() * math.pi);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: bitSize * (1 + random.nextDouble()),
            height: bitSize * (1 + random.nextDouble()),
          ),
          bitsPaint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShreddingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.text != text;
  }
}
