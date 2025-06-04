import 'dart:async';

import 'package:audio_record_stt/src/models/audio_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  StreamController<String>? _textController;
  String _currentText = '';

  Future<bool> _checkPermission() async {
    final micPermission = await Permission.microphone.request();

    if (micPermission.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return micPermission.isGranted;
  }

  Future<AudioResult> initialize() async {
    try {
      if (!await _checkPermission()) {
        return AudioResult.error('마이크 권한이 필요합니다.');
      }

      final available = await _speechToText.initialize(
        onError: (error) => _handleError(error.errorMsg),
        onStatus: (status) => _handleStatus(status),
      );

      if (!available) {
        return AudioResult.error('음성인식을 사용할 수 없습니다.');
      }
      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('STT 초기화 실패: $e');
    }
  }

  Future<AudioResult> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    try {
      if (!_speechToText.isAvailable) {
        return AudioResult.error('');
      }
      _textController = StreamController<String>.broadcast();
      _currentText = '';
      _isListening = true;
      await _speechToText.listen(
        onResult: (result) {
          _currentText = result.recognizedWords;
          if (result.finalResult) {
            onFinalResult(_currentText);
          } else {
            onPartialResult(_currentText);
          }
        },
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 5),
        //TODO 해당 Deprecated 옵션 제거 후 수정 필요
        cancelOnError: true,
        partialResults: true,
        localeId: localeId,
      );

      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('STT 시작 실패: $e');
    }
  }

  // STT 정지
  Future<AudioResult> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;

      final finalText = _currentText;
      _textController?.close();
      _textController = null;

      return AudioResult.success(transcription: finalText);
    } catch (e) {
      return AudioResult.error('STT 정지 실패: $e');
    }
  }

  // STT 취소
  Future<AudioResult> cancelListening() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _textController?.close();
      _textController = null;
      _currentText = '';

      return AudioResult.success();
    } catch (e) {
      return AudioResult.error('STT 취소 실패: $e');
    }
  }

  // 사용 가능한 언어 목록 가져오기
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speechToText.locales();
  }

  // 에러 처리
  void _handleError(String error) {
    print('STT Error: $error');
    _textController?.addError(error);
  }

  // 상태 처리
  void _handleStatus(String status) {
    print('STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  // 현재 상태 확인
  bool get isListening => _isListening;
  bool get isAvailable => _speechToText.isAvailable;
  String get currentText => _currentText;

  // 리소스 해제
  void dispose() {
    _speechToText.stop();
    _textController?.close();
  }
}
