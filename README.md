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

Flutter package for audio recording and speech-to-text conversion with easy-to-use wrapper classes.

## 🚀 Features

- 🎤 Easy audio recording with permission handling
- 🗣️ Speech-to-text conversion
- 📱 Cross-platform support (iOS, Android)
- 🛡️ Built-in error handling
- 📁 Automatic file path management

## 🔧 Installation

### From GitHub (Private Repository)

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

### Basic Audio Recording

```dart
import 'package:audio_record_stt/audio_record_stt.dart';

class RecordingExample extends StatefulWidget {
  @override
  _RecordingExampleState createState() => _RecordingExampleState();
}

class _RecordingExampleState extends State<RecordingExample> {
  final AudioRecorderWrapper _recorder = AudioRecorderWrapper();

  Future<void> startRecording() async {
    final result = await _recorder.startRecording();
    
    if (result.success) {
      print('Recording started: ${result.filePath}');
    } else {
      print('Error: ${result.error}');
    }
  }

  Future<void> stopRecording() async {
    final result = await _recorder.stopRecording();
    
    if (result.success) {
      print('Recording saved: ${result.filePath}');
      print('Duration: ${result.duration}');
    } else {
      print('Error: ${result.error}');
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
```

### Custom Recording Path

```dart
final result = await _recorder.startRecording(
  path: '/custom/path/my_audio.m4a'
);
```

### Check Recording Status

```dart
bool isRecording = await _recorder.isRecording();
```

## 🏗️ API Reference

### AudioRecorderWrapper

| Method | Description | Return Type |
|--------|-------------|-------------|
| `startRecording({String? path})` | Start audio recording | `Future<AudioResult>` |
| `stopRecording()` | Stop audio recording | `Future<AudioResult>` |
| `isRecording()` | Check if currently recording | `Future<bool>` |
| `dispose()` | Clean up resources | `void` |

### AudioResult

| Property | Type | Description |
|----------|------|-------------|
| `success` | `bool` | Whether operation was successful |
| `filePath` | `String?` | Path to recorded audio file |
| `duration` | `Duration?` | Recording duration |
| `transcription` | `String?` | Speech-to-text result |
| `error` | `String?` | Error message if failed |

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
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

- [record](https://pub.dev/packages/record) - Audio recording
- [speech_to_text](https://pub.dev/packages/speech_to_text) - Speech recognition  
- [permission_handler](https://pub.dev/packages/permission_handler) - Permission management
- [path_provider](https://pub.dev/packages/path_provider) - File path utilities
