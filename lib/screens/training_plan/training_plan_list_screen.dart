import 'package:flutter/material.dart';

import '../../db/models.dart';
import '../../db/training_plan_dao.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import 'training_plan_detail_screen.dart';

class TrainingPlanListScreen extends StatefulWidget {
  const TrainingPlanListScreen({super.key});

  @override
  State<TrainingPlanListScreen> createState() => _TrainingPlanListScreenState();
}

class _TrainingPlanListScreenState extends State<TrainingPlanListScreen> {
  final _dao = TrainingPlanDao();
  List<TrainingPlan> _plans = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _dao.getAllPlans();
    if (mounted) {
      setState(() {
        _plans = plans;
        _loading = false;
      });
    }
  }

  static String _levelLabel(String? level) => switch (level) {
        'beginner' => 'Người mới bắt đầu',
        'intermediate' => 'Trung cấp',
        'advanced' => 'Nâng cao',
        _ => '',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lộ trình luyện tập')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _plans.isEmpty
              ? const Center(
                  child: EmptyState(icon: Icons.route, title: 'Chưa có lộ trình nào'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _plans.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final plan = _plans[i];
                    return SectionCard(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => TrainingPlanDetailScreen(planId: plan.id!)),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(plan.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  '${plan.totalWeeks} tuần • ${_levelLabel(plan.level)}',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
