import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/state/providers.dart';

void main() {
  Future<void> logAbort(AppDatabase db, int taskId, int sec) =>
      db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: taskId,
        type: TaskEventType.tomatoAbort,
        createdAt: DateTime.now(),
        durationSec: Value(sec),
      ));

  test('两次「久放弃」(无显式太难了) → 诊断主因=能力(二次喂诊断)', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '写论文');
    await logAbort(db, id, 300); // ≥2min → 能力
    await logAbort(db, id, 400); // ≥2min → 能力

    final c =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(taskDiagnosisProvider(id), (_, _) {});
    final diag = await c.read(taskDiagnosisProvider(id).future);
    expect(diag.dominant, FailureReason.tired); // 能力(A)
  });

  test('两次「秒放弃」→ 诊断主因=动机', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.taskDao.insertCapture(title: '背单词');
    await logAbort(db, id, 20); // <2min → 动机
    await logAbort(db, id, 40); // <2min → 动机

    final c =
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);
    c.listen(taskDiagnosisProvider(id), (_, _) {});
    final diag = await c.read(taskDiagnosisProvider(id).future);
    expect(diag.dominant, FailureReason.noMotivation); // 动机(M)
  });
}
