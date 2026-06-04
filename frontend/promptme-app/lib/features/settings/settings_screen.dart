import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../services/ai/ai_client.dart';
import '../../services/ai/ai_config.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import 'feishu_import_sheet.dart';

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
  final _subName = TextEditingController();
  final _subUrl = TextEditingController();
  final _aiKey = TextEditingController();
  final _baseUrl = TextEditingController();
  final _model = TextEditingController();

  bool _obscureKey = true;
  String _preset = '自定义';
  bool _testing = false;
  String? _testResult;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(settingsProvider).aiConfig;
    _aiKey.text = cfg.apiKey;
    _baseUrl.text = cfg.baseUrl ?? '';
    _model.text = cfg.model ?? '';
    _preset = _presetNameFor(_baseUrl.text);
  }

  @override
  void dispose() {
    _subName.dispose();
    _subUrl.dispose();
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

  // ---- 苹果日历订阅 ----

  Future<void> _addSubscription() async {
    final url = _subUrl.text.trim();
    if (url.isEmpty) return;
    final name = _subName.text.trim().isEmpty ? '我的日历' : _subName.text.trim();
    final db = ref.read(databaseProvider);
    // 同 URL 复用，避免重复添加导致事件翻倍。
    final existing = await db.calendarDao.subscriptionsList();
    final match = existing.where((s) => s.url == url).toList();
    final id = match.isNotEmpty
        ? match.first.id
        : await db.calendarDao.addSubscription(
            SubscriptionsCompanion.insert(url: url, displayName: name));
    await _fetchInto(id, url, label: '订阅已拉取');
    if (mounted) {
      _subUrl.clear();
      _subName.clear();
    }
  }

  Future<void> _fetchInto(int id, String url, {required String label}) async {
    final db = ref.read(databaseProvider);
    try {
      final total = await ref.read(subscriptionServiceProvider).refresh(id, url);
      final todayN =
          (await db.calendarDao.eventsForDate(ref.read(selectedDateProvider)))
              .length;
      _toast('$label：共 $total 个事件，今天 $todayN 个');
    } catch (e) {
      _toast('拉取失败：$e');
    }
  }

  Future<void> _deleteSubscription(Subscription sub) async {
    await ref.read(databaseProvider).calendarDao.deleteSubscription(sub.id);
    _toast('已删除「${sub.displayName}」');
  }

  // ---- AI ----

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
    final subs = ref.watch(subscriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppColors.paper),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _calendarCard(subs),
          _feishuCard(),
          _aiCard(),
        ],
      ),
    );
  }

  // ---------------- 卡片 ----------------

  Widget _calendarCard(AsyncValue<List<Subscription>> subs) => _card(
        title: '苹果日历订阅',
        subtitle: '粘贴 iCloud published 链接，拉取时间块到「今日」。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subName,
              decoration: _dec('名称（可选，如：工作 / 家庭）'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _subUrl,
              keyboardType: TextInputType.url,
              decoration:
                  _dec('https://p…-caldav.icloud.com.cn/published/…'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _addSubscription,
                child: const Text('添加并拉取'),
              ),
            ),
            const SizedBox(height: 12),
            subs.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Text('订阅列表出错：$e',
                  style: const TextStyle(color: AppColors.q1)),
              data: (list) => Column(
                children: [
                  for (final sub in list) _subTile(sub),
                  if (list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('还没有订阅。粘贴 published 链接添加。',
                            style: TextStyle(
                                color: AppColors.ink40, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _feishuCard() => _card(
        title: '飞书任务导入',
        subtitle: '从飞书复制四象限任务的 Markdown，粘贴导入到今日。',
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.content_paste, size: 18),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.paper,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (_) => const FeishuImportSheet(),
            ),
            label: const Text('粘贴 Markdown 导入'),
          ),
        ),
      );

  Widget _aiCard() => _card(
        title: 'AI（自带 key）',
        subtitle: '只兼容 OpenAI 协议。选服务商自动填 Base URL，再填 key。',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

  Widget _subTile(Subscription sub) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink20)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    sub.lastFetchedAt == null ? '未拉取' : sub.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.ink40),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: AppColors.ink60),
              tooltip: '重新拉取',
              onPressed: () => _fetchInto(sub.id, sub.url, label: '已重新拉取'),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 20, color: AppColors.q1),
              tooltip: '删除',
              onPressed: () => _deleteSubscription(sub),
            ),
          ],
        ),
      );
}
