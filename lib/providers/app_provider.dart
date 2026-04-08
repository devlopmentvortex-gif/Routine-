import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
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

  // ─── Focus Actions ─────────────────────────────────────────────────────────

  Future<void> saveFocusSession(FocusSession session) async {
    await _dbService.saveFocusSession(session);
    await _loadWeeklyStats();
  }
}
