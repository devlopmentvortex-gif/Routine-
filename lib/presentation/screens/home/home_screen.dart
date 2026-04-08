import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit_model.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';
import '../../widgets/common/pressable.dart';
import '../../widgets/common/section_header.dart';
import '../focus/focus_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      floatingActionButton: _FocusFAB(),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            elevation: 0,
            leadingWidth: 0,
            titleSpacing: 20,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()} 👋',
                        style: TextStyle(fontSize: 13, color: subColor),
                      ),
                      Text(
                        'Routine+',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(Icons.person_outline_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Progress Ring ───────────────────────────────────────────
                _ProgressSection(provider: provider)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, duration: 500.ms),

                const SizedBox(height: 24),

                // ── Quick Stats ─────────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                      label: 'Tasks done',
                      value:
                          '${provider.todayTasksDone}/${provider.todayTasksTotal}',
                      color: AppColors.primary,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Habits kept',
                      value:
                          '${provider.todayHabitsDone}/${provider.habits.length}',
                      color: AppColors.secondary,
                      icon: Icons.local_fire_department_rounded,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Focus mins',
                      value: '${provider.totalFocusMinutes}',
                      color: AppColors.warning,
                      icon: Icons.timer_outlined,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .slideY(begin: 0.2, delay: 150.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Today's Schedule ─────────────────────────────────────────
                const SectionHeader(title: 'Today\'s Schedule', showAll: false),
                const SizedBox(height: 12),
                _ScheduleSection(provider: provider)
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 500.ms),

                const SizedBox(height: 28),

                // ── Habit streaks ────────────────────────────────────────────
                const SectionHeader(title: 'Habit Streaks', showAll: false),
                const SizedBox(height: 12),
                if (provider.habits.isEmpty)
                  _EmptyHabits()
                else
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.habits.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        return _HabitStreakCard(habit: provider.habits[i])
                            .animate()
                            .fadeIn(delay: (300 + i * 60).ms)
                            .slideX(begin: 0.3, delay: (300 + i * 60).ms);
                      },
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Progress Section ──────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  final AppProvider provider;
  const _ProgressSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // Ring
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _AnimatedRing(progress: provider.todayProgress),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(provider.todayProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'done',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.darkTextSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${provider.todayTasksDone} of ${provider.todayTasksTotal} tasks completed',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  _getMotivationalText(provider.todayProgress),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalText(double progress) {
    if (progress == 0) return 'Start strong today! 💪';
    if (progress < 0.3) return 'Great start, keep going!';
    if (progress < 0.6) return 'You\'re making great progress!';
    if (progress < 1.0) return 'Almost there, push through! 🚀';
    return 'All done! Amazing work today! 🎉';
  }
}

class _AnimatedRing extends StatefulWidget {
  final double progress;
  const _AnimatedRing({required this.progress});

  @override
  State<_AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<_AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedRing old) {
    super.didUpdateWidget(old);
    _anim = Tween<double>(begin: _anim.value, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        painter: _RingPainter(progress: _anim.value),
        child: const SizedBox(width: 110, height: 110),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;
    const startAngle = -math.pi / 2;

    // Track
    final trackPaint = Paint()
      ..color = AppColors.darkBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Schedule Section ──────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  final AppProvider provider;
  const _ScheduleSection({required this.provider});

  @override
  Widget build(BuildContext context) {
    final slots = [
      ('morning', '🌅', 'Morning'),
      ('afternoon', '☀️', 'Afternoon'),
      ('evening', '🌙', 'Evening'),
    ];

    return Column(
      children: slots.asMap().entries.map((entry) {
        final slot = entry.value;
        final tasks = provider.tasksForSlot(slot.$1);
        return _TimeSlotCard(
          emoji: slot.$2,
          label: slot.$3,
          tasks: tasks,
        ).animate().fadeIn(delay: (50 * entry.key).ms);
      }).toList(),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String emoji;
  final String label;
  final List<TaskModel> tasks;

  const _TimeSlotCard({
    required this.emoji,
    required this.label,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${tasks.length} tasks',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No tasks for $label',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.darkTextHint),
              ),
            )
          else
            ...tasks.take(3).map((task) => _MiniTaskTile(task: task)),
        ],
      ),
    );
  }
}

class _MiniTaskTile extends StatelessWidget {
  final TaskModel task;
  const _MiniTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: task.priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? AppColors.darkTextHint : null,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => provider.toggleTask(task.id, !task.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    task.isCompleted ? AppColors.secondary : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.secondary
                      : AppColors.darkBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit Streak Card ─────────────────────────────────────────────────────────

class _HabitStreakCard extends StatelessWidget {
  final HabitModel habit;
  const _HabitStreakCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = habit.currentStreak;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(habit.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              habit.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                streak > 0 ? '🔥' : '○',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '$streak day${streak != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHabits extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: const Text(
        'No habits yet. Add one in the Habits tab!',
        style: TextStyle(color: AppColors.darkTextHint, fontSize: 13),
      ),
    );
  }
}

class _FocusFAB extends StatefulWidget {
  @override
  State<_FocusFAB> createState() => _FocusFABState();
}

class _FocusFABState extends State<_FocusFAB> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FocusScreen()),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.timer_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
