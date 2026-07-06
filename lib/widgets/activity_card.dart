import 'dart:io';

import 'package:flutter/material.dart';

import '../db/models.dart';
import '../utils/formatters.dart';
import 'section_card.dart';

class ActivityCard extends StatelessWidget {
  final RunActivity activity;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ActivityCard({super.key, required this.activity, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          if (activity.photoPath != null && File(activity.photoPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(activity.photoPath!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.directions_run, color: scheme.onPrimaryContainer),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dateFriendly(activity.date),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _Badge(text: Formatters.distanceKm(activity.distanceKm)),
                    _Badge(text: Formatters.duration(activity.durationSeconds)),
                    _Badge(text: Formatters.pace(activity.avgPaceSecPerKm)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onDelete == null) return card;
    return Dismissible(
      key: ValueKey(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Xoá hoạt động?'),
                content: const Text('Bạn có chắc muốn xoá buổi chạy này không?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete!.call(),
      child: card,
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
