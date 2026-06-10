import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../inbox/inbox_screen.dart';
import '../settings/settings_screen.dart';
import '../todo/todo_screen.dart';
import 'placeholder_screens.dart';

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
        title: Text(_titles[_index],
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800)),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.inbox_outlined),
              selectedIcon: Icon(Icons.inbox),
              label: '收件箱'),
          NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: '待办'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: '复盘'),
        ],
      ),
    );
  }
}
