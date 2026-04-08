import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/habit_model.dart';
import '../../../providers/app_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: 20,
            title: const Text('Analytics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Summary cards row
                Row(
                  children: [
                    _SummaryCard(
                      title: 'Total Tasks',
                      value: '${provider.tasks.length}',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      title: 'Completed',
                      value: '${provider.completedTasks.length}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 12),
                    _SummaryCard(
                      title: 'Focus hrs',
                      value:
                          '${(provider.totalFocusMinutes / 60).toStringAsFixed(1)}',
                      icon: Icons.timer_outlined,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Weekly tasks chart
                _SectionCard(
                  title: 'Tasks Completed This Week',
                  child: _WeeklyBarChart(stats: provider.weeklyStats),
                ),
                const SizedBox(height: 16),

                // Habits overview
                _SectionCard(
                  title: 'Habit Overview',
                  child: _HabitsOverviewList(habits: provider.habits),
                ),
                const SizedBox(height: 16),

                // Habit heatmap (last 30 days)
                _SectionCard(
                  title: 'Habit Activity — Last 30 Days',
                  child: _HabitHeatmap(habits: provider.habits),
                ),
                const SizedBox(height: 16),

                // Productivity score
                _ProductivityScore(provider: provider),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.darkTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ── Weekly Bar Chart ──────────────────────────────────────────────────

class _WeeklyBarChart extends StatelessWidget {
  final Map<String, int> stats;

  const _WeeklyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final keys = stats.keys.toList();
    final values = stats.values.toList();
    final maxVal =
        values.isEmpty ? 5 : values.reduce((a, b) => a > b ? a : b).toDouble();

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal < 5 ? 5 : maxVal + 1,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= keys.length) {
                    return const SizedBox();
                  }
                  final date = DateTime.tryParse(keys[idx]);
                  final label = date != null ? dayLabels[date.weekday - 1] : '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkTextSecondary)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox();
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.darkTextSecondary),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.darkBorder,
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(values.length, (i) {
            final today = DateTime.now();
            final keyDate = DateTime.tryParse(keys[i]);
            final isToday = keyDate != null &&
                keyDate.day == today.day &&
                keyDate.month == today.month;

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: 28,
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: isToday
                        ? [AppColors.primary, AppColors.primaryLight]
                        : [
                            AppColors.primary.withOpacity(0.4),
                            AppColors.primary.withOpacity(0.6)
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Habits Overview List ──────────────────────────────────────────────

class _HabitsOverviewList extends StatelessWidget {
  final List<HabitModel> habits;

  const _HabitsOverviewList({required this.habits});

  @override
  Widget build(BuildContext context) {
    if (habits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text('No habits yet',
              style: TextStyle(color: AppColors.darkTextSecondary)),
        ),
      );
    }

    return Column(
      children: habits.map((habit) {
        Color habitColor;
        try {
          habitColor = Color(int.parse(habit.color.replaceFirst('#', '0xFF')));
        } catch (_) {
          habitColor = AppColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(habit.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          '${(habit.monthlyCompletionRate * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
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
                        valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Habit Heatmap ─────────────────────────────────────────────────────

class _HabitHeatmap extends StatelessWidget {
  final List<HabitModel> habits;

  const _HabitHeatmap({required this.habits});

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(35, (i) => now.subtract(Duration(days: 34 - i)));

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((day) {
        final completed =
            habits.where((h) => h.completionLog[_dateKey(day)] == true).length;
        final total = habits.length;
        final intensity = total > 0 ? completed / total : 0.0;

        return Tooltip(
          message: '${day.day}/${day.month}: $completed/$total habits',
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: intensity == 0
                  ? AppColors.darkSurfaceElevated
                  : AppColors.secondary.withOpacity(0.15 + intensity * 0.75),
              borderRadius: BorderRadius.circular(6),
              border: isSameDay(day, now)
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: intensity > 0
                ? Center(
                    child: Text(
                      '$completed',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary
                            .withOpacity(0.5 + intensity * 0.5),
                      ),
                    ),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;
}

// ── Productivity Score ────────────────────────────────────────────────────────

class _ProductivityScore extends StatelessWidget {
  final AppProvider provider;

  const _ProductivityScore({required this.provider});

  int _computeScore() {
    final taskScore = provider.tasks.isEmpty
        ? 0
        : ((provider.completedTasks.length / provider.tasks.length) * 50)
            .toInt();
    final habitScore = provider.habits.isEmpty
        ? 0
        : (provider.habits
                    .map((h) => h.monthlyCompletionRate)
                    .reduce((a, b) => a + b) /
                provider.habits.length *
                30)
            .toInt();
    final focusScore =
        (provider.totalFocusMinutes / 200 * 20).clamp(0, 20).toInt();
    return (taskScore + habitScore + focusScore).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = _computeScore();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.darkBorder,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text('$score',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Productivity Score',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  score >= 80
                      ? '🏆 Outstanding! Keep it up!'
                      : score >= 60
                          ? '⚡ Great progress!'
                          : score >= 40
                              ? '📈 Building momentum!'
                              : '🌱 Just getting started!',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  '${score}% of your potential',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
