import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../inbox/inbox_screen.dart';
import '../review/review_screen.dart';
import '../settings/settings_screen.dart';
import '../todo/todo_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // 默认「待办」

  static const _screens = [InboxScreen(), TodoScreen(), ReviewScreen()];
  static const _titles = ['收件箱', '待办', '复盘'];

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        title: Text(_titles[_index], style: AppText.title(22)),
        actions: [
          IconButton(
            key: const ValueKey('open-settings'),
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.ink60,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: _TabBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// 底部 Tab 栏：纸色卡底 + 顶部细指示条（取自高保真原型，替代 Material 默认胶囊）。
class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (Icons.inbox_outlined, Icons.inbox, '收件箱'),
    (Icons.checklist_outlined, Icons.checklist, '待办'),
    (Icons.insights_outlined, Icons.insights, '复盘'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.ink20)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(child: _tab(i)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int i) {
    final on = index == i;
    final (icon, selIcon, label) = _items[i];
    final color = on ? AppColors.ink : AppColors.ink40;
    return InkWell(
      onTap: () => onTap(i),
      child: Stack(
        children: [
          if (on)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 28,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(3)),
                  ),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(on ? selIcon : icon, size: 23, color: color),
                const SizedBox(height: 3),
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
