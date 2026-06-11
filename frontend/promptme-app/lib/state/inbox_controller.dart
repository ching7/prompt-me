import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import 'providers.dart';

class InboxController {
  InboxController(this.ref);
  final Ref ref;

  AppDatabase get _db => ref.read(databaseProvider);

  /// 手记/桌面捕获：source=capture、scheduledDate=null 进收件箱。
  Future<void> capture({required String text, String? domain}) =>
      _db.taskDao.insertCapture(title: text, domain: domain);

  /// 单条加入今日。
  Future<void> addToToday(int id) {
    final n = DateTime.now();
    return _db.taskDao.addToToday(id, DateTime(n.year, n.month, n.day));
  }

  /// 一键把多条加入今日。
  Future<void> addAllToToday(List<int> ids) async {
    final n = DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    for (final id in ids) {
      await _db.taskDao.addToToday(id, today);
    }
  }

  /// 改标题（详情弹窗）。
  Future<void> editTitle(int id, String title) =>
      _db.taskDao.updateTitle(id, title);

  /// 删除条目（连带行为事件，与 TodayController.deleteTask 一致）。
  Future<void> delete(int id) async {
    await _db.taskEventDao.deleteForTask(id);
    await _db.taskDao.deleteTask(id);
  }
}

final inboxControllerProvider =
    Provider<InboxController>((ref) => InboxController(ref));

/// 收件箱列表：无排期的待办，新→旧（见 TaskDao.watchInbox）。
final inboxProvider = StreamProvider<List<Task>>(
    (ref) => ref.watch(databaseProvider).taskDao.watchInbox());
