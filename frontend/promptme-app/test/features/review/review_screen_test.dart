import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/review/review_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('复盘屏显示今日小结 + 累计（完成一件后今日完成=1）', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    final id = await db.taskDao.insertCapture(title: '写周报');
    await db.taskDao.markDone(id, DateTime.now());
    await db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: id, type: TaskEventType.done, createdAt: DateTime.now()));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ReviewScreen()),
    ));
    // drift 流异步发射；显式 pump 两帧，不用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('今日小结'), findsOneWidget);
    expect(find.text('累计'), findsOneWidget);
    expect(find.textContaining('MAP'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 今日完成 = 1

    await db.close();
    await tester.pump();
  });
}
