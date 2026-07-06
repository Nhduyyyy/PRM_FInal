import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../db/models.dart';
import '../../state/badges_provider.dart';
import '../../state/goals_provider.dart';
import '../../state/history_provider.dart';
import '../../state/home_provider.dart';
import '../../state/profile_provider.dart';
import '../../state/run_session_provider.dart';
import '../../state/stats_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/badge_icons.dart';
import '../../widgets/route_map_view.dart';
import '../home/home_shell.dart';

const _moods = ['😞', '😐', '🙂', '😄', '🤩'];

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key});

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  final _noteController = TextEditingController();
  final _tagController = TextEditingController();
  String? _mood;
  String? _photoPath;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600);
      if (picked != null) setState(() => _photoPath = picked.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Không thể mở camera trên thiết bị này.'
                : 'Không thể mở thư viện ảnh.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final session = context.read<RunSessionProvider>();
    final weightKg = context.read<ProfileProvider>().profile?.weightKg ?? 60;

    final result = await session.saveActivity(
      weightKg: weightKg,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      mood: _mood,
      photoPath: _photoPath,
      locationTag: _tagController.text.trim().isEmpty ? null : _tagController.text.trim(),
    );

    if (!mounted) return;
    final profileProvider = context.read<ProfileProvider>();
    final homeProvider = context.read<HomeProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final statsProvider = context.read<StatsProvider>();
    final goalsProvider = context.read<GoalsProvider>();
    final badgesProvider = context.read<BadgesProvider>();

    await profileProvider.refreshStreak();
    await homeProvider.load();
    historyProvider.load();
    statsProvider.load();
    goalsProvider.load();
    badgesProvider.load();

    if (result.newBadges.isNotEmpty && mounted) {
      await _showBadgeUnlockDialog(result.newBadges);
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
      (route) => false,
    );
  }

  Future<void> _showBadgeUnlockDialog(List<RunBadge> badges) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 Mở khoá huy hiệu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final b in badges)
              ListTile(
                leading: Icon(badgeIconFor(b.icon), color: Theme.of(ctx).colorScheme.primary),
                title: Text(b.name),
                subtitle: Text(b.description),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tuyệt vời!')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RunSessionProvider>();
    final weightKg = context.watch<ProfileProvider>().profile?.weightKg ?? 60;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoàn thành!'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Center(child: Icon(Icons.emoji_events, size: 48, color: Colors.amber)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RouteMapView(points: session.points),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _StatBox(label: 'Quãng đường', value: Formatters.distanceKm(session.distanceKm)),
              _StatBox(label: 'Thời gian', value: Formatters.duration(session.elapsed.inSeconds)),
              _StatBox(label: 'Pace TB', value: Formatters.pace(session.avgPaceSecPerKm)),
              _StatBox(label: 'Calo', value: '${session.estimatedCalories(weightKg)} kcal'),
            ],
          ),
          const SizedBox(height: 24),
          Text('Cảm nhận của bạn thế nào?', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final mood in _moods)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _mood = mood),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _mood == mood ? scheme.primaryContainer : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(mood, style: const TextStyle(fontSize: 26)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Ghi chú', hintText: 'Cảm nhận của bạn...'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _tagController,
            decoration: const InputDecoration(labelText: 'Địa điểm / thời tiết (tuỳ chọn)'),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Thêm ảnh'),
          ),
          if (_photoPath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(File(_photoPath!), height: 140, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
