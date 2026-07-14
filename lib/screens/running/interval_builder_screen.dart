import 'dart:convert';

import 'package:flutter/material.dart';

import '../../db/models.dart';
import '../../db/workout_template_dao.dart';

/// Form to build a new interval workout template: an ordered list of
/// segments (fast/recover, by distance or duration, optional target pace),
/// saved for reuse across future runs.
class IntervalBuilderScreen extends StatefulWidget {
  const IntervalBuilderScreen({super.key});

  @override
  State<IntervalBuilderScreen> createState() => _IntervalBuilderScreenState();
}

class _IntervalBuilderScreenState extends State<IntervalBuilderScreen> {
  final _nameController = TextEditingController();
  final _segments = <IntervalSegment>[
    const IntervalSegment(type: 'fast', mode: 'distance', value: 400),
    const IntervalSegment(type: 'recover', mode: 'distance', value: 200),
  ];
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addSegment() {
    setState(() => _segments.add(const IntervalSegment(type: 'fast', mode: 'distance', value: 400)));
  }

  void _removeSegment(int index) {
    setState(() => _segments.removeAt(index));
  }

  void _updateSegment(int index, IntervalSegment segment) {
    setState(() => _segments[index] = segment);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _segments.isEmpty) return;
    setState(() => _saving = true);

    final template = WorkoutTemplate(
      name: _nameController.text.trim(),
      configJson: jsonEncode(_segments.map((s) => s.toJson()).toList()),
      createdAt: DateTime.now().toIso8601String(),
    );
    final id = await WorkoutTemplateDao().insert(template);

    if (!mounted) return;
    Navigator.of(context).pop(WorkoutTemplate.fromMap({...template.toMap(), 'id': id}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bài tập Interval')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Tên bài tập',
              hintText: 'VD: 5 hiệp 400m nhanh + 200m đi bộ',
            ),
          ),
          const SizedBox(height: 20),
          Text('Các hiệp', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (var i = 0; i < _segments.length; i++)
            _SegmentEditor(
              index: i,
              segment: _segments[i],
              onChanged: (s) => _updateSegment(i, s),
              onRemove: _segments.length > 1 ? () => _removeSegment(i) : null,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addSegment,
            icon: const Icon(Icons.add),
            label: const Text('Thêm hiệp'),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Lưu bài tập'),
          ),
        ],
      ),
    );
  }
}

class _SegmentEditor extends StatelessWidget {
  final int index;
  final IntervalSegment segment;
  final ValueChanged<IntervalSegment> onChanged;
  final VoidCallback? onRemove;

  const _SegmentEditor({
    required this.index,
    required this.segment,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDistance = segment.mode == 'distance';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Hiệp ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                if (onRemove != null)
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: onRemove),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'fast', label: Text('Chạy nhanh')),
                      ButtonSegment(value: 'recover', label: Text('Hồi phục')),
                    ],
                    selected: {segment.type},
                    onSelectionChanged: (s) => onChanged(IntervalSegment(
                      type: s.first,
                      mode: segment.mode,
                      value: segment.value,
                      targetPaceSecPerKm: segment.targetPaceSecPerKm,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'distance', label: Text('Theo khoảng cách')),
                      ButtonSegment(value: 'duration', label: Text('Theo thời gian')),
                    ],
                    selected: {segment.mode},
                    onSelectionChanged: (s) => onChanged(IntervalSegment(
                      type: segment.type,
                      mode: s.first,
                      value: s.first == 'distance' ? 400 : 60,
                      targetPaceSecPerKm: segment.targetPaceSecPerKm,
                    )),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(isDistance ? 'Khoảng cách (m):' : 'Thời gian (giây):'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    value: segment.value.clamp(isDistance ? 50 : 10, isDistance ? 2000 : 600),
                    min: isDistance ? 50 : 10,
                    max: isDistance ? 2000 : 600,
                    divisions: isDistance ? 39 : 59,
                    label: segment.value.toStringAsFixed(0),
                    onChanged: (v) => onChanged(IntervalSegment(
                      type: segment.type,
                      mode: segment.mode,
                      value: v,
                      targetPaceSecPerKm: segment.targetPaceSecPerKm,
                    )),
                  ),
                ),
                SizedBox(width: 48, child: Text(segment.value.toStringAsFixed(0))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
