import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
import '../data/models/habit_model.dart';
import '../data/services/database_service.dart';
import '../data/services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  StreamSubscription? _authSubscription;

  // Theme
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  // Tasks
  List<TaskModel> _tasks = [];
  List<TaskModel> get tasks => _tasks;
  List<TaskModel> get pendingTasks =>
      _tasks.where((t) => !t.isCompleted).toList();
  List<TaskModel> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();
  List<TaskModel> get highPriorityTasks =>
      pendingTasks.where((t) => t.priority == Priority.high).toList();
  List<TaskModel> get mediumPriorityTasks =>
      pendingTasks.where((t) => t.priority == Priority.medium).toList();
  List<TaskModel> get lowPriorityTasks =>
      pendingTasks.where((t) => t.priority == Priority.low).toList();

  List<TaskModel> tasksForSlot(String slot) =>
      pendingTasks.where((t) => t.timeSlot == slot).toList();

  // Habits
  List<HabitModel> _habits = [];
  List<HabitModel> get habits => _habits;

  // Focus Sessions
  List<FocusSession> _focusSessions = [];
  List<FocusSession> get focusSessions => _focusSessions;

  int get totalFocusMinutes => _focusSessions
      .where((s) => s.isCompleted)
      .fold(0, (sum, s) => sum + s.durationMinutes);

  // Loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Subscriptions
  StreamSubscription? _tasksSub;
  StreamSubscription? _habitsSub;
  StreamSubscription? _focusSub;

  // Analytics
  Map<String, int> _weeklyStats = {};
  Map<String, int> get weeklyStats => _weeklyStats;

  // Initialize app and listen to auth state
  Future<void> initialize() async {
    await _loadTheme();

    // Listen to authentication state changes
    _authSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _startDataStreams();
      } else {
        _clearData();
      }
    });
  }

  void _startDataStreams() {
    _tasksSub?.cancel();
    _habitsSub?.cancel();
    _focusSub?.cancel();

    _tasksSub = _dbService.streamTasks().listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });

    _habitsSub = _dbService.streamHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });

    _focusSub = _dbService.streamFocusSessions().listen((sessions) {
      _focusSessions = sessions;
      notifyListeners();
    });
  }

  void _clearData() {
    _tasksSub?.cancel();
    _habitsSub?.cancel();
    _focusSub?.cancel();

    _tasks.clear();
    _habits.clear();
    _focusSessions.clear();
    notifyListeners();
  }

  // Today progress
  double get todayProgress {
    final today = DateTime.now();
    final todayTasks = _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == today.year &&
          t.dueDate!.month == today.month &&
          t.dueDate!.day == today.day;
    }).toList();
    if (todayTasks.isEmpty) return 0;
    final done = todayTasks.where((t) => t.isCompleted).length;
    return done / todayTasks.length;
  }

  int get todayTasksTotal {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == today.year &&
          t.dueDate!.month == today.month &&
          t.dueDate!.day == today.day;
    }).length;
  }

  int get todayTasksDone {
    final today = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == today.year &&
          t.dueDate!.month == today.month &&
          t.dueDate!.day == today.day &&
          t.isCompleted;
    }).length;
  }

  int get todayHabitsDone {
    final today = DateTime.now();
    return _habits.where((h) => h.isCompletedOn(today)).length;
  }

  AppProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('themeMode') ?? 'dark';
    _themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'themeMode', mode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  void startListening() {
    _tasksSub = _dbService.streamTasks().listen((tasks) {
      _tasks = tasks;
      notifyListeners();
    });
    _habitsSub = _dbService.streamHabits().listen((habits) {
      _habits = habits;
      notifyListeners();
    });
    _focusSub = _dbService.streamFocusSessions().listen((sessions) {
      _focusSessions = sessions;
      notifyListeners();
    });
    _loadWeeklyStats();
  }

  void stopListening() {
    _tasksSub?.cancel();
    _habitsSub?.cancel();
    _focusSub?.cancel();
  }

  Future<void> _loadWeeklyStats() async {
    _weeklyStats = await _dbService.getWeeklyTaskStats();
    notifyListeners();
  }

  // ─── Task Actions ──────────────────────────────────────────────────────────

  Future<void> addTask(TaskModel task) async {
    await _dbService.addTask(task);
  }

  Future<void> updateTask(TaskModel task) async {
    await _dbService.updateTask(task);
  }

  Future<void> deleteTask(String taskId) async {
    await _dbService.deleteTask(taskId);
  }

  Future<void> toggleTask(String taskId, bool done) async {
    await _dbService.toggleTaskStatus(taskId, done);
  }

  Future<void> updateSubTasks(String taskId, List<SubTask> subTasks) async {
    await _dbService.updateSubTask(taskId, subTasks);
  }

  // ─── Habit Actions ─────────────────────────────────────────────────────────

  Future<void> addHabit(HabitModel habit) async {
    await _dbService.addHabit(habit);
  }

  Future<void> deleteHabit(String habitId) async {
    await _dbService.deleteHabit(habitId);
  }

  Future<void> toggleHabit(String habitId, String dateKey, bool done) async {
    await _dbService.toggleHabitCompletion(habitId, dateKey, done);
  }

  // Helper function to create date key
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Optimistic UI updates for habits
  Future<void> toggleHabitOptimistic(String habitId) async {
    final habitIndex = _habits.indexWhere((h) => h.id == habitId);
    if (habitIndex == -1) return;

    final habit = _habits[habitIndex];
    final todayKey = _dateKey(DateTime.now());
    final isCurrentlyCompleted = habit.isCompletedOn(DateTime.now());

    // Optimistic update - update UI immediately
    if (isCurrentlyCompleted) {
      _habits[habitIndex] = habit.uncompleteForToday();
    } else {
      _habits[habitIndex] = habit.completeForToday();
    }
    notifyListeners();

    // Sync with Firebase in background
    try {
      await _dbService.toggleHabitCompletion(
          habitId, todayKey, !isCurrentlyCompleted);
    } catch (e) {
      // Revert on error
      _habits[habitIndex] = habit;
      notifyListeners();
    }
  }

  // Get habits grouped by time slot
  Map<TimeSlot, List<HabitModel>> get habitsByTimeSlot {
    final Map<TimeSlot, List<HabitModel>> grouped = {};
    for (final slot in TimeSlot.values) {
      grouped[slot] = [];
    }

    for (final habit in _habits) {
      if (habit.isActive) {
        grouped[habit.timeSlot]!.add(habit);
      }
    }

    // Sort each group by priority and creation date
    for (final slot in TimeSlot.values) {
      grouped[slot]!.sort((a, b) {
        // First by priority (high to low)
        final priorityOrder = {
          HabitPriority.high: 0,
          HabitPriority.medium: 1,
          HabitPriority.low: 2,
        };
        final priorityCompare =
            priorityOrder[a.priority]!.compareTo(priorityOrder[b.priority]!);
        if (priorityCompare != 0) return priorityCompare;

        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });
    }

    return grouped;
  }

  // Get today's completion percentage
  double get todayHabitCompletionPercentage {
    if (_habits.isEmpty) return 0.0;
    final completedCount = _habits.where((h) => h.isCompletedToday).length;
    return completedCount / _habits.length;
  }

  // ─── Focus Actions ─────────────────────────────────────────────────────────

  Future<void> saveFocusSession(FocusSession session) async {
    await _dbService.saveFocusSession(session);
    await _loadWeeklyStats();
  }
}
