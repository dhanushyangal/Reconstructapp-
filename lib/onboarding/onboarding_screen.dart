import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/initial_auth_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showGetStarted = false;
  bool _showLogo = true;
  bool _showReconstructLogo = false;

  final List<String> _onboardingImages = [
    'assets/onboarding1.jpg',
    'assets/onboarding2.jpg',
    'assets/onboarding3.jpg',
  ];

  @override
  void initState() {
    super.initState();

    // Show first logo for 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showLogo = false;
          _showReconstructLogo = true;
        });

        // Show second logo for 1 second then show onboarding
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showReconstructLogo = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => InitialAuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _showLogo
          ? Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Image.asset(
                  'assets/logo_transparent.png',
                  fit: BoxFit.contain,
                ),
              ),
            )
          : _showReconstructLogo
              ? Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Image.asset(
                      'assets/reconstruct_transparent.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                          _showGetStarted =
                              index == _onboardingImages.length - 1;
                        });
                      },
                      itemCount: _onboardingImages.length,
                      itemBuilder: (context, index) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height * 0.7,
                              width: MediaQuery.of(context).size.width * 0.9,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 5,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  color: Colors.white,
                                  child: Image.asset(
                                    _onboardingImages[index],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (!_showGetStarted)
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: MediaQuery.of(context).size.height * 0.3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.arrow_back_ios,
                              color: Colors.black.withOpacity(0.7),
                              size: 20,
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.black.withOpacity(0.7),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      bottom: 50,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _onboardingImages.length,
                              (index) => Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentPage == index
                                      ? Colors.black
                                      : Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          if (_showGetStarted) ...[
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: ElevatedButton(
                                onPressed: _finishOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text('Get Started'),
                              ),
                            ),
                          ],
                          if (!_showGetStarted) ...[
                            const SizedBox(height: 20),
                            Text(
                              'Swipe to continue',
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
