import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database.dart';
import '../domain/ai/ai_models.dart';
import '../domain/enums.dart';
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

  /// 今日仍 pending 且已降级的任务 → 「『标题』已降级 N 次，反复卡在能力」。
  Future<List<String>> _gatherStruggling() async {
    final today = ref.read(selectedDateProvider);
    final tasks = await _db.taskDao.tasksForDate(today);
    final out = <String>[];
    for (final t in tasks) {
      if (t.status != TaskStatus.pending || t.downgradeLevel <= 0) continue;
      final events = await _db.taskEventDao.forTask(t.id);
      final diag = MapDiagnosis.from(events
          .where((e) => e.type == TaskEventType.tooHard && e.reason != null)
          .map((e) => e.reason!));
      final factor = diag.dominant != null
          ? '反复卡在${diag.dominant!.foggFactorName}'
          : '失败原因混合';
      out.add('「${t.title}」已降级 ${t.downgradeLevel} 次，$factor');
    }
    return out;
  }
}

final reviewControllerProvider =
    Provider<ReviewController>((ref) => ReviewController(ref));
