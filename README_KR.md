# Audio Record STT

자동 재시작 기능을 갖춘 고급 오디오 녹음 및 연속 음성 인식 Flutter 패키지입니다.

## 🚀 주요 기능

- 🎤 **고급 오디오 녹음** - 포괄적인 제어가 가능한 고품질 녹음
- 🔄 **연속 STT** - 네이티브 OS 타임아웃 제한을 우회하는 자동 재시작 패턴
- 🗣️ **실시간 음성 인식** - 부분 및 최종 결과와 함께하는 라이브 전사
- 📁 **파일 기반 STT 처리** - 녹음된 오디오 파일을 텍스트로 변환
- 🛡️ **스마트 오류 처리** - 자동 복구 및 재시작 메커니즘
- 📱 **크로스 플랫폼 지원** - iOS 및 Android 호환
- 🎯 **통합 관리자** - 모든 작업을 위한 단일 `AudioSTTManager` 클래스

## 💡 왜 이 패키지를 선택해야 할까요?

**문제점**: 네이티브 iOS/Android STT 엔진은 하드코딩된 2-5초 침묵 타임아웃을 가지고 있어 무시할 수 없으며, 자연스러운 말하기 중단 시 자동으로 인식이 중단됩니다.

**해결책**: 저희의 **자동 재시작 패턴**은 STT 세션이 종료될 때 자동으로 재시작하여, 사용자가 명시적으로 중지할 때까지 진정한 연속 음성 인식을 제공합니다.

## 🔧 설치

`pubspec.yaml`에 다음을 추가하세요:

```yaml
dependencies:
  audio_record_stt:
    git:
      url: https://github.com/ParkJS09/audio_record_stt.git
      ref: master
```

그 다음 실행하세요:
```bash
flutter pub get
```

### 필수 권한 설정

#### Android
`android/app/src/main/AndroidManifest.xml`에 추가:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
`ios/Runner/Info.plist`에 추가:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>이 앱은 오디오를 녹음하기 위해 마이크 접근이 필요합니다</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>이 앱은 오디오를 텍스트로 변환하기 위해 음성 인식 접근이 필요합니다</string>
```

## 📖 사용법

### 🔄 연속 STT (권장)

장문의 받아쓰기, 음성 메모, 또는 자연스러운 말하기 중단이 인식을 방해하지 않아야 하는 시나리오에 완벽합니다.

```dart
import 'package:audio_record_stt/audio_record_stt.dart';

class ContinuousSTTExample extends StatefulWidget {
  @override
  _ContinuousSTTExampleState createState() => _ContinuousSTTExampleState();
}

class _ContinuousSTTExampleState extends State<ContinuousSTTExample> {
  final AudioSTTManager _manager = AudioSTTManager();
  String _finalText = '';
  String _partialText = '';

  @override
  void initState() {
    super.initState();
    _initializeSTT();
  }

  Future<void> _initializeSTT() async {
    await _manager.initialize();
  }

  Future<void> _startContinuousSTT() async {
    final result = await _manager.startContinuousSTT(
      onPartialResult: (text) {
        setState(() => _partialText = text);
      },
      onFinalResult: (text) {
        setState(() {
          _finalText = _finalText.isEmpty ? text : '$_finalText $text';
          _partialText = '';
        });
      },
      localeId: 'ko_KR', // 한국어 또는 'en_US' 영어
    );

    if (!result.success) {
      print('오류: ${result.error}');
    }
  }

  Future<void> _stopSTT() async {
    await _manager.stopSTT();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }
}
```

### 🎤 녹음 + 연속 STT

실시간 전사를 받으면서 동시에 오디오를 녹음:

```dart
Future<void> _startRecordingWithSTT() async {
  final result = await _manager.startRecordingWithSTT(
    onPartialResult: (text) {
      setState(() => _partialText = text);
    },
    onFinalResult: (text) {
      setState(() => _finalText += text + ' ');
    },
    continuousMode: true, // 자동 재시작 활성화
  );
}

Future<void> _stopRecordingWithSTT() async {
  final result = await _manager.stopRecordingWithSTT();
  
  if (result.success) {
    print('오디오 저장됨: ${result.filePath}');
    print('전사 결과: ${result.transcription}');
  }
}
```

### 📁 간단한 오디오 녹음

```dart
final AudioSTTManager _manager = AudioSTTManager();

// 녹음 시작
await _manager.startRecording();

