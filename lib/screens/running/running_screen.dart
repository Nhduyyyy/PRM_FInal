import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/location_service.dart';
import '../../state/profile_provider.dart';
import '../../state/run_session_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/route_map_view.dart';
import '../run_summary/run_summary_screen.dart';

class RunningScreen extends StatefulWidget {
  const RunningScreen({super.key});

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
    final result = await session.start();
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
                  if (session.gpsWeak)
                    Positioned(
                      top: 48,
                      left: 16,
                      right: 16,
                      child: _WarningBanner(text: 'Tín hiệu GPS yếu'),
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
  const _WarningBanner({required this.text});

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
          const Icon(Icons.gps_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
