<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Audio Record STT

Flutter package for advanced audio recording and continuous speech-to-text conversion with auto-restart functionality.

## 🚀 Key Features

- 🎤 **Advanced Audio Recording** - High-quality recording with comprehensive controls
- 🔄 **Continuous STT** - Auto-restart pattern that bypasses native OS timeout limitations  
- 🗣️ **Real-time Speech Recognition** - Live transcription with partial and final results
- 📁 **File-based STT Processing** - Convert recorded audio files to text
- 🛡️ **Smart Error Handling** - Automatic recovery and restart mechanisms
- 📱 **Cross-platform Support** - iOS and Android compatible
- 🎯 **Unified Manager** - Single `AudioSTTManager` class for all operations

## 💡 Why Choose This Package?

**Problem**: Native iOS/Android STT engines have hardcoded 2-5 second silence timeouts that cannot be overridden, causing automatic interruption during natural speech pauses.

**Solution**: Our **auto-restart pattern** automatically restarts STT sessions when they end, providing truly continuous speech recognition until the user explicitly stops it.

## 🔧 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  audio_record_stt:
    git:
      url: https://github.com/ParkJS09/audio_record_stt.git
      ref: master
```

Then run:
```bash
flutter pub get
```

### Required Permissions

#### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app needs speech recognition access to convert audio to text</string>
```

## 📖 Usage

### 🔄 Continuous STT (Recommended)

Perfect for long-form dictation, voice notes, or any scenario where natural speech pauses shouldn't interrupt recognition.

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
      localeId: 'en_US', // or 'ko_KR' for Korean
    );

    if (!result.success) {
      print('Error: ${result.error}');
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

### 🎤 Recording + Continuous STT

Record audio while simultaneously getting real-time transcription:

```dart
Future<void> _startRecordingWithSTT() async {
  final result = await _manager.startRecordingWithSTT(
    onPartialResult: (text) {
      setState(() => _partialText = text);
    },
    onFinalResult: (text) {
      setState(() => _finalText += text + ' ');
    },
    continuousMode: true, // Enable auto-restart
  );
}

Future<void> _stopRecordingWithSTT() async {
  final result = await _manager.stopRecordingWithSTT();
  
  if (result.success) {
    print('Audio saved: ${result.filePath}');
    print('Transcription: ${result.transcription}');
  }
}
```

### 📁 Simple Audio Recording

```dart
final AudioSTTManager _manager = AudioSTTManager();

// Start recording
await _manager.startRecording();

// Stop and get file
final result = await _manager.stopRecording();
if (result.success) {
  print('Saved to: ${result.filePath}');
}
```

### 🗣️ One-time STT (Traditional)

```dart
await _manager.startSTT(
  onPartialResult: (text) => print('Partial: $text'),
  onFinalResult: (text) => print('Final: $text'),
);
```

## 🏗️ API Reference

### AudioSTTManager

#### Core Methods

| Method | Description | Return Type |
|--------|-------------|-------------|
| `initialize()` | Initialize STT services | `Future<AudioResult>` |
| `startContinuousSTT()` | Start continuous STT with auto-restart | `Future<AudioResult>` |
| `startRecordingWithSTT()` | Record + STT simultaneously | `Future<AudioResult>` |
| `stopSTT()` | Stop all STT operations | `Future<AudioResult>` |
| `stopRecordingWithSTT()` | Stop recording and STT | `Future<AudioResult>` |

#### Recording Methods

| Method | Description | Return Type |
|--------|-------------|-------------|
| `startRecording({String? path})` | Start audio recording | `Future<AudioResult>` |
| `stopRecording()` | Stop audio recording | `Future<AudioResult>` |
| `pauseRecording()` | Pause recording | `Future<AudioResult>` |
| `resumeRecording()` | Resume recording | `Future<AudioResult>` |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isRecording` | `bool` | Currently recording status |
| `isSTTActive` | `bool` | STT active status |
| `isSTTAvailable` | `bool` | STT service availability |

### AudioResult

| Property | Type | Description |
|----------|------|-------------|
| `success` | `bool` | Operation success status |
| `filePath` | `String?` | Audio file path |
| `duration` | `Duration?` | Recording duration |
| `transcription` | `String?` | STT result text |
| `error` | `String?` | Error message |

## 🎯 Use Cases

### 📝 Voice Note Taking
```dart
// Perfect for long voice memos
await _manager.startContinuousSTT(
  onFinalResult: (text) => saveNoteToDatabase(text),
);
```

### 🎙️ Interview Recording
```dart
// Record while getting live transcription
await _manager.startRecordingWithSTT(
  onPartialResult: (text) => showLiveSubtitles(text),
  onFinalResult: (text) => addToTranscript(text),
);
```

### 🗣️ Voice Commands
```dart
// Quick one-time recognition
await _manager.startSTT(
  onFinalResult: (command) => executeVoiceCommand(command),
);
```

## ⚡ Performance Tips

1. **Use Continuous STT** for long sessions to avoid interruptions
2. **Initialize once** at app startup for faster response
3. **Handle permissions** early in your app flow
4. **Dispose properly** to free up resources

## 🔧 Advanced Configuration

### Custom Recording Settings

```dart
// Custom file path
await _manager.startRecording(
  path: await _manager.createCustomPath(
    fileName: 'interview_${DateTime.now().millisecondsSinceEpoch}.m4a',
  ),
);
```

### Language Support

```dart
// Get available locales
final locales = await _manager.getAvailableLocales();

// Use specific language
await _manager.startContinuousSTT(
  localeId: 'ko_KR', // Korean
  // localeId: 'en_US', // English
  // localeId: 'ja_JP', // Japanese
  onFinalResult: (text) => print(text),
);
```

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run example app:
```bash
cd example
flutter run
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Dependencies

- [record](https://pub.dev/packages/record) - Audio recording functionality
- [speech_to_text](https://pub.dev/packages/speech_to_text) - Speech recognition engine
- [permission_handler](https://pub.dev/packages/permission_handler) - Runtime permissions
- [path_provider](https://pub.dev/packages/path_provider) - File system access

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/ParkJS09/audio_record_stt/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/ParkJS09/audio_record_stt/discussions)
- 📧 **Email**: your-email@example.com

---

**Made with ❤️ for the Flutter community**
