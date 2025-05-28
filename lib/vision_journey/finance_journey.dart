import 'package:flutter/material.dart';

class FinanceJourney extends StatefulWidget {
  const FinanceJourney({Key? key}) : super(key: key);

  @override
  State<FinanceJourney> createState() => _FinanceJourneyState();
}

class _FinanceJourneyState extends State<FinanceJourney> {
  int currentStep = 1;
  String selectedGoal = 'Save Money';
  double targetAmount = 5000;
  String selectedTimeline = '1 year';

  // Add proper data structures for tasks with checkbox state
  final Map<String, List<TaskItem>> goalTasks = {
    'Save Money': [
      TaskItem(task: 'Set up automatic transfers to savings'),
      TaskItem(task: 'Cut unnecessary subscriptions'),
      TaskItem(task: 'Create a monthly spending limit'),
      TaskItem(task: 'Use the 50/30/20 budget rule'),
    ],
    'Invest Wisely': [
      TaskItem(task: 'Open a retirement account'),
      TaskItem(task: 'Research index funds'),
      TaskItem(task: 'Set up a regular investment schedule'),
      TaskItem(task: 'Diversify your portfolio'),
    ],
    'Reduce Debt': [
      TaskItem(task: 'List all debts with interest rates'),
      TaskItem(task: 'Use the debt snowball/avalanche method'),
      TaskItem(task: 'Negotiate lower interest rates'),
      TaskItem(task: 'Allocate extra funds to debt payments'),
    ],
    'Budget Better': [
      TaskItem(task: 'Track all expenses for a month'),
      TaskItem(task: 'Categorize spending and identify areas to cut'),
      TaskItem(task: 'Create a realistic budget'),
      TaskItem(task: 'Review budget weekly'),
    ],
  };

  // Add a getter for the current tasks based on selected goal
  List<TaskItem> get currentTasks => goalTasks[selectedGoal] ?? [];

  final Map<int, List<Map<String, dynamic>>> savedTasks = {
    1: [],
    2: [],
    3: [],
    4: []
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              right: -100,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.15),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStepper(),
                    const SizedBox(height: 16),
                    _buildCurrentStep(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Finance Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber <= currentStep;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green : Colors.green.shade100,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(
                            color:
                                isActive ? Colors.white : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepTitle(stepNumber),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.green.shade700
                            : Colors.green.shade300,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: stepNumber < currentStep
                          ? Colors.green
                          : Colors.green.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Intro';
      case 2:
        return 'Goal';
      case 3:
        return 'Plan';
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
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              '💸 Welcome to Your Finance Journey!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Text(
                'Design your personalized finance plan for the next year. You\'ll choose financial goals, set a budget, and track your progress along the way.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  height: 1.5,
                ),
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
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 3,
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
              'Step 2: Choose a Financial Goal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select one financial goal to focus on:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Goal selection grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGoalCard('Save Money', '💰',
                    'Build an emergency fund and save for the future'),
                _buildGoalCard('Invest Wisely', '📈',
                    'Learn about investments and grow your portfolio'),
                _buildGoalCard('Reduce Debt', '💳',
                    'Create a plan to pay off debts strategically'),
                _buildGoalCard('Budget Better', '📊',
                    'Track spending and create a sustainable budget'),
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

