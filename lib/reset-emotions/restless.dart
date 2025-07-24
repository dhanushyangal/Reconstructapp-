import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class RestlessScreen extends StatefulWidget {
  const RestlessScreen({super.key});

  @override
  _RestlessScreenState createState() => _RestlessScreenState();
}

class _RestlessScreenState extends State<RestlessScreen>
    with TickerProviderStateMixin {
  int currentStep = 1;
  final int totalSteps = 3;
  String? selectedFocus;
  bool showSuccessMessage = false;

  late AnimationController _breathingController;
  late AnimationController _fadeController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_fadeController);

    _fadeController.forward();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void completeStep(int stepNumber) {
    if (stepNumber == currentStep) {
      HapticFeedback.lightImpact();
      setState(() {
        showSuccessMessage = true;
      });

      Timer(Duration(milliseconds: 1500), () {
        setState(() {
          showSuccessMessage = false;
          currentStep++;
        });

        if (currentStep > totalSteps) {
          Navigator.pushReplacementNamed(
            context,
            '/celebrate-sustain',
            arguments: {'emotion': 'restless'},
          );
        }
      });
    }
  }

  Widget buildProgressTrack() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: 4,
                width: MediaQuery.of(context).size.width *
                    0.8 *
                    ((currentStep - 1) / (totalSteps - 1)),
                decoration: BoxDecoration(
                  color: Color(0xFF4F46E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              int stepNum = index + 1;
              bool isActive = stepNum == currentStep;
              bool isCompleted = stepNum < currentStep;

              return Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Color(0xFF10B981)
                      : isActive
                          ? Color(0xFF4F46E5)
                          : Colors.grey[300],
                  shape: BoxShape.circle,
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

  Widget buildStep1() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            if (showSuccessMessage && currentStep == 1)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Well done! You've completed the breathing exercise.",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              "Step 1: Calm Your Breath",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Let's start with a simple breathing exercise to center yourself.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Color(0xFFBFDBFE),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "Breathe",
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 24),
            Text(
              "Follow the circle's rhythm: inhale as it expands, exhale as it contracts.",
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F46E5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStep2() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            if (showSuccessMessage && currentStep == 2)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Great job! You've found your focus.",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              "Step 2: Find Your Focus",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Choose what you'd like to focus on right now.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                buildFocusCard("breath", "Your Breath",
                    "Focus on the sensation of breathing"),
                buildFocusCard(
                    "body", "Your Body", "Notice physical sensations"),
                buildFocusCard("sound", "Sounds", "Listen to ambient sounds"),
                buildFocusCard("thoughts", "Your Thoughts",
                    "Observe thoughts without judgment"),
              ],
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F46E5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFocusCard(String focus, String title, String description) {
    bool isSelected = selectedFocus == focus;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          selectedFocus = focus;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFE0E7FF) : Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF818CF8) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStep3() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            if (showSuccessMessage && currentStep == 3)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Excellent! You've completed the grounding exercise.",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            Text(
              "Step 3: Ground Yourself",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Let's do a quick grounding exercise to help you feel more present.",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Take a moment to:",
                    style: TextStyle(
                      color: Color(0xFF1E40AF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    List<String> steps = [
                      "Feel your feet on the ground",
                      "Notice the weight of your body",
                      "Take three deep breaths",
                      "Name three things you can see",
                      "Name three things you can hear",
                    ];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        "${index + 1}. ${steps[index]}",
                        style: TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 16,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => completeStep(3),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4F46E5),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Complete Journey",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
      backgroundColor: Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF4F46E5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Feeling Restless?",
          style: TextStyle(
            color: Color(0xFF4F46E5),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                "Let's find your focus and calm that energy, one step at a time.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              buildProgressTrack(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: currentStep == 1
                      ? buildStep1()
                      : currentStep == 2
                          ? buildStep2()
                          : buildStep3(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
