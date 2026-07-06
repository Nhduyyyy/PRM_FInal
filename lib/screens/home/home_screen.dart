import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/home_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../activity_detail/activity_detail_screen.dart';
import '../running/running_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<HomeProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final profile = context.watch<ProfileProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile.hasProfile ? 'Chào, ${profile.profile!.name}!' : 'Xin chào!',
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: home.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _GoalProgressCard(home: home),
                  const SizedBox(height: 14),
                  _StreakCard(streak: profile.streak.currentStreak),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          backgroundColor: scheme.primary,
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RunningScreen()),
                          );
                          if (context.mounted) _load();
                        },
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.directions_run, size: 48, color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'BẮT ĐẦU\nCHẠY',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('Hoạt động gần nhất', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (home.recentActivities.isEmpty)
                    const EmptyState(
                      icon: Icons.directions_run,
                      title: 'Chưa có hoạt động nào',
                      subtitle: 'Bắt đầu buổi chạy đầu tiên của bạn ngay!',
                    )
                  else
                    Column(
                      children: [
                        for (final activity in home.recentActivities) ...[
                          ActivityCard(
                            activity: activity,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailScreen(activityId: activity.id!),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                ],
              ),
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final HomeProvider home;
  const _GoalProgressCard({required this.home});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = home.activeGoal;

    if (goal == null) {
      return SectionCard(
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            const Expanded(child: Text('Chưa đặt mục tiêu tuần này')),
          ],
        ),
      );
    }

    final progress = home.goalProgress.clamp(0.0, 1.0);
    final achievedKm = home.goalProgress * goal.targetKm;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.type == 'weekly' ? 'Mục tiêu tuần này' : 'Mục tiêu tháng này',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${achievedKm.toStringAsFixed(1)}/${goal.targetKm.toStringAsFixed(0)} km  •  ${(progress * 100).toStringAsFixed(0)}%',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 28),
          const SizedBox(width: 12),
          Text('$streak ngày streak', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}
