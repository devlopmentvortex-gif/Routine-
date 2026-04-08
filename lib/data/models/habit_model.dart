import 'package:flutter/material.dart';

enum HabitPriority { high, medium, low }

enum HabitCategory {
  health,
  fitness,
  productivity,
  mindfulness,
  learning,
  social,
  creativity,
  custom
}

enum TimeSlot { morning, afternoon, evening, anytime }

extension HabitPriorityExt on HabitPriority {
  String get label {
    switch (this) {
      case HabitPriority.high:
        return 'High';
      case HabitPriority.medium:
        return 'Medium';
      case HabitPriority.low:
        return 'Low';
    }
  }

  Color get color {
    switch (this) {
      case HabitPriority.high:
        return const Color(0xFF9333EA); // Purple
      case HabitPriority.medium:
        return const Color(0xFFF59E0B); // Amber
      case HabitPriority.low:
        return const Color(0xFF64748B); // Slate
    }
  }
}

extension HabitCategoryExt on HabitCategory {
  String get label {
    switch (this) {
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.fitness:
        return 'Fitness';
      case HabitCategory.productivity:
        return 'Productivity';
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.learning:
        return 'Learning';
      case HabitCategory.social:
        return 'Social';
      case HabitCategory.creativity:
        return 'Creativity';
      case HabitCategory.custom:
        return 'Custom';
    }
  }

  String get defaultEmoji {
    switch (this) {
      case HabitCategory.health:
        return '💊';
      case HabitCategory.fitness:
        return '🏃';
      case HabitCategory.productivity:
        return '📈';
      case HabitCategory.mindfulness:
        return '🧘';
      case HabitCategory.learning:
        return '📚';
      case HabitCategory.social:
        return '👥';
      case HabitCategory.creativity:
        return '🎨';
      case HabitCategory.custom:
        return '⭐';
    }
  }

  String get defaultColor {
    switch (this) {
      case HabitCategory.health:
        return '#EF4444';
      case HabitCategory.fitness:
        return '#10B981';
      case HabitCategory.productivity:
        return '#3B82F6';
      case HabitCategory.mindfulness:
        return '#8B5CF6';
      case HabitCategory.learning:
        return '#F59E0B';
      case HabitCategory.social:
        return '#EC4899';
      case HabitCategory.creativity:
        return '#14B8A6';
      case HabitCategory.custom:
        return '#7C6EF5';
    }
  }
}

extension TimeSlotExt on TimeSlot {
  String get label {
    switch (this) {
      case TimeSlot.morning:
        return 'Morning';
      case TimeSlot.afternoon:
        return 'Afternoon';
      case TimeSlot.evening:
        return 'Evening';
      case TimeSlot.anytime:
        return 'Anytime';
    }
  }

  TimeOfDay get timeRange {
    switch (this) {
      case TimeSlot.morning:
        return const TimeOfDay(hour: 6, minute: 0);
      case TimeSlot.afternoon:
        return const TimeOfDay(hour: 12, minute: 0);
      case TimeSlot.evening:
        return const TimeOfDay(hour: 18, minute: 0);
      case TimeSlot.anytime:
        return const TimeOfDay(hour: 12, minute: 0);
    }
  }
}

class HabitModel {
  final String id;
  final String userId;
  String title;
  String description;
  String emoji;
  String color;
  HabitCategory category;
  HabitPriority priority;
  TimeSlot timeSlot;
  String frequency; // 'daily', 'weekly', 'custom'
  Map<String, bool> completionLog; // key: 'yyyy-MM-dd', value: done
  DateTime? lastCompletedDate;
  int currentStreak;
  int bestStreak;
  bool isActive;
  List<String> reminderTimes; // HH:MM format strings
  DateTime createdAt;
  DateTime? updatedAt;

  HabitModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.emoji,
    required this.color,
    required this.category,
    required this.priority,
    required this.timeSlot,
    required this.frequency,
    Map<String, bool>? completionLog,
    this.lastCompletedDate,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.isActive = true,
    List<String>? reminderTimes,
    DateTime? createdAt,
    this.updatedAt,
  })  : completionLog = completionLog ?? {},
        reminderTimes = reminderTimes ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Enhanced streak logic with 24-hour reset
  int calculateCurrentStreak() {
    if (completionLog.isEmpty) return 0;

    int streak = 0;
    DateTime currentDate = DateTime.now();
    final todayKey = _dateKey(currentDate);
    final yesterdayKey =
        _dateKey(currentDate.subtract(const Duration(days: 1)));

    // Check if habit was completed today or yesterday
    bool hasRecentCompletion =
        completionLog[todayKey] == true || completionLog[yesterdayKey] == true;

    if (!hasRecentCompletion) {
      return 0; // Reset streak if no completion in last 24 hours
    }

    // Count consecutive days backwards from today
    while (true) {
      final key = _dateKey(currentDate);
      if (completionLog[key] == true) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Check if habit is completed on a specific date
  bool isCompletedOn(DateTime date) {
    return completionLog[_dateKey(date)] == true;
  }

  // Check if habit is completed today
  bool get isCompletedToday {
    return isCompletedOn(DateTime.now());
  }

  // Get completion rate for the last N days
  double getCompletionRateForDays(int days) {
    if (completionLog.isEmpty) return 0.0;

    int completedCount = 0;
    DateTime currentDate = DateTime.now();

    for (int i = 0; i < days; i++) {
      final checkDate = currentDate.subtract(Duration(days: i));
      if (isCompletedOn(checkDate)) {
        completedCount++;
      }
    }

    return completedCount / days;
  }

  // Get monthly completion rate
  double get monthlyCompletionRate {
    return getCompletionRateForDays(30);
  }

  // Get weekly completion rate
  double get weeklyCompletionRate {
    return getCompletionRateForDays(7);
  }

  // Get completion status for the last 7 days (for UI display)
  List<bool> get last7DaysCompletion {
    final List<bool> completions = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      completions.add(isCompletedOn(date));
    }

    return completions;
  }

  // Update streak based on completion
  void updateStreak() {
    final now = DateTime.now();
    final todayKey = _dateKey(now);
    final yesterdayKey = _dateKey(now.subtract(const Duration(days: 1)));

    if (completionLog[todayKey] == true) {
      // Completed today - calculate streak
      currentStreak = calculateCurrentStreak();
      lastCompletedDate = now;

      // Update best streak if needed
      if (currentStreak > bestStreak) {
        bestStreak = currentStreak;
      }
    } else if (completionLog[yesterdayKey] == false &&
        completionLog[todayKey] == false) {
      // Missed both yesterday and today - reset streak
      currentStreak = 0;
    }
  }

  // Mark habit as completed for today
  HabitModel completeForToday() {
    final todayKey = _dateKey(DateTime.now());
    final updatedCompletionLog = Map<String, bool>.from(completionLog);
    updatedCompletionLog[todayKey] = true;

    final updatedHabit = HabitModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      emoji: emoji,
      color: color,
      category: category,
      priority: priority,
      timeSlot: timeSlot,
      frequency: frequency,
      completionLog: updatedCompletionLog,
      lastCompletedDate: DateTime.now(),
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isActive: isActive,
      reminderTimes: List<String>.from(reminderTimes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    updatedHabit.updateStreak();
    return updatedHabit;
  }

  // Mark habit as incomplete for today
  HabitModel uncompleteForToday() {
    final todayKey = _dateKey(DateTime.now());
    final updatedCompletionLog = Map<String, bool>.from(completionLog);
    updatedCompletionLog[todayKey] = false;

    final updatedHabit = HabitModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      emoji: emoji,
      color: color,
      category: category,
      priority: priority,
      timeSlot: timeSlot,
      frequency: frequency,
      completionLog: updatedCompletionLog,
      lastCompletedDate: lastCompletedDate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      isActive: isActive,
      reminderTimes: List<String>.from(reminderTimes),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    updatedHabit.updateStreak();
    return updatedHabit;
  }

  // Helper method to create date key
  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'emoji': emoji,
      'color': color,
      'category': category.name,
      'priority': priority.name,
      'timeSlot': timeSlot.name,
      'frequency': frequency,
      'completionLog': completionLog,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'isActive': isActive,
      'reminderTimes': reminderTimes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firebase Map
  factory HabitModel.fromMap(Map<dynamic, dynamic> map) {
    try {
      // Handle completionLog with proper type checking for RTDB
      Map<String, bool> completionLog = {};
      if (map['completionLog'] != null) {
        if (map['completionLog'] is Map) {
          final completionLogMap = map['completionLog'] as Map;
          completionLog = completionLogMap
              .map((k, v) => MapEntry(k.toString(), v is bool ? v : false));
        }
      }

      // Parse reminderTimes
      List<String> reminderTimes = [];
      if (map['reminderTimes'] != null) {
        if (map['reminderTimes'] is List) {
          reminderTimes =
              (map['reminderTimes'] as List).map((e) => e.toString()).toList();
        }
      }

      return HabitModel(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        emoji: map['emoji']?.toString() ?? '⭐',
        color: map['color']?.toString() ?? '#7C6EF5',
        category: HabitCategory.values.firstWhere(
          (c) => c.name == map['category'],
          orElse: () => HabitCategory.custom,
        ),
        priority: HabitPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => HabitPriority.medium,
        ),
        timeSlot: TimeSlot.values.firstWhere(
          (t) => t.name == map['timeSlot'],
          orElse: () => TimeSlot.morning,
        ),
        frequency: map['frequency']?.toString() ?? 'daily',
        completionLog: completionLog,
        lastCompletedDate: map['lastCompletedDate'] != null
            ? DateTime.tryParse(map['lastCompletedDate'].toString())
            : null,
        currentStreak: map['currentStreak'] ?? 0,
        bestStreak: map['bestStreak'] ?? 0,
        isActive: map['isActive'] ?? true,
        reminderTimes: reminderTimes,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: map['updatedAt'] != null
            ? DateTime.tryParse(map['updatedAt'].toString())
            : null,
      );
    } catch (e) {
      // Return a default habit if parsing fails
      return HabitModel(
        id: map['id']?.toString() ?? '',
        userId: map['userId']?.toString() ?? '',
        title: map['title']?.toString() ?? 'Error Loading Habit',
        description: '',
        emoji: '⭐',
        color: '#7C6EF5',
        category: HabitCategory.custom,
        priority: HabitPriority.medium,
        timeSlot: TimeSlot.morning,
        frequency: 'daily',
        completionLog: {},
        createdAt: DateTime.now(),
      );
    }
  }

  // Create a copy with updated fields
  HabitModel copyWith({
    String? title,
    String? description,
    String? emoji,
    String? color,
    HabitCategory? category,
    HabitPriority? priority,
    TimeSlot? timeSlot,
    String? frequency,
    Map<String, bool>? completionLog,
    DateTime? lastCompletedDate,
    int? currentStreak,
    int? bestStreak,
    bool? isActive,
    List<String>? reminderTimes,
    DateTime? updatedAt,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      timeSlot: timeSlot ?? this.timeSlot,
      frequency: frequency ?? this.frequency,
      completionLog: completionLog ?? this.completionLog,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      isActive: isActive ?? this.isActive,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HabitModel{id: $id, title: $title, category: $category, priority: $priority, currentStreak: $currentStreak}';
  }
}
