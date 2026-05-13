import 'package:flutter/widgets.dart';

class TaskModel {
  final String id;
  final String tag;
  final ValueNotifier<int> completedUnits;
  final int totalUnits;
  final String description;

  TaskModel({
    required this.id,
    required this.tag,
    required this.completedUnits,
    required this.totalUnits,
    required this.description,
  });

  double get progress => (completedUnits.value / totalUnits).clamp(0.0, 1.0);

  void addProgress(int units) => completedUnits.value += units;

  void dispose() => completedUnits.dispose();
}
