import 'package:flutter/material.dart';

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('$label · 占位', style: const TextStyle(fontSize: 18)));
}

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('待办');
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});
  @override
  Widget build(BuildContext context) => const _Placeholder('复盘');
}
