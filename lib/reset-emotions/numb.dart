import 'package:flutter/material.dart';
import 'celebrate_sustain.dart';

class NumbJourney extends StatefulWidget {
  const NumbJourney({super.key});

  @override
  State<NumbJourney> createState() => _NumbJourneyPageState();
}

class _NumbJourneyPageState extends State<NumbJourney>
    with TickerProviderStateMixin {
  int currentStep = 1;
  final int totalSteps = 3;
  Set<String> selectedSensations = <String>{};
  Set<String> selectedEmotions = <String>{};

  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    updateProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void updateProgress() {
    final progress = (currentStep - 1) / (totalSteps - 1);
    _progressController.animateTo(progress);
  }

  void completeStep(int stepNumber) {
    if (stepNumber == currentStep) {
      // Show success message with snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getSuccessMessage(stepNumber)),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );

      // Wait and move to next step
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          currentStep++;
        });
        updateProgress();

        if (currentStep > totalSteps) {
          // Navigate to celebration page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CelebrateSustainPage(emotion: 'numb'),
            ),
          );
        }
      });
    }
  }

  String _getSuccessMessage(int step) {
    switch (step) {
      case 1:
        return "Well done! You've reconnected with your body.";
      case 2:
        return "Great job! You've identified your emotions.";
      case 3:
        return "Excellent! You've completed the grounding exercise.";
      default:
        return "Great work!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back to Emotions',
          style: TextStyle(color: Colors.blue, fontSize: 16),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Header
                const Text(
                  'Feeling Numb?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Let's reconnect with your senses and emotions, one step at a time.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Progress Track
                _buildProgressTrack(),
                const SizedBox(height: 32),

                // Step Content
                Expanded(
                  child: _buildCurrentStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTrack() {
    return Column(
      children: [
        // Progress bar
        Container(
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Step indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(totalSteps, (index) {
            final stepNum = index + 1;
            final isActive = stepNum == currentStep;
            final isCompleted = stepNum < currentStep;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isActive
                        ? Colors.blue
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNum.toString(),
                  style: TextStyle(
                    color: isActive || isCompleted ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 1:
        return _buildPhysicalAwarenessStep();
      case 2:
        return _buildEmotionalCheckInStep();
      case 3:
        return _buildGroundingExerciseStep();
      default:
        return Container();
    }
  }

  Widget _buildPhysicalAwarenessStep() {
    final sensations = [
      {'key': 'warm', 'icon': '🔥', 'label': 'Warm'},
      {'key': 'cold', 'icon': '❄️', 'label': 'Cold'},
      {'key': 'tingle', 'icon': '⚡', 'label': 'Tingly'},
      {'key': 'heavy', 'icon': '⚖️', 'label': 'Heavy'},
    ];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 1: Physical Awareness',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Let's start by noticing physical sensations. Tap on what you feel right now.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: sensations.length,
                itemBuilder: (context, index) {
                  final sensation = sensations[index];
                  final isSelected =
                      selectedSensations.contains(sensation['key']);

                  return _buildSensationCard(
                    sensation['key']!,
                    sensation['icon']!,
                    sensation['label']!,
                    isSelected,
                    (key) {
                      setState(() {
                        if (selectedSensations.contains(key)) {
                          selectedSensations.remove(key);
                        } else {
                          selectedSensations.add(key);
                        }
                      });
                    },
                  );
                },
              ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalCheckInStep() {
    final emotions = [
      {'key': 'calm', 'icon': '😌', 'label': 'Calm'},
      {'key': 'empty', 'icon': '🫗', 'label': 'Empty'},
      {'key': 'distant', 'icon': '🌫️', 'label': 'Distant'},
      {'key': 'curious', 'icon': '🤔', 'label': 'Curious'},
      {'key': 'tired', 'icon': '😴', 'label': 'Tired'},
      {'key': 'neutral', 'icon': '😐', 'label': 'Neutral'},
    ];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 2: Emotional Check-in',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Now, let's check in with your emotions. Select any that resonate.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: emotions.length,
                itemBuilder: (context, index) {
                  final emotion = emotions[index];
                  final isSelected = selectedEmotions.contains(emotion['key']);

                  return _buildSensationCard(
                    emotion['key']!,
                    emotion['icon']!,
                    emotion['label']!,
                    isSelected,
                    (key) {
                      setState(() {
                        if (selectedEmotions.contains(key)) {
                          selectedEmotions.remove(key);
                        } else {
                          selectedEmotions.add(key);
                        }
                      });
                    },
                  );
                },
              ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingExerciseStep() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Step 3: Ground Yourself',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Let's do a quick grounding exercise to help you reconnect.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Take a moment to:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildGroundingStep('1. Notice 5 things you can see'),
                          _buildGroundingStep('2. Feel 4 things you can touch'),
                          _buildGroundingStep(
                              '3. Listen for 3 things you can hear'),
                          _buildGroundingStep(
                              '4. Smell 2 things you can smell'),
                          _buildGroundingStep('5. Taste 1 thing you can taste'),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Complete Exercise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroundingStep(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: Colors.blue.shade800,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSensationCard(
    String key,
    String icon,
    String label,
    bool isSelected,
    Function(String) onTap,
  ) {
    return GestureDetector(
      onTap: () => onTap(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo.shade100 : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.indigo : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
