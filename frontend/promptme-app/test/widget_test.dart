import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:promptme/app.dart';

void main() {
  testWidgets('app shows brand on launch', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await tester.pumpWidget(const PromptMeApp());
    expect(find.text('PromptMe'), findsOneWidget);
    expect(find.text('记录每一次行动'), findsOneWidget);
  });
}
