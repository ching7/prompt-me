import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database.dart';
import '../../services/ai/ai_config.dart';
import '../../state/integration_providers.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import 'feishu_import_sheet.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _subUrl = TextEditingController();
  final _aiKey = TextEditingController();
  final _baseUrl = TextEditingController();
  AiProvider _provider = AiProvider.claude;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(settingsProvider).aiConfig;
    _provider = cfg.provider;
    _aiKey.text = cfg.apiKey;
    _baseUrl.text = cfg.baseUrl ?? '';
  }

  @override
  void dispose() {
    _subUrl.dispose();
    _aiKey.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _addSubscription() async {
    final url = _subUrl.text.trim();
    if (url.isEmpty) return;
    final db = ref.read(databaseProvider);
    final id = await db.calendarDao.addSubscription(
        SubscriptionsCompanion.insert(url: url, displayName: '我的日历'));
    try {
      await ref.read(subscriptionServiceProvider).refresh(id, url);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('订阅已添加并拉取')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('拉取失败：$e')));
      }
    }
  }

  Future<void> _saveAi() async {
    await ref.read(settingsProvider).saveAi(
          provider: _provider,
          apiKey: _aiKey.text.trim(),
          baseUrl: _baseUrl.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('AI 设置已保存')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), backgroundColor: AppColors.paper),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('苹果日历订阅'),
          TextField(
            controller: _subUrl,
            decoration: const InputDecoration(
                hintText: 'https://p…-caldav.icloud.com.cn/published/…'),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _addSubscription, child: const Text('添加并拉取')),
          const SizedBox(height: 24),
          _section('飞书任务导入'),
          OutlinedButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.paper,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
              builder: (_) => const FeishuImportSheet(),
            ),
            child: const Text('粘贴 Markdown 导入'),
          ),
          const SizedBox(height: 24),
          _section('AI（自带 key）'),
          DropdownButton<AiProvider>(
            value: _provider,
            items: const [
              DropdownMenuItem(value: AiProvider.claude, child: Text('Claude')),
              DropdownMenuItem(
                  value: AiProvider.openaiCompatible,
                  child: Text('OpenAI 兼容（DeepSeek/Qwen…）')),
            ],
            onChanged: (v) => setState(() => _provider = v!),
          ),
          TextField(
            controller: _aiKey,
            decoration: const InputDecoration(hintText: 'API Key'),
            obscureText: true,
          ),
          if (_provider == AiProvider.openaiCompatible)
            TextField(
              controller: _baseUrl,
              decoration:
                  const InputDecoration(hintText: 'Base URL，如 https://api.deepseek.com'),
            ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _saveAi, child: const Text('保存 AI 设置')),
        ],
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );
}
