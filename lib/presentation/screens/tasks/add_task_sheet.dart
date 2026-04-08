import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../providers/app_provider.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key});

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Priority _priority = Priority.medium;
  String? _timeSlot;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _isRecurring = false;
  String? _recurringType;
  final List<String> _subTaskTitles = [];
  final _subTaskCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subTaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final task = TaskModel(
      id: const Uuid().v4(),
      userId: uid,
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
      priority: _priority,
      status: TaskStatus.pending,
      dueDate: _dueDate,
      dueTime: _dueTime,
      timeSlot: _timeSlot,
      isRecurring: _isRecurring,
      recurringType: _recurringType,
      subTasks: _subTaskTitles
          .map((t) => SubTask(id: const Uuid().v4(), title: t))
          .toList(),
    );

    await context.read<AppProvider>().addTask(task);

    // Wait for Firebase sync
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pop(context);
    }
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

            const Text('New Task',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Task title...',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Description (optional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),

            // Priority
            const Text('Priority',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: Priority.values.map((p) {
                final selected = _priority == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? p.color.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected ? p.color : AppColors.darkBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          color:
                              selected ? p.color : AppColors.darkTextSecondary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Time slot
            const Text('Time Slot',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                ('morning', '🌅', 'Morning'),
                ('afternoon', '☀️', 'Afternoon'),
                ('evening', '🌙', 'Evening'),
              ].map((slot) {
                final selected = _timeSlot == slot.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _timeSlot = selected ? null : slot.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.darkBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        '${slot.$2} ${slot.$3}',
                        style: TextStyle(
                          color: selected
                              ? AppColors.primary
                              : AppColors.darkTextSecondary,
                          fontSize: 13,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Due date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                          : 'Set due date (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dueDate != null ? null : AppColors.darkTextHint,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.darkTextHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Due time
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(
                      _dueTime != null
                          ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                          : 'Set time (optional)',
                      style: TextStyle(
                        fontSize: 14,
                        color: _dueTime != null ? null : AppColors.darkTextHint,
                      ),
                    ),
                    const Spacer(),
                    if (_dueTime != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueTime = null),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.darkTextHint),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Recurring toggle
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recurring Task',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Repeats automatically',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkTextSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _isRecurring,
                  onChanged: (v) => setState(() => _isRecurring = v),
                ),
              ],
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              Row(
                children: ['daily', 'weekly', 'monthly'].map((type) {
                  final selected = _recurringType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _recurringType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.info.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: selected
                                ? AppColors.info
                                : AppColors.darkBorder,
                          ),
                        ),
                        child: Text(
                          type[0].toUpperCase() + type.substring(1),
                          style: TextStyle(
                            color: selected
                                ? AppColors.info
                                : AppColors.darkTextSecondary,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 20),

            // Sub-tasks
            const Text('Sub-tasks',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._subTaskTitles.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle_rounded,
                          color: AppColors.darkTextHint, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.value,
                              style: const TextStyle(fontSize: 14))),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _subTaskTitles.removeAt(e.key)),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.darkTextHint),
                      ),
                    ],
                  ),
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subTaskCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add sub-task...',
                      isDense: true,
                    ),
                    onSubmitted: _addSubTask,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _addSubTask(_subTaskCtrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Add Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSubTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() => _subTaskTitles.add(title.trim()));
    _subTaskCtrl.clear();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }
}
