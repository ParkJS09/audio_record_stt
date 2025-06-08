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

  // 자동 재시작 관련 변수들
  bool _shouldKeepListening = false;
  Timer? _restartTimer;
  Function(String)? _onPartialResult;
  Function(String)? _onFinalResult;
  String _currentLocaleId = 'ko_KR';

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

  // 일반 STT 시작 (기존 방식)
  Future<AudioResult> startListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    _shouldKeepListening = false; // 자동 재시작 비활성화
    return await _startSingleSession(
      onPartialResult: onPartialResult,
      onFinalResult: onFinalResult,
      localeId: localeId,
    );
  }

  // 연속 STT 시작 (자동 재시작)
  Future<AudioResult> startContinuousListening({
    required Function(String) onPartialResult,
    required Function(String) onFinalResult,
    String localeId = 'ko_KR',
  }) async {
    print('🔄 연속 STT 시작');

    // 콜백 함수들 저장
    _onPartialResult = onPartialResult;
    _onFinalResult = onFinalResult;
    _currentLocaleId = localeId;
    _shouldKeepListening = true;

    return await _startSingleSession(
      onPartialResult: onPartialResult,
      onFinalResult: (text) {
        // 최종 결과 전달
        onFinalResult(text);

        print('🔄 Final result received: $text');

        // 자동 재시작 스케줄링
        if (_shouldKeepListening && !_isListening) {
          _scheduleRestart();
        }
      },
      localeId: localeId,
    );
  }

  // 단일 STT 세션 시작
  Future<AudioResult> _startSingleSession({
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
        await Future.delayed(const Duration(milliseconds: 100));
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
        listenFor: const Duration(minutes: 2), // 짧게 설정 (자동 재시작용)
        pauseFor: const Duration(seconds: 3), // 짧은 중단 감지
        cancelOnError: false,
        partialResults: true,
        localeId: localeId,
        listenMode: ListenMode.dictation,
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

  // 자동 재시작 스케줄링
  void _scheduleRestart() {
    _restartTimer?.cancel();

    print('🔄 자동 재시작 스케줄링...');

    _restartTimer = Timer(const Duration(milliseconds: 500), () async {
      if (_shouldKeepListening && !_isListening) {
        print('🔄 자동 재시작 실행');

        final result = await _startSingleSession(
          onPartialResult: _onPartialResult!,
          onFinalResult: (text) {
            _onFinalResult!(text);

            // 다시 자동 재시작 스케줄링
            if (_shouldKeepListening && !_isListening) {
              _scheduleRestart();
            }
          },
          localeId: _currentLocaleId,
        );

        if (!result.success) {
          print('🔴 자동 재시작 실패: ${result.error}');
          // 재시작 실패 시 재시도
          if (_shouldKeepListening) {
            _scheduleRestart();
          }
        }
      }
    });
  }

  // STT 정지 (연속 모드도 완전 중지)
  Future<AudioResult> stopListening() async {
    try {
      print('🛑 STT 정지 (연속 모드 포함)');

      // 자동 재시작 중지
      _shouldKeepListening = false;
      _restartTimer?.cancel();
      _restartTimer = null;

      if (_isListening) {
        await _speechToText.stop();
        _isListening = false;
      }

      final finalText = _currentText;
      _textController?.close();
      _textController = null;

      // 콜백 초기화
      _onPartialResult = null;
      _onFinalResult = null;

      return AudioResult.success(transcription: finalText);
    } catch (e) {
      return AudioResult.error('STT 정지 실패: $e');
    }
  }

  // STT 취소 (연속 모드도 완전 취소)
  Future<AudioResult> cancelListening() async {
    try {
      print('❌ STT 취소 (연속 모드 포함)');

      // 자동 재시작 중지
      _shouldKeepListening = false;
      _restartTimer?.cancel();
      _restartTimer = null;

      if (_isListening) {
        await _speechToText.cancel();
        _isListening = false;
      }

      _textController?.close();
      _textController = null;
      _currentText = '';

      // 콜백 초기화
      _onPartialResult = null;
      _onFinalResult = null;

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

    // 연속 모드에서 에러 발생 시 재시작 시도
    if (_shouldKeepListening) {
      print('🔄 에러 후 자동 재시작 시도');
      _scheduleRestart();
    }
  }

  // 상태 처리
  void _handleStatus(String status) {
    print('🔵 STT Status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;

      // 연속 모드에서 done 상태 시 재시작 스케줄링
      if (_shouldKeepListening && status == 'done') {
        print('🔄 Done 상태에서 자동 재시작 스케줄링');
        _scheduleRestart();
      }
    }
  }

  // 현재 상태 확인
  bool get isListening => _isListening;
  bool get isAvailable => _speechToText.isAvailable && _isInitialized;
  bool get isInitialized => _isInitialized;
  String get currentText => _currentText;

  // 리소스 해제
  void dispose() {
    _shouldKeepListening = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    _speechToText.stop();
    _textController?.close();
    _isListening = false;
    _isInitialized = false;
    _onPartialResult = null;
    _onFinalResult = null;
  }
}