  Widget _buildGoalCard(String title, String emoji, String description) {
    final isSelected = selectedGoal == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = title;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.grey.shade200,
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
                color: Colors.green.shade100,
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
    final TextEditingController amountController =
        TextEditingController(text: targetAmount.toString());

    return Card(
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 3: Financial Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s create a financial plan based on your goal:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Goal details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Selected Goal: $selectedGoal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Goal amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Set your target amount:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        decoration: InputDecoration(
                          prefixText: '\$ ',
                          hintText: '5,000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.green.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          try {
                            final amount = double.parse(value);
                            setState(() {
                              targetAmount = amount;
                            });
                          } catch (e) {
                            // Handle invalid input
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Timeline
                      const Text(
                        'Timeline to achieve goal:',
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
                                BorderSide(color: Colors.green.shade300),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        value: selectedTimeline,
                        items: const [
                          DropdownMenuItem(
                            value: '3 months',
                            child: Text('3 months'),
                          ),
                          DropdownMenuItem(
                            value: '6 months',
                            child: Text('6 months'),
                          ),
                          DropdownMenuItem(
                            value: '1 year',
                            child: Text('1 year'),
                          ),
                          DropdownMenuItem(
                            value: '2 years',
                            child: Text('2 years'),
                          ),
                          DropdownMenuItem(
                            value: '5 years',
                            child: Text('5 years'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedTimeline = value;
                            });
                          }
                        },
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
              'Step 4: Action Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s break down your goal into actionable steps:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),

            // Action steps
            _buildActionStepsCard(),

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

  Widget _buildActionStepsCard() {
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
            'Key actions for $selectedGoal:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const Divider(),
                // Task list - now using the TaskItem model
                ...currentTasks.map((taskItem) => _buildActionItem(taskItem)),
                // Add task button
                TextButton.icon(
                  onPressed: () {
                    // Show dialog to add a new task
                    _showAddTaskDialog();
                  },
                  icon: Icon(Icons.add, color: Colors.green.shade600),
                  label: Text(
                    'Add New Action',
                    style: TextStyle(color: Colors.green.shade600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Progress tracking
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Tracking',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current progress:'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: 0.25,
                            backgroundColor: Colors.grey.shade300,
                            color: Colors.green,
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
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        '25%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(TaskItem taskItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Checkbox(
            value: taskItem.isCompleted,
            onChanged: (value) {
              // Update the task completion state
              setState(() {
                taskItem.isCompleted = value ?? false;
              });
            },
            activeColor: Colors.green,
          ),
          Expanded(
            child: Text(
              taskItem.task,
              style: TextStyle(
                decoration: taskItem.isCompleted
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
                  // Would show delete confirmation in a real app
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

  void _showAddTaskDialog() {
    final TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: TextField(
            controller: _controller,
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
                if (_controller.text.isNotEmpty) {
                  setState(() {
                    goalTasks[selectedGoal]!
                        .add(TaskItem(task: _controller.text));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep5() {
    // Calculate monthly contribution
    double monthlyContribution = 0;
    if (selectedTimeline == '3 months') {
      monthlyContribution = targetAmount / 3;
    } else if (selectedTimeline == '6 months') {
      monthlyContribution = targetAmount / 6;
    } else if (selectedTimeline == '1 year') {
      monthlyContribution = targetAmount / 12;
    } else if (selectedTimeline == '2 years') {
      monthlyContribution = targetAmount / 24;
    } else if (selectedTimeline == '5 years') {
      monthlyContribution = targetAmount / 60;
    }

    // Get completed tasks
    final completedTasks =
        currentTasks.where((task) => task.isCompleted).toList();

    return Card(
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Step 5: Financial Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(height: 24),

            // Goal summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Goal: $selectedGoal',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Target: \$${targetAmount.toStringAsFixed(0)}'),
                  Text('Timeline: $selectedTimeline'),
                  const SizedBox(height: 8),
                  Text(
                    'Monthly contribution needed: \$${monthlyContribution.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Selected Actions: ${completedTasks.length}/${currentTasks.length} completed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Action summary - now showing actual tasks
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (completedTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No actions completed yet',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        else
                          ...completedTasks
                              .map((task) => _buildSummaryAction(task)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Projected results
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Projected Results',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildProjectionItem(
                          'After 3 months:',
                          '\$1,248',
                          '25% of goal',
                        ),
                        const Divider(),
                        _buildProjectionItem(
                          'After 6 months:',
                          '\$2,496',
                          '50% of goal',
                        ),
                        const Divider(),
                        _buildProjectionItem(
                          'After 12 months:',
                          '\$5,000',
                          '100% of goal',
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
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '🏅 FINANCIAL PLANNER',
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

  Widget _buildSummaryAction(TaskItem taskItem) {
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
            taskItem.isCompleted ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(taskItem.task)),
        ],
      ),
    );
  }

  Widget _buildProjectionItem(String period, String amount, String percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            period,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                  fontSize: 16,
                ),
              ),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
    String? nextLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 3,
            ),
            child: Text(nextLabel ?? 'Continue'),
          ),
        ],
      ),
    );
  }
}

// Add a TaskItem class to track task completion state
class TaskItem {
  final String task;
  bool isCompleted;

  TaskItem({required this.task, this.isCompleted = false});
}
