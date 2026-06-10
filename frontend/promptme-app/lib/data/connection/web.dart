import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web 平台：用 WasmDatabase（sqlite3 编译成 WASM，跑在浏览器里，OPFS/IndexedDB 持久化）。
/// 依赖 web/ 下两个资源：sqlite3.wasm、drift_worker.js（见 README 国内网络说明）。
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'promptme',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return db.resolvedExecutor;
  });
}
