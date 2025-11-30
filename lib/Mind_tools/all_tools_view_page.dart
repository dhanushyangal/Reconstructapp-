import 'package:flutter/material.dart';
import '../services/tool_usage_service.dart';

class AllToolsViewPage extends StatefulWidget {
  const AllToolsViewPage({super.key});

  @override
  State<AllToolsViewPage> createState() => _AllToolsViewPageState();
}

class _AllToolsViewPageState extends State<AllToolsViewPage> {
  final ToolUsageService _toolUsageService = ToolUsageService();
  bool _isLoading = true;
  Set<String> _completedTools = {};

  // Define all tools organized by category
  final Map<String, List<Map<String, dynamic>>> _allTools = {
    'Reset my emotions': [
      // Release negative thoughts (4 tools)
      {'name': 'Thought Shredder', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Break Things', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Make Me Smile', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Bubble Wrap Popper', 'category': ToolUsageService.categoryResetEmotions},
      // Build positive self-talk (4 tools)
      {'name': 'Self love Affirmations', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Gratitude Affirmations', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Confidence Affirmations', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'High performance Affirmations', 'category': ToolUsageService.categoryResetEmotions},
      // Master your breathing (4 tools)
      {'name': 'Box Breathing', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Alternate Nose Breathing', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Deep Breathing', 'category': ToolUsageService.categoryResetEmotions},
      {'name': 'Intentional Breathing', 'category': ToolUsageService.categoryResetEmotions},
    ],
    'Clear my mind': [
      // Digital coloring (4 tools)
      {'name': 'Elephant Coloring', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Bird Coloring', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Figure Coloring', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Face Coloring', 'category': ToolUsageService.categoryClearMind},
      // Sliding puzzles (4 tools) - Note: names may have trailing spaces
      {'name': 'Fox Sliding Puzzle ', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Dog Sliding Puzzle', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Lion Sliding Puzzle', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Owl Sliding Puzzle', 'category': ToolUsageService.categoryClearMind},
      // Memory games (4 tools)
      {'name': 'Everyday things - memory game', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Famous monuments - memory game', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Famous people - memory game', 'category': ToolUsageService.categoryClearMind},
      {'name': 'Japanese animals - memory game', 'category': ToolUsageService.categoryClearMind},
    ],
    'Plan my future': [
      {'name': 'Annual Goals', 'category': ToolUsageService.categoryPlanFuture, 'normalized': true},
      {'name': 'Weekly Goals', 'category': ToolUsageService.categoryPlanFuture, 'normalized': true},
      {'name': 'Monthly Goals', 'category': ToolUsageService.categoryPlanFuture, 'normalized': true},
      {'name': 'Daily Goals', 'category': ToolUsageService.categoryPlanFuture, 'normalized': true},
    ],
  };

  final Map<String, Color> _categoryColors = {
    'Reset my emotions': Colors.red,
    'Clear my mind': Colors.orange,
    'Plan my future': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    _loadCompletedTools();
  }

  Future<void> _loadCompletedTools() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final today = _formatDate(DateTime.now());
      final completedSet = <String>{};

      // Load completed tools for each category
      for (var category in [
        ToolUsageService.categoryResetEmotions,
        ToolUsageService.categoryClearMind,
        ToolUsageService.categoryPlanFuture,
      ]) {
        final entries = await _toolUsageService.getEntriesForCategoryAndDate(category, today);

        if (category == ToolUsageService.categoryPlanFuture) {
          // Normalize Plan my future tools
          final normalized = entries.map((e) {
            final toolName = e['toolName'] as String? ?? '';
            final metadata = e['metadata'] as Map<String, dynamic>? ?? {};
            final toolType = metadata['toolType'] as String?;

            if (toolType == 'annual_goals') return 'Annual Goals';
            if (toolType == 'weekly_goals') return 'Weekly Goals';
            if (toolType == 'monthly_goals') return 'Monthly Goals';
            if (toolType == 'daily_goals') return 'Daily Goals';

            final name = toolName.toLowerCase();
            if (name.contains('annual') || name.contains('vision board')) return 'Annual Goals';
            if (name.contains('weekly')) return 'Weekly Goals';
            if (name.contains('monthly')) return 'Monthly Goals';
            if (name.contains('daily')) return 'Daily Goals';

            return toolName;
          }).where((name) => name.isNotEmpty).toSet();

          completedSet.addAll(normalized);
        } else {
          // For other categories, use tool names as-is
          final toolNames = entries
              .map((e) => e['toolName'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toSet();
          completedSet.addAll(toolNames);
        }
      }

      setState(() {
        _completedTools = completedSet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading completed tools: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isToolCompleted(String toolName, Map<String, dynamic> toolData) {
    if (toolData['normalized'] == true) {
      // For normalized tools, check exact match (normalized names)
      return _completedTools.contains(toolName);
    }
    
    // Trim both tool name and check against trimmed completed tools
    final toolNameTrimmed = toolName.trim();
    
    // Check exact match first (with trimming)
    for (var completed in _completedTools) {
      if (completed.trim() == toolNameTrimmed) {
        return true;
      }
    }
    
    // For tools with variations, check partial matches
    final toolNameLower = toolNameTrimmed.toLowerCase();
    for (var completed in _completedTools) {
      final completedTrimmed = completed.trim();
      final completedLower = completedTrimmed.toLowerCase();
      
      // Handle puzzle names (e.g., "Fox Sliding Puzzle" matches "Fox Sliding Puzzle ")
      if (toolNameLower.contains('puzzle') && completedLower.contains('puzzle')) {
        final toolBase = toolNameLower.replaceAll(' sliding puzzle', '').replaceAll(' puzzle', '').trim();
        final completedBase = completedLower.replaceAll(' sliding puzzle', '').replaceAll(' puzzle', '').trim();
        if (toolBase == completedBase && toolBase.isNotEmpty) {
          return true;
        }
      }
      
      // Handle memory game names
      if (toolNameLower.contains('memory') && completedLower.contains('memory')) {
        final toolBase = toolNameLower.replaceAll(' - memory game', '').replaceAll(' memory game', '').trim();
        final completedBase = completedLower.replaceAll(' - memory game', '').replaceAll(' memory game', '').trim();
        if (toolBase == completedBase && toolBase.isNotEmpty) {
          return true;
        }
      }
      
      // Handle coloring names
      if (toolNameLower.contains('coloring') && completedLower.contains('coloring')) {
        final toolBase = toolNameLower.replaceAll(' coloring', '').trim();
        final completedBase = completedLower.replaceAll(' coloring', '').trim();
        if (toolBase == completedBase && toolBase.isNotEmpty) {
          return true;
        }
      }
      
      // Handle affirmation names
      if (toolNameLower.contains('affirmations') && completedLower.contains('affirmations')) {
        final toolBase = toolNameLower.replaceAll(' affirmations', '').trim();
        final completedBase = completedLower.replaceAll(' affirmations', '').trim();
        if (toolBase == completedBase && toolBase.isNotEmpty) {
          return true;
        }
      }
    }
    
    return false;
  }

  String _getDisplayName(String toolName) {
    // Convert tool names to display format
    if (toolName == 'Make Me Smile') return 'Make me smile';
    if (toolName == 'Bubble Wrap Popper') return 'Bubble popper';
    if (toolName == 'Self love Affirmations') return 'Self-love';
    if (toolName == 'Gratitude Affirmations') return 'Gratitude';
    if (toolName == 'Confidence Affirmations') return 'Confidence';
    if (toolName == 'High performance Affirmations') return 'High performance';
    if (toolName == 'Alternate Nose Breathing') return 'Nose breathing';
    if (toolName == 'Figure Coloring') return 'Giraffe coloring';
    if (toolName == 'Fox Sliding Puzzle') return 'Fox puzzle';
    if (toolName == 'Dog Sliding Puzzle') return 'Dog puzzle';
    if (toolName == 'Lion Sliding Puzzle') return 'Lion puzzle';
    if (toolName == 'Owl Sliding Puzzle') return 'Owl puzzle';
    if (toolName == 'Everyday things - memory game') return 'Everyday memory cards';
    if (toolName == 'Famous monuments - memory game') return 'Monuments memory cards';
    if (toolName == 'Famous people - memory game') return 'Famous people memory cards';
    if (toolName == 'Japanese animals - memory game') return 'Japanese animals memory cards';
    if (toolName == 'Annual Goals') return 'Annual Planner';
    if (toolName == 'Weekly Goals') return 'Weekly Planner';
    if (toolName == 'Monthly Goals') return 'Monthly Planner';
    if (toolName == 'Daily Goals') return 'Daily Planner';
    return toolName;
  }
  // ➤ ADD THIS HERE
int _completedCountForCategory(String categoryName, List<Map<String, dynamic>> tools) {
  int count = 0;

  for (var tool in tools) {
    final toolName = tool['name'] as String;
    if (_isToolCompleted(toolName, tool)) {
      count++;
    }
  }

  return count;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Tools'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: _allTools.entries.map((entry) {
                  final categoryName = entry.key;
                  final tools = entry.value;
                  final categoryColor = _categoryColors[categoryName]!;

                  return _buildCategorySection(categoryName, tools, categoryColor);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildCategorySection(
    String categoryName,
    List<Map<String, dynamic>> tools,
    Color categoryColor,
  ) {
    final isPlanFuture = categoryName == 'Plan my future';
    final crossAxisCount = isPlanFuture ? 4 : 4;
    final mainAxisSpacing = isPlanFuture ? 8.0 : 12.0;
    final crossAxisSpacing = isPlanFuture ? 8.0 : 12.0;

    return Container(
      margin: EdgeInsets.only(
        bottom: categoryName == 'Plan my future' ? 0 : 24,
        top: categoryName == 'Reset my emotions' ? 0 : 24,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: categoryName == 'Plan my future' ? 20 : 0,
      ),
      decoration: BoxDecoration(
        color: categoryName == 'Plan my future' ? Colors.grey[100] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              categoryName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Sub-text
Padding(
  padding: const EdgeInsets.only(bottom: 16.0),
  child: Text(
    '${_completedCountForCategory(categoryName, tools)} of ${tools.length} unlocked',
    style: const TextStyle(
      fontSize: 13,
      color: Colors.black54,
      fontWeight: FontWeight.w500,
    ),
  ),
),
    
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: isPlanFuture ? 0.90 : 0.75,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              final toolName = tool['name'] as String;
              final isCompleted = _isToolCompleted(toolName, tool);
              final displayName = _getDisplayName(toolName);

              return _buildToolCircle(
                displayName,
                categoryColor,
                isCompleted,
              );
            },
          ),
          if (categoryName == 'Clear my mind')
            Container(
              margin: const EdgeInsets.only(top: 16),
              height: 1,
              color: Colors.black,
            ),
        ],
      ),
    );
  }

  Widget _buildToolCircle(String toolName, Color categoryColor, bool isCompleted) {
    final circleColor = isCompleted ? categoryColor : categoryColor.withOpacity(0.3);
    final isPlanFuture = toolName.contains('Planner');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: isPlanFuture ? 65 : 70,
            height: isPlanFuture ? 65 : 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
            ),
            child: isCompleted
                ? Icon(
                    Icons.star,
                    color: Colors.white,
                    size: isPlanFuture ? 28 : 32,
                  )
                : null,
          ),
          SizedBox(height: isPlanFuture ? 2 : 4),
          Text(
            toolName,
            style: TextStyle(
              fontSize: isPlanFuture ? 9.0 : 9.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: isPlanFuture ? 1.0 : 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

