import 'package:flutter/material.dart';

import '../state/badges_provider.dart';
import '../utils/formatters.dart';
import 'badge_icons.dart';

/// Accent color for a badge tier, or null for 'single' (non-tiered) badges
/// which just use the theme's default unlocked color.
Color? tierColor(String tier) => switch (tier) {
      'bronze' => const Color(0xFFCD7F32),
      'silver' => const Color(0xFFA8ADB4),
      'gold' => const Color(0xFFFFC107),
      _ => null,
    };

String tierLabel(String tier) => switch (tier) {
      'bronze' => 'Đồng',
      'silver' => 'Bạc',
      'gold' => 'Vàng',
      _ => '',
    };

class BadgeGridItem extends StatelessWidget {
  final BadgeWithStatus item;
  final VoidCallback? onTap;

  const BadgeGridItem({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final unlocked = item.unlocked;
    final accent = tierColor(item.badge.tier);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: unlocked ? (accent?.withValues(alpha: 0.18) ?? scheme.primaryContainer) : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: unlocked && accent != null ? Border.all(color: accent, width: 1.5) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badgeIconFor(item.badge.icon),
              size: 34,
              color: unlocked
                  ? (accent ?? scheme.onPrimaryContainer)
                  : scheme.onSurfaceVariant.withValues(alpha: 0.4),
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
                color: unlocked ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
            if (accent != null) ...[
              const SizedBox(height: 4),
              Text(
                tierLabel(item.badge.tier),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
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
            if (tierColor(item.badge.tier) != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tier ${tierLabel(item.badge.tier)}',
                style: TextStyle(color: tierColor(item.badge.tier), fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
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
