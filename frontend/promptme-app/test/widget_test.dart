import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:promptme/app.dart';
import 'package:promptme/data/database.dart';
import 'package:promptme/state/providers.dart';

void main() {
  testWidgets('app boots to TodayScreen', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('zh');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const PromptMeApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsOneWidget); // 今日屏头部
  });
}
