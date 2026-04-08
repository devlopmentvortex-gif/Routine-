import 'package:flutter/material.dart';

enum Priority { high, medium, low }

enum TaskStatus { pending, completed }

extension PriorityExt on Priority {
  String get label {
    switch (this) {
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case Priority.high:
        return const Color(0xFFEF5350);
      case Priority.medium:
        return const Color(0xFFFFA726);
      case Priority.low:
        return const Color(0xFF66BB6A);
    }
  }
}

class TaskModel {
  final String id;
  final String userId;
  String title;
  String? description;
  Priority priority;
  TaskStatus status;
  DateTime? dueDate;
  TimeOfDay? dueTime;
  String? timeSlot; // 'morning', 'afternoon', 'evening'
  bool isRecurring;
  String? recurringType; // 'daily', 'weekly', 'monthly'
  List<SubTask> subTasks;
  DateTime createdAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    this.dueDate,
    this.dueTime,
    this.timeSlot,
    this.isRecurring = false,
    this.recurringType,
    List<SubTask>? subTasks,
    DateTime? createdAt,
  })  : subTasks = subTasks ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isCompleted => status == TaskStatus.completed;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
      'timeSlot': timeSlot,
      'isRecurring': isRecurring,
      'recurringType': recurringType,
      'subTasks': subTasks.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    TimeOfDay? parseTime(String? timeStr) {
      if (timeStr == null) return null;
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return TaskModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      priority: Priority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => Priority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TaskStatus.pending,
      ),
      dueDate:
          map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
      dueTime: parseTime(map['dueTime']),
      timeSlot: map['timeSlot'],
      isRecurring: map['isRecurring'] ?? false,
      recurringType: map['recurringType'],
      subTasks:
          (map['subTasks'] as List?)?.map((s) => SubTask.fromMap(s)).toList() ??
              [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SubTask {
  final String id;
  String title;
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromMap(Map<dynamic, dynamic> map) => SubTask(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        isCompleted: map['isCompleted'] ?? false,
      );
}

// ─── Focus Session Model ────────────────────────────────────────────────────

class FocusSession {
  final String id;
  final String userId;
  int durationMinutes;
  String? taskTitle;
  DateTime startedAt;
  bool isCompleted;

  FocusSession({
    required this.id,
    required this.userId,
    required this.durationMinutes,
    this.taskTitle,
    DateTime? startedAt,
    this.isCompleted = false,
  }) : startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'durationMinutes': durationMinutes,
        'taskTitle': taskTitle,
        'startedAt': startedAt.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory FocusSession.fromMap(Map<dynamic, dynamic> map) => FocusSession(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        durationMinutes: map['durationMinutes'] ?? 25,
        taskTitle: map['taskTitle'],
        startedAt: map['startedAt'] != null
            ? DateTime.tryParse(map['startedAt']) ?? DateTime.now()
            : DateTime.now(),
        isCompleted: map['isCompleted'] ?? false,
      );
}
