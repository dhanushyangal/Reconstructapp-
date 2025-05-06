import 'package:flutter/material.dart';
import 'color_me_page.dart';
import 'face_color_page.dart';
import 'figure_color_page.dart';
import 'elephant_color_page.dart';

class ColorMeNowPage extends StatefulWidget {
  const ColorMeNowPage({super.key});

  @override
  State<ColorMeNowPage> createState() => _ColorMeNowPageState();
}

class _ColorMeNowPageState extends State<ColorMeNowPage> {
  // Current selection
  String currentPage = 'Bird';
  final List<String> availablePages = ['Bird', 'Face', 'Figure', 'Elephant'];

  // Image assets for preview
  final Map<String, String> previewAssets = {
    'Bird': 'assets/images/bird_preview.png',
    'Face': 'assets/images/face_preview.png',
    'Figure': 'assets/images/figure_preview.png',
    'Elephant': 'assets/images/elephant_preview.png',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Me Now'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Subject selector
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availablePages.length,
              itemBuilder: (context, index) {
                final page = availablePages[index];
                final isSelected = page == currentPage;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentPage = page;
                    });
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                      border: isSelected
                          ? Border.all(color: Colors.blue.shade400, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForPage(page),
                          color: isSelected
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          page,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.blue.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Description

          // Selected coloring page
          Expanded(
            child: _buildSelectedPage(),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(String page) {
    switch (page) {
      case 'Bird':
        return Icons.flutter_dash;
      case 'Face':
        return Icons.face;
      case 'Figure':
        return Icons.accessibility_new;
      case 'Elephant':
        return Icons.pets;
      default:
        return Icons.color_lens;
    }
  }

  Widget _buildSelectedPage() {
    switch (currentPage) {
      case 'Bird':
        return const ColorMeContent();
      case 'Face':
        return const FaceColorContent();
      case 'Figure':
        return const FigureColorContent();
      case 'Elephant':
        return const ElephantColorContent();
      default:
        return const Center(child: Text('Select a coloring page'));
    }
  }
}

// Content-only widgets for each coloring page
class ColorMeContent extends StatelessWidget {
  const ColorMeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Navigator.push would create another scaffold inside scaffold
    // so we'll just use the content portion of ColorMePage
    return _EmbeddedColoringPage(
      builder: (context) => ColorMePage(),
    );
  }
}

class FaceColorContent extends StatelessWidget {
  const FaceColorContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _EmbeddedColoringPage(
      builder: (context) => FaceColorPage(),
    );
  }
}

class FigureColorContent extends StatelessWidget {
  const FigureColorContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _EmbeddedColoringPage(
      builder: (context) => FigureColorPage(),
    );
  }
}

class ElephantColorContent extends StatelessWidget {
  const ElephantColorContent({super.key});

  @override
  Widget build(BuildContext context) {
    return _EmbeddedColoringPage(
      builder: (context) => ElephantColorPage(),
    );
  }
}

// Helper widget to embed a full page as content
class _EmbeddedColoringPage extends StatelessWidget {
  final Widget Function(BuildContext) builder;

  const _EmbeddedColoringPage({required this.builder});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      // Get the widget tree from the builder
      final Widget fullPage = builder(context);

      // Find the actual content below the AppBar
      if (fullPage is Scaffold) {
        // Extract the body from the scaffold
        return fullPage.body ?? const SizedBox.shrink();
      }

      // Fallback if structure changes
      return fullPage;
    });
  }
}
