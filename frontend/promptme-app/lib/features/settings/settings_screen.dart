import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai/ai_client.dart';
import '../../services/ai/ai_config.dart';
import '../../state/integration_providers.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _aiKey = TextEditingController();
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();

  bool _obscureKey = true;
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;
  bool _aiEnabled = false;

  // ---- 桌面同步（ntfy） ----
  final _ntfyTopic = TextEditingController();
  bool _syncEnabled = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    final cfg = s.aiConfig;
    _aiKey.text = cfg.apiKey;
    _baseUrl.text = cfg.baseUrl ?? '';
    _model.text = cfg.model ?? '';
    _aiEnabled = s.aiEnabled;
    _ntfyTopic.text = s.ntfyTopic;
    _syncEnabled = s.syncEnabled;
  }

  @override
  void dispose() {
    _aiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    _ntfyTopic.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  // ---- AI ----

  /// 切 AI 总开关：即时存 + 失效缓存的 AiClient（下次按新 enabled 重建）。
  Future<void> _toggleAi(bool v) async {
    setState(() => _aiEnabled = v);
    await ref.read(settingsProvider).setAiEnabled(v);
    ref.invalidate(aiClientProvider);
    _toast(v ? 'AI 已开启' : 'AI 已关闭（走本地兜底）');
  }

  Future<void> _saveAi() async {
    await ref.read(settingsProvider).saveAi(
          apiKey: _aiKey.text.trim(),
          baseUrl: _baseUrl.text.trim(),
          model: _model.text.trim(),
        );
    // AiClient 是缓存的 Provider：保存后必须失效，否则仍用旧（空 key/旧 base/旧 model）配置。
    ref.invalidate(aiClientProvider);
    final cfg = ref.read(settingsProvider).aiConfig;
    _toast('AI 设置已保存（模型 ${cfg.effectiveModel}）');
  }

  Future<void> _testConnection() async {
    final key = _aiKey.text.trim();
    if (key.isEmpty) {
      setState(() {
        _testOk = false;
        _testResult = '请先填 API Key';
      });
      return;
    }
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final client = AiClient(
      config: AiConfig(
        apiKey: key,
        baseUrl: _baseUrl.text.trim(),
        model: _model.text.trim(),
      ),
    );
    final err = await client.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = err == null;
      _testResult = err == null ? '连接正常，密钥可用 ✓' : '连接失败：$err';
    });
  }

  // ---- 桌面同步（ntfy） ----

  /// 应用同步设置：存 topic + 开关，并即时启停订阅。
  Future<void> _applySync(bool enabled) async {
    final s = ref.read(settingsProvider);
    await s.setNtfyTopic(_ntfyTopic.text.trim());
    await s.setSyncEnabled(enabled);
    final svc = ref.read(ntfySyncServiceProvider);
    if (s.syncActive) {
      svc.start(s.ntfyTopic);
    } else {
      svc.stop();
    }
  }

  Future<void> _toggleSync(bool v) async {
    if (v && _ntfyTopic.text.trim().isEmpty) {
      _genTopic(); // 开同步但没 topic → 自动生成一个
    }
    setState(() => _syncEnabled = v);
    await _applySync(v);
    _toast(v ? '同步已开启（订阅 topic）' : '同步已关闭');
  }

  Future<void> _saveSyncTopic() async {
    await _applySync(_syncEnabled);
    _toast('topic 已保存${_syncEnabled ? '，已按新 topic 订阅' : ''}');
  }

  /// 生成超长随机 topic（公共 ntfy 弱口令；敏感后再自托管）。
  void _genTopic() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    final s = List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
    setState(() => _ntfyTopic.text = 'promptme-$s');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppColors.paper),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _aiCard(),
          _syncCard(),
        ],
      ),
    );
  }

  Widget _syncCard() => _card(
        title: '桌面同步（ntfy）',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('启用桌面同步',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                Switch(
                  value: _syncEnabled,
                  activeThumbColor: AppColors.leaf,
                  onChanged: _toggleSync,
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.ink20),
            _fieldLabel('Topic（手机与桌面一致）'),
            TextField(
              controller: _ntfyTopic,
              decoration: _dec(
                'promptme-超长随机串',
                suffix: IconButton(
                  tooltip: '复制',
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.ink40),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _ntfyTopic.text.trim()));
                    _toast('已复制 topic');
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _genTopic,
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const Text('随机生成'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveSyncTopic,
                    child: const Text('保存 topic'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('公共 topic 公开可读，用随机串当口令。',
                style: TextStyle(fontSize: 11.5, color: AppColors.ink40)),
          ],
        ),
      );

  // ---------------- 卡片 ----------------

  Widget _aiCard() => _card(
        title: '自定义 AI（OpenAI 协议）',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('启用 AI',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                Switch(
                  value: _aiEnabled,
                  activeThumbColor: AppColors.leaf,
                  onChanged: _toggleAi,
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.ink20),
            _fieldLabel('Base URL'),
            TextField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              decoration: _dec('https://api.deepseek.com'),
            ),
            const SizedBox(height: 14),
            _fieldLabel('API Key'),
            TextField(
              controller: _aiKey,
              obscureText: _obscureKey,
              decoration: _dec(
                'sk-…',
                suffix: IconButton(
                  icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: AppColors.ink40),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('模型'),
            TextField(
              controller: _model,
              decoration: _dec('留空用 deepseek-chat'),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              _testBanner(),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _testing ? null : _testConnection,
                    icon: _testing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(_testing ? '测试中…' : '测试连接'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveAi,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  // ---------------- 小组件 ----------------

  Widget _card({
    required String title,
    String? subtitle,
    required Widget child,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink40)),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      );

  Widget _fieldLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(t,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink60)),
      );

  InputDecoration _dec(String hint, {Widget? suffix}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.ink40, fontSize: 13.5),
        isDense: true,
        filled: true,
        fillColor: AppColors.paper,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink20),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
        ),
      );

  Widget _testBanner() {
    final color = _testOk ? AppColors.leaf : AppColors.q1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_testOk ? Icons.check_circle : Icons.error_outline,
              size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_testResult!,
                style: TextStyle(
                    fontSize: 12.5,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
