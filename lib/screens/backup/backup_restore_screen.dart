import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/backup_service.dart';
import '../../services/demo_seed_service.dart';
import '../splash_screen.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final _service = BackupService();
  bool _busy = false;
  String? _lastExportPath;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final file = await _service.exportToFile();
      await _service.shareBackup();
      if (mounted) setState(() => _lastExportPath = file.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _seedDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo dữ liệu demo?'),
        content: const Text(
          'Sẽ tạo tài khoản "demo" (mật khẩu "demo123") với ~10 tuần lịch sử chạy bộ, '
          'mục tiêu, huy hiệu, giáo án, streak... và chuyển phiên hiện tại sang tài khoản này. '
          'Chạy lại sẽ xoá và tạo mới toàn bộ dữ liệu demo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tạo')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await DemoSeedService().seedDemoAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khôi phục dữ liệu?'),
        content: const Text(
          'Toàn bộ dữ liệu hiện tại (hoạt động, mục tiêu, huy hiệu...) sẽ bị thay thế bằng dữ liệu trong file này.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Khôi phục')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await _service.restoreFromFile(File(path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã khôi phục dữ liệu. Khởi động lại ứng dụng để áp dụng.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sao lưu & Khôi phục')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sao lưu toàn bộ dữ liệu (hoạt động, mục tiêu, huy hiệu, lộ trình...) ra một file JSON, '
              'hoặc khôi phục từ file đã sao lưu trước đó.',
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Xuất dữ liệu (Export)'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            ),
            if (_lastExportPath != null) ...[
              const SizedBox(height: 8),
              Text(
                'Đã lưu: $_lastExportPath',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Khôi phục dữ liệu (Import)'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (kDebugMode) ...[
              const Divider(height: 40),
              Text('Công cụ debug', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _seedDemoData,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Tạo dữ liệu demo (~10 tuần)'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập bằng demo / demo123 sau khi tạo. Chỉ hiển thị ở bản debug.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
