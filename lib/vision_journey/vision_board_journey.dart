import 'package:flutter/material.dart';
import 'travel_journey.dart';
import 'selfcare_journey.dart';
import 'finance_journey.dart';

class VisionBoardJourney extends StatelessWidget {
  const VisionBoardJourney({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative background shapes
            Positioned(
              left: -40,
              top: -40,
              child: Image.asset(
                'assets/shape_top_left.png',
                width: 200,
                height: 200,
                color: Colors.indigo.withOpacity(0.3),
              ),
            ),
            Positioned(
              right: -40,
              bottom: -40,
              child: Image.asset(
                'assets/shape_bottom_right.png',
                width: 200,
                height: 200,
                color: Colors.amber.withOpacity(0.3),
              ),
            ),

            // Main content
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildMainContent(context),
                ),
                _buildFooter(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      child: const Column(
        children: [
          SizedBox(height: 8),
          Text(
            'Reconstruct',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4338CA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          const Text(
            'Your Vision Board',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4338CA),
            ),
          ),
          // Gradient underline
          Container(
            height: 6,
            width: 120,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFA78BFA), Color(0xFF38BDF8)],
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Text(
            'Start or continue your journeys below. Each card is a new adventure!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dream big. Grow daily. Celebrate every step.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),

          // Journey cards grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildJourneyCard(
                context: context,
                emoji: '🌍',
                title: 'Travel',
                description: 'Plan your dream destinations for 2025',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const TravelJourney()),
                ),
              ),
              _buildJourneyCard(
                context: context,
                emoji: '🧘‍♂️',
                title: 'Self-Care',
                description: 'Build and track one life habit for a month',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SelfCareJourney()),
                ),
              ),
              _buildJourneyCard(
                context: context,
                emoji: '💸',
                title: 'Finance',
                description: 'Expand portfolio & become financially aware',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FinanceJourney()),
                ),
              ),
              _buildLockedJourneyCard(
                emoji: '💼',
                title: 'Career',
                description: 'Coming soon',
              ),
              _buildLockedJourneyCard(
                emoji: '🏥',
                title: 'Health',
                description: 'Coming soon',
              ),
              _buildLockedJourneyCard(
                emoji: '👨‍👩‍👧‍👦',
                title: 'Family',
                description: 'Coming soon',
              ),
              _buildLockedJourneyCard(
                emoji: '❤️',
                title: 'Relationships',
                description: 'Coming soon',
              ),
              _buildLockedJourneyCard(
                emoji: '🍲',
                title: 'Food',
                description: 'Coming soon',
              ),
              _buildLockedJourneyCard(
                emoji: '🎨',
                title: 'Hobbies',
                description: 'Coming soon',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyCard({
    required BuildContext context,
    required String emoji,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.7),
                color,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Journey',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedJourneyCard({
    required String emoji,
    required String title,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Opacity(
        opacity: 0.6,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.grey[500],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Locked'),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: const Text(
        '© 2023 Reconstruct. All rights reserved.',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
