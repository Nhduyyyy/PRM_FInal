import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/models.dart';
import '../../db/training_plan_dao.dart';
import '../../state/training_plan_provider.dart';

class TrainingPlanDetailScreen extends StatefulWidget {
  final int planId;
  const TrainingPlanDetailScreen({super.key, required this.planId});

  @override
  State<TrainingPlanDetailScreen> createState() => _TrainingPlanDetailScreenState();
}

class _TrainingPlanDetailScreenState extends State<TrainingPlanDetailScreen> {
  final _dao = TrainingPlanDao();
  TrainingPlan? _plan;
  List<TrainingPlanDay> _days = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plan = await _dao.getPlanById(widget.planId);
    final days = await _dao.getPlanDays(widget.planId);
    if (mounted) {
      setState(() {
        _plan = plan;
        _days = days;
        _loading = false;
      });
    }
  }

  static String _dayTypeLabel(String type) => switch (type) {
        'rest' => 'Nghỉ',
        'easy_run' => 'Chạy nhẹ',
        'interval' => 'Interval',
        'long_run' => 'Chạy dài',
        _ => type,
      };

  static IconData _dayTypeIcon(String type) => switch (type) {
        'rest' => Icons.hotel,
        'easy_run' => Icons.directions_run,
        'interval' => Icons.repeat,
        'long_run' => Icons.timeline,
        _ => Icons.circle,
      };

  Future<void> _startPlan(BuildContext context) async {
    final provider = context.read<TrainingPlanProvider>();
    if (provider.hasActivePlan && provider.plan?.id != widget.planId) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đổi lộ trình?'),
          content: Text('Bạn đang theo lộ trình "${provider.plan?.name}". Bắt đầu lộ trình mới sẽ thay thế nó.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đổi')),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await provider.startPlan(widget.planId);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    if (_loading || plan == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final planProvider = context.watch<TrainingPlanProvider>();
    final isActive = planProvider.hasActivePlan && planProvider.plan?.id == widget.planId;
    final weeks = _days.map((d) => d.weekNumber).toSet().toList()..sort();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (plan.description != null) ...[
            Text(plan.description!, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
          ],
          ElevatedButton(
            onPressed: isActive ? () => planProvider.stopPlan() : () => _startPlan(context),
            style: isActive ? ElevatedButton.styleFrom(backgroundColor: scheme.errorContainer) : null,
            child: Text(isActive ? 'Dừng lộ trình này' : 'Bắt đầu lộ trình này'),
          ),
          const SizedBox(height: 20),
          for (final week in weeks) ...[
            Text('Tuần $week', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final day in _days.where((d) => d.weekNumber == week))
              _DayTile(
                day: day,
                completed: planProvider.isCompleted(day),
              ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final TrainingPlanDay day;
  final bool completed;
  const _DayTile({required this.day, required this.completed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : _TrainingPlanDetailScreenState._dayTypeIcon(day.dayType),
            color: completed ? Colors.green : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_TrainingPlanDetailScreenState._dayTypeLabel(day.dayType)} — Ngày ${day.dayNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (day.description != null)
                  Text(day.description!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
