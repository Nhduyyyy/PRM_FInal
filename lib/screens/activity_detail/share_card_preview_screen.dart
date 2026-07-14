import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../db/models.dart';
import '../../widgets/share_card_view.dart';

const _swatches = [Colors.indigo, Colors.teal, Colors.deepOrange, Colors.black87];

class ShareCardPreviewScreen extends StatefulWidget {
  final RunActivity activity;
  final List<RoutePoint> points;

  const ShareCardPreviewScreen({super.key, required this.activity, required this.points});

  @override
  State<ShareCardPreviewScreen> createState() => _ShareCardPreviewScreenState();
}

class _ShareCardPreviewScreenState extends State<ShareCardPreviewScreen> {
  final _controller = ScreenshotController();
  Color _background = _swatches.first;
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final bytes = await _controller.capture(pixelRatio: 3);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      await dir.create(recursive: true);
      final file = File('${dir.path}/run_tracker_share_card.png');
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Buổi chạy của tôi trên Run Tracker 🏃');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chia sẻ')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Screenshot(
                controller: _controller,
                child: ShareCardView(
                  activity: widget.activity,
                  points: widget.points,
                  backgroundColor: _background,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in _swatches)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() => _background = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _background == color ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: _sharing ? null : _share,
              icon: const Icon(Icons.share),
              label: Text(_sharing ? 'Đang tạo ảnh...' : 'Chia sẻ ảnh'),
            ),
          ),
        ],
      ),
    );
  }
}
