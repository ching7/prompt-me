import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'features/inbox/capture_sheet.dart';
import 'services/sync/desktop_capture_sender.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'theme/app_theme.dart';

/// 桌面端（macOS）零摩擦捕获入口。运行：
/// `flutter run -t lib/main_desktop.dart -d macos`
/// 全局热键 ⌘⇧Space 唤起浮窗 → 记一笔 → POST ntfy → 手机收件箱。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  const options = WindowOptions(
    size: Size(460, 340),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );
  unawaited(windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  }));

  final prefs = await SharedPreferences.getInstance();
  runApp(DesktopApp(prefs: prefs));
}

class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PromptMe 捕获',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: DesktopCaptureScreen(prefs: prefs),
    );
  }
}

class DesktopCaptureScreen extends StatefulWidget {
  const DesktopCaptureScreen({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<DesktopCaptureScreen> createState() => _DesktopCaptureScreenState();
}

class _DesktopCaptureScreenState extends State<DesktopCaptureScreen> {
  final _sender = DesktopCaptureSender();
  final _topicCtl = TextEditingController();
  HotKey? _hotKey;
  bool _editingTopic = false;
  String? _flash; // 发送反馈

  String get _topic => widget.prefs.getString('ntfy_topic') ?? '';

  @override
  void initState() {
    super.initState();
    _topicCtl.text = _topic;
    _editingTopic = _topic.isEmpty;
    _registerHotKey();
  }

  Future<void> _registerHotKey() async {
    final hk = HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );
    _hotKey = hk;
    await hotKeyManager.register(hk, keyDownHandler: (_) async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  @override
  void dispose() {
    if (_hotKey != null) hotKeyManager.unregister(_hotKey!);
    _topicCtl.dispose();
    super.dispose();
  }

  Future<void> _saveTopic() async {
    await widget.prefs.setString('ntfy_topic', _topicCtl.text.trim());
    setState(() => _editingTopic = _topic.isEmpty);
  }

  Future<void> _send(String text, String? domain) async {
    if (_topic.isEmpty) {
      setState(() {
        _editingTopic = true;
        _flash = '先设置 topic';
      });
      return;
    }
    final ok = await _sender.send(topic: _topic, text: text, domain: domain);
    if (!mounted) return;
    if (ok) {
      await windowManager.hide(); // 发完即隐，零摩擦
      setState(() => _flash = null);
    } else {
      setState(() => _flash = '发送失败，检查网络/topic');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            windowManager.hide(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('捕获', style: AppText.title(20)),
                    const Spacer(),
                    if (!_editingTopic)
                      TextButton.icon(
                        onPressed: () => setState(() => _editingTopic = true),
                        icon: const Icon(Icons.cloud_done_outlined, size: 16),
                        label: Text(_topic,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ),
                    IconButton(
                      tooltip: '隐藏（Esc）',
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.ink40,
                      onPressed: () => windowManager.hide(),
                    ),
                  ],
                ),
                if (_editingTopic) _topicEditor(),
                if (_flash != null) ...[
                  const SizedBox(height: 4),
                  Text(_flash!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.q1)),
                ],
                const SizedBox(height: 6),
                Expanded(
                  child: CaptureSheet(onCapture: _send),
                ),
                Text('⌘⇧Space 唤起 · Esc 隐藏',
                    style: TextStyle(fontSize: 10.5, color: AppColors.ink40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topicEditor() => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _topicCtl,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '与手机一致的 ntfy topic',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveTopic(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _saveTopic, child: const Text('保存')),
          ],
        ),
      );
}
