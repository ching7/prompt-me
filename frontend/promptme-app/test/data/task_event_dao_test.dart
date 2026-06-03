import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('logs done and too_hard events with reason', () async {
    final taskId = await db.taskDao.insertTask(TasksCompanion.insert(
      title: '项目周报',
      quadrant: Quadrant.importantUrgent,
      source: TaskSource.feishu,
    ));

    await db.taskEventDao.log(TaskEventsCompanion.insert(
      taskId: taskId,
      type: TaskEventType.tooHard,
      createdAt: DateTime(2026, 6, 3, 16),
      reason: const Value(FailureReason.tired),
      microVersionText: const Value('只打开清单，写一句话'),
    ));

    final events = await db.taskEventDao.forTask(taskId);
    expect(events.single.type, TaskEventType.tooHard);
    expect(events.single.reason, FailureReason.tired);
  });
}
