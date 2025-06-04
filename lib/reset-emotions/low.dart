import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'celebrate_sustain.dart';

class FeelingLowScreen extends StatefulWidget {
  const FeelingLowScreen({Key? key}) : super(key: key);

  @override
  State<FeelingLowScreen> createState() => _FeelingLowScreenState();
}

class _FeelingLowScreenState extends State<FeelingLowScreen>
    with TickerProviderStateMixin {
  int currentStep = 1;
  final int totalSteps = 3;
  List<String> breakableItems = [];
  List<bool> itemsBroken = [];
  List<bool> bubblesPopped = [];
  TextEditingController thoughtController = TextEditingController();
  String shreddedText = '';
  bool showSuccess = false;

  late AnimationController _successAnimationController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.easeOut,
    ));
    _initializeBreakables();
    _initializeBubbles();
  }

  @override
  void dispose() {
    _successAnimationController.dispose();
    thoughtController.dispose();
    super.dispose();
  }

  void _initializeBreakables() {
    const items = ['🏺', '🍽️', '🖼️', '🍷', '💡'];
    breakableItems = List.generate(10, (index) => items[index % items.length]);
    itemsBroken = List.generate(10, (index) => false);
  }

  void _initializeBubbles() {
    bubblesPopped = List.generate(25, (index) => false);
  }

  void _breakItem(int index) {
    if (!itemsBroken[index]) {
      setState(() {
        itemsBroken[index] = true;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _popBubble(int index) {
    if (!bubblesPopped[index]) {
      setState(() {
        bubblesPopped[index] = true;
      });
      HapticFeedback.lightImpact();
    }
  }

  void _shredThought() {
    final text = thoughtController.text;
    if (text.trim().isEmpty) {
      setState(() {
        shreddedText = "Nothing to shred. Type something first!";
      });
      return;
    }

    String shredded = "";
    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        shredded += ' ';
      } else {
        shredded += (i % 3 == 0) ? text[i] : '█';
      }
    }

    setState(() {
      shreddedText = shredded;
      thoughtController.clear();
    });
    HapticFeedback.mediumImpact();
  }

  void _completeStep(int stepNumber) {
    if (stepNumber == currentStep) {
      setState(() {
        showSuccess = true;
      });
      _successAnimationController.forward();

      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          showSuccess = false;
          if (currentStep < totalSteps) {
            currentStep++;
          } else {
            // Navigate to celebration page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CelebrateSustainPage(emotion: 'low'),
              ),
            );
          }
        });
        _successAnimationController.reset();
      });
    }
  }

  double get progressValue => (currentStep - 1) / (totalSteps - 1);

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
            minHeight: 4,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepNum = index + 1;
              final isActive = stepNum == currentStep;
              final isCompleted = stepNum < currentStep;

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? Colors.indigo
                          : Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    stepNum.toString(),
                    style: TextStyle(
                      color: isActive || isCompleted
                          ? Colors.white
                          : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _successAnimation.value)),
          child: Opacity(
            opacity: _successAnimation.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep1() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSuccess && currentStep == 1)
              _buildSuccessMessage("Well done! You've released some energy."),
            const Text(
              'Step 1: Break Things',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Let's start by releasing some built-up tension. Tap items to \"break\" them.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: breakableItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _breakItem(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: itemsBroken[index]
                            ? Colors.red[300]
                            : Colors.red[100],
                        border: Border.all(color: Colors.red, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          itemsBroken[index] ? '💥' : breakableItems[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _completeStep(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSuccess && currentStep == 2)
              _buildSuccessMessage(
                  "Great job! You've popped away some tension."),
            const Text(
              'Step 2: Bubble Wrap Popper',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Now, let's find some calm through a simple bubble wrap activity.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 25,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _popBubble(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: bubblesPopped[index]
                            ? Colors.grey[400]
                            : Colors.green[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          bubblesPopped[index] ? '' : 'pop',
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
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _completeStep(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSuccess && currentStep == 3)
              _buildSuccessMessage(
                  "Excellent! You've shredded those negative thoughts."),
            const Text(
              'Step 3: Thought Shredder',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Finally, let's release any lingering negative thoughts.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: thoughtController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Let it all out here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _shredThought,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Shred It!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (shreddedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  shreddedText,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _completeStep(3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Complete Final Step',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
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
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.indigo),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Back to Emotions',
          style: TextStyle(color: Colors.indigo),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Feeling a Bit Low?',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's work through this together, one step at a time.",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              _buildProgressIndicator(),
              const SizedBox(height: 20),
              if (currentStep == 1) _buildStep1(),
              if (currentStep == 2) _buildStep2(),
              if (currentStep == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }
}
