import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 原生平台（Android / macOS / iOS）：落地到应用文档目录下的 sqlite 文件。
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase(File(p.join(dir.path, 'promptme.sqlite')));
  });
}
