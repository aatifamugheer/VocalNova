class Recommendation {
  final String recommendationId;
  final String childId;
  final String theme;
  final String difficulty;
  final int sessionItems;
  final String nextActivity;
  final String reason;

  const Recommendation({
    required this.recommendationId,
    required this.childId,
    required this.theme,
    required this.difficulty,
    required this.sessionItems,
    required this.nextActivity,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'recommendationId': recommendationId,
      'childId': childId,
      'theme': theme,
      'difficulty': difficulty,
      'sessionItems': sessionItems,
      'nextActivity': nextActivity,
      'reason': reason,
    };
  }

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      recommendationId: map['recommendationId'] as String,
      childId: map['childId'] as String,
      theme: map['theme'] as String,
      difficulty: map['difficulty'] as String,
      sessionItems: (map['sessionItems'] as num).toInt(),
      nextActivity: map['nextActivity'] as String,
      reason: map['reason'] as String,
    );
  }
}
