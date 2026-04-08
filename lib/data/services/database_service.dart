import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import '../models/habit_model.dart';

class DatabaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // ─── Tasks ────────────────────────────────────────────────────────────────

  DatabaseReference get _tasksRef => _db.ref('users/$_uid/tasks');

  Stream<List<TaskModel>> streamTasks() {
    return _tasksRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <TaskModel>[];
      }

      try {
        final Map data = event.snapshot.value as Map;
        final tasks = data.values
            .map((v) {
              try {
                return TaskModel.fromMap(v as Map);
              } catch (e) {
                return null;
              }
            })
            .where((task) => task != null)
            .cast<TaskModel>()
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return tasks;
      } catch (e) {
        return <TaskModel>[];
      }
    });
  }

  Future<void> addTask(TaskModel task) async {
    await _tasksRef.child(task.id).set(task.toMap());
  }

  Future<void> updateTask(TaskModel task) async {
    await _tasksRef.child(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId) async {
    await _tasksRef.child(taskId).remove();
  }

  Future<void> toggleTaskStatus(String taskId, bool isCompleted) async {
    await _tasksRef.child(taskId).update({
      'status': isCompleted ? 'completed' : 'pending',
    });
  }

  Future<void> updateSubTask(String taskId, List<SubTask> subTasks) async {
    await _tasksRef.child(taskId).update({
      'subTasks': subTasks.map((s) => s.toMap()).toList(),
    });
  }

  // ─── Habits ───────────────────────────────────────────────────────────────

  DatabaseReference get _habitsRef => _db.ref('users/$_uid/habits');

  Stream<List<HabitModel>> streamHabits() {
    return _habitsRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <HabitModel>[];
      }

      try {
        final Map data = event.snapshot.value as Map;
        final habits = data.values
            .map((v) {
              try {
                return HabitModel.fromMap(v as Map);
              } catch (e) {
                return null;
              }
            })
            .where((habit) => habit != null)
            .cast<HabitModel>()
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return habits;
      } catch (e) {
        return <HabitModel>[];
      }
    });
  }

  Future<void> addHabit(HabitModel habit) async {
    await _habitsRef.child(habit.id).set(habit.toMap());
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _habitsRef.child(habit.id).update(habit.toMap());
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitsRef.child(habitId).remove();
  }

  Future<void> toggleHabitCompletion(
      String habitId, String dateKey, bool isDone) async {
    await _habitsRef
        .child(habitId)
        .child('completionLog')
        .update({dateKey: isDone});
  }

  // ─── Focus Sessions ───────────────────────────────────────────────────────

  DatabaseReference get _focusRef => _db.ref('users/$_uid/focusSessions');

  Future<void> saveFocusSession(FocusSession session) async {
    await _focusRef.child(session.id).set(session.toMap());
  }

  Stream<List<FocusSession>> streamFocusSessions() {
    return _focusRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final Map data = event.snapshot.value as Map;
      return data.values.map((v) => FocusSession.fromMap(v as Map)).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    });
  }

  // ─── Analytics helpers ───────────────────────────────────────────────────

  Future<Map<String, int>> getWeeklyTaskStats() async {
    final snap = await _tasksRef.get();
    if (!snap.exists || snap.value == null) return {};

    final Map data = snap.value as Map;
    final Map<String, int> stats = {};
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      stats[key] = 0;
    }

    for (final v in data.values) {
      final task = TaskModel.fromMap(v as Map);
      if (task.isCompleted && task.dueDate != null) {
        final key =
            '${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2, '0')}-${task.dueDate!.day.toString().padLeft(2, '0')}';
        if (stats.containsKey(key)) {
          stats[key] = (stats[key] ?? 0) + 1;
        }
      }
    }
    return stats;
  }
}
