import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/activity_tracker_mixin.dart';
import 'custom_vision_board_page.dart';
import '../../components/nav_logpage.dart';

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
    with ActivityTrackerMixin, TickerProviderStateMixin {
  Set<String> _selectedAreas = {};
  bool _isLoading = false;
  final TextEditingController _customNameController = TextEditingController();
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  String get pageName => 'Life Areas Selection';

  @override
  void dispose() {
    _customNameController.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

  // All 22 life areas plus custom option
  final List<String> _allLifeAreas = [
    'Custom Card', // Add custom card option
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
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 75% progress for step 3
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
    
    // Start with empty selection - no pre-selected areas
    _selectedAreas = <String>{};
  }

  void _toggleArea(String area) {
    if (area == 'Custom Card') {
      _showCustomCardDialog();
      return;
    }
    
    setState(() {
      if (_selectedAreas.contains(area)) {
        _selectedAreas.remove(area);
      } else {
        _selectedAreas.add(area);
      }
    });
  }

  void _showCustomCardDialog() {
    _customNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Custom Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter a name for your custom life area:'),
              SizedBox(height: 16),
              TextField(
                controller: _customNameController,
                decoration: InputDecoration(
                  hintText: 'e.g., My Dream Job, Travel Goals, etc.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.add_circle_outline, color: Color(0xFF23C4F7)),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final customName = _customNameController.text.trim();
                if (customName.isNotEmpty) {
                  setState(() {
                    _selectedAreas.add(customName);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Custom card "$customName" added!'),
                      backgroundColor: Color(0xFF23C4F7),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF23C4F7),
                foregroundColor: Colors.white,
              ),
              child: Text('Add Card'),
            ),
          ],
        );
      },
    );
  }

  void _removeCustomArea(String area) {
    setState(() {
      _selectedAreas.remove(area);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom card "$area" removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _proceedToVisionBoard() async {
    if (_selectedAreas.length < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least 1 life area to continue'),
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

      // Show success screen first
      _showSuccessScreen();
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

  void _showSuccessScreen() {
    // Navigate to success screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
        builder: (context) => VisionBoardSuccessPage(
                            template: widget.template,
                            imagePath: widget.imagePath,
                            selectedAreas: _selectedAreas.toList(),
                          ),
                        ),
    );
  }

  Widget _buildLifeAreaItem(String area) {
    final bool isSelected = _selectedAreas.contains(area);
    final bool isCustomCard = area == 'Custom Card';
    final bool isCustomCreated = _selectedAreas.contains(area) && area != 'Custom Card';
    
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
        leading: isCustomCard ? Icon(
          Icons.add_circle_outline,
          color: Color(0xFF23C4F7),
          size: 24,
        ) : isCustomCreated ? Icon(
          Icons.star,
          color: Color(0xFF23C4F7),
          size: 20,
        ) : null,
        title: Text(
          area,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isCustomCard || isCustomCreated ? FontWeight.w600 : FontWeight.w500,
            color: isCustomCard || isCustomCreated ? Color(0xFF23C4F7) : Colors.black87,
          ),
        ),
        trailing: isCustomCard ? null : (isCustomCreated ? IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: Colors.red,
            size: 20,
          ),
          onPressed: () {
            _removeCustomArea(area);
          },
        ) : Checkbox(
          value: isSelected,
          onChanged: (bool? value) {
            _toggleArea(area);
          },
          activeColor: Color(0xFF23C4F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        )),
        onTap: isCustomCreated ? null : () => _toggleArea(area),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Select life-areas to focus on for the year',
      showBackButton: false,
      selectedIndex: 2, // Dashboard index
      // Using default navigation handler from NavLogPage
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
                      'Selected: ${_selectedAreas.length} areas',
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
                      itemCount: _allLifeAreas.length + _selectedAreas.where((area) => area != 'Custom Card' && !_allLifeAreas.contains(area)).length,
                      itemBuilder: (context, index) {
                        // Get custom created areas
                        final customAreas = _selectedAreas.where((area) => area != 'Custom Card' && !_allLifeAreas.contains(area)).toList();
                        
                        // Find the position of "Custom Card" in the predefined list
                        final customCardIndex = _allLifeAreas.indexOf('Custom Card');
                        
                        if (index < customCardIndex) {
                          // Show predefined areas before Custom Card
                          return _buildLifeAreaItem(_allLifeAreas[index]);
                        } else if (index == customCardIndex) {
                          // Show the Custom Card option
                          return _buildLifeAreaItem(_allLifeAreas[index]);
                        } else if (index < customCardIndex + 1 + customAreas.length) {
                          // Show custom created areas right after Custom Card
                          final customIndex = index - customCardIndex - 1;
                          if (customIndex < customAreas.length) {
                            return _buildLifeAreaItem(customAreas[customIndex]);
                          }
                        } else {
                          // Show remaining predefined areas after custom cards
                          final remainingIndex = index - customAreas.length;
                          if (remainingIndex < _allLifeAreas.length) {
                            return _buildLifeAreaItem(_allLifeAreas[remainingIndex]);
                          }
                        }
                        
                        return SizedBox.shrink();
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
                      'Continue with ${_selectedAreas.length} area${_selectedAreas.length == 1 ? '' : 's'}',
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

class VisionBoardSuccessPage extends StatefulWidget {
  final String template;
  final String imagePath;
  final List<String> selectedAreas;

  const VisionBoardSuccessPage({
    super.key,
    required this.template,
    required this.imagePath,
    required this.selectedAreas,
  });

  @override
  State<VisionBoardSuccessPage> createState() => _VisionBoardSuccessPageState();
}

class _VisionBoardSuccessPageState extends State<VisionBoardSuccessPage>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0, // 100% progress for success page
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animations
    _animationController!.forward();
    _progressAnimationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _progressAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: 'Success',
      showBackButton: false,
      selectedIndex: 2, // Dashboard index
      // Using default navigation handler from NavLogPage
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8FAFF)],
          ),
        ),
        child: Column(
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
            
            // Success content
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success icon with animation
                      AnimatedBuilder(
                        animation: _scaleAnimation ?? const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation?.value ?? 1.0,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Color(0xFF23C4F7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF23C4F7).withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Success message with fade animation
                      AnimatedBuilder(
                        animation: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation?.value ?? 1.0,
                            child: Column(
                              children: [
                                Text(
                                  "Your board is ready!",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "You've selected ${widget.selectedAreas.length} life area${widget.selectedAreas.length == 1 ? '' : 's'} to focus on. Let's create your personalized vision board!",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 40),
                                
                                // Action button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to custom vision board page
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CustomVisionBoardPage(
                                            template: widget.template,
                                            imagePath: widget.imagePath,
                                            selectedAreas: widget.selectedAreas,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF23C4F7),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                    ),
                                    child: Text(
                                      "Let's Plan Your Future",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
