import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai/ai_config.dart';

class SettingsController {
  SettingsController(this._prefs);
  final SharedPreferences _prefs;

  static const _kKey = 'ai_key';
  static const _kBaseUrl = 'ai_base_url';
  static const _kModel = 'ai_model';
  static const _kEnabled = 'ai_enabled';

  /// AI 总开关，默认关（不开启就保持现状）。
  bool get aiEnabled => _prefs.getBool(_kEnabled) ?? false;

  Future<void> setAiEnabled(bool v) => _prefs.setBool(_kEnabled, v);

  AiConfig get aiConfig => AiConfig(
        apiKey: _prefs.getString(_kKey) ?? '',
        baseUrl: _prefs.getString(_kBaseUrl),
        model: _prefs.getString(_kModel),
        enabled: aiEnabled,
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

}
