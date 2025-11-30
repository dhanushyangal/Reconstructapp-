import 'package:flutter/material.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';
import 'christmas_cutout_selection_page.dart';

class ChristmasSuccessPage extends StatefulWidget {
  const ChristmasSuccessPage({super.key});

  @override
  State<ChristmasSuccessPage> createState() => _ChristmasSuccessPageState();
}

class _ChristmasSuccessPageState extends State<ChristmasSuccessPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.75,
      end: 1.0, // 100% progress for success page
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

  void _navigateToChristmasSelection() {
    // Track the activity
    trackClick('christmas_success_try_different');

    // Navigate back to Christmas cutout selection page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChristmasCutoutSelectionPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Great Job!',
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
          
          // Main content
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Light blue horizontal line above
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Color(0xFF23C4F7),
                        margin: EdgeInsets.symmetric(horizontal: 40),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Main success message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          "Nice job! You've created a thing of beauty!",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Light blue horizontal line below
                      Container(
                        width: double.infinity,
                        height: 2,
                        color: Color(0xFF23C4F7),
                        margin: EdgeInsets.symmetric(horizontal: 40),
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Christmas greeting
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          "Wishing you a\nMerry Christmas\n&\nA Happy New Year!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      const SizedBox(height: 80),
                      
                      // Call to action
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "try a different ",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToChristmasSelection,
                              child: Text(
                                "Christmas cutout coloring",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF23C4F7),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get pageName => 'Christmas Success';
}


