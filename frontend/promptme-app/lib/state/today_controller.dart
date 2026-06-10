import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/enums.dart';
import '../domain/fogg/downgrade.dart';
import 'integration_providers.dart';
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

  /// 重新开启已完成任务：回到 pending、清掉完成时间。
  Future<void> reopen(int id) => _db.taskDao.reopen(id);

  /// 删除任务，连带其行为事件。
  Future<void> deleteTask(int id) async {
    await _db.taskEventDao.deleteForTask(id);
    await _db.taskDao.deleteTask(id);
  }

  /// 无底线降级：每次在原任务基础上把层级 +1，用本地兜底文案生成微习惯。
  /// 返回新的微习惯文案。AI 实网降级在计划③替换实现。
  Future<String> tooHard(int id, FailureReason reason) async {
    final task = await _db.taskDao.getById(id);
    final level = (task?.downgradeLevel ?? 0) + 1;
    final title = task?.title ?? '';
    String micro;
    try {
      final ai = ref.read(aiClientProvider);
      micro = ai.config.isActive
          ? await ai.downgrade(taskTitle: title, reason: reason, level: level)
          : Downgrade.localFallback(title, level);
    } catch (_) {
      micro = Downgrade.localFallback(title, level);
    }
    await _db.taskDao.applyDowngrade(id, micro, level);
    await _db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: id,
      type: TaskEventType.tooHard,
      createdAt: DateTime.now(),
      reason: Value(reason),
      microVersionText: Value(micro),
    ));
    try {
      await ref.read(notificationServiceProvider).showMicroHabit(micro);
    } catch (_) {}
    return micro;
  }
}

final todayControllerProvider =
    Provider<TodayController>((ref) => TodayController(ref));
