import 'package:flutter/material.dart';
import '../services/tool_usage_service.dart';
import '../components/nav_logpage.dart';

class ToolUsageHistoryPage extends StatefulWidget {
  const ToolUsageHistoryPage({super.key});

  @override
  State<ToolUsageHistoryPage> createState() => _ToolUsageHistoryPageState();
}

class _ToolUsageHistoryPageState extends State<ToolUsageHistoryPage> {
  final ToolUsageService _toolUsageService = ToolUsageService();
  String _selectedCategory = 'All';
  String? _selectedDate;
  List<Map<String, dynamic>> _entries = [];
  List<String> _availableDates = [];
  bool _isLoading = true;

  final Map<String, String> _categoryDisplayNames = {
    'All': 'All Categories',
    ToolUsageService.categoryResetEmotions: 'Reset my emotions',
    ToolUsageService.categoryClearMind: 'Clear my mind',
    ToolUsageService.categoryPlanFuture: 'Plan my future',
  };

  final Map<String, Color> _categoryColors = {
    ToolUsageService.categoryResetEmotions: const Color(0xFF81D0FF),
    ToolUsageService.categoryClearMind: const Color(0xFFB19CD9),
    ToolUsageService.categoryPlanFuture: const Color(0xFFFFD89B),
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load available dates
      if (_selectedCategory == 'All') {
        _availableDates = await _toolUsageService.getAllDatesWithEntries();
      } else {
        _availableDates = await _toolUsageService.getDatesForCategory(_selectedCategory);
      }

      // Load entries
      await _loadEntries();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEntries() async {
    if (_selectedDate != null) {
      if (_selectedCategory == 'All') {
        _entries = await _toolUsageService.getEntriesForDate(_selectedDate!);
      } else {
        _entries = await _toolUsageService.getEntriesForCategoryAndDate(
          _selectedCategory,
          _selectedDate!,
        );
      }
    } else {
      // Load all entries for category
      if (_selectedCategory == 'All') {
        final allDates = await _toolUsageService.getAllDatesWithEntries();
        _entries = [];
        for (var date in allDates) {
          final dateEntries = await _toolUsageService.getEntriesForDate(date);
          _entries.addAll(dateEntries);
        }
      } else {
        _entries = await _toolUsageService.getEntriesForCategory(_selectedCategory);
      }
    }

    // Sort by timestamp (most recent first)
    _entries.sort((a, b) {
      final timestampA = a['timestamp'] as String? ?? '';
      final timestampB = b['timestamp'] as String? ?? '';
      return timestampB.compareTo(timestampA);
    });
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedDate = null; // Reset date when category changes
    });
    _loadData();
  }

  void _onDateSelected(String date) {
    setState(() {
      _selectedDate = _selectedDate == date ? null : date;
    });
    _loadEntries();
  }

  Future<void> _selectDateFromCalendar() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final dateString = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _onDateSelected(dateString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'My Journal',
      showBackButton: true,
      selectedIndex: 2,
      body: Column(
        children: [
          // Category filter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All'),
                        const SizedBox(width: 8),
                        _buildCategoryChip(ToolUsageService.categoryResetEmotions),
                        const SizedBox(width: 8),
                        _buildCategoryChip(ToolUsageService.categoryClearMind),
                        const SizedBox(width: 8),
                        _buildCategoryChip(ToolUsageService.categoryPlanFuture),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Date selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _selectDateFromCalendar,
                          tooltip: 'Select date',
                        ),
                        if (_selectedDate != null)
                          GestureDetector(
                            onTap: () => _onDateSelected(_selectedDate!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFF23C4F7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    ToolUsageService.formatDateForDisplay(_selectedDate!),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ..._availableDates.take(7).map((date) {
                          final isSelected = _selectedDate == date;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _onDateSelected(date),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(0xFF23C4F7)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  ToolUsageService.formatDateForDisplay(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Entries list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No entries found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedDate != null
                                  ? 'Try selecting a different date'
                                  : 'Start using tools to see your history here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (context, index) {
                          final entry = _entries[index];
                          return _buildEntryCard(entry);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    final displayName = _categoryDisplayNames[category] ?? category;
    final color = _categoryColors[category] ?? Colors.grey;

    return GestureDetector(
      onTap: () => _onCategoryChanged(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final category = entry['category'] as String? ?? 'unknown';
    final toolName = entry['toolName'] as String? ?? 'Unknown Tool';
    final date = entry['date'] as String? ?? '';
    final timestamp = entry['timestamp'] as String? ?? '';
    final color = _categoryColors[category] ?? Colors.grey;

    // Parse timestamp for display
    String timeDisplay = '';
    try {
      if (timestamp.isNotEmpty) {
        final dateTime = DateTime.parse(timestamp);
        final hour = dateTime.hour;
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        timeDisplay = '$displayHour:$minute $period';
      }
    } catch (e) {
      // Ignore parsing errors
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _categoryDisplayNames[category] ?? category,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (timeDisplay.isNotEmpty)
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                toolName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ToolUsageService.formatDateForDisplay(date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

