import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../db/models.dart';
import '../../models/activity_type.dart';
import '../../services/location_service.dart';
import '../../state/profile_provider.dart';
import '../../state/run_session_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/route_map_view.dart';
import '../run_summary/run_summary_screen.dart';

class RunningScreen extends StatefulWidget {
  final ActivityType activityType;
  final WorkoutTemplate? template;
  final int? planDayId;

  const RunningScreen({
    super.key,
    this.activityType = ActivityType.run,
    this.template,
    this.planDayId,
  });

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final session = context.read<RunSessionProvider>();
    final result = await session.start(
      activityType: widget.activityType,
      template: widget.template,
      planDayId: widget.planDayId,
    );
    if (!mounted) return;

    if (result != LocationAccessResult.granted) {
      final message = switch (result) {
        LocationAccessResult.serviceDisabled => 'Vui lòng bật GPS để theo dõi buổi chạy.',
        LocationAccessResult.permissionDenied => 'Ứng dụng cần quyền truy cập vị trí để chạy.',
        LocationAccessResult.permissionDeniedForever =>
          'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật lại trong Cài đặt.',
        _ => 'Không thể truy cập vị trí.',
      };
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không có quyền GPS'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _confirmEndRun(RunSessionProvider session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kết thúc buổi chạy?'),
        content: const Text('Bạn có chắc muốn kết thúc buổi chạy này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kết thúc')),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      session.finish();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RunSummaryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<RunSessionProvider>();
    final weightKg = context.watch<ProfileProvider>().profile?.weightKg ?? 60;
    final scheme = Theme.of(context).colorScheme;
    final isPaused = session.state == RunSessionState.paused;
    final isAutoPaused = session.isAutoPaused;
    final segments = session.segments;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  Positioned.fill(child: RouteMapView(points: session.points)),
                  Positioned(
                    top: 48,
                    left: 16,
                    child: _ActivityTypeChip(type: session.activityType),
                  ),
                  Positioned(
                    top: 48,
                    right: 16,
                    child: _MuteButton(session: session),
                  ),
                  if (session.gpsWeak)
                    const Positioned(
                      top: 96,
                      left: 16,
                      right: 16,
                      child: _WarningBanner(text: 'Tín hiệu GPS yếu'),
                    ),
                  if (isAutoPaused)
                    const Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _WarningBanner(
                        text: 'Tự động tạm dừng — đứng yên',
                        icon: Icons.pause_circle_outline,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (segments != null && segments.isNotEmpty) ...[
                        _IntervalProgress(
                          segments: segments,
                          currentIndex: session.currentSegmentIndex,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        Formatters.distanceKm(session.distanceKm),
                        style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800),
                      ),
                      const Text('quãng đường'),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _MetricColumn(label: 'Thời gian', value: Formatters.duration(session.elapsed.inSeconds)),
                          _MetricColumn(label: 'Pace hiện tại', value: Formatters.pace(session.currentPaceSecPerKm)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('TB: ${Formatters.pace(session.avgPaceSecPerKm)}',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                          Text('${session.estimatedCalories(weightKg)} kcal',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => isPaused ? session.resume() : session.pause(),
                              child: Text(isPaused ? 'Tiếp tục' : 'Tạm dừng'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: scheme.error),
                              onPressed: () => _confirmEndRun(session),
                              child: const Text('Kết thúc'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  const _MetricColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  const _WarningBanner({required this.text, this.icon = Icons.gps_off});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActivityTypeChip extends StatelessWidget {
  final ActivityType type;
  const _ActivityTypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(type.label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  final RunSessionProvider session;
  const _MuteButton({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(
          session.voiceEnabled ? Icons.volume_up : Icons.volume_off,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () => session.setVoiceEnabled(!session.voiceEnabled),
      ),
    );
  }
}

class _IntervalProgress extends StatelessWidget {
  final List<IntervalSegment> segments;
  final int currentIndex;
  const _IntervalProgress({required this.segments, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = currentIndex >= segments.length;
    final label = done
        ? 'Đã hoàn thành ${segments.length}/${segments.length} hiệp'
        : 'Hiệp ${currentIndex + 1}/${segments.length} — '
            '${segments[currentIndex].type == 'fast' ? 'Chạy nhanh' : 'Hồi phục'}';

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: segments.isEmpty ? 0 : currentIndex / segments.length,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
            color: scheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }
}
