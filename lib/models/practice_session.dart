class PracticeSession {
  final String exerciseName;
  final DateTime date;
  final int durationSeconds;
  final int attempts;
  final int successes;
  final int skips;
  final int difficultyLevel;

  PracticeSession({
    required this.exerciseName,
    required this.date,
    required this.durationSeconds,
    required this.attempts,
    required this.successes,
    required this.skips,
    required this.difficultyLevel,
  });

  double get successRate {
    if (attempts == 0) return 0;
    return successes / attempts;
  }

  Map<String, dynamic> toMap() {
    return {
      'exercise_name': exerciseName,
      'date': date.toIso8601String(),
      'duration_seconds': durationSeconds,
      'attempts': attempts,
      'successes': successes,
      'skips': skips,
      'difficulty_level': difficultyLevel,
      'success_rate': successRate,
    };
  }
}