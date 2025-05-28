import 'package:flutter/material.dart';

class SelfCareJourney extends StatefulWidget {
  const SelfCareJourney({Key? key}) : super(key: key);

  @override
  State<SelfCareJourney> createState() => _SelfCareJourneyState();
}

class _SelfCareJourneyState extends State<SelfCareJourney> {
  int currentStep = 1;
  String selectedHabit = 'Look Better';
  String selectedMonth = 'June';
  int satisfactionRating = 0; // 0-4 for 5 emoji ratings
  String weeklyReflection = '';

  // Add task management with completion state
  final Map<String, List<HabitTask>> habitTasks = {
    'Look Better': [
      HabitTask(task: 'Daily showers'),
      HabitTask(task: 'Brushing teeth (twice a day)'),
      HabitTask(task: 'Trimmed nails'),
      HabitTask(task: 'Moisturized skin'),
    ],
    'Dress Well': [
      HabitTask(task: 'Plan outfits ahead'),
      HabitTask(task: 'Iron clothes'),
      HabitTask(task: 'Organize wardrobe'),
      HabitTask(task: 'Accessorize appropriately'),
    ],
    'Feel More Confident': [
      HabitTask(task: 'Practice positive affirmations'),
      HabitTask(task: 'Maintain good posture'),
      HabitTask(task: 'Prepare for social interactions'),
      HabitTask(task: 'Exercise regularly'),
    ],
  };

