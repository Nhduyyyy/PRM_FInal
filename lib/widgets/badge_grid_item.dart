import 'package:flutter/material.dart';

import '../state/badges_provider.dart';
import '../utils/formatters.dart';
import 'badge_icons.dart';

class BadgeGridItem extends StatelessWidget {
  final BadgeWithStatus item;
  final VoidCallback? onTap;

  const BadgeGridItem({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlocked = item.unlocked;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: unlocked ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIconFor(item.badge.icon),
              size: 34,
              color: unlocked ? scheme.onPrimaryContainer : scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              item.badge.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: unlocked ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showBadgeDetailSheet(BuildContext context, BadgeWithStatus item) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIconFor(item.badge.icon),
              size: 56,
              color: item.unlocked ? scheme.primary : scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(item.badge.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(item.badge.description, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            if (item.unlocked && item.unlockedAt != null)
              Text(
                'Mở khoá ngày ${Formatters.dateShort(item.unlockedAt!.substring(0, 10))}',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              )
            else
              Text(
                'Chưa mở khoá',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
          ],
        ),
      );
    },
  );
}
