enum Quadrant {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent;

  String get label => switch (this) {
        Quadrant.importantUrgent => '重要紧急',
        Quadrant.importantNotUrgent => '重要非紧急',
        Quadrant.notImportantUrgent => '不重要紧急',
        Quadrant.notImportantNotUrgent => '不重要不紧急',
      };

  /// 排序权重：重要紧急最靠前（今日聚焦置顶）。
  int get priority => index;

  /// 容错匹配飞书标签：去掉空格与分隔符再比对。
  static Quadrant? fromLabel(String raw) {
    final s = raw.replaceAll(RegExp(r'[\s·•・\*#]'), '');
    return switch (s) {
      '重要紧急' => Quadrant.importantUrgent,
      '重要非紧急' => Quadrant.importantNotUrgent,
      '不重要紧急' => Quadrant.notImportantUrgent,
      '不重要不紧急' => Quadrant.notImportantNotUrgent,
      _ => null,
    };
  }
}

enum TaskStatus { pending, done }

enum TaskSource { manual, feishu, capture }

// 末尾追加 capture/tomato；intEnum 存 index，done=0/tooHard=1 不可动（兼容旧数据）。
enum TaskEventType { done, tooHard, capture, tomato }

enum FailureReason {
  forgot,
  tired,
  noMotivation;

  String get label => switch (this) {
        FailureReason.forgot => '忘记',
        FailureReason.tired => '太累',
        FailureReason.noMotivation => '没动力',
      };

  /// 对应福格模型中塌掉的要素。
  String get foggFactor => switch (this) {
        FailureReason.forgot => 'P',
        FailureReason.tired => 'A',
        FailureReason.noMotivation => 'M',
      };
}
