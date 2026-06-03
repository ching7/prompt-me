import 'package:flutter/material.dart';
import '../../../domain/fogg/today_aggregator.dart';
import '../../../theme/app_colors.dart';

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({super.key, required this.events});
  final List<TodayEvent> events;

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('日程 · 苹果日历'),
        ...events.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text(e.allDay ? '全天' : _hhmm(e.start),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink60)),
                  ),
                  Container(
                    width: 3,
                    height: 28,
                    color: AppColors.q3,
                    margin: const EdgeInsets.only(right: 12),
                  ),
                  Expanded(
                      child: Text(e.title,
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                ],
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5)),
      );
}
