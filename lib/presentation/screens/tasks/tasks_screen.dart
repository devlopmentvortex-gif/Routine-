import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';
import 'add_task_sheet.dart';
import 'task_detail_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "tasks_fab",
        onPressed: () => _showAddTask(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Task',
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
                const Text('Tasks',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(
                  '${provider.pendingTasks.length} pending · ${provider.completedTasks.length} done',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.darkTextSecondary),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (provider.tasks.isEmpty) _EmptyState(),

                // Completed Tasks
                if (provider.completedTasks.isNotEmpty) ...[
                  _PriorityHeader(
                      label: 'Completed ✓', color: AppColors.secondary),
                  const SizedBox(height: 8),
                  ...provider.completedTasks.asMap().entries.map((e) =>
                      _TaskCard(task: e.value, provider: provider)
                          .animate()
                          .fadeIn(delay: (50 * e.key).ms)),
                  const SizedBox(height: 20),
                ],

                // High Priority
                if (provider.highPriorityTasks.isNotEmpty) ...[
                  _PriorityHeader(
                      label: 'High Priority 🔴', color: AppColors.priorityHigh),
                  const SizedBox(height: 8),
                  ...provider.highPriorityTasks.asMap().entries.map((e) =>
                      _TaskCard(task: e.value, provider: provider)
                          .animate()
                          .fadeIn(delay: (50 * e.key).ms)),
                  const SizedBox(height: 20),
                ],

                // Medium Priority
                if (provider.mediumPriorityTasks.isNotEmpty) ...[
                  _PriorityHeader(
                      label: 'Medium Priority 🟡',
                      color: AppColors.priorityMedium),
                  const SizedBox(height: 8),
                  ...provider.mediumPriorityTasks.asMap().entries.map((e) =>
                      _TaskCard(task: e.value, provider: provider)
                          .animate()
                          .fadeIn(delay: (50 * e.key).ms)),
                  const SizedBox(height: 20),
                ],

                // Low Priority
                if (provider.lowPriorityTasks.isNotEmpty) ...[
                  _PriorityHeader(
                      label: 'Low Priority 🟢', color: AppColors.priorityLow),
                  const SizedBox(height: 8),
                  ...provider.lowPriorityTasks.asMap().entries.map((e) =>
                      _TaskCard(task: e.value, provider: provider)
                          .animate()
                          .fadeIn(delay: (50 * e.key).ms)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTask(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTaskSheet(),
    );
  }
}

class _PriorityHeader extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatefulWidget {
  final TaskModel task;
  final AppProvider provider;

  const _TaskCard({required this.task, required this.provider});

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final task = widget.task;

    return Dismissible(
      key: Key(task.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Icon(Icons.check_circle_rounded,
            color: AppColors.secondary, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child:
            const Icon(Icons.delete_rounded, color: AppColors.danger, size: 28),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          widget.provider.toggleTask(task.id, true);
        } else {
          widget.provider.deleteTask(task.id);
        }
      },
      child: GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        onLongPress: () => _showDetail(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: task.priority.color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Priority bar
                    Container(
                      width: 3,
                      height: 44,
                      decoration: BoxDecoration(
                        color: task.priority.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Checkbox
                    GestureDetector(
                      onTap: () => widget.provider
                          .toggleTask(task.id, !task.isCompleted),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? AppColors.secondary
                              : Colors.transparent,
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
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted
                                  ? AppColors.darkTextHint
                                  : (isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary),
                            ),
                          ),
                          if (task.dueDate != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              _formatDate(task.dueDate!),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkTextSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Badges
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (task.isRecurring)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              '↻ ${task.recurringType ?? 'daily'}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.info,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (task.subTasks.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.darkTextSecondary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Sub-tasks (expandable)
              if (_expanded && task.subTasks.isNotEmpty)
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(28, 0, 14, 14),
                    child: Column(
                      children: task.subTasks.map((sub) {
                        return _SubTaskTile(
                          subTask: sub,
                          onToggle: (done) {
                            final updated = task.subTasks
                                .map((s) => s.id == sub.id
                                    ? SubTask(
                                        id: s.id,
                                        title: s.title,
                                        isCompleted: done)
                                    : s)
                                .toList();
                            widget.provider.updateSubTasks(task.id, updated);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) return 'Today';
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
    return '${months[date.month - 1]} ${date.day}';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TaskDetailSheet(task: widget.task),
    );
  }
}

class _SubTaskTile extends StatelessWidget {
  final SubTask subTask;
  final ValueChanged<bool> onToggle;

  const _SubTaskTile({required this.subTask, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onToggle(!subTask.isCompleted),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subTask.isCompleted
                    ? AppColors.secondary
                    : Colors.transparent,
                border: Border.all(
                  color: subTask.isCompleted
                      ? AppColors.secondary
                      : AppColors.darkBorder,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: subTask.isCompleted
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              subTask.title,
              style: TextStyle(
                fontSize: 13,
                decoration:
                    subTask.isCompleted ? TextDecoration.lineThrough : null,
                color: subTask.isCompleted
                    ? AppColors.darkTextHint
                    : AppColors.darkTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No tasks yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkTextPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first task',
            style: TextStyle(fontSize: 14, color: AppColors.darkTextSecondary),
          ),
        ],
      ),
    );
  }
}
