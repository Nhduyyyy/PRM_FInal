import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/goals_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<GoalsProvider>().load());
  }

  Future<void> _openGoalForm({String? initialType, double? initialTarget}) async {
    final goals = context.read<GoalsProvider>();
    String type = initialType ?? 'weekly';
    double target = initialTarget ?? 20;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đặt mục tiêu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'weekly', label: Text('Theo tuần')),
                  ButtonSegment(value: 'monthly', label: Text('Theo tháng')),
                ],
                selected: {type},
                onSelectionChanged: (s) => setSheetState(() => type = s.first),
              ),
              const SizedBox(height: 20),
              Text('${target.round()} km', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Slider(
                value: target,
                min: 5,
                max: type == 'weekly' ? 50 : 200,
                divisions: 45,
                onChanged: (v) => setSheetState(() => target = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await goals.createGoal(type: type, targetKm: target);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Lưu mục tiêu'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mục tiêu')),
      body: goals.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (goals.activeGoal == null)
                  const EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'Chưa có mục tiêu nào',
                    subtitle: 'Đặt mục tiêu để theo dõi tiến độ chạy bộ của bạn.',
                  )
                else
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goals.activeGoal!.type == 'weekly' ? 'Mục tiêu tuần này' : 'Mục tiêu tháng này',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: goals.activeProgress.clamp(0.0, 1.0),
                            minHeight: 12,
                            backgroundColor: scheme.surfaceContainerHighest,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${(goals.activeProgress * goals.activeGoal!.targetKm).toStringAsFixed(1)}/'
                          '${goals.activeGoal!.targetKm.toStringAsFixed(0)} km',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        Text(
                          'Còn ${_daysLeft(goals.activeGoal!.endDate)} ngày',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => _openGoalForm(
                    initialType: goals.activeGoal?.type,
                    initialTarget: goals.activeGoal?.targetKm,
                  ),
                  child: Text(goals.activeGoal == null ? 'Đặt mục tiêu mới' : 'Chỉnh sửa mục tiêu'),
                ),
                const SizedBox(height: 24),
                if (goals.pastGoals.isNotEmpty) ...[
                  Text('Lịch sử mục tiêu', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  for (final past in goals.pastGoals) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        past.achieved ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: past.achieved ? Colors.green : scheme.onSurfaceVariant,
                      ),
                      title: Text(
                        '${past.goal.type == 'weekly' ? 'Tuần' : 'Tháng'} ${Formatters.dateShort(past.goal.startDate)}',
                      ),
                      subtitle: Text('${past.achievedKm.toStringAsFixed(1)}/${past.goal.targetKm.toStringAsFixed(0)} km'),
                    ),
                  ],
                ],
              ],
            ),
    );
  }

  int _daysLeft(String endDate) {
    final end = DateTime.parse(endDate);
    final now = DateTime.now();
    final diff = DateTime(end.year, end.month, end.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff < 0 ? 0 : diff;
  }
}
