import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'features/inbox/capture_sheet.dart';
import 'services/sync/desktop_capture_sender.dart';
import 'theme/app_colors.dart';
import 'theme/app_text.dart';
import 'theme/app_theme.dart';

/// 桌面端（macOS）零摩擦捕获入口。运行：
/// `flutter run -t lib/main_desktop.dart -d macos`
/// 菜单栏 tray 常驻；全局热键（可在「设置」改）唤起浮窗 → 记一笔 → POST ntfy → 手机收件箱。
const _kTopicKey = 'ntfy_topic';
const _kHotKeyKey = 'desktop_hotkey'; // 存 HotKey.toJson 的 JSON 串

HotKey _defaultHotKey() => HotKey(
      key: PhysicalKeyboardKey.space,
      modifiers: [HotKeyModifier.meta, HotKeyModifier.shift],
      scope: HotKeyScope.system,
    );

HotKey _loadHotKey(SharedPreferences prefs) {
  final raw = prefs.getString(_kHotKeyKey);
  if (raw == null) return _defaultHotKey();
  try {
    return HotKey.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return _defaultHotKey();
  }
}

/// 人类可读快捷键：⌘⇧Space 之类。
String hotKeyLabel(HotKey hk) {
  const sym = {
    HotKeyModifier.meta: '⌘',
    HotKeyModifier.shift: '⇧',
    HotKeyModifier.alt: '⌥',
    HotKeyModifier.control: '⌃',
    HotKeyModifier.capsLock: '⇪',
    HotKeyModifier.fn: 'fn',
  };
  final mods = (hk.modifiers ?? []).map((m) => sym[m] ?? m.name).join();
  var keyName = hk.logicalKey.keyLabel.trim();
  if (keyName.isEmpty || keyName == ' ') keyName = hk.physicalKey.debugName ?? '?';
  return '$mods$keyName';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  const options = WindowOptions(
    size: Size(460, 480),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
    alwaysOnTop: true,
  );
  unawaited(windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true); // 关窗=隐藏，常驻 tray
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

class _DesktopCaptureScreenState extends State<DesktopCaptureScreen>
    with TrayListener, WindowListener {
  final _sender = DesktopCaptureSender();
  final _topicCtl = TextEditingController();

  late HotKey _hotKey; // 当前生效的全局热键
  HotKey? _recording; // 录制中的新组合（未保存）
  bool _recordingMode = false; // 正在录制（此时挂载 recorder、临时摘掉全局热键）
  bool _settingsMode = false; // 设置面板 / 捕获面板
  bool _testing = false; // 「测试快捷键」中：触发只反馈、不切面板
  bool _justTriggered = false; // 检测：刚收到一次热键
  String? _flash; // 顶部提示条

  String get _topic => widget.prefs.getString(_kTopicKey) ?? '';

  @override
  void initState() {
    super.initState();
    _topicCtl.text = _topic;
    _hotKey = _loadHotKey(widget.prefs);
    _settingsMode = _topic.isEmpty; // 没配过 topic → 默认进设置
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initTray();
    _registerHotKey(_hotKey);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    hotKeyManager.unregisterAll();
    _topicCtl.dispose();
    super.dispose();
  }

  // ── tray ─────────────────────────────────────────────
  Future<void> _initTray() async {
    await trayManager.setIcon('assets/tray_icon.png', isTemplate: true);
    await trayManager.setToolTip('PromptMe 捕获');
    await _refreshTrayMenu();
  }

  Future<void> _refreshTrayMenu() async {
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'capture', label: '捕获…  ${hotKeyLabel(_hotKey)}'),
      MenuItem(key: 'settings', label: '设置…'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: '退出'),
    ]));
  }

  @override
  void onTrayIconMouseDown() => _showCapture(); // 左键 = 快速捕获
  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();
  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'capture':
        _showCapture();
        break;
      case 'settings':
        _showSettings();
        break;
      case 'quit':
        _quit();
        break;
    }
  }

  // ── window ───────────────────────────────────────────
  @override
  void onWindowClose() {
    // preventClose=true → 自己处理：隐藏而非退出（常驻 tray）。
    windowManager.hide();
  }

  Future<void> _showCapture() async {
    setState(() {
      _settingsMode = false;
      _recordingMode = false;
    });
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _showSettings() async {
    setState(() => _settingsMode = true);
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    await trayManager.destroy();
    exit(0);
  }

  // ── 热键 ─────────────────────────────────────────────
  Future<void> _registerHotKey(HotKey hk) async {
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(hk, keyDownHandler: (_) async {
      if (_testing) {
        // 检测模式：只反馈「收到」，不切面板
        setState(() => _justTriggered = true);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _justTriggered = false);
        });
        return;
      }
      await _showCapture();
    });
  }

  Future<void> _startRecording() async {
    FocusScope.of(context).unfocus();
    // 录制期间摘掉全局热键，免得按下旧键被系统抢走
    await hotKeyManager.unregisterAll();
    setState(() {
      _recordingMode = true;
      _recording = null;
    });
  }

  Future<void> _cancelRecording() async {
    await _registerHotKey(_hotKey); // 恢复旧键
    setState(() {
      _recordingMode = false;
      _recording = null;
    });
  }

  bool get _recordValid =>
      _recording != null && (_recording!.modifiers?.isNotEmpty ?? false);

  Future<void> _saveHotKey() async {
    final hk = _recording!;
    await widget.prefs.setString(_kHotKeyKey, jsonEncode(hk.toJson()));
    _hotKey = hk;
    await _registerHotKey(hk);
    await _refreshTrayMenu();
    setState(() {
      _recordingMode = false;
      _recording = null;
      _flash = '快捷键已更新：${hotKeyLabel(hk)}';
    });
  }

  void _startTest() {
    setState(() {
      _testing = true;
      _justTriggered = false;
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) setState(() => _testing = false);
    });
  }

  // ── topic ────────────────────────────────────────────
  Future<void> _saveTopic() async {
    await widget.prefs.setString(_kTopicKey, _topicCtl.text.trim());
    setState(() => _flash = _topic.isEmpty ? '请填写 topic' : 'topic 已保存');
  }

  Future<void> _send(String text, String? domain) async {
    if (_topic.isEmpty) {
      setState(() {
        _settingsMode = true;
        _flash = '先在设置里填 topic';
      });
      return;
    }
    bool ok;
    try {
      ok = await _sender.send(topic: _topic, text: text, domain: domain);
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    if (ok) {
      await windowManager.hide(); // 发完即隐，零摩擦（仍常驻菜单栏 tray，非退出）
      setState(() => _flash = null);
    } else {
      setState(() => _flash = '发送失败，检查网络/topic');
    }
  }

  // ── UI ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_recordingMode) {
            _cancelRecording();
          } else {
            windowManager.hide();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.paper,
          body: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: _settingsMode ? _settingsView() : _captureView(),
          ),
        ),
      ),
    );
  }

  Widget _flashLine() => _flash == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(_flash!,
              style: const TextStyle(fontSize: 11.5, color: AppColors.q1)),
        );

  Widget _captureView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('捕获', style: AppText.title(20)),
            const Spacer(),
            IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined, size: 18),
              color: AppColors.ink40,
              onPressed: _showSettings,
            ),
            IconButton(
              tooltip: '隐藏（Esc）',
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.ink40,
              onPressed: () => windowManager.hide(),
            ),
          ],
        ),
        if (_topic.isEmpty)
          GestureDetector(
            onTap: _showSettings,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.q1.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('⚠ 未设置同步 topic，点此前往设置',
                  style: TextStyle(fontSize: 12, color: AppColors.q1)),
            ),
          ),
        _flashLine(),
        const SizedBox(height: 6),
        Flexible(
          child: SingleChildScrollView(
            child: CaptureSheet(onCapture: _send),
          ),
        ),
        const SizedBox(height: 4),
        Text('${hotKeyLabel(_hotKey)} 唤起 · Esc 隐藏',
            style: const TextStyle(fontSize: 10.5, color: AppColors.ink40)),
      ],
    );
  }

  Widget _settingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('设置', style: AppText.title(20)),
            const Spacer(),
            TextButton.icon(
              onPressed: _showCapture,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('返回捕获'),
            ),
          ],
        ),
        _flashLine(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _sectionTitle('同步 topic'),
                const SizedBox(height: 6),
                Row(children: [
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
                ]),
                const SizedBox(height: 22),
                _sectionTitle('全局快捷键'),
                const SizedBox(height: 8),
                _hotKeySection(),
              ],
            ),
          ),
        ),
        Text('菜单栏图标常驻 · ⊕ 右键有菜单',
            style: const TextStyle(fontSize: 10.5, color: AppColors.ink40)),
      ],
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink40));

  Widget _hotKeySection() {
    if (_recordingMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pop, width: 1.4),
            ),
            child: Column(
              children: [
                const Text('按下新的组合键…（建议含 ⌘/⌥/⌃ 修饰键）',
                    style: TextStyle(fontSize: 12.5, color: AppColors.ink60)),
                const SizedBox(height: 12),
                // recorder 会捕获任意按键 → 仅录制态挂载
                HotKeyRecorder(
                  initalHotKey: _recording,
                  onHotKeyRecorded: (hk) => setState(() => _recording = hk),
                ),
                const SizedBox(height: 6),
                if (_recording != null)
                  Text(hotKeyLabel(_recording!),
                      style: AppText.title(18)),
                if (_recording != null && !_recordValid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('⚠ 需至少一个修饰键，否则会和普通打字冲突',
                        style: TextStyle(fontSize: 11.5, color: AppColors.q1)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            FilledButton(
              onPressed: _recordValid ? _saveHotKey : null,
              child: const Text('保存'),
            ),
            const SizedBox(width: 10),
            TextButton(onPressed: _cancelRecording, child: const Text('取消')),
          ]),
        ],
      );
    }
    // 非录制态：展示当前键 + 更改 + 测试 + 检测结果
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ink20),
            ),
            child: Text(hotKeyLabel(_hotKey),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: _startRecording, child: const Text('更改')),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          OutlinedButton.icon(
            onPressed: _testing ? null : _startTest,
            icon: const Icon(Icons.bolt, size: 16),
            label: Text(_testing ? '按下试试…' : '测试'),
          ),
          const SizedBox(width: 12),
          if (_testing && !_justTriggered)
            const Text('现在按下你的快捷键',
                style: TextStyle(fontSize: 12, color: AppColors.ink60)),
          if (_justTriggered)
            const Text('✓ 全局快捷键有效',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.leaf)),
        ]),
        const SizedBox(height: 8),
        const Text('提示：若测试无反应，去 系统设置 → 隐私与安全性 → 辅助功能，给本 App 授权后重开。',
            style: TextStyle(fontSize: 11, color: AppColors.ink40)),
      ],
    );
  }
}
