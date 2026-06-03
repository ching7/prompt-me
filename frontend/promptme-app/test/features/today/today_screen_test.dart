import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/domain/enums.dart';
import 'package:promptme/features/today/today_screen.dart';
import 'package:promptme/state/providers.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('zh');
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: TodayScreen()),
    ));
    await tester.pumpAndSettle();
  }

  Future<int> seedTask() => db.taskDao.insertTask(TasksCompanion.insert(
        title: '整理农信问题',
        quadrant: Quadrant.importantUrgent,
        source: TaskSource.manual,
        scheduledDate: Value(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day)),
      ));

  testWidgets('tapping 我做到了 marks task done', (tester) async {
    final id = await seedTask();
    await pump(tester);
    expect(find.text('整理农信问题'), findsOneWidget);

    await tester.tap(find.text('我做到了'));
    await tester.pump(); // 触发 complete
    await tester.pump(const Duration(milliseconds: 100));

    expect((await db.taskDao.getById(id))!.status, TaskStatus.done);

    await tester.pump(const Duration(seconds: 2)); // 让庆祝层自动消失，排空计时器
  });

  testWidgets('太难了 → 选原因 → 任务降级', (tester) async {
    final id = await seedTask();
    await pump(tester);

    await tester.tap(find.text('太难了'));
    await tester.pumpAndSettle(); // 弹层

    await tester.tap(find.text('太累'));
    await tester.pumpAndSettle(); // 关闭弹层 + 执行降级 + snackbar

    final row = await db.taskDao.getById(id);
    expect(row!.downgradeLevel, 1);
    expect(row.currentPromptText, isNotNull);
    final ev = (await db.taskEventDao.forTask(id)).single;
    expect(ev.reason, FailureReason.tired);

    await tester.pump(const Duration(seconds: 5)); // 排空 snackbar 自动消失计时器
  });
}
