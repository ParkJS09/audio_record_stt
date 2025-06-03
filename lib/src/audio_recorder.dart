import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'models/audio_result.dart';

class AudioRecorderWrapper {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  Future<bool> _checkPermission() async {
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return micPermission.isGranted;
  }

  Future<AudioResult> startRecording({String? path}) async {
    try {
      if (!await _checkPermission()) {
        return AudioResult.error('녹음 권한을 확인해주세요.');
      }
      _currentRecordingPath = path ?? await _getDefaultPath();
      _recordingStartTime = DateTime.now();

      await _recorder.start(
        RecordConfig(sampleRate: 16000, bitRate: 128000),
        path: _currentRecordingPath!,
      );
      return AudioResult.success(filePath: _currentRecordingPath!);
    } catch (e) {
      return AudioResult.error('녹음 시작 에러 : $e');
    }
  }

  Future<AudioResult> stopRecording() async {
    try {
      // stop을 호출 시 String으로 Path를 반환하기에 await 사용
      final path = await _recorder.stop();
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : null;

      return AudioResult.success(filePath: path, duration: duration);
    } catch (e) {
      return AudioResult.error('녹음 중단 에러 : $e');
    }
  }

  Future<String> _getDefaultPath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.m4a';
      return '${directory.path}/$fileName';
    } catch (e) {
      // fallback: 임시 디렉토리 사용
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '${tempDir.path}/audio_$timestamp.m4a';
    }
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  void dispose() {
    _recorder.dispose();
  }
}
