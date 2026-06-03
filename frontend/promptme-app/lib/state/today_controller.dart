import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/downgrade.dart';
import 'providers.dart';

class TodayController {
  TodayController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  Future<void> addTask({
    required String title,
    required Quadrant quadrant,
  }) async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    await _db.taskDao.insertTask(TasksCompanion.insert(
      title: title,
      quadrant: quadrant,
      source: TaskSource.manual,
      scheduledDate: Value(today),
      firstScheduledDate: Value(today),
    ));
  }

  Future<void> complete(int id) async {
    final now = DateTime.now();
    await _db.taskDao.markDone(id, now);
    await _db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.done,
      createdAt: now,
    ));
  }

  /// 无底线降级：每次在原任务基础上把层级 +1，用本地兜底文案生成微习惯。
  /// 返回新的微习惯文案。AI 实网降级在计划③替换实现。
  Future<String> tooHard(int id, FailureReason reason) async {
    final task = await _db.taskDao.getById(id);
    final level = (task?.downgradeLevel ?? 0) + 1;
    final micro = Downgrade.localFallback(task?.title ?? '', level);
    await _db.taskDao.applyDowngrade(id, micro, level);
    await _db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.tooHard,
      createdAt: DateTime.now(),
      reason: Value(reason),
      microVersionText: Value(micro),
    ));
    return micro;
  }
}

final todayControllerProvider =
    Provider<TodayController>((ref) => TodayController(ref));
