import 'package:flutter/material.dart';

import '../../db/models.dart';
import '../../db/workout_template_dao.dart';
import '../../widgets/empty_state.dart';
import 'interval_builder_screen.dart';

/// Lists saved interval workout templates so the user can pick one to run,
/// or create a new one via [IntervalBuilderScreen].
class IntervalTemplatePickerScreen extends StatefulWidget {
  const IntervalTemplatePickerScreen({super.key});

  @override
  State<IntervalTemplatePickerScreen> createState() => _IntervalTemplatePickerScreenState();
}

class _IntervalTemplatePickerScreenState extends State<IntervalTemplatePickerScreen> {
  final _dao = WorkoutTemplateDao();
  List<WorkoutTemplate> _templates = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final templates = await _dao.getAll();
    if (mounted) {
      setState(() {
        _templates = templates;
        _loading = false;
      });
    }
  }

  Future<void> _createNew() async {
    final template = await Navigator.of(context).push<WorkoutTemplate>(
      MaterialPageRoute(builder: (_) => const IntervalBuilderScreen()),
    );
    if (template == null || !mounted) return;
    Navigator.of(context).pop(template);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài tập Interval'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _createNew)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const EmptyState(
                        icon: Icons.repeat,
                        title: 'Chưa có bài tập nào',
                        subtitle: 'Tạo bài tập interval đầu tiên của bạn.',
                      ),
                      ElevatedButton(onPressed: _createNew, child: const Text('Tạo mới')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _templates.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final t = _templates[i];
                    return Card(
                      child: ListTile(
                        title: Text(t.name),
                        trailing: const Icon(Icons.play_arrow),
                        onTap: () => Navigator.of(context).pop(t),
                      ),
                    );
                  },
                ),
    );
  }
}
