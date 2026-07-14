import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/backup_service.dart';

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
          ],
        ),
      ),
    );
  }
}
