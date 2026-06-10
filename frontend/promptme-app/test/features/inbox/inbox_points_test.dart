import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/features/inbox/inbox_screen.dart';
import 'package:promptme/state/inbox_controller.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('收件箱顶栏 ★ 捕获后即时 +2', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: InboxScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('★0'), findsOneWidget);

    await c.read(inboxControllerProvider).capture(text: 'A');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('★2'), findsOneWidget); // 捕获 +2 即时反映
    await tester.pumpAndSettle(); // 跑完 ★ 跳动动画，避免残留 ticker
  });
}
