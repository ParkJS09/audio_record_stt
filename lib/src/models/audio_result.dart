class AudioResult {
  final bool success;
  final String? filePath;
  final String? transcription;
  final String? error;
  final Duration? duration;

  AudioResult({
    required this.success,
    this.filePath,
    this.transcription,
    this.error,
    this.duration,
  });

  factory AudioResult.success({
    String? filePath,
    String? transcription,
    Duration? duration,
  }) {
    return AudioResult(
      success: true,
      filePath: filePath,
      transcription: transcription,
      duration: duration,
    );
  }

  factory AudioResult.error(String error) {
    return AudioResult(success: false, error: error);
  }
}
