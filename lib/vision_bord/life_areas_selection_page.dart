import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/activity_tracker_mixin.dart';
import 'custom_vision_board_page.dart';

class LifeAreasSelectionPage extends StatefulWidget {
  final String template;
  final String imagePath;

  const LifeAreasSelectionPage({
    super.key,
    required this.template,
    required this.imagePath,
  });

  @override
  State<LifeAreasSelectionPage> createState() => _LifeAreasSelectionPageState();
}

class _LifeAreasSelectionPageState extends State<LifeAreasSelectionPage>
    with ActivityTrackerMixin {
  Set<String> _selectedAreas = {};
  bool _isLoading = false;

  String get pageName => 'Life Areas Selection';

  // All 22 life areas
  final List<String> _allLifeAreas = [
    'Travel',
    'Career',
    'Family',
    'Income',
    'Health',
    'Fitness',
    'Social life',
    'Self care',
    'Skill',
    'Education',
    'Relationships',
    'Spirituality',
    'Hobbies',
    'Personal Growth',
    'Financial Planning',
    'Home & Living',
    'Technology',
    'Environment',
    'Community',
    'Creativity',
    'Adventure',
    'Wellness',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-select the first 9 areas as shown in the image
    _selectedAreas = Set.from(_allLifeAreas.take(9));
  }

  void _toggleArea(String area) {
    setState(() {
      if (_selectedAreas.contains(area)) {
        _selectedAreas.remove(area);
      } else {
        _selectedAreas.add(area);
      }
    });
  }

  Future<void> _proceedToVisionBoard() async {
    if (_selectedAreas.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select exactly 9 life areas to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Track the activity
      trackClick('${widget.template} - Life areas selected: ${_selectedAreas.length}');

      // Save selected areas to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_life_areas', _selectedAreas.toList());
      await prefs.setString('selected_template', widget.template);
      await prefs.setString('selected_template_image', widget.imagePath);

      // Navigate to custom vision board page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomVisionBoardPage(
            template: widget.template,
            imagePath: widget.imagePath,
            selectedAreas: _selectedAreas.toList(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving selection: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLifeAreaItem(String area) {
    final bool isSelected = _selectedAreas.contains(area);
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF23C4F7).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        title: Text(
          area,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (bool? value) {
            _toggleArea(area);
          },
          activeColor: Color(0xFF23C4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        onTap: () => _toggleArea(area),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select 9 life-areas to focus on for the year'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.66, // Step 2 of 3
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF23C4F7)),
          ),
        ),
      ),
      body: Column(
        children: [
          // Life areas container
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color(0xFF23C4F7),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header with count
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFF23C4F7).withOpacity(0.1),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    ),
                    child: Text(
                      'Selected: ${_selectedAreas.length}/9 areas',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF23C4F7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  // Life areas list
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allLifeAreas.length,
                      itemBuilder: (context, index) {
                        return _buildLifeAreaItem(_allLifeAreas[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom action button
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceedToVisionBoard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue with ${_selectedAreas.length} areas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
