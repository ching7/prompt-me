import 'dart:convert';
import '../enums.dart';
import 'ai_models.dart';

class AiResponseParser {
  /// 从可能包含散文/代码围栏的文本中抽出第一个 JSON 对象或数组。
  static String _extractJson(String raw, {required bool array}) {
    final open = array ? '[' : '{';
    final close = array ? ']' : '}';
    final start = raw.indexOf(open);
    final end = raw.lastIndexOf(close);
    if (start < 0 || end <= start) {
      throw const FormatException('no JSON found in AI response');
    }
    return raw.substring(start, end + 1);
  }

  static PrioritizeResult parsePrioritize(String raw) {
    final map = jsonDecode(_extractJson(raw, array: false)) as Map<String, dynamic>;
    final suggestions = ((map['suggestions'] as List?) ?? [])
        .map((e) => e as Map<String, dynamic>)
        .map((e) => PrioritySuggestion(
              taskTitle: (e['task'] ?? '').toString(),
              quadrant: Quadrant.fromLabel((e['quadrant'] ?? '').toString()) ??
                  Quadrant.importantNotUrgent,
              reason: (e['reason'] ?? '').toString(),
            ))
        .toList();
    final focus =
        ((map['todayFocus'] as List?) ?? []).map((e) => e.toString()).toList();
    return PrioritizeResult(suggestions: suggestions, todayFocus: focus);
  }

  static List<ReviewItem> parseReview(String raw) {
    final list = jsonDecode(_extractJson(raw, array: true)) as List;
    return list.map((e) => e as Map<String, dynamic>).map((e) => ReviewItem(
          taskTitle: (e['task'] ?? '').toString(),
          diagnosis: (e['diagnosis'] ?? '').toString(),
          foggFactor: (e['fogg'] ?? '').toString(),
          suggestion: (e['suggestion'] ?? '').toString(),
        )).toList();
  }
}
