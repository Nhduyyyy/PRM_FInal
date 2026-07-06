import 'package:flutter/material.dart';

/// A single large-number stat display, e.g. distance/time/pace readouts on
/// the Running and Run Summary screens.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool big;
  final IconData? icon;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.big = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(height: 4),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: big ? 44 : 22,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
