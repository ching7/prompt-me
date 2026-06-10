import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/ai/ai_client.dart';
import '../../services/ai/ai_config.dart';
import '../../state/integration_providers.dart';
import '../../theme/app_colors.dart';

/// OpenAI 兼容服务商预设：点一下自动填 Base URL（与模型）。
class _AiPreset {
  final String name;
  final String baseUrl;
  final String model;
  const _AiPreset(this.name, this.baseUrl, this.model);
}

const _aiPresets = <_AiPreset>[
  _AiPreset('讯飞星火', 'https://maas-api.cn-huabei-1.xf-yun.com/v1', ''),
  _AiPreset('DeepSeek', 'https://api.deepseek.com', 'deepseek-chat'),
  _AiPreset('Qwen', 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'qwen-plus'),
];

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
  String _preset = '自定义';
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;
  bool _aiEnabled = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    final cfg = s.aiConfig;
    _aiKey.text = cfg.apiKey;
    _baseUrl.text = cfg.baseUrl ?? '';
    _model.text = cfg.model ?? '';
    _preset = _presetNameFor(_baseUrl.text);
    _aiEnabled = s.aiEnabled;
  }

  @override
  void dispose() {
    _aiKey.dispose();
    _baseUrl.dispose();
    _model.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  String _presetNameFor(String url) {
    final u = url.trim();
    for (final p in _aiPresets) {
      if (p.baseUrl == u) return p.name;
    }
    return '自定义';
  }

  void _selectPreset(String name) {
    final match = _aiPresets.where((e) => e.name == name).toList();
    setState(() {
      _preset = name;
      _testResult = null;
      if (match.isNotEmpty) {
        _baseUrl.text = match.first.baseUrl;
        _model.text = match.first.model;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppColors.paper),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _aiCard(),
        ],
      ),
    );
  }

  // ---------------- 卡片 ----------------

  Widget _aiCard() => _card(
        title: 'AI（自带 key）',
        subtitle: '只兼容 OpenAI 协议。选服务商自动填 Base URL，再填 key。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('启用 AI',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('关闭后所有 AI 功能走本地兜底（不发网络请求）',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.ink40)),
                    ],
                  ),
                ),
                Switch(
                  value: _aiEnabled,
                  activeThumbColor: AppColors.leaf,
                  onChanged: _toggleAi,
                ),
              ],
            ),
            const Divider(height: 18, color: AppColors.ink20),
            _fieldLabel('服务商'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _aiPresets) _presetChip(p.name),
                _presetChip('自定义'),
              ],
            ),
            const SizedBox(height: 16),
            _fieldLabel('Base URL'),
            TextField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              onChanged: (v) =>
                  setState(() => _preset = _presetNameFor(v)),
              decoration: _dec('https://…（讯飞可用 /v1 或 /v2）'),
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
              decoration:
                  _dec('留空用 deepseek-chat；讯飞填 MaaS 模型 ID（如 xdeepseekv3）'),
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

  Widget _presetChip(String name) {
    final selected = _preset == name;
    return GestureDetector(
      onTap: () => _selectPreset(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? AppColors.ink : AppColors.ink20),
        ),
        child: Text(name,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.paper : AppColors.ink60)),
      ),
    );
  }

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
