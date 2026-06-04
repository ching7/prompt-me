import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_config.dart';

class SettingsController {
  SettingsController(this._prefs);
  final SharedPreferences _prefs;

  static const _kKey = 'ai_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';
  static const _kSubUrl = 'subscription_url';

  AiConfig get aiConfig => AiConfig(
        apiKey: _prefs.getString(_kKey) ?? '',
        baseUrl: _prefs.getString(_kBaseUrl),
        model: _prefs.getString(_kModel),
      );

  Future<void> saveAi({
    required String apiKey,
    String? baseUrl,
    String? model,
  }) async {
    await _prefs.setString(_kKey, apiKey);
    if (baseUrl != null) await _prefs.setString(_kBaseUrl, baseUrl);
    if (model != null) await _prefs.setString(_kModel, model);
  }

  String? get pendingSubscriptionUrl => _prefs.getString(_kSubUrl);
  Future<void> saveSubscriptionUrl(String url) =>
      _prefs.setString(_kSubUrl, url);
}
