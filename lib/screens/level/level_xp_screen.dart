import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/user_level_provider.dart';

class LevelXpScreen extends StatelessWidget {
  const LevelXpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserLevelProvider>();
    final scheme = Theme.of(context).colorScheme;

    if (provider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final info = provider.info;

    return Scaffold(
      appBar: AppBar(title: const Text('Cấp độ & XP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 56,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                '${info.level}',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: 16),
            Text(info.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: info.progress,
                minHeight: 14,
                backgroundColor: scheme.surfaceContainerHighest,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${info.xpIntoLevel.toStringAsFixed(0)}/${info.xpForNextLevel.toStringAsFixed(0)} XP đến Level ${info.level + 1}',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Text(
              'Tổng XP: ${provider.userLevel.totalXp.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Text(
              'Kiếm XP bằng cách chạy (10 XP/km), thưởng thêm 20% khi hoàn thành đúng ngày theo lộ trình luyện tập.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
