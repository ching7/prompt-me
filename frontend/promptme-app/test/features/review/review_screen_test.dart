import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/review/review_screen.dart';
import 'package:promptme/state/integration_providers.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('复盘屏显示今日小结 + 累计 + AI 关闭引导', (tester) async {
    SharedPreferences.setMockInitialValues({}); // AI 默认关
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    final id = await db.taskDao.insertCapture(title: '写周报');
    await db.taskDao.markDone(id, DateTime.now());
    await db.taskEventDao.log(TaskEventsCompanion.insert(
        taskId: id, type: TaskEventType.done, createdAt: DateTime.now()));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: ReviewScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('今日小结'), findsOneWidget);
    expect(find.text('累计'), findsOneWidget);
    expect(find.textContaining('MAP'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // 今日完成 = 1

    // 点「AI 复盘」(关 AI) → 内联显引导
    await tester.tap(find.byKey(const ValueKey('review-ai')));
    await tester.pump();
    expect(find.textContaining('开启 AI'), findsOneWidget);

    await db.close();
    await tester.pump();
  });
}
