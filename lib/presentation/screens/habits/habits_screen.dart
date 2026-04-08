import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHabit(context),
        backgroundColor: AppColors.secondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Habit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Habits',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(
                  '${provider.todayHabitsDone}/${provider.habits.length} done today',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Weekly summary strip
                _WeeklySummaryStrip(habits: provider.habits),
                const SizedBox(height: 24),

                if (provider.habits.isEmpty)
                  _EmptyHabits()
                else
                  ...provider.habits.asMap().entries.map((e) =>
                      _HabitCard(habit: e.value, provider: provider)
                          .animate()
                          .fadeIn(delay: (80 * e.key).ms)
                          .slideY(
                              begin: 0.2,
                              delay: (80 * e.key).ms,
                              duration: 400.ms)),
              ]),
            ),
          ),
        ],
      ),
    );
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

// ── Weekly Summary Strip ──────────────────────────────────────────────────────

class _WeeklySummaryStrip extends StatelessWidget {
  final List<HabitModel> habits;
  const _WeeklySummaryStrip({required this.habits});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
              final key = _dateKey(day);
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
                    width: 32,
                    height: 32,
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
                          fontSize: 11,
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

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Habit Card ────────────────────────────────────────────────────────────────

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final AppProvider provider;
  const _HabitCard({required this.habit, required this.provider});

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final last7 = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final streak = habit.currentStreak;
    final isToday = habit.isCompletedOn(now);
    final todayKey = _dateKey(now);

    // Parse habit color
    Color habitColor;
    try {
      habitColor = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      habitColor = AppColors.primary;
    }

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday
                ? habitColor.withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: habitColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(habit.emoji,
                          style: const TextStyle(fontSize: 22)),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              streak > 0
                                  ? '🔥 $streak day streak'
                                  : '○ No streak',
                              style: TextStyle(
                                fontSize: 12,
                                color: streak > 0
                                    ? AppColors.warning
                                    : AppColors.darkTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (streak >= 7) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Text('🏆 Week+',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Today toggle
                  GestureDetector(
                    onTap: () =>
                        provider.toggleHabit(habit.id, todayKey, !isToday),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday ? habitColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isToday ? habitColor : AppColors.darkBorder,
                          width: 2,
                        ),
                      ),
                      child: isToday
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 7-day dots
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: last7.map((day) {
                  final done = habit.isCompletedOn(day);
                  final isToday2 = day.day == now.day &&
                      day.month == now.month &&
                      day.year == now.year;
                  final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color:
                              done ? habitColor : habitColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isToday2 ? habitColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: done
                            ? const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 16),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dayLabels[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday2
                              ? habitColor
                              : AppColors.darkTextSecondary,
                          fontWeight:
                              isToday2 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Monthly progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.darkTextSecondary)),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Habit Sheet ───────────────────────────────────────────────────────────

class _AddHabitSheet extends StatefulWidget {
  const _AddHabitSheet();

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _titleCtrl = TextEditingController();
  String _selectedEmoji = '⭐';
  String _selectedColor = '#7C6EF5';
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
    '🧘',
    '💊',
    '🧹',
    '🙏',
    '❤️',
    '🎨',
    '🎭',
    '💻',
    '🌅',
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
      emoji: _selectedEmoji,
      color: _selectedColor,
      frequency: _frequency,
    );

    await context.read<AppProvider>().addHabit(habit);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const Text('New Habit',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Habit name...',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Pick an Emoji',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                          ? AppColors.primary.withOpacity(0.2)
                          : (isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightBg),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            selected ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Color',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
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
                      duration: const Duration(milliseconds: 150),
                      width: 32,
                      height: 32,
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
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Text('Frequency',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: ['daily', 'weekly'].map((f) {
                final selected = _frequency == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.secondary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
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
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Add Habit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: const [
          Text('🔥', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('No habits yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkTextPrimary)),
          SizedBox(height: 8),
          Text('Build a streak starting today!',
              style:
                  TextStyle(fontSize: 14, color: AppColors.darkTextSecondary)),
        ],
      ),
    );
  }
}
