import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/shell/home_shell.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('app boots to HomeShell with three tabs', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: HomeShell()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('收件箱'), findsWidgets); // nav label + inbox screen title
    expect(find.text('待办'), findsWidgets);
    expect(find.text('复盘'), findsOneWidget);
    expect(find.text('待办 · 占位'), findsOneWidget); // 默认选中「待办」

    await db.close();
    await tester.pump();
  });
}
