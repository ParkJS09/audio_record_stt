import 'package:flutter/material.dart';
import 'package:audio_record_stt/audio_record_stt.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Record STT Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AudioSTTDemo(),
    );
  }
}

class AudioSTTDemo extends StatefulWidget {
  @override
  _AudioSTTDemoState createState() => _AudioSTTDemoState();
}

class _AudioSTTDemoState extends State<AudioSTTDemo> {
  final AudioSTTManager _manager = AudioSTTManager();
  String _partialText = '';
  String _finalText = '';
  String _statusText = '준비됨';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSTT();
  }

  Future<void> _initializeSTT() async {
    setState(() => _statusText = '초기화 중...');

    final result = await _manager.initialize();

    setState(() {
      _isInitialized = result.success;
      _statusText = result.success ? '준비됨' : '초기화 실패: ${result.error}';
    });
  }

  Future<void> _startSTT() async {
    if (!_isInitialized) {
      await _initializeSTT();
      return;
    }

    setState(() {
      _statusText = 'STT 시작 중...';
      _partialText = '';
      _finalText = '';
    });

    final result = await _manager.startSTT(
      onPartialResult: (text) {
        setState(() {
          _partialText = text;
          _statusText = '듣는 중... (실시간)';
        });
      },
      onFinalResult: (text) {
        setState(() {
          _finalText = text;
          _statusText = '완료됨';
        });
      },
      localeId: 'ko_KR',
    );

    if (!result.success) {
      setState(() => _statusText = 'STT 시작 실패: ${result.error}');
    }
  }

  Future<void> _stopSTT() async {
    setState(() => _statusText = 'STT 중지 중...');

    final result = await _manager.stopSTT();

    setState(() {
      _statusText = result.success ? '중지됨' : '중지 실패: ${result.error}';
    });
  }

  Future<void> _startRecordingWithSTT() async {
    if (!_isInitialized) {
      await _initializeSTT();
      return;
    }

    setState(() {
      _statusText = '녹음 + STT 시작 중...';
      _partialText = '';
      _finalText = '';
    });

    final result = await _manager.startRecordingWithSTT(
      onPartialResult: (text) {
        setState(() {
          _partialText = text;
          _statusText = '녹음 중... (실시간 인식)';
        });
      },
      onFinalResult: (text) {
        setState(() {
          _finalText = text;
        });
      },
      localeId: 'ko_KR',
    );

    if (!result.success) {
      setState(() => _statusText = '시작 실패: ${result.error}');
    }
  }

  Future<void> _stopRecordingWithSTT() async {
    setState(() => _statusText = '녹음 + STT 중지 중...');

    final result = await _manager.stopRecordingWithSTT();

    setState(() {
      if (result.success) {
        _statusText = '완료! 파일: ${result.filePath}';
        _finalText = result.transcription ?? _finalText;
      } else {
        _statusText = '중지 실패: ${result.error}';
      }
    });
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Audio Record STT Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상태 표시
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _manager.isSTTActive
                    ? Colors.green[100]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '상태: $_statusText',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            SizedBox(height: 20),

            // 실시간 텍스트
            Container(
              width: double.infinity,
              height: 100,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '실시간 인식:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _partialText.isEmpty ? '음성을 인식 중...' : _partialText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // 최종 텍스트
            Container(
              width: double.infinity,
              height: 100,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최종 결과:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _finalText.isEmpty
                            ? '완료된 인식 결과가 여기에 표시됩니다.'
                            : _finalText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 버튼들
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isInitialized && !_manager.isSTTActive
                      ? _startSTT
                      : null,
                  child: Text('STT만 시작'),
                ),
                ElevatedButton(
                  onPressed: _manager.isSTTActive ? _stopSTT : null,
                  child: Text('STT 중지'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton(
                  onPressed:
                      _isInitialized &&
                          !_manager.isRecording &&
                          !_manager.isSTTActive
                      ? _startRecordingWithSTT
                      : null,
                  child: Text('녹음+STT 시작'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: _manager.isRecording || _manager.isSTTActive
                      ? _stopRecordingWithSTT
                      : null,
                  child: Text('녹음+STT 중지'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 정보
            Text(
              '💡 팁: "안녕하세요", "테스트", "음성인식" 등을 말해보세요!',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
