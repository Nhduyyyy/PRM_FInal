import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/history_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../activity_detail/activity_detail_screen.dart';
import '../compare/compare_runs_screen.dart';
import '../heatmap/all_routes_heatmap_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<HistoryProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Bản đồ tổng hợp',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllRoutesHeatmapScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'So sánh buổi chạy',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CompareRunsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: history.filter == HistoryFilter.all,
                  onTap: () => history.setFilter(HistoryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tuần này',
                  selected: history.filter == HistoryFilter.thisWeek,
                  onTap: () => history.setFilter(HistoryFilter.thisWeek),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Tháng này',
                  selected: history.filter == HistoryFilter.thisMonth,
                  onTap: () => history.setFilter(HistoryFilter.thisMonth),
                ),
              ],
            ),
          ),
          Expanded(
            child: history.loading
                ? const Center(child: CircularProgressIndicator())
                : history.activities.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.history,
                          title: 'Không có hoạt động nào',
                          subtitle: 'Thử chọn bộ lọc khác hoặc bắt đầu buổi chạy mới.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: history.activities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final activity = history.activities[i];
                          return ActivityCard(
                            activity: activity,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailScreen(activityId: activity.id!),
                              ),
                            ),
                            onDelete: () => history.deleteActivity(activity.id!),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
