import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';

class TaskDetailSheet extends StatelessWidget {
  final TaskModel task;
  const TaskDetailSheet({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: task.priority.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(task.description!,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.darkTextSecondary, height: 1.6)),
          ],
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.flag_rounded, label: 'Priority', value: task.priority.label),
          if (task.timeSlot != null)
            _InfoRow(icon: Icons.schedule_rounded, label: 'Slot', value: task.timeSlot!),
          if (task.dueDate != null)
            _InfoRow(
                icon: Icons.calendar_today_rounded,
                label: 'Due',
                value: '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'),
          if (task.isRecurring)
            _InfoRow(icon: Icons.repeat_rounded, label: 'Recurring', value: task.recurringType ?? 'daily'),
          if (task.subTasks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Sub-tasks (${task.subTasks.where((s) => s.isCompleted).length}/${task.subTasks.length})',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...task.subTasks.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(s.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: s.isCompleted ? AppColors.secondary : AppColors.darkBorder, size: 18),
                  const SizedBox(width: 10),
                  Text(s.title,
                      style: TextStyle(
                        fontSize: 14,
                        decoration: s.isCompleted ? TextDecoration.lineThrough : null,
                        color: s.isCompleted ? AppColors.darkTextHint : null,
                      )),
                ],
              ),
            )),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.darkTextSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.darkTextSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
