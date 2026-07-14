import 'package:flutter/material.dart';

import '../../db/models.dart';
import '../../models/activity_type.dart';
import 'interval_template_picker_screen.dart';
import 'running_screen.dart';

/// Shown before starting a run: pick an activity type, then either start a
/// free run or attach a saved interval workout template.
class SelectActivityTypeScreen extends StatefulWidget {
  const SelectActivityTypeScreen({super.key});

  @override
  State<SelectActivityTypeScreen> createState() => _SelectActivityTypeScreenState();
}

class _SelectActivityTypeScreenState extends State<SelectActivityTypeScreen> {
  ActivityType _selected = ActivityType.run;

  Future<void> _startRun({WorkoutTemplate? template}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RunningScreen(activityType: _selected, template: template),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickInterval() async {
    final template = await Navigator.of(context).push<WorkoutTemplate>(
      MaterialPageRoute(builder: (_) => const IntervalTemplatePickerScreen()),
    );
    if (template == null || !mounted) return;
    await _startRun(template: template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn hoạt động')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Bạn muốn tập gì hôm nay?', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.3,
            children: [
              for (final type in ActivityType.values)
                _ActivityTypeCard(
                  type: type,
                  selected: _selected == type,
                  onTap: () => setState(() => _selected = type),
                ),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            onPressed: () => _startRun(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickInterval,
            icon: const Icon(Icons.repeat),
            label: const Text('Interval Workout'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }
}

class _ActivityTypeCard extends StatelessWidget {
  final ActivityType type;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityTypeCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: selected ? Border.all(color: scheme.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type.icon, size: 40, color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(
              type.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? scheme.primary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
