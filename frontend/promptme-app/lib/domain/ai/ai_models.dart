import '../enums.dart';

class PrioritySuggestion {
  final String taskTitle;
  final Quadrant quadrant;
  final String reason;
  PrioritySuggestion({
    required this.taskTitle,
    required this.quadrant,
    required this.reason,
  });
}

class PrioritizeResult {
  final List<PrioritySuggestion> suggestions;
  final List<String> todayFocus;
  PrioritizeResult({required this.suggestions, required this.todayFocus});
}

class ReviewItem {
  final String taskTitle;
  final String diagnosis;
  final String foggFactor;
  final String suggestion;
  ReviewItem({
    required this.taskTitle,
    required this.diagnosis,
    required this.foggFactor,
    required this.suggestion,
  });
}
