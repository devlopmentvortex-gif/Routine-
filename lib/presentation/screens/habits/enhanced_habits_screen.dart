import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit_model.dart';
import '../../../providers/app_provider.dart';

class EnhancedHabitsScreen extends StatelessWidget {
  const EnhancedHabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "enhanced_habits_fab",
        onPressed: () => _showAddHabit(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Habit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        slivers: [
          // Modern Header with Progress
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkSurfaceElevated]
                        : [AppColors.lightSurface, Colors.white],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Habits',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                        const SizedBox(height: 16),
                        // Circular Progress Widget
                        Row(
                          children: [
                            _CircularProgressIndicator(
                              progress: provider.todayHabitCompletionPercentage,
                              size: 80,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(provider.todayHabitCompletionPercentage * 100).toInt()}% Complete Today',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${provider.todayHabitsDone} of ${provider.habits.length} habits done',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.darkTextSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Week View Strip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _WeekViewStrip(habits: provider.habits),
            ),
          ),

          // Habits grouped by time slot
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (provider.habits.isEmpty)
                  const _EmptyHabitsState()
                else
                  ..._buildTimeSlotSections(context, provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeSlotSections(
      BuildContext context, AppProvider provider) {
    final groupedHabits = provider.habitsByTimeSlot;
    final sections = <Widget>[];

    for (final slot in TimeSlot.values) {
      final habits = groupedHabits[slot]!;
      if (habits.isEmpty) continue;

      sections.add(
        _TimeSlotSection(
          title: slot.label,
          icon: _getTimeSlotIcon(slot),
          habits: habits,
          provider: provider,
        ).animate().fadeIn(delay: (TimeSlot.values.indexOf(slot) * 100).ms),
      );
    }

    return sections;
  }

  IconData _getTimeSlotIcon(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return Icons.wb_sunny_rounded;
      case TimeSlot.afternoon:
        return Icons.wb_twilight_rounded;
      case TimeSlot.evening:
        return Icons.nightlight_rounded;
      case TimeSlot.anytime:
        return Icons.all_inclusive_rounded;
    }
  }

  void _showAddHabit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddHabitSheet(),
    );
  }
}

// ── Circular Progress Widget ───────────────────────────────────────────────────────────────

class _CircularProgressIndicator extends StatelessWidget {
  final double progress;
  final double size;

