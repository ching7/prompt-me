import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/ai/ai_models.dart';
import '../domain/enums.dart';
import '../domain/fogg/focus_diagnosis.dart';
import '../domain/fogg/map_diagnosis.dart';
import 'integration_providers.dart';
import 'providers.dart';

class ReviewController {
  ReviewController(this.ref);
  final Ref ref;
  AppDatabase get _db => ref.read(databaseProvider);

  /// AI 是否可用（开关开 + 有 key）。复盘屏按钮据此置灰。
  bool get aiActive => ref.read(aiClientProvider).config.isActive;

  /// 生成 AI 复盘建议：收集今日仍在「挣扎」的任务（pending 且已降级）+ 其失败要素，
  /// 喂给已有的 AiClient.review（判 M/A/P + 给建议）。关 AI 时返回空。
  Future<List<ReviewItem>> generate() async {
    final ai = ref.read(aiClientProvider);
    if (!ai.config.isActive) {
      debugPrint('[AI] 复盘·未启用 → 跳过');
      return const [];
    }
    final descriptions = await _gatherStruggling();
    debugPrint('[AI] 复盘·调用 review（${descriptions.length} 条挣扎任务）');
    final items = await ai.review(descriptions);
    debugPrint('[AI] 复盘·返回 ${items.length} 条建议');
    return items;
  }

  /// 今日仍 pending 且已降级的任务 → 「『标题』已降级 N 次，反复卡在能力；放弃番茄 K 次（平均专注 X 分）」。
  /// 诊断含「专注时长二次喂诊断」；放弃信息一并喂给 AI，让建议更有据。
  Future<List<String>> _gatherStruggling() async {
    // 跟随复盘屏选中的日期（看历史某天时也对得上），不是全局「今天」。
    final date = ref.read(reviewDateProvider);
    final tasks = await _db.taskDao.tasksForDate(date);
    final out = <String>[];
    for (final t in tasks) {
      if (t.status != TaskStatus.pending || t.downgradeLevel <= 0) continue;
      final events = await _db.taskEventDao.forTask(t.id);
      final diag = MapDiagnosis.from(FocusDiagnosis.reasonsFrom(events.map(
          (e) => (type: e.type, reason: e.reason, durationSec: e.durationSec))));
      final factor = diag.dominant != null
          ? '反复卡在${diag.dominant!.foggFactorName}'
          : '失败原因混合';
      out.add(
          '「${t.title}」已降级 ${t.downgradeLevel} 次，$factor${_abortNote(events)}');
    }
    return out;
  }

  /// 放弃番茄的次数 + 平均专注分钟（有时长的才算）。无放弃 → 空串。
  String _abortNote(List<TaskEvent> events) {
    final aborts =
        events.where((e) => e.type == TaskEventType.tomatoAbort).toList();
    if (aborts.isEmpty) return '';
    final durs = aborts
        .map((e) => e.durationSec)
        .whereType<int>()
        .toList();
    if (durs.isEmpty) return '；放弃番茄 ${aborts.length} 次';
    final avgMin = (durs.reduce((a, b) => a + b) / durs.length / 60).round();
    return '；放弃番茄 ${aborts.length} 次（平均专注约 $avgMin 分）';
  }
}

final reviewControllerProvider =
    Provider<ReviewController>((ref) => ReviewController(ref));
