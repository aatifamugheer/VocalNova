class SpeechResult {
  final String attemptId;
  final String targetWord;
  final String recognizedText;
  final double speechScore;
  final double confidence;
  final String feedbackType;
  final String feedbackMessage;
  final DateTime? timestamp;
  final String? error;

  const SpeechResult({
    required this.attemptId,
    required this.targetWord,
    required this.recognizedText,
    required this.speechScore,
    required this.confidence,
    required this.feedbackType,
    required this.feedbackMessage,
    this.timestamp,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'attemptId': attemptId,
      'targetWord': targetWord,
      'recognizedText': recognizedText,
      'speechScore': speechScore,
      'confidence': confidence,
      'feedbackType': feedbackType,
      'feedbackMessage': feedbackMessage,
      'timestamp': timestamp?.toIso8601String(),
      'error': error,
    };
  }

  factory SpeechResult.fromMap(Map<String, dynamic> map) {
    return SpeechResult(
      attemptId: map['attemptId'] as String,
      targetWord: map['targetWord'] as String,
      recognizedText: map['recognizedText'] as String,
      speechScore: (map['speechScore'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      feedbackType: map['feedbackType'] as String,
      feedbackMessage: map['feedbackMessage'] as String? ?? '',
      timestamp: map['timestamp'] == null
          ? null
          : DateTime.tryParse(map['timestamp'] as String),
      error: map['error'] as String?,
    );
  }
}