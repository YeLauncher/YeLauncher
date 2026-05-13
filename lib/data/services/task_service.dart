import 'package:yelauncher/domain/models/task/task_model.dart';
import 'package:yelauncher/utilities/result.dart';

class TaskService {
  final Map<String, TaskModel> _tasks = {};
  final Map<String, List<TaskModel>> _tasksByTag = {};

  Future<Result<List<TaskModel>>> getTasks() async {
    return Result.success(_tasks.values.toList());
  }

  Future<Result<List<TaskModel>>> getTasksByTag(String tag) async {
    return Result.success(_tasksByTag[tag] ?? []);
  }

  Future<Result<void>> addTask(TaskModel task) async {
    _tasks[task.id] = task;
    _tasksByTag.putIfAbsent(task.tag, () => []).add(task);
    return Result.success(null);
  }

  Future<Result<void>> removeTask(String id) async {
    final task = _tasks.remove(id);
    if (task != null) {
      _tasksByTag[task.tag]?.removeWhere((t) => t.id == id);
    }
    return Result.success(null);
  }

  Future<Result<void>> clearTasks() async {
    _tasks.clear();
    _tasksByTag.clear();
    return Result.success(null);
  }

  Future<Result<void>> clearTasksByTag(String tag) async {
    final tasksToRemove = _tasksByTag.remove(tag) ?? [];
    for (var task in tasksToRemove) {
      _tasks.remove(task.id);
    }
    return Result.success(null);
  }
}