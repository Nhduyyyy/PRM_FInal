import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Records a short voice memo after a run (via `record`) and plays it back
/// (via `audioplayers`, since `record` only records). Stores files under the
/// app's documents directory so they survive between sessions.
class VoiceMemoService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Starts recording to a new file, returning its path, or null if the
  /// microphone permission was denied.
  Future<String?> startRecording() async {
    if (!await hasPermission()) return null;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: path);
    return path;
  }

  Future<String?> stopRecording() => _recorder.stop();

  Future<void> play(String path) => _player.play(DeviceFileSource(path));

  Future<void> stopPlayback() => _player.stop();

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}