  // Get current tasks based on selected habit
  List<HabitTask> get currentTasks => habitTasks[selectedHabit] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStepper(),
                const SizedBox(height: 16),
                _buildCurrentStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(5, (index) {
        final stepNumber = index + 1;
        final isActive = stepNumber <= currentStep;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.purple : Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: TextStyle(
                          color:
                              isActive ? Colors.white : Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStepTitle(stepNumber),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              if (index < 4)
                Expanded(
                  child: Container(
                    height: 2,
                    color: Colors.purple.shade200,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Intro';
      case 2:
        return 'Habit';
      case 3:
        return 'Schedule';
      case 4:
        return 'Track';
      case 5:
        return 'Summary';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              '🌱 Welcome to Your Self-Care Journey!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7E22CE),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Design your personalized self-care plan for the next month. You\'ll choose a habit to focus on, set a schedule, and track your progress along the way.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  currentStep = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 2: Choose a Self-Care Habit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7E22CE),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select one habit to focus on for the next month:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Habit selection grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHabitCard('Look Better', '💄',
                    'Enhance your appearance with consistent grooming'),
                _buildHabitCard('Dress Well', '👔',
                    'Refine your style to reflect your best self'),
                _buildHabitCard('Feel More Confident', '💪',
                    'Build confidence through physical care'),
              ],
            ),

            const SizedBox(height: 24),
            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 1;
                });
              },
              onNext: () {
                setState(() {
                  currentStep = 3;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCard(String title, String emoji, String description) {
    final isSelected = selectedHabit == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedHabit = title;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple.shade400 : Colors.grey.shade200,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 12),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 3: Pick a Start Month',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7E22CE),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When do you want to begin your self-care journey?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Month selection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.purple.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected Habit: $selectedHabit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E22CE),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Month:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.purple.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        value: selectedMonth,
                        items: const [
                          DropdownMenuItem(
                            value: 'January',
                            child: Text('January'),
                          ),
                          DropdownMenuItem(
                            value: 'February',
                            child: Text('February'),
                          ),
                          DropdownMenuItem(
                            value: 'March',
                            child: Text('March'),
                          ),
                          DropdownMenuItem(
                            value: 'April',
                            child: Text('April'),
                          ),
                          DropdownMenuItem(
                            value: 'May',
                            child: Text('May'),
                          ),
                          DropdownMenuItem(
                            value: 'June',
                            child: Text('June'),
                          ),
                          DropdownMenuItem(
                            value: 'July',
                            child: Text('July'),
                          ),
                          DropdownMenuItem(
                            value: 'August',
                            child: Text('August'),
                          ),
                          DropdownMenuItem(
                            value: 'September',
                            child: Text('September'),
                          ),
                          DropdownMenuItem(
                            value: 'October',
                            child: Text('October'),
                          ),
                          DropdownMenuItem(
                            value: 'November',
                            child: Text('November'),
                          ),
                          DropdownMenuItem(
                            value: 'December',
                            child: Text('December'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedMonth = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '2025',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 2;
                });
              },
              onNext: () {
                setState(() {
                  currentStep = 4;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 4: Weekly Routine Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7E22CE),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Build your weekly self-care routine:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Weekly routine card
            _buildWeeklyRoutineCard(),

            const SizedBox(height: 24),
            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 3;
                });
              },
              onNext: () {
                setState(() {
                  currentStep = 5;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyRoutineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Let\'s build your self-care routine:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Week 1',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    Row(
                      children: [
                        SizedBox(
                          height: 36,
                          child: TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide:
                                    BorderSide(color: Colors.purple.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            readOnly: true,
                            controller: TextEditingController(
                                text: DateTime.now().toString().split(' ')[0]),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            // Would show reminder dialog in a real app
                          },
                          icon: const Icon(Icons.notifications_outlined),
                          color: Colors.purple.shade600,
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                // Task list - now with state
                ...currentTasks.map((task) => _buildTaskItem(task)),
                // Add task button
                TextButton.icon(
                  onPressed: () {
                    _showAddTaskDialog();
                  },
                  icon: Icon(Icons.add, color: Colors.purple.shade600),
                  label: Text(
                    'Add New Task',
                    style: TextStyle(color: Colors.purple.shade600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Would show next week in a real app
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Save & Continue to Week 2'),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(HabitTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              // Update the task state
              setState(() {
                task.isCompleted = value ?? false;
              });
            },
            activeColor: Colors.purple,
          ),
          Expanded(
            child: Text(
              task.task,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Would show edit dialog in a real app
                },
                icon: const Icon(Icons.edit, size: 16),
                color: Colors.grey.shade600,
              ),
              IconButton(
                onPressed: () {
                  // Would show notes dialog in a real app
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                color: Colors.grey.shade600,
              ),
              IconButton(
                onPressed: () {
                  // Show delete confirmation
                  _showDeleteConfirmation(task);
                },
                icon: const Icon(Icons.delete_outline, size: 16),
                color: Colors.red.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add dialog to create new tasks
  void _showAddTaskDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    habitTasks[selectedHabit]!
                        .add(HabitTask(task: controller.text));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  // Add confirmation dialog for deleting tasks
  void _showDeleteConfirmation(HabitTask task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete "${task.task}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  habitTasks[selectedHabit]!.remove(task);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep5() {
    // Get completed tasks
    final completedTasks =
        currentTasks.where((task) => task.isCompleted).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 5: Self-Care Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7E22CE),
              ),
            ),
            const SizedBox(height: 24),

            // Habit summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Self-Care Focus: $selectedHabit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E22CE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Starting: $selectedMonth 2025'),
                  const SizedBox(height: 8),

                  // Progress
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Progress: ${completedTasks.length}/${currentTasks.length} tasks',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: currentTasks.isEmpty
                                  ? 0
                                  : completedTasks.length / currentTasks.length,
                              backgroundColor: Colors.white,
                              color: Colors.purple,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${(currentTasks.isEmpty ? 0 : (completedTasks.length / currentTasks.length * 100)).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Your Selected Tasks:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Week tasks summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Week 1',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (completedTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No tasks completed yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...completedTasks
                              .map((task) => _buildSummaryTask(task)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Weekly reflection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Reflection',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7E22CE),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Take time to reflect on your progress each week:',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How do you feel after Week 1?',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts on your progress...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.purple.shade300),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            setState(() {
                              weeklyReflection = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rate your satisfaction:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEmojiButton('😞', 0),
                            _buildEmojiButton('😐', 1),
                            _buildEmojiButton('🙂', 2),
                            _buildEmojiButton('😀', 3),
                            _buildEmojiButton('🤩', 4),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Badges
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '+100 XP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '🏅 LIFESTYLE REFRESHER',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 4;
                });
              },
              onNext: () {
                // In a real app, this would save the plan
                Navigator.pop(context);
              },
              nextLabel: 'Save Plan',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTask(HabitTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.purple.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(task.task)),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, int rating) {
    final isSelected = satisfactionRating == rating;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          satisfactionRating = rating;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.purple.shade100 : Colors.grey.shade100,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(40, 40),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
    String? nextLabel,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: onBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: const Text('Back'),
        ),
        ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: Text(nextLabel ?? 'Continue'),
        ),
      ],
    );
  }
}

// Add a class to track habit task completion
class HabitTask {
  final String task;
  bool isCompleted;

  HabitTask({
    required this.task,
    this.isCompleted = false,
  });
}
