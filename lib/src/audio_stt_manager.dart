import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'audio_recorder.dart';
import 'stt_service.dart';
import 'models/audio_result.dart';

class AudioSTTManager {
  final AudioRecorderWrapper _audioRecorder = AudioRecorderWrapper();
  final STTService _sttService = STTService();

  bool _isRecording = false;
  bool _isSTTActive = false;

  // 초기화
  Future<AudioResult> initialize() async {
    final sttResult = await _sttService.initialize();
    if (!sttResult.success) {
      return sttResult;
    }
    return AudioResult.success();
  }

  // 권한 체크
  Future<bool> checkPermissions() async {
    return await _sttService.hasPermission();
  }

  // 1. 단순 녹음만
  Future<AudioResult> startRecording({String? path}) async {
    if (_isRecording) {
      return AudioResult.error('이미 녹음 중입니다');
    }

    final result = await _audioRecorder.startRecording(path: path);
    if (result.success) {
      _isRecording = true;
    }
    return result;
  }

  Future<AudioResult> stopRecording() async {
    if (!_isRecording) {
      return AudioResult.error('녹음 중이 아닙니다');
    }

    final result = await _audioRecorder.stopRecording();
    _isRecording = false;
    return result;
  }

  Future<AudioResult> pauseRecording() async {
    if (!_isRecording) {
      return AudioResult.error('녹음 중이 아닙니다');
    }
    return await _audioRecorder.pauseRecording();
  }

  Future<AudioResult> resumeRecording() async {
    if (!_isRecording) {
      return AudioResult.error('녹음 중이 아닙니다');
    }
    return await _audioRecorder.resumeRecording();
  }

  Future<AudioResult> cancelRecording() async {
    if (!_isRecording) {
      return AudioResult.error('녹음 중이 아닙니다');
    }

    final result = await _audioRecorder.cancelRecording();
    _isRecording = false;
    return result;
  }

  // 2. 실시간 STT만
  Future<AudioResult> startSTT({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    if (_isSTTActive) {
      return AudioResult.error('이미 STT가 활성화되어 있습니다');
    }

    final result = await _sttService.startListening(
      onPartialResult: onPartialResult,
      onFinalResult: onFinalResult,
      localeId: localeId,
    );

    if (result.success) {
      _isSTTActive = true;
    }
    return result;
  }

  Future<AudioResult> stopSTT() async {
    if (!_isSTTActive) {
      return AudioResult.error('STT가 활성화되어 있지 않습니다');
    }

    final result = await _sttService.stopListening();
    _isSTTActive = false;
    return result;
  }

  Future<AudioResult> cancelSTT() async {
    if (!_isSTTActive) {
      return AudioResult.error('STT가 활성화되어 있지 않습니다');
    }

    final result = await _sttService.cancelListening();
    _isSTTActive = false;
    return result;
  }

  // 3. 녹음 + 실시간 STT 병렬 처리
  Future<AudioResult> startRecordingWithSTT({
    String? path,
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    // 녹음 시작
    final recordResult = await startRecording(path: path);
    if (!recordResult.success) {
      return recordResult;
    }

    // STT 시작
    final sttResult = await startSTT(
      onPartialResult: onPartialResult,
      onFinalResult: onFinalResult,
      localeId: localeId,
    );

    if (!sttResult.success) {
      // STT 실패하면 녹음도 정지
      await stopRecording();
      return sttResult;
    }

    return AudioResult.success();
  }

  Future<AudioResult> stopRecordingWithSTT() async {
    // 병렬로 둘 다 정지
    final recordFuture = stopRecording();
    final sttFuture = stopSTT();

    final results = await Future.wait([recordFuture, sttFuture]);

    final recordResult = results[0];
    final sttResult = results[1];

    // 둘 중 하나라도 실패하면 에러 리턴
    if (!recordResult.success) return recordResult;
    if (!sttResult.success) return sttResult;

    // 성공시 녹음 파일과 텍스트 모두 포함
    return AudioResult.success(
      filePath: recordResult.filePath,
      transcription: sttResult.transcription,
      duration: recordResult.duration,
    );
  }

  Future<AudioResult> pauseRecordingWithSTT() async {
    final recordFuture = pauseRecording();
    final sttFuture = cancelSTT(); // STT는 일시정지가 없어서 cancel

    final results = await Future.wait([recordFuture, sttFuture]);

    if (!results[0].success) return results[0];
    if (!results[1].success) return results[1];

    return AudioResult.success();
  }

  Future<AudioResult> resumeRecordingWithSTT({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    final recordFuture = resumeRecording();
    final sttFuture = startSTT(
      onPartialResult: onPartialResult,
      onFinalResult: onFinalResult,
      localeId: localeId,
    );

    final results = await Future.wait([recordFuture, sttFuture]);

    if (!results[0].success) return results[0];
    if (!results[1].success) return results[1];

    return AudioResult.success();
  }

  // 유틸리티 메서드들
  Future<String> createCustomPath({
    required String fileName,
    bool useDocumentsDirectory = true,
  }) async {
    try {
      final directory = useDocumentsDirectory
          ? await getApplicationDocumentsDirectory()
          : await getTemporaryDirectory();
      return '${directory.path}/$fileName';
    } catch (e) {
      final tempDir = await getTemporaryDirectory();
      return '${tempDir.path}/$fileName';
    }
  }

  Future<List<LocaleName>> getAvailableLocales() async {
    return await _sttService.getAvailableLocales();
  }

  // 볼륨 레벨 스트림 (파형 그리기용)
  Stream<Amplitude> onAmplitudeChanged(Duration interval) {
    return _audioRecorder.onAmplitudeChanged(interval);
  }

  Future<Amplitude> getAmplitude() async {
    return await _audioRecorder.getAmplitude();
  }

  // 상태 확인
  bool get isRecording => _isRecording;
  bool get isSTTActive => _isSTTActive;
  bool get isRecorderAvailable => _audioRecorder != null;
  bool get isSTTAvailable => _sttService.isAvailable;

  // 현재 STT 텍스트
  String get currentSTTText => _sttService.currentText;

  Future<bool> isRecordingPaused() async {
    return await _audioRecorder.isPaused();
  }

  // 리소스 해제
  void dispose() {
    _audioRecorder.dispose();
    _sttService.dispose();
    _isRecording = false;
    _isSTTActive = false;
  }
}
