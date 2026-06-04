enum AiProvider { claude, openaiCompatible }

class AiConfig {
  final AiProvider provider;
  final String apiKey;
  final String? baseUrl; // openaiCompatible 用；claude 固定
  final String? model;

  const AiConfig({
    required this.provider,
    required this.apiKey,
    this.baseUrl,
    this.model,
  });

  bool get isConfigured => apiKey.isNotEmpty;

  String get effectiveModel =>
      model ??
      switch (provider) {
        AiProvider.claude => 'claude-sonnet-4-6',
        AiProvider.openaiCompatible => 'deepseek-chat',
      };

  Uri get endpoint => switch (provider) {
        AiProvider.claude => Uri.parse('https://api.anthropic.com/v1/messages'),
        AiProvider.openaiCompatible =>
          Uri.parse('${baseUrl ?? 'https://api.openai.com'}/v1/chat/completions'),
      };
}
