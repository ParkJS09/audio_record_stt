import 'dart:io';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models/audio_result.dart';

class AudioRecorderWrapper {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  // 권한 체크
  Future<bool> _checkPermissions() async {
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return micPermission.isGranted;
  }

  // 앱 문서 디렉토리 가져오기
  Future<Directory> getDocumentsDirectory() async {
    try {
      return await path_provider.getApplicationDocumentsDirectory();
    } catch (e) {
      throw Exception('앱 문서 디렉토리를 가져올 수 없습니다: $e');
    }
  }

  // 임시 디렉토리 가져오기
  Future<Directory> getTempDirectory() async {
    try {
      return await path_provider.getTemporaryDirectory();
    } catch (e) {
      throw Exception('임시 디렉토리를 가져올 수 없습니다: $e');
    }
  }

  // 기본 저장 경로 생성
  Future<String> _getDefaultPath() async {
    try {
      // 1순위: 앱 문서 디렉토리
      final directory = await getDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'audio_$timestamp.m4a';
      return '${directory.path}/$fileName';
    } catch (e) {
      try {
        // 2순위: 임시 디렉토리 (fallback)
        final tempDir = await getTempDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        return '${tempDir.path}/audio_$timestamp.m4a';
      } catch (e2) {
        throw Exception('저장 경로를 생성할 수 없습니다: $e2');
      }
    }
  }

  // 사용자 정의 경로 생성 도우미
  Future<String> createCustomPath({
    required String fileName,
    bool useDocumentsDirectory = true,
  }) async {
    try {
      final directory = useDocumentsDirectory
          ? await getDocumentsDirectory()
          : await getTempDirectory();

      // 파일명에 확장자가 없으면 기본 확장자 추가
      final finalFileName = fileName.contains('.') ? fileName : '$fileName.m4a';

      return '${directory.path}/$finalFileName';
    } catch (e) {
      throw Exception('사용자 정의 경로 생성 실패: $e');
    }
  }

  // 녹음 시작
  Future<AudioResult> startRecording({String? path}) async {
    try {
      if (!await _checkPermissions()) {
        return AudioResult.error('마이크 권한이 필요합니다');
      }

      _currentRecordingPath = path ?? await _getDefaultPath();
      _recordingStartTime = DateTime.now();

      await _recorder.start(const RecordConfig(), path: _currentRecordingPath!);

      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('녹음 시작 실패: $e');
    }
  }

  // 녹음 정지
  Future<AudioResult> stopRecording() async {
    try {
      final path = await _recorder.stop();
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : null;

      _recordingStartTime = null;

      return AudioResult.success(filePath: path, duration: duration);
    } catch (e) {
      return AudioResult.error('녹음 정지 실패: $e');
    }
  }

  // 녹음 일시정지
  Future<AudioResult> pauseRecording() async {
    try {
      await _recorder.pause();
      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('녹음 일시정지 실패: $e');
    }
  }

  // 녹음 재개
  Future<AudioResult> resumeRecording() async {
    try {
      await _recorder.resume();
      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('녹음 재개 실패: $e');
    }
  }

  // 녹음 취소
  Future<AudioResult> cancelRecording() async {
    try {
      await _recorder.cancel();
      _recordingStartTime = null;
      _currentRecordingPath = null;
      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('녹음 취소 실패: $e');
    }
  }

  // 상태 확인
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }

  // 볼륨 레벨 스트림 (파형 그리기용)
  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _recorder.onAmplitudeChanged(interval);
  }

  // 현재 볼륨 레벨
  Future<Amplitude> getAmplitude() async {
    return await _recorder.getAmplitude();
  }

  // 리소스 해제
  void dispose() {
    _recorder.dispose();
  }
}