// 정지하고 파일 얻기
final result = await _manager.stopRecording();
if (result.success) {
  print('저장 위치: ${result.filePath}');
}
```

### 🗣️ 일회성 STT (기존 방식)

```dart
await _manager.startSTT(
  onPartialResult: (text) => print('부분 결과: $text'),
  onFinalResult: (text) => print('최종 결과: $text'),
);
```

## 🏗️ API 참조

### AudioSTTManager

#### 핵심 메서드

| 메서드 | 설명 | 반환 타입 |
|--------|------|-----------|
| `initialize()` | STT 서비스 초기화 | `Future<AudioResult>` |
| `startContinuousSTT()` | 자동 재시작으로 연속 STT 시작 | `Future<AudioResult>` |
| `startRecordingWithSTT()` | 녹음 + STT 동시 실행 | `Future<AudioResult>` |
| `stopSTT()` | 모든 STT 작업 중지 | `Future<AudioResult>` |
| `stopRecordingWithSTT()` | 녹음 및 STT 중지 | `Future<AudioResult>` |

#### 녹음 메서드

| 메서드 | 설명 | 반환 타입 |
|--------|------|-----------|
| `startRecording({String? path})` | 오디오 녹음 시작 | `Future<AudioResult>` |
| `stopRecording()` | 오디오 녹음 중지 | `Future<AudioResult>` |
| `pauseRecording()` | 녹음 일시정지 | `Future<AudioResult>` |
| `resumeRecording()` | 녹음 재개 | `Future<AudioResult>` |

#### 속성

| 속성 | 타입 | 설명 |
|------|------|------|
| `isRecording` | `bool` | 현재 녹음 상태 |
| `isSTTActive` | `bool` | STT 활성 상태 |
| `isSTTAvailable` | `bool` | STT 서비스 사용 가능 여부 |

### AudioResult

| 속성 | 타입 | 설명 |
|------|------|------|
| `success` | `bool` | 작업 성공 여부 |
| `filePath` | `String?` | 오디오 파일 경로 |
| `duration` | `Duration?` | 녹음 시간 |
| `transcription` | `String?` | STT 결과 텍스트 |
| `error` | `String?` | 오류 메시지 |

## 🎯 사용 사례

### 📝 음성 메모 작성
```dart
// 긴 음성 메모에 완벽
await _manager.startContinuousSTT(
  onFinalResult: (text) => saveNoteToDatabase(text),
);
```

### 🎙️ 인터뷰 녹음
```dart
// 라이브 전사를 받으면서 녹음
await _manager.startRecordingWithSTT(
  onPartialResult: (text) => showLiveSubtitles(text),
  onFinalResult: (text) => addToTranscript(text),
);
```

### 🗣️ 음성 명령
```dart
// 빠른 일회성 인식
await _manager.startSTT(
  onFinalResult: (command) => executeVoiceCommand(command),
);
```

## ⚡ 성능 팁

1. **긴 세션에는 연속 STT 사용** - 중단을 방지하기 위해
2. **앱 시작 시 한 번 초기화** - 더 빠른 응답을 위해
3. **권한을 앱 플로우 초기에 처리** - 사용자 경험 개선
4. **적절한 해제** - 리소스 절약을 위해

## 🔧 고급 설정

### 커스텀 녹음 설정

```dart
// 커스텀 파일 경로
await _manager.startRecording(
  path: await _manager.createCustomPath(
    fileName: 'interview_${DateTime.now().millisecondsSinceEpoch}.m4a',
  ),
);
```

### 언어 지원

```dart
// 사용 가능한 로케일 가져오기
final locales = await _manager.getAvailableLocales();

// 특정 언어 사용
await _manager.startContinuousSTT(
  localeId: 'ko_KR', // 한국어
  // localeId: 'en_US', // 영어
  // localeId: 'ja_JP', // 일본어
  onFinalResult: (text) => print(text),
);
```

## 🧪 테스트

테스트 실행:
```bash
flutter test
```

예제 앱 실행:
```bash
cd example
flutter run
```

## 🤝 기여하기

1. 저장소를 포크하세요
2. 기능 브랜치를 생성하세요 (`git checkout -b feature/amazing-feature`)
3. 변경사항을 커밋하세요 (`git commit -m 'Add amazing feature'`)
4. 브랜치에 푸시하세요 (`git push origin feature/amazing-feature`)
5. Pull Request를 여세요

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다 - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 🔗 의존성

- [record](https://pub.dev/packages/record) - 오디오 녹음 기능
- [speech_to_text](https://pub.dev/packages/speech_to_text) - 음성 인식 엔진
- [permission_handler](https://pub.dev/packages/permission_handler) - 런타임 권한
- [path_provider](https://pub.dev/packages/path_provider) - 파일 시스템 접근

## 📞 지원

- 🐛 **버그 리포트**: [GitHub Issues](https://github.com/ParkJS09/audio_record_stt/issues)
- 💡 **기능 요청**: [GitHub Discussions](https://github.com/ParkJS09/audio_record_stt/discussions)
- 📧 **이메일**: your-email@example.com

---

**Flutter 커뮤니티를 위해 ❤️로 만들어졌습니다** 