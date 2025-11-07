import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/tool_usage_service.dart';
import 'package:intl/intl.dart';
import 'all_tools_view_page.dart';

class DashboardTrackerPage extends StatefulWidget {
  const DashboardTrackerPage({super.key});

  @override
  State<DashboardTrackerPage> createState() => _DashboardTrackerPageState();
}

class _DashboardTrackerPageState extends State<DashboardTrackerPage>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory; // null = All, or 'Release', 'Reset', 'Rewrite'
  int _completedCount = 0;
  int _totalCount = 0;
  double _progressPercentage = 0.0;
  bool _isLoading = true;
  
  // Individual category counts for "All" view
  int _releaseCount = 0;
  int _resetCount = 0;
  int _rewriteCount = 0;
  
  final ToolUsageService _toolUsageService = ToolUsageService();
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  // Category configurations
  final Map<String, Map<String, dynamic>> _categories = {
    'Release': {
      'category': ToolUsageService.categoryResetEmotions,
      'total': 12,
      'color': Colors.red,
      'lightColor': Colors.red.shade100,
      'message': "You've completed the basic mental fitness activities for today",
      'level': 'basic',
    },
    'Reset': {
      'category': ToolUsageService.categoryClearMind,
      'total': 12,
      'color': Colors.orange,
      'lightColor': Colors.orange.shade100,
      'message': "You've completed the intermediate mental fitness activities for today",
      'level': 'intermediate',
    },
    'Rewrite': {
      'category': ToolUsageService.categoryPlanFuture,
      'total': 4,
      'color': Colors.green,
      'lightColor': Colors.green.shade100,
      'message': "You've completed the advance mental fitness activities for today",
      'level': 'advance',
    },
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedCategory == null) {
        // Load all categories combined
        final releaseCompleted = await _toolUsageService.getUniqueToolsCountForToday(
          ToolUsageService.categoryResetEmotions);
        final resetCompleted = await _toolUsageService.getUniqueToolsCountForToday(
          ToolUsageService.categoryClearMind);
        final rewriteCompleted = await _toolUsageService.getUniqueToolsCountForToday(
          ToolUsageService.categoryPlanFuture);
        
        final totalAll = 12 + 12 + 4; // 28 total
        final completedAll = releaseCompleted + resetCompleted + rewriteCompleted;
        final percentage = totalAll > 0 ? (completedAll / totalAll * 100).clamp(0.0, 100.0) : 0.0;

        setState(() {
          _completedCount = completedAll;
          _totalCount = totalAll;
          _progressPercentage = percentage;
          _releaseCount = releaseCompleted;
          _resetCount = resetCompleted;
          _rewriteCount = rewriteCompleted;
          _isLoading = false;
        });
      } else {
        // Load specific category
        final categoryData = _categories[_selectedCategory]!;
        final category = categoryData['category'] as String;
        final total = categoryData['total'] as int;

        final completed = await _toolUsageService.getUniqueToolsCountForToday(category);
        final percentage = total > 0 ? (completed / total * 100).clamp(0.0, 100.0) : 0.0;

        setState(() {
          _completedCount = completed;
          _totalCount = total;
          _progressPercentage = percentage;
          _isLoading = false;
        });
      }

      // Animate progress
      _progressAnimationController.forward(from: 0.0);
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String? category) {
    if (_selectedCategory != category) {
      setState(() {
        _selectedCategory = category;
      });
      // Reset animation before loading new data
      _progressAnimationController.reset();
      _loadData();
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final day = now.day;
    String suffix = 'th';
    if (day == 1 || day == 21 || day == 31) suffix = 'st';
    else if (day == 2 || day == 22) suffix = 'nd';
    else if (day == 3 || day == 23) suffix = 'rd';
    
    final formatter = DateFormat("EEEE, d'$suffix' MMMM ''25");
    return formatter.format(now);
  }

  String _getCongratulatoryMessage() {
    if (_selectedCategory == null) {
      // All categories view
      if (_completedCount == 0) {
        return "You're on the path to building everyday mental fitness!";
      }
      return "You're on the path to building everyday mental fitness!";
    } else {
      // Specific category view
      if (_completedCount == 0) {
        return "Keep going! Complete more ${_selectedCategory!.toLowerCase()} activities.";
      }
      return _categories[_selectedCategory]!['message'] as String;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color categoryColor;
    Color categoryLightColor;
    
    if (_selectedCategory == null) {
      // All categories - use light blue
      categoryColor = Colors.lightBlue;
      categoryLightColor = Colors.lightBlue.shade100;
    } else {
      final categoryData = _categories[_selectedCategory]!;
      categoryColor = categoryData['color'] as Color;
      categoryLightColor = categoryData['lightColor'] as Color;
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Date display
                Text(
                  _getCurrentDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Circular progress indicator
                _buildCircularProgress(categoryColor, categoryLightColor),
                
                const SizedBox(height: 16),
                
                // Label below progress
                Text(
                  'Your daily mental fitness score',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.normal,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Category buttons
                _buildCategoryButtons(categoryColor),
                
                const SizedBox(height: 20),
                
                // View All Tools button
                _buildViewAllToolsButton(),
                
                const SizedBox(height: 40),
                
                // Congratulatory message
                _buildCongratulatoryMessage(),
                
                const SizedBox(height: 60),
                
                // Daily goals section
                _buildDailyGoalsSection(),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularProgress(Color color, Color lightColor) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedProgress = _progressPercentage * _progressAnimation.value;
        
        return SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rings (multiple concentric circles)
              CustomPaint(
                size: const Size(200, 200),
                painter: CircularProgressPainter(
                  progress: animatedProgress / 100,
                  color: color,
                  lightColor: lightColor,
                  isAllView: _selectedCategory == null,
                  releaseProgress: _selectedCategory == null 
                      ? (_releaseCount / 12.0 * _progressAnimation.value).clamp(0.0, 1.0) 
                      : 0.0,
                  resetProgress: _selectedCategory == null 
                      ? (_resetCount / 12.0 * _progressAnimation.value).clamp(0.0, 1.0) 
                      : 0.0,
                  rewriteProgress: _selectedCategory == null 
                      ? (_rewriteCount / 4.0 * _progressAnimation.value).clamp(0.0, 1.0) 
                      : 0.0,
                ),
              ),
              
              // Inner circle with percentage and count
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _selectedCategory == null ? Colors.lightBlue : lightColor,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${animatedProgress.toInt()}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_completedCount/$_totalCount',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategory == null ? Colors.lightBlue.shade700 : color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryButtons(Color selectedColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCategoryButton('Release', Colors.red),
        const SizedBox(width: 40),
        _buildCategoryButton('Reset', Colors.orange),
        const SizedBox(width: 40),
        _buildCategoryButton('Rewrite', Colors.green),
      ],
    );
  }

  Widget _buildCategoryButton(String category, Color color) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isSelected ? color : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCongratulatoryMessage() {
    return Column(
      children: [
        Text(
          _completedCount > 0 ? 'Congratulations!' : 'Keep Going!',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            _getCongratulatoryMessage(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.black87,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllToolsButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AllToolsViewPage(),
            ),
          );
        },
        icon: const Icon(Icons.grid_view, color: Colors.white),
        label: const Text(
          'View All Tools',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyGoalsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your daily goals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              // Placeholder for daily goal indicators
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color lightColor;
  final bool isAllView;
  final double releaseProgress;
  final double resetProgress;
  final double rewriteProgress;

  CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.lightColor,
    this.isAllView = false,
    this.releaseProgress = 0.0,
    this.resetProgress = 0.0,
    this.rewriteProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    if (isAllView) {
      // Show different rings for each category
      // Outer ring - Release (red)
      _drawRing(canvas, center, radius, 8.0, Colors.red, releaseProgress, 0.4);
      // Middle ring - Reset (yellow/orange)
      _drawRing(canvas, center, radius - 12, 6.0, Colors.orange, resetProgress, 0.5);
      // Inner ring - Rewrite (green)
      _drawRing(canvas, center, radius - 24, 4.0, Colors.green, rewriteProgress, 0.6);
    } else {
      // Show single category with multiple rings
      final rings = [
        {'radius': radius, 'strokeWidth': 8.0, 'alpha': 0.3},
        {'radius': radius - 10, 'strokeWidth': 6.0, 'alpha': 0.4},
        {'radius': radius - 20, 'strokeWidth': 4.0, 'alpha': 0.5},
      ];

      for (var ring in rings) {
        final r = ring['radius'] as double;
        final strokeWidth = ring['strokeWidth'] as double;
        final alpha = ring['alpha'] as double;
        
        // Background circle (light color)
        final backgroundPaint = Paint()
          ..color = lightColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        
        canvas.drawCircle(center, r, backgroundPaint);
        
        // Progress arc (main color)
        final progressPaint = Paint()
          ..color = color.withOpacity(alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        
        final sweepAngle = 2 * math.pi * progress;
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          -math.pi / 2, // Start from top
          sweepAngle,
          false,
          progressPaint,
        );
      }
    }
  }
  
  void _drawRing(Canvas canvas, Offset center, double radius, double strokeWidth, Color ringColor, double progress, double alpha) {
    // Background circle
    final backgroundPaint = Paint()
      ..color = ringColor.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor.withOpacity(alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.lightColor != lightColor ||
        oldDelegate.isAllView != isAllView ||
        oldDelegate.releaseProgress != releaseProgress ||
        oldDelegate.resetProgress != resetProgress ||
        oldDelegate.rewriteProgress != rewriteProgress;
  }
}
