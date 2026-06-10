import 'package:drift/drift.dart';

// 条件导入：Web 端永不编译 native.dart（避免 sqlite3→ffi 被打进 Web 包而报错）。
// 默认走 native（Android/macOS/iOS）；当 dart:js_interop 可用（即 Web）时走 web.dart。
import 'native.dart' if (dart.library.js_interop) 'web.dart' as impl;

/// 平台无关的数据库连接入口。AppDatabase 只认这一个，不直接 import native/web。
QueryExecutor openConnection() => impl.openConnection();
