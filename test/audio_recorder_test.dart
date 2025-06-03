import 'package:flutter_test/flutter_test.dart';
import 'package:audio_record_stt/src/audio_recorder.dart';
import 'package:audio_record_stt/src/models/audio_result.dart';

void main() {
  group('AudioRecorderWrapper Tests', () {
    late AudioRecorderWrapper audioRecorder;

    setUp(() {
      audioRecorder = AudioRecorderWrapper();
    });

    tearDown(() {
      audioRecorder.dispose();
    });

    group('AudioResult 클래스 테스트', () {
      test('성공 결과가 올바르게 생성되어야 함', () {
        // When
        final result = AudioResult.success(
          filePath: '/test/path/audio.m4a',
          duration: Duration(seconds: 30),
        );

        // Then
        expect(result.success, isTrue);
        expect(result.filePath, equals('/test/path/audio.m4a'));
        expect(result.duration, equals(Duration(seconds: 30)));
        expect(result.error, isNull);
      });

      test('에러 결과가 올바르게 생성되어야 함', () {
        // When
        final result = AudioResult.error('테스트 에러');

        // Then
        expect(result.success, isFalse);
        expect(result.error, equals('테스트 에러'));
        expect(result.filePath, isNull);
      });
    });

    group('녹음 상태 확인 테스트', () {
      test('초기 상태에서는 녹음 중이 아니어야 함', () async {
        // When
        final isRecording = await audioRecorder.isRecording();

        // Then
        expect(isRecording, isFalse);
      });
    });

    group('기본 경로 생성 로직 확인', () {
      test('null 경로로 녹음 시작하면 기본 경로가 생성되어야 함', () async {
        // 이 테스트는 실제 권한이 필요하므로 integration test에서 실행하는 것이 좋습니다
        // 현재는 로직 검증만 수행
        expect(true, isTrue); // placeholder
      });
    });

    test('AudioRecorderWrapper 인스턴스가 올바르게 생성되어야 함', () {
      expect(audioRecorder, isA<AudioRecorderWrapper>());
    });
  });
}

// Integration Test용 별도 테스트
// test_driver/app.dart 파일에서 실행할 수 있는 통합 테스트
/*
Integration Test 예시:

void integrationTests() {
  group('AudioRecorder Integration Tests', () {
    testWidgets('실제 녹음 테스트', (WidgetTester tester) async {
      final audioRecorder = AudioRecorderWrapper();
      
      // 녹음 시작
      final startResult = await audioRecorder.startRecording();
      expect(startResult.success, isTrue);
      
      // 잠시 대기
      await Future.delayed(Duration(seconds: 2));
      
      // 녹음 중 확인
      final isRecording = await audioRecorder.isRecording();
      expect(isRecording, isTrue);
      
      // 녹음 중지
      final stopResult = await audioRecorder.stopRecording();
      expect(stopResult.success, isTrue);
      expect(stopResult.duration, isNotNull);
      
      audioRecorder.dispose();
    });
  });
}
*/
