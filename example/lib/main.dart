import 'package:flutter/material.dart';
import 'package:audio_record_stt/audio_record_stt.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Record STT Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AudioSTTTestPage(),
    );
  }
}

class AudioSTTTestPage extends StatefulWidget {
  const AudioSTTTestPage({super.key});

  @override
  State<AudioSTTTestPage> createState() => _AudioSTTTestPageState();
}

class _AudioSTTTestPageState extends State<AudioSTTTestPage> {
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

  // 연속 STT 시작 (자동 재시작)
  Future<void> _startContinuousSTT() async {
    if (!_isInitialized) {
      await _initializeSTT();
      return;
    }

    setState(() {
      _statusText = '연속 STT 시작 중...';
      _partialText = '';
      _finalText = '';
    });

    final result = await _manager.startContinuousSTT(
      onPartialResult: (text) {
        setState(() {
          _partialText = text;
          _statusText = '듣는 중... (연속 모드)';
        });
      },
      onFinalResult: (text) {
        setState(() {
          _finalText = _finalText.isEmpty ? text : '$_finalText $text';
          _statusText = '듣는 중... (연속 모드)';
        });
      },
      localeId: 'ko_KR',
    );

    if (!result.success) {
      setState(() => _statusText = '연속 STT 시작 실패: ${result.error}');
    }
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
        print('partialText: $text');
        setState(() {
          _partialText = text;
        });
      },
      onFinalResult: (text) {
        print('finalText: $text');
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Audio Record STT 테스트'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 상태 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _manager.isSTTActive
                    ? Colors.green[100]
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _manager.isSTTActive ? Icons.mic : Icons.mic_off,
                    color: _manager.isSTTActive ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '상태: $_statusText',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 실시간 텍스트
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.hearing, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        '실시간 인식:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _partialText.isEmpty ? '음성을 인식 중...' : _partialText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _partialText.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 최종 텍스트
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(12),
                color: Colors.green[50],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        '최종 결과:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _finalText.isEmpty
                            ? '완료된 인식 결과가 여기에 누적됩니다. (연속 모드에서는 문장별로 누적)'
                            : _finalText,
                        style: TextStyle(
                          fontSize: 16,
                          color: _finalText.isEmpty
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 컨트롤 버튼들
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // 연속 STT (권장)
                ElevatedButton.icon(
                  onPressed: _isInitialized && !_manager.isSTTActive
                      ? _startContinuousSTT
                      : null,
                  icon: const Icon(Icons.autorenew),
                  label: const Text('연속 STT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                // 녹음+연속STT
                ElevatedButton.icon(
                  onPressed:
                      _isInitialized &&
                          !_manager.isRecording &&
                          !_manager.isSTTActive
                      ? _startRecordingWithSTT
                      : null,
                  icon: const Icon(Icons.fiber_smart_record),
                  label: const Text('녹음+연속STT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                // 중지
                ElevatedButton.icon(
                  onPressed: _manager.isRecording || _manager.isSTTActive
                      ? _stopRecordingWithSTT
                      : null,
                  icon: const Icon(Icons.stop_circle),
                  label: const Text('중지'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // 사용법 안내
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.amber[700]),
                      const SizedBox(width: 8),
                      Text(
                        '테스트 팁',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '🔄 "연속 STT": 침묵 감지로 자동 중단되지 않는 연속 음성 인식!\n📝 "안녕하세요", "음성 인식 테스트", "플러터 개발" 등을 말해보세요!',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
