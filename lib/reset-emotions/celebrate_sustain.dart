import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';

class CelebrateSustainPage extends StatefulWidget {
  final String? emotion;

  const CelebrateSustainPage({Key? key, this.emotion}) : super(key: key);

  @override
  _CelebrateSustainPageState createState() => _CelebrateSustainPageState();
}

class _CelebrateSustainPageState extends State<CelebrateSustainPage>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _breathingController;
  List<ConfettiParticle> confettiParticles = [];
  bool _isBreathingActive = false;
  String _breathingText = 'Get Ready';
  Timer? _breathingTimer;
  int _breathingPhase = 0;
  List<String> gratitudes = [];
  String selectedColor = '#000000';
  List<bool> bubblesPoppedState = List.filled(64, false);
  final TextEditingController _gratitude1Controller = TextEditingController();
  final TextEditingController _gratitude2Controller = TextEditingController();
  final TextEditingController _gratitude3Controller = TextEditingController();
  final TextEditingController _affirmationController = TextEditingController();

  final List<String> affirmations = [
    "I am capable and strong.",
    "I choose to find moments of peace today.",
    "I am resilient and can handle challenges.",
    "I am worthy of happiness and joy.",
    "I am grateful for the progress I'm making."
  ];

  final List<Color> colorPalette = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    _createConfetti();
    _confettiController.repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _breathingController.dispose();
    _breathingTimer?.cancel();
    _gratitude1Controller.dispose();
    _gratitude2Controller.dispose();
    _gratitude3Controller.dispose();
    _affirmationController.dispose();
    super.dispose();
  }

  void _createConfetti() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.cyan
    ];
    confettiParticles = List.generate(50, (index) {
      return ConfettiParticle(
        x: Random().nextDouble(),
        y: Random().nextDouble() * -1,
        color: colors[Random().nextInt(colors.length)],
        speed: 0.5 + Random().nextDouble() * 0.5,
      );
    });
  }

  void _setReminder() {
    // In a real app, you would use a notification plugin
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reminder Set'),
        content: const Text(
            'Reminder set for tomorrow at 9 AM!\n\n(Note: In a production app, this would use local notifications)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _startBreathing() {
    setState(() {
      _isBreathingActive = true;
      _breathingPhase = 0;
    });

    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isBreathingActive) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_breathingPhase < 4) {
          _breathingText = 'Breathe In...';
        } else if (_breathingPhase < 11) {
          _breathingText = 'Hold...';
        } else if (_breathingPhase < 19) {
          _breathingText = 'Breathe Out...';
        }

        _breathingPhase = (_breathingPhase + 1) % 19;
      });
    });
  }

  void _stopBreathing() {
    setState(() {
      _isBreathingActive = false;
      _breathingText = 'Get Ready';
    });
    _breathingTimer?.cancel();
  }

  void _popBubble(int index) {
    setState(() {
      bubblesPoppedState[index] = true;
    });
    HapticFeedback.lightImpact();
  }

  void _saveGratitude() {
    final newGratitudes = [
      _gratitude1Controller.text,
      _gratitude2Controller.text,
      _gratitude3Controller.text,
    ].where((g) => g.trim().isNotEmpty).toList();

    if (newGratitudes.isNotEmpty) {
      setState(() {
        gratitudes = newGratitudes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your gratitudes have been saved!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please write at least one thing you are grateful for.')),
      );
    }
  }

  Widget _buildToolModal(String toolType) {
    switch (toolType) {
      case 'coloringSheet':
        return _buildColoringSheet();
      case 'gratitudeActivity':
        return _buildGratitudeActivity();
      case 'affirmationCard':
        return _buildAffirmationCard();
      case 'breathingTechnique':
        return _buildBreathingTechnique();
      case 'bubbleWrapperTool':
        return _buildBubbleWrapperTool();
      default:
        return Container();
    }
  }

  Widget _buildColoringSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Mindful Coloring Sheet',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple)),
        const SizedBox(height: 16),
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomPaint(
            painter: MandalaPainter(),
            child: Container(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          children: colorPalette.map((color) {
            return GestureDetector(
              onTap: () => setState(() => selectedColor =
                  '#${color.value.toRadixString(16).substring(2)}'),
              child: Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedColor ==
                            '#${color.value.toRadixString(16).substring(2)}'
                        ? Colors.black
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGratitudeActivity() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Quick Gratitude Journal',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green)),
        const SizedBox(height: 16),
        const Text(
            'Take a moment to think about three things you are grateful for today, big or small.'),
        const SizedBox(height: 16),
        TextField(
          controller: _gratitude1Controller,
          decoration: const InputDecoration(
            hintText: '1. I am grateful for...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gratitude2Controller,
          decoration: const InputDecoration(
            hintText: '2. I am grateful for...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _gratitude3Controller,
          decoration: const InputDecoration(
            hintText: '3. I am grateful for...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveGratitude,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Save Gratitude',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAffirmationCard() {
    final randomAffirmation =
        affirmations[Random().nextInt(affirmations.length)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Positive Affirmation',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                randomAffirmation,
                style: const TextStyle(fontSize: 18, color: Colors.blue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Repeat this to yourself a few times. Feel free to modify it to better suit you.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _affirmationController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your own affirmation here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreathingTechnique() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('4-7-8 Breathing Technique',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade200,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _breathingText,
                  style: const TextStyle(fontSize: 18, color: Colors.blue),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        const Text('Follow the circle\'s rhythm:'),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Breathe in for 4 seconds'),
            Text('• Hold for 7 seconds'),
            Text('• Exhale for 8 seconds'),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _isBreathingActive ? _stopBreathing : _startBreathing,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: Text(_isBreathingActive ? 'Stop Breathing' : 'Start Breathing',
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildBubbleWrapperTool() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Advanced Bubble Popper',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 64,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _popBubble(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: bubblesPoppedState[index]
                        ? Colors.grey.shade300
                        : Colors.blue.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      bubblesPoppedState[index] ? '' : 'pop',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Text('Click to pop the bubbles. Watch them all disappear!',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showToolModal(String toolType) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToolModal(toolType),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done with this Tool'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xfff0f9ff), Color(0xffe0f2fe)],
          ),
        ),
        child: Stack(
          children: [
            // Confetti animation
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                      confettiParticles, _confettiController.value),
                  size: Size.infinite,
                );
              },
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Column(
                      children: [
                        const Text(
                          "That's Great Progress!",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.emotion != null
                              ? 'Well done on taking a step to reset after feeling ${widget.emotion}. Let\'s keep that positive momentum going.'
                              : 'Well done on taking a step to reset your emotions. Let\'s keep that positive momentum going.',
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Main content card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reminder section
                          Container(
                            padding: const EdgeInsets.only(bottom: 24),
                            decoration: const BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.grey)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Maintain Your Streak',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.indigo,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Consistency is key. Would you like to set a reminder to check in with yourself tomorrow?',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Set a daily reminder:',
                                          style: TextStyle(
                                            color: Colors.indigo,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: _setReminder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Text('Set Reminder'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Self-care tools section
                          const Text(
                            'Choose a Self-Care Tool',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Select one or more activities to continue nurturing your well-being.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 24),

                          // Tool grid
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            children: [
                              _buildToolCard(
                                  '🎨',
                                  'Coloring Sheet',
                                  'Unwind with a creative pattern.',
                                  Colors.purple,
                                  'coloringSheet'),
                              _buildToolCard(
                                  '🙏',
                                  'Gratitude Activity',
                                  'Reflect on things you\'re thankful for.',
                                  Colors.green,
                                  'gratitudeActivity'),
                              _buildToolCard(
                                  '💬',
                                  'Affirmation Card',
                                  'Boost yourself with positive statements.',
                                  Colors.blue,
                                  'affirmationCard'),
                              _buildToolCard(
                                  '🫧',
                                  'New Breathing Technique',
                                  'Try a different way to calm your breath.',
                                  Colors.teal,
                                  'breathingTechnique'),
                              _buildToolCard(
                                  '✨',
                                  'Fun Bubble Popper',
                                  'Another version of the satisfying pop.',
                                  Colors.pink,
                                  'bubbleWrapperTool'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Finish button
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 8,
                            ),
                            child: const Text(
                              'Finish Journey for Today',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nice job resetting today! Come back anytime.',
                          style: TextStyle(fontSize: 12, color: Colors.black45),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard(String icon, String title, String description,
      Color color, String toolType) {
    return GestureDetector(
      onTap: () => _showToolModal(toolType),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ConfettiParticle {
  double x;
  double y;
  final Color color;
  final double speed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.speed,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double animationValue;

  ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      final currentY =
          (particle.y + animationValue * particle.speed) * size.height;

      if (currentY > size.height) {
        particle.y = -0.1;
      }

      canvas.drawCircle(
        Offset(particle.x * size.width, currentY),
        5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class MandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    // Draw mandala pattern
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final endPoint = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      canvas.drawLine(center, endPoint, paint);
    }

    // Draw circles
    canvas.drawCircle(center, radius * 0.3, paint);
    canvas.drawCircle(center, radius * 0.6, paint);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
