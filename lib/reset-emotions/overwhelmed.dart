import 'package:flutter/material.dart';
import 'dart:async';

class OverwhelmedJourney extends StatelessWidget {
  const OverwhelmedJourney({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overwhelmed Journey',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const OverwhelmedJourneyPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class OverwhelmedJourneyPage extends StatefulWidget {
  const OverwhelmedJourneyPage({super.key});

  @override
  State<OverwhelmedJourneyPage> createState() => _OverwhelmedJourneyPageState();
}

class _OverwhelmedJourneyPageState extends State<OverwhelmedJourneyPage>
    with TickerProviderStateMixin {
  int currentStep = 1;
  final int totalSteps = 3;

  // Box breathing variables
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  Timer? _breathingTextTimer;
  bool isBreathingActive = false;
  String breathingText = 'Get Ready...';
  final List<String> breathingTexts = [
    'Breathe In...',
    'Hold...',
    'Breathe Out...',
    'Hold...'
  ];
  int breathingTextIndex = 0;

  // Bubble wrap variables
  List<bool> bubbleStates = List.filled(25, false);
  int bubblePopCount = 0;
  final int totalBubbles = 25;

  // Success message visibility
  Map<int, bool> successMessageVisible = {1: false, 2: false, 3: false};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _breathingTextTimer?.cancel();
    super.dispose();
  }

  void startBoxBreathing() {
    setState(() {
      isBreathingActive = true;
      breathingTextIndex = 0;
      breathingText = breathingTexts[breathingTextIndex];
    });

    _breathingController.repeat();

    _breathingTextTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (isBreathingActive) {
        setState(() {
          breathingTextIndex = (breathingTextIndex + 1) % breathingTexts.length;
          breathingText = breathingTexts[breathingTextIndex];
        });
      }
    });
  }

  void stopBoxBreathing() {
    setState(() {
      isBreathingActive = false;
      breathingText = 'Paused. Press Start to resume.';
    });

    _breathingController.stop();
    _breathingTextTimer?.cancel();
  }

  void popBubble(int index) {
    if (!bubbleStates[index]) {
      setState(() {
        bubbleStates[index] = true;
        bubblePopCount++;
      });
    }
  }

  void resetBubbles() {
    setState(() {
      bubbleStates = List.filled(25, false);
      bubblePopCount = 0;
    });
  }

  void completeStep(int stepNumber) {
    if (stepNumber == currentStep) {
      setState(() {
        successMessageVisible[stepNumber] = true;
      });

      Timer(const Duration(milliseconds: 1500), () {
        setState(() {
          successMessageVisible[stepNumber] = false;
          currentStep++;
        });

        if (currentStep > totalSteps) {
          _navigateToCelebration();
        } else if (currentStep == 2) {
          resetBubbles();
        }
      });
    }
  }

  void _navigateToCelebration() {
    Navigator.pushReplacementNamed(
      context,
      '/celebrate-sustain',
      arguments: {'emotion': 'overwhelmed'},
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isCompleted = stepNum < currentStep;
              final isActive = stepNum == currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? Colors.blue
                                : Colors.grey[300],
                      ),
                      child: Center(
                        child: Text(
                          stepNum.toString(),
                          style: TextStyle(
                            color: (isCompleted || isActive)
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (index < totalSteps - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted ? Colors.green : Colors.grey[300],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(int step) {
    final messages = {
      1: 'Well done! You\'ve completed the breathing exercise.',
      2: 'Great job! You\'ve released some tension.',
      3: 'Excellent! You\'ve completed the visualization exercise.',
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: successMessageVisible[step] == true ? 60 : 0,
      child: successMessageVisible[step] == true
          ? Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  messages[step] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBoxBreathingStep() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSuccessMessage(1),
            const Text(
              'Step 1: Box Breathing',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s start with a simple breathing exercise to calm your nervous system.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Box breathing visualization
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[700]!, width: 2),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _breathingAnimation,
                    builder: (context, child) {
                      final progress = _breathingAnimation.value;
                      double x, y;

                      if (progress <= 0.25) {
                        // Bottom left to top left
                        x = 0;
                        y = 200 - (progress * 4 * 200);
                      } else if (progress <= 0.5) {
                        // Top left to top right
                        x = (progress - 0.25) * 4 * 200;
                        y = 0;
                      } else if (progress <= 0.75) {
                        // Top right to bottom right
                        x = 200;
                        y = (progress - 0.5) * 4 * 200;
                      } else {
                        // Bottom right to bottom left
                        x = 200 - (progress - 0.75) * 4 * 200;
                        y = 200;
                      }

                      return Positioned(
                        left: x - 6,
                        top: y - 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              breathingText,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isBreathingActive)
                  ElevatedButton(
                    onPressed: startBoxBreathing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Start'),
                  ),
                if (isBreathingActive)
                  ElevatedButton(
                    onPressed: stopBoxBreathing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Stop'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleWrapStep() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSuccessMessage(2),
            const Text(
              'Step 2: Release Tension',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Now, let\'s release some tension with a bubble wrap activity.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Bubble wrap grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: totalBubbles,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => popBubble(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bubbleStates[index]
                            ? Colors.grey
                            : Colors.blue[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          bubbleStates[index] ? '' : 'pop',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Popped: $bubblePopCount / $totalBubbles',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationStep() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSuccessMessage(3),
            const Text(
              'Step 3: Peaceful Visualization',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Finally, let\'s visualize a calm, peaceful place.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Close your eyes and imagine:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...const [
                    '• A place where you feel completely safe and at peace',
                    '• Notice the colors, sounds, and sensations',
                    '• Take a few deep breaths in this peaceful space',
                    '• When you\'re ready, slowly bring your awareness back'
                  ].map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[800],
                          ),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Complete Journey',
                    style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
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
            colors: [Color(0xffe6f7ff), Color(0xffdcf2ff)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.blue),
                    ),
                    const Expanded(
                      child: Text(
                        'Back to Emotions',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Feeling Overwhelmed?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Let\'s find some calm, one step at a time.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Progress indicator
                _buildProgressIndicator(),

                // Current step content
                if (currentStep == 1) _buildBoxBreathingStep(),
                if (currentStep == 2) _buildBubbleWrapStep(),
                if (currentStep == 3) _buildVisualizationStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