  const _CircularProgressIndicator({
    required this.progress,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          // Center text
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Week View Strip ─────────────────────────────────────────────────────────────────────

class _WeekViewStrip extends StatelessWidget {
  final List<HabitModel> habits;
  const _WeekViewStrip({required this.habits});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.asMap().entries.map((entry) {
              final day = entry.value;
              final completedCount =
                  habits.where((h) => h.isCompletedOn(day)).length;
              final total = habits.length;
              final rate = total > 0 ? completedCount / total : 0.0;
              final isToday = day.day == now.day &&
                  day.month == now.month &&
                  day.year == now.year;

              return Column(
                children: [
                  Text(
                    dayLabels[day.weekday - 1],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isToday
                          ? AppColors.primary
                          : AppColors.darkTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rate == 0
                          ? (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightBg)
                          : AppColors.secondary.withOpacity(0.15 + rate * 0.7),
                      border: Border.all(
                        color: isToday ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        total > 0 ? '$completedCount' : '-',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: rate > 0
                              ? AppColors.secondary
                              : AppColors.darkTextHint,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Time Slot Section ───────────────────────────────────────────────────────────────

class _TimeSlotSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<HabitModel> habits;
  final AppProvider provider;

  const _TimeSlotSection({
    required this.title,
    required this.icon,
    required this.habits,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${habits.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...habits.asMap().entries.map((entry) => _AdvancedHabitCard(
              habit: entry.value,
              provider: provider,
              index: entry.key,
            )
                .animate()
                .fadeIn(delay: (entry.key * 80).ms)
                .slideY(begin: 0.2, delay: (entry.key * 80).ms)),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Advanced Habit Card ───────────────────────────────────────────────────────────────

class _AdvancedHabitCard extends StatelessWidget {
  final HabitModel habit;
  final AppProvider provider;
  final int index;

  const _AdvancedHabitCard({
    required this.habit,
    required this.provider,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompletedToday = habit.isCompletedToday;
    final last7Days = habit.last7DaysCompletion;

    // Parse habit color
    Color habitColor;
    try {
      habitColor = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      habitColor = AppColors.primary;
    }

    // Get priority border color
    final priorityBorderColor = habit.priority.color;

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child:
            const Icon(Icons.delete_rounded, color: AppColors.danger, size: 28),
      ),
      onDismissed: (_) => provider.deleteHabit(habit.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompletedToday
                ? priorityBorderColor.withOpacity(0.8)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isCompletedToday ? 2.5 : 1,
          ),
          boxShadow: isCompletedToday
              ? [
                  BoxShadow(
                    color: priorityBorderColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Category icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: habitColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        habit.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (habit.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            habit.description,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.darkTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Streak badge
                  if (habit.currentStreak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            '${habit.currentStreak}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Today toggle
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await provider.toggleHabitOptimistic(habit.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isCompletedToday ? habitColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCompletedToday
                              ? habitColor
                              : AppColors.darkBorder,
                          width: 2,
                        ),
                      ),
                      child: isCompletedToday
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 22)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7-day completion dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isCompleted = last7Days[i];
                  final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? habitColor
                              : habitColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i == 6 ? habitColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: isCompleted
                            ? const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 14),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: 9,
                          color:
                              i == 6 ? habitColor : AppColors.darkTextSecondary,
                          fontWeight:
                              i == 6 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 12),

              // Progress bar and priority indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly Progress',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.darkTextSecondary),
                            ),
                            Text(
                              '${(habit.monthlyCompletionRate * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: habitColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: habit.monthlyCompletionRate,
                            backgroundColor: habitColor.withOpacity(0.12),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(habitColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Priority indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityBorderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: priorityBorderColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      habit.priority.label[0],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: priorityBorderColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Habit Sheet ───────────────────────────────────────────────────────────────────

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet();

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _selectedEmoji = '⭐';
  String _selectedColor = '#7C6EF5';
  HabitCategory _selectedCategory = HabitCategory.custom;
  HabitPriority _selectedPriority = HabitPriority.medium;
  TimeSlot _selectedTimeSlot = TimeSlot.anytime;
  String _frequency = 'daily';
  bool _loading = false;

  final List<String> _emojis = [
    '⭐',
    '🏃',
    '💧',
    '📚',
    '🧘',
    '💪',
    '🥗',
    '😴',
    '✍️',
    '🎯',
    '🎨',
    '🌿',
    '☕',
    '🚴',
    '🏊',
    '🧹',
    '🙏',
    '❤️',
    '🎭',
    '💻',
    '🌅',
    '🎵',
    '📱',
    '🛏️',
  ];

  final List<String> _colors = [
    '#7C6EF5',
    '#36D7A0',
    '#F5885A',
    '#42A5F5',
    '#EF5350',
    '#FFA726',
    '#AB47BC',
    '#26A69A',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final habit = HabitModel(
      id: const Uuid().v4(),
      userId: uid,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      emoji: _selectedEmoji,
      color: _selectedColor,
      category: _selectedCategory,
      priority: _selectedPriority,
      timeSlot: _selectedTimeSlot,
      frequency: _frequency,
    );

    await context.read<AppProvider>().addHabit(habit);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Parse selected color for preview
    Color selectedColorValue;
    try {
      selectedColorValue =
          Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      selectedColorValue = AppColors.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header with emoji preview
            Row(
              children: [
                // Live emoji + color preview bubble
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selectedColorValue.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selectedColorValue.withOpacity(0.5), width: 2),
                  ),
                  child: Center(
                    child: Text(_selectedEmoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('New Habit',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                      Text(
                        _titleCtrl.text.isEmpty
                            ? 'What habit do you want to build?'
                            : _titleCtrl.text,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.darkTextSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Input Fields ──
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Habit name...',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(
                hintText: 'Description (optional)...',
                prefixIcon: Icon(Icons.description_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 22),

            // ── Category ──
            _SectionLabel(label: 'Category', icon: Icons.category_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: HabitCategory.values.map((category) {
                final selected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                      _selectedEmoji = category.defaultEmoji;
                      _selectedColor = category.defaultColor;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withOpacity(0.18)
                          : (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightBg),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '${category.defaultEmoji} ${category.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.primary : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Priority + Frequency side by side ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          label: 'Priority', icon: Icons.flag_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: HabitPriority.values.map((priority) {
                          final selected = _selectedPriority == priority;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedPriority = priority),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? priority.color.withOpacity(0.18)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? priority.color
                                      : AppColors.darkBorder,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                priority.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? priority.color
                                      : AppColors.darkTextSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Frequency
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                          label: 'Frequency', icon: Icons.repeat_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['daily', 'weekly'].map((f) {
                          final selected = _frequency == f;
                          return GestureDetector(
                            onTap: () => setState(() => _frequency = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.secondary.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.secondary
                                      : AppColors.darkBorder,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                f[0].toUpperCase() + f.substring(1),
                                style: TextStyle(
                                  color: selected
                                      ? AppColors.secondary
                                      : AppColors.darkTextSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Time Slot ── (full width, segmented style)
            _SectionLabel(label: 'Time Slot', icon: Icons.schedule_rounded),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkSurfaceElevated : AppColors.lightBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: TimeSlot.values.map((slot) {
                  final selected = _selectedTimeSlot == slot;
                  final slotIcon = _timeSlotIcon(slot);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTimeSlot = slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary.withOpacity(0.5)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              slotIcon,
                              size: 16,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.darkTextSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slot.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.darkTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 22),

            // ── Emoji ──
            _SectionLabel(label: 'Emoji', icon: Icons.emoji_emotions_rounded),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final selected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? selectedColorValue.withOpacity(0.22)
                          : (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightBg),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            selected ? selectedColorValue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),

            // ── Color ──
            _SectionLabel(label: 'Color', icon: Icons.palette_rounded),
            const SizedBox(height: 12),
            Row(
              children: _colors.map((c) {
                Color color;
                try {
                  color = Color(int.parse(c.replaceFirst('#', '0xFF')));
                } catch (_) {
                  color = AppColors.primary;
                }
                final selected = _selectedColor == c;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selected ? 36 : 30,
                      height: selected ? 36 : 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.55),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Submit Button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Add Habit',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _timeSlotIcon(TimeSlot slot) {
    switch (slot) {
      case TimeSlot.morning:
        return Icons.wb_sunny_rounded;
      case TimeSlot.afternoon:
        return Icons.wb_twilight_rounded;
      case TimeSlot.evening:
        return Icons.nightlight_rounded;
      case TimeSlot.anytime:
        return Icons.all_inclusive_rounded;
    }
  }
}

// ── Section Label Helper ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.darkTextSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.darkTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _EmptyHabitsState extends StatelessWidget {
  const _EmptyHabitsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No habits for today',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start building better habits today!',
            style: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '💡 Tip: Start small and be consistent',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
