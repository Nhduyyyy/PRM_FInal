import 'package:flutter/material.dart';

import '../../db/activity_dao.dart';
import '../../db/models.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class _Metric {
  final String label;
  final String valueA;
  final String valueB;
  final double rawA;
  final double rawB;
  final bool? higherIsBetter; // null = no highlight (context-dependent metric)

  const _Metric(this.label, this.valueA, this.valueB, this.rawA, this.rawB, this.higherIsBetter);
}

/// Lets the user pick two activities and see their key stats side by side,
/// with the better value highlighted for metrics where "better" is unambiguous.
class CompareRunsScreen extends StatefulWidget {
  const CompareRunsScreen({super.key});

  @override
  State<CompareRunsScreen> createState() => _CompareRunsScreenState();
}

class _CompareRunsScreenState extends State<CompareRunsScreen> {
  List<RunActivity> _all = const [];
  RunActivity? _a;
  RunActivity? _b;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await ActivityDao().getAll();
    if (mounted) {
      setState(() {
        _all = all;
        _loading = false;
      });
    }
  }

  Future<void> _pick(bool isA) async {
    final selected = await showModalBottomSheet<RunActivity>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final activity in _all)
              ListTile(
                title: Text(Formatters.dateFriendly(activity.date)),
                subtitle: Text(
                  '${Formatters.distanceKm(activity.distanceKm)} • ${Formatters.duration(activity.durationSeconds)}',
                ),
                onTap: () => Navigator.pop(ctx, activity),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => isA ? _a = selected : _b = selected);
    }
  }

  List<_Metric> _metrics(RunActivity a, RunActivity b) => [
        _Metric('Quãng đường', Formatters.distanceKm(a.distanceKm), Formatters.distanceKm(b.distanceKm),
            a.distanceKm, b.distanceKm, true),
        _Metric('Thời gian', Formatters.duration(a.durationSeconds), Formatters.duration(b.durationSeconds),
            a.durationSeconds.toDouble(), b.durationSeconds.toDouble(), null),
        _Metric('Pace trung bình', Formatters.pace(a.avgPaceSecPerKm), Formatters.pace(b.avgPaceSecPerKm),
            a.avgPaceSecPerKm.toDouble(), b.avgPaceSecPerKm.toDouble(), false),
        _Metric('Pace tốt nhất', Formatters.pace(a.bestPaceSecPerKm), Formatters.pace(b.bestPaceSecPerKm),
            a.bestPaceSecPerKm.toDouble(), b.bestPaceSecPerKm.toDouble(), false),
        _Metric('Calo', '${a.calories} kcal', '${b.calories} kcal', a.calories.toDouble(), b.calories.toDouble(),
            null),
      ];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_all.length < 2) {
      return const Scaffold(
        body: Center(
          child: EmptyState(
            icon: Icons.compare_arrows,
            title: 'Cần ít nhất 2 buổi chạy',
            subtitle: 'Hoàn thành thêm buổi chạy để so sánh.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('So sánh buổi chạy')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _PickerButton(activity: _a, onTap: () => _pick(true))),
                const SizedBox(width: 12),
                Expanded(child: _PickerButton(activity: _b, onTap: () => _pick(false))),
              ],
            ),
            const SizedBox(height: 24),
            if (_a != null && _b != null)
              Expanded(
                child: ListView(
                  children: [
                    for (final metric in _metrics(_a!, _b!)) _CompareRow(metric: metric),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  final RunActivity? activity;
  final VoidCallback onTap;
  const _PickerButton({required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
      child: activity == null
          ? const Text('Chọn buổi chạy')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(Formatters.dateFriendly(activity!.date), textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(
                  Formatters.distanceKm(activity!.distanceKm),
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final _Metric metric;
  const _CompareRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final aWins = metric.higherIsBetter == null
        ? false
        : metric.higherIsBetter!
            ? metric.rawA > metric.rawB
            : metric.rawA < metric.rawB;
    final bWins = metric.higherIsBetter == null
        ? false
        : metric.higherIsBetter!
            ? metric.rawB > metric.rawA
            : metric.rawB < metric.rawA;

    Widget valueText(String value, bool wins) => Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: wins ? scheme.primary : scheme.onSurface,
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Text(metric.label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              valueText(metric.valueA, aWins),
              valueText(metric.valueB, bWins),
            ],
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }
}
