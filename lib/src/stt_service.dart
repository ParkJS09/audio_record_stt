import 'dart:async';

import 'package:audio_record_stt/src/models/audio_result.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  StreamController<String>? _textController;
  String _currentText = '';

  Future<bool> _checkPermission() async {
    final micPermission = await Permission.microphone.status;

    if (micPermission.isDenied || micPermission.isPermanentlyDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }

    return micPermission.isGranted;
  }

  Future<AudioResult> initialize() async {
    try {
      if (!await _checkPermission()) {
        return AudioResult.error('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
      }

      final available = await _speechToText.initialize(
        onError: (error) => _handleError(error.errorMsg),
        onStatus: (status) => _handleStatus(status),
        debugLogging: true, // 디버깅을 위해 추가
      );

      if (!available) {
        return AudioResult.error('이 기기에서는 음성인식을 사용할 수 없습니다.');
      }

      _isInitialized = true;
      return AudioResult.success();
    } catch (e) {
      _isInitialized = false;
      return AudioResult.error('STT 초기화 실패: $e');
    }
  }

  Future<AudioResult> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    try {
      // 초기화 여부 확인
      if (!_isInitialized) {
        final initResult = await initialize();
        if (!initResult.success) {
          return initResult;
        }
      }

      // 이미 듣고 있으면 중지
      if (_isListening) {
        await _speechToText.stop();
      }

      // 사용 가능 여부 재확인
      if (!_speechToText.isAvailable) {
        return AudioResult.error('음성인식 서비스를 사용할 수 없습니다.');
      }

      _textController = StreamController<String>.broadcast();
      _currentText = '';
      _isListening = true;

      final success = await _speechToText.listen(
        onResult: (result) {
          _currentText = result.recognizedWords;
          print(
            'STT Result: ${result.recognizedWords}, Final: ${result.finalResult}',
          );

          if (result.finalResult) {
            onFinalResult(_currentText);
          } else {
            onPartialResult(_currentText);
          }
        },
        listenFor: const Duration(seconds: 30), // 30초로 제한
        pauseFor: const Duration(seconds: 3), // 3초 침묵시 일시정지
        cancelOnError: true,
        partialResults: true,
        localeId: localeId,
        listenMode: ListenMode.confirmation, // 확인 모드 사용
      );

      if (!success) {
        _isListening = false;
        return AudioResult.error('음성인식 시작에 실패했습니다.');
      }

      return AudioResult.success();
    } catch (e) {
      _isListening = false;
      return AudioResult.error('STT 시작 실패: $e');
    }
  }

  // STT 정지
  Future<AudioResult> stopListening() async {
    try {
      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }

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
      if (_isListening) {
        await _speechToText.cancel();
        _isListening = false;
      }

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
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _speechToText.locales();
    } catch (e) {
      print('언어 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 시스템 레벨 확인
  Future<bool> hasPermission() async {
    return await _checkPermission();
  }

  // 에러 처리
  void _handleError(String error) {
    print('🔴 STT Error: $error');
    _textController?.addError(error);
    _isListening = false;
  }

  // 상태 처리
  void _handleStatus(String status) {
    print('🔵 STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  // 현재 상태 확인
  bool get isListening => _isListening;
  bool get isAvailable => _speechToText.isAvailable && _isInitialized;
  bool get isInitialized => _isInitialized;
  String get currentText => _currentText;

  // 리소스 해제
  void dispose() {
    _speechToText.stop();
    _textController?.close();
    _isListening = false;
    _isInitialized = false;
  }
}
