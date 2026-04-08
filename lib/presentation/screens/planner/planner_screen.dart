import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';
import '../tasks/add_task_sheet.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor =
        isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final allTasks = provider.tasks;

    final selectedTasks = allTasks.where((t) {
      if (t.dueDate == null) {
        return false;
      }
      final matches = t.dueDate!.year == _selectedDay.year &&
          t.dueDate!.month == _selectedDay.month &&
          t.dueDate!.day == _selectedDay.day;
      if (matches) {}
      return matches;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: "planner_fab",
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTaskSheet(),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: 20,
            title: const Text('Planner',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Calendar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: _format,
                    onFormatChanged: (f) => setState(() => _format = f),
                    onDaySelected: (selected, focused) => setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    }),
                    onPageChanged: (focused) =>
                        setState(() => _focusedDay = focused),
                    eventLoader: (day) {
                      return provider.tasks.where((t) {
                        if (t.dueDate == null) return false;
                        return t.dueDate!.year == day.year &&
                            t.dueDate!.month == day.month &&
                            t.dueDate!.day == day.day;
                      }).toList();
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      defaultTextStyle:
                          TextStyle(color: textPrimary, fontSize: 14),
                      weekendTextStyle:
                          TextStyle(color: textPrimary, fontSize: 14),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      markerDecoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      markerSize: 5,
                      markersMaxCount: 3,
                      cellMargin: const EdgeInsets.all(4),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.primary),
                      ),
                      formatButtonTextStyle: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      titleTextStyle: TextStyle(
                        color: textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      leftChevronIcon: Icon(Icons.chevron_left_rounded,
                          color: textSecondary),
                      rightChevronIcon: Icon(Icons.chevron_right_rounded,
                          color: textSecondary),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      weekendStyle: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Selected day tasks
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        _formatSelectedDay(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${selectedTasks.length} tasks',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                if (selectedTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Text('📅', style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks for this day',
                          style: TextStyle(color: textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, i) {
                      final task = selectedTasks[i];
                      return _PlannerTaskTile(task: task, provider: provider);
                    },
                  ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSelectedDay() {
    final now = DateTime.now();
    if (isSameDay(_selectedDay, now)) return 'Today';
    if (isSameDay(_selectedDay, now.add(const Duration(days: 1))))
      return 'Tomorrow';
    if (isSameDay(_selectedDay, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[_selectedDay.weekday - 1]}, ${months[_selectedDay.month - 1]} ${_selectedDay.day}';
  }
}

class _PlannerTaskTile extends StatelessWidget {
  final TaskModel task;
  final AppProvider provider;

  const _PlannerTaskTile({required this.task, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: task.priority.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 44,
            decoration: BoxDecoration(
              color: task.priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? AppColors.darkTextHint : null,
                  ),
                ),
                if (task.timeSlot != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        task.timeSlot == 'morning'
                            ? '🌅'
                            : task.timeSlot == 'afternoon'
                                ? '☀️'
                                : '🌙',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.timeSlot![0].toUpperCase() +
                            task.timeSlot!.substring(1),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.darkTextSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          GestureDetector(
            onTap: () => provider.toggleTask(task.id, !task.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color:
                    task.isCompleted ? AppColors.secondary : Colors.transparent,
                border: Border.all(
                  color: task.isCompleted
                      ? AppColors.secondary
                      : AppColors.darkBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
