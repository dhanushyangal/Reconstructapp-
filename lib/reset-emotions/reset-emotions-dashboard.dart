import 'package:flutter/material.dart';

class ResetEmotionsDashboard extends StatelessWidget {
  const ResetEmotionsDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE6F7FF),
              Color(0xFFDCF2FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Reconstruct',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: [
                        // Title Section
                        Text(
                          'How are you feeling right now?',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Container(
                          width: 80,
                          height: 4,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF64B5F6), Color(0xFF1E88E5)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'Select an emotion to start your guided journey.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),

                        // Emotion Cards Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 900
                                  ? 3
                                  : MediaQuery.of(context).size.width > 640
                                      ? 2
                                      : 1,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.85,
                          children: [
                            _buildEmotionCard(
                              emoji: '🤯',
                              title: 'Overwhelmed',
                              description:
                                  'Find tools to calm your mind and regain focus.',
                              onTap: () {},
                            ),
                            _buildEmotionCard(
                              emoji: '😔',
                              title: 'Low',
                              description:
                                  'Activities to help you vent and lift your spirits.',
                              onTap: () {},
                            ),
                            _buildEmotionCard(
                              emoji: '😠',
                              title: 'Angry',
                              description:
                                  'Techniques to soothe yourself and find peace.',
                              onTap: () {},
                            ),
                            _buildEmotionCard(
                              emoji: '😬',
                              title: 'Restless',
                              description:
                                  'Exercises to help you gain clarity and calm.',
                              onTap: () {},
                            ),
                            _buildEmotionCard(
                              emoji: '😶',
                              title: 'Numb',
                              description:
                                  'Explore ways to reconnect with your emotions.',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  '© 2023 Reconstruct. All rights reserved.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionCard({
    required String emoji,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacer(),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Begin Journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
