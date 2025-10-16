import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import 'love_yourself_quiz_page.dart';

class AffirmationCardsPage extends StatefulWidget {
  final String categoryName;

  const AffirmationCardsPage({
    super.key,
    required this.categoryName,
  });

  @override
  State<AffirmationCardsPage> createState() => _AffirmationCardsPageState();
}

class _AffirmationCardsPageState extends State<AffirmationCardsPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  List<bool> _flippedCards = [];
  int _flippedCount = 0;
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  // Affirmations data for each category
  final Map<String, List<Map<String, dynamic>>> _affirmationsData = {
    'Self love': [
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-1.png',
        'quote': 'You\'re allowed to feel what you feel.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-2.png',
        'quote': 'You\'re loved more than you know.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-3.png',
        'quote': 'You are valued.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-4.png',
        'quote': 'Build positive self-talk.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-5.png',
        'quote': 'You\'re allowed to let go of toxic people.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-6.png',
        'quote': 'You\'re highly capable of making the right decisions.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-7.png',
        'quote': 'You\'re right in prioritizing yourself over others.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-8.png',
        'quote': 'All that you wish for is coming to you.',
      },
      {
        'image': 'assets/Build_Self_love/Self_love/Loveyourself-9.png',
        'quote': 'You speak with a calm confidence.',
      },
    ],
    'Gratitude': [
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/20.png',
        'quote': 'I am thankful for this day.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/21.png',
        'quote': 'I am grateful for the people in my life.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/22.png',
        'quote': 'I see the good around me.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/23.png',
        'quote': 'I am blessed by life\'s moments.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/24.png',
        'quote': 'I appreciate all the lessons I\'ve learned.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/25.png',
        'quote': 'I am aware of how much I already have.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/26.png',
        'quote': 'I am at peace with what I can\'t control.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/27.png',
        'quote': 'I am present and mindful of today\'s gifts.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/28.png',
        'quote': 'I am surrounded by love & kindness.',
      },
      {
        'image': 'assets/Build_Self_love/Gratitude_cards/29.png',
        'quote': 'I am grateful for the chance to grow each day.',
      },
    ],
    'Confidence': [
      {
        'image': 'assets/Build_Self_love/Confidence_cards/1.png',
        'quote': 'I can handle whatever comes my way.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/2.png',
        'quote': 'I can learn what I don\'t yet know.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/3.png',
        'quote': 'I can speak up and be heard.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/4.png',
        'quote': 'I will trust my instincts.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/5.png',
        'quote': 'I will back myself in every decision.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/6.png',
        'quote': 'I will show up fully and give my best.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/7.png',
        'quote': 'I want to grow stronger each day.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/8.png',
        'quote': 'I will use my voice with courage.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/9.png',
        'quote': 'I embrace challenges with confidence.',
      },
      {
        'image': 'assets/Build_Self_love/Confidence_cards/10.png',
        'quote': 'I keep moving forward, no matter what.',
      },
    ],
    'High Performance': [
      {
        'image': 'assets/Build_Self_love/High_performance_cards/10.png',
        'quote': 'I start strong.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/11.png',
        'quote': 'I move fast.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/12.png',
        'quote': 'I push harder.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/13.png',
        'quote': 'I stay sharp.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/14.png',
        'quote': 'I rise higher.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/15.png',
        'quote': 'I act now.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/16.png',
        'quote': 'I keep going.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/17.png',
        'quote': 'I break limits.',
      },
      {
        'image': 'assets/Build_Self_love/High_performance_cards/18.png',
        'quote': 'I finish strong.',
      },
    ],
  };

  // Get affirmations for the current category
  List<Map<String, dynamic>> get _affirmations => 
      _affirmationsData[widget.categoryName] ?? [];

  @override
  void initState() {
    super.initState();
    
    // Initialize flipped cards list
    _flippedCards = List.filled(_affirmations.length, false);
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.5,
      end: 0.75, // 75% progress for affirmation cards page
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

  void _flipCard(int index) {
    if (!_flippedCards[index]) {
      setState(() {
        _flippedCards[index] = true;
        _flippedCount++;
      });

      // Track the activity
      trackClick('affirmation_card_${widget.categoryName}_$index');

      // Check if all cards are flipped
      if (_flippedCount == _affirmations.length) {
        // Show completion message after a delay
        Future.delayed(Duration(seconds: 2), () {
          _showCompletionDialog();
        });
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: Colors.orange,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You\'ve completed all ${widget.categoryName.toLowerCase()} affirmations!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Keep practicing these positive affirmations daily for the best results.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset all cards
                setState(() {
                  _flippedCards = List.filled(_affirmations.length, false);
                  _flippedCount = 0;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Over',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: widget.categoryName,
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
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Build self-love for a stronger you',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _affirmations.length,
                      itemBuilder: (context, index) {
                        return _buildFlipCard(index);
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  // Next button
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _navigateToQuiz();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF23C4F7),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(int index) {
    final affirmation = _affirmations[index];
    final isFlipped = _flippedCards[index];

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(isFlipped ? 3.14159 : 0),
          child: isFlipped ? _buildBackCard(affirmation) : _buildFrontCard(affirmation),
        ),
      ),
    );
  }

  Widget _buildFrontCard(Map<String, dynamic> affirmation) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          affirmation['image'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image_not_supported,
                size: 40,
                color: Colors.grey[400],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackCard(Map<String, dynamic> affirmation) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159), // Flip the text back
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                affirmation['quote'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '***',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToQuiz() {
    // Track the activity
    trackClick('affirmation_cards_next_${widget.categoryName}');

    // Navigate to quiz page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoveYourselfQuizPage(
          categoryName: widget.categoryName,
        ),
      ),
    );
  }

  String get pageName => '${widget.categoryName} Affirmations';
}
