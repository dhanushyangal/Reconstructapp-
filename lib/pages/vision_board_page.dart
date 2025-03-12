import 'package:flutter/material.dart';
import 'box_them_vision_board.dart';
import 'post_it_theme_vision_board.dart';
import 'premium_them_vision_board.dart';
import 'sport_it_theme_vision_board.dart';
import 'animal_board_page.dart';
import 'watercolor_board_page.dart';

class VisionBoardPage extends StatelessWidget {
  const VisionBoardPage({super.key});

  Widget _buildTemplateCard(
      BuildContext context, String imagePath, String title) {
    return GestureDetector(
      onTap: () {
        if (title == 'Premium theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumThemeVisionBoard(),
            ),
          );
        } else if (title == 'PostIt theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostItThemeVisionBoard(),
            ),
          );
        } else if (title == 'Sport theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SportThemeVisionBoard(),
            ),
          );
        } else if (title == 'Animal theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AnimalThemeVisionBoard(),
            ),
          );
        } else if (title == 'Watercolor theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WatercolorThemeVisionBoard(),
            ),
          );
        } else if (title == 'Box theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisionBoardDetailsPage(title: title),
            ),
          );
        }
        // Add more conditions for other titles if needed
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
      appBar: AppBar(
        title: const Text('Vision Board'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vision Board Templates for 2025',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your own custom 2025 vision board online for FREE.',
              style: TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                children: [
                  _buildTemplateCard(
                      context,
                      'assets/vision-board-ruled-theme.png',
                      'Box theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/Post-it Theme-Vision-Board.png',
                      'PostIt theme Vision Board'),
                  _buildTemplateCard(context, 'assets/premium-theme.png',
                      'Premium theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/sporttheme-vision-board.png',
                      'Sport theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/animal-themed-template.png',
                      'Animal theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/watercolor-theme-vision-board.png',
                      'Watercolor theme Vision Board'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
