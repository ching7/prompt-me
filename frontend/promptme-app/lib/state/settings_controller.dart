import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_config.dart';

class SettingsController {
  SettingsController(this._prefs);
  final SharedPreferences _prefs;

  static const _kProvider = 'ai_provider';
  static const _kKey = 'ai_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kSubUrl = 'subscription_url';

  AiConfig get aiConfig => AiConfig(
        provider: AiProvider.values[_prefs.getInt(_kProvider) ?? 0],
        apiKey: _prefs.getString(_kKey) ?? '',
        baseUrl: _prefs.getString(_kBaseUrl),
      );

  Future<void> saveAi({
    required AiProvider provider,
    required String apiKey,
    String? baseUrl,
  }) async {
    await _prefs.setInt(_kProvider, provider.index);
    await _prefs.setString(_kKey, apiKey);
    if (baseUrl != null) await _prefs.setString(_kBaseUrl, baseUrl);
  }

  String? get pendingSubscriptionUrl => _prefs.getString(_kSubUrl);
  Future<void> saveSubscriptionUrl(String url) =>
      _prefs.setString(_kSubUrl, url);
}
