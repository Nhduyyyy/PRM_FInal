import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_type.dart';
import '../../services/home_widget_service.dart';
import '../../state/home_provider.dart';
import '../../state/pedometer_provider.dart';
import '../../state/profile_provider.dart';
import '../../state/training_plan_provider.dart';
import '../../state/user_level_provider.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_card.dart';
import '../activity_detail/activity_detail_screen.dart';
import '../level/level_xp_screen.dart';
import '../running/running_screen.dart';
import '../running/select_activity_type_screen.dart';
import '../training_plan/training_plan_detail_screen.dart';
import '../training_plan/training_plan_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      context.read<PedometerProvider>().start();
    });
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<HomeProvider>().load(),
      context.read<TrainingPlanProvider>().load(),
      context.read<UserLevelProvider>().load(),
    ]);
    unawaited(HomeWidgetService.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();
    final profile = context.watch<ProfileProvider>();
    final trainingPlan = context.watch<TrainingPlanProvider>();
    final userLevel = context.watch<UserLevelProvider>();
    final pedometer = context.watch<PedometerProvider>();
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
                  _XpBar(userLevel: userLevel),
                  const SizedBox(height: 14),
                  if (pedometer.available) ...[
                    _PedometerCard(steps: pedometer.stepsToday),
                    const SizedBox(height: 14),
                  ],
                  _TodayPlanCard(trainingPlan: trainingPlan, onReload: _load),
                  const SizedBox(height: 14),
                  if (home.weeklyChallenge != null) ...[
                    _WeeklyChallengeCard(home: home),
                    const SizedBox(height: 14),
                  ],
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
                            MaterialPageRoute(builder: (_) => const SelectActivityTypeScreen()),
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

class _XpBar extends StatelessWidget {
  final UserLevelProvider userLevel;
  const _XpBar({required this.userLevel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final info = userLevel.info;

    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LevelXpScreen()),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: scheme.primaryContainer,
            child: Text('${info.level}', style: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: info.progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PedometerCard extends StatelessWidget {
  final int steps;
  const _PedometerCard({required this.steps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Row(
        children: [
          Icon(Icons.directions_walk, color: scheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$steps bước', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                Text('Bước chân hôm nay', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final TrainingPlanProvider trainingPlan;
  final Future<void> Function() onReload;
  const _TodayPlanCard({required this.trainingPlan, required this.onReload});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = trainingPlan.todayPlan;

    if (!trainingPlan.hasActivePlan) {
      return SectionCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TrainingPlanListScreen()),
        ),
        child: Row(
          children: [
            Icon(Icons.route, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            const Expanded(child: Text('Khám phá lộ trình luyện tập')),
            const Icon(Icons.chevron_right),
          ],
        ),
      );
    }

    if (today == null) {
      return SectionCard(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TrainingPlanDetailScreen(planId: trainingPlan.plan!.id!)),
        ),
        child: Row(
          children: [
            Icon(Icons.route, color: scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            const Expanded(child: Text('Bạn đã hoàn thành lộ trình luyện tập!')),
          ],
        ),
      );
    }

    final isRest = today.dayType == 'rest';
    final label = switch (today.dayType) {
      'rest' => 'Hôm nay: Nghỉ ngơi',
      'easy_run' => 'Hôm nay: Chạy nhẹ ${today.targetDistanceKm?.toStringAsFixed(1)}km',
      'interval' => 'Hôm nay: Interval',
      'long_run' => 'Hôm nay: Chạy dài ${today.targetDistanceKm?.toStringAsFixed(1)}km',
      _ => 'Hôm nay',
    };

    return SectionCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TrainingPlanDetailScreen(planId: trainingPlan.plan!.id!)),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (today.description != null)
                  Text(today.description!, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          if (!isRest)
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(64, 40)),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => RunningScreen(activityType: ActivityType.run, planDayId: today.id),
                  ),
                );
                await onReload();
              },
              child: const Text('Bắt đầu'),
            ),
        ],
      ),
    );
  }
}

class _WeeklyChallengeCard extends StatelessWidget {
  final HomeProvider home;
  const _WeeklyChallengeCard({required this.home});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final challenge = home.weeklyChallenge!;
    final progress = (home.weeklyChallengeProgressKm / challenge.targetKm).clamp(0.0, 1.0);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: Colors.amber),
              const SizedBox(width: 8),
              const Text('Thử thách tuần này', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${home.weeklyChallengeProgressKm.toStringAsFixed(1)}/${challenge.targetKm.toStringAsFixed(1)} km',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
