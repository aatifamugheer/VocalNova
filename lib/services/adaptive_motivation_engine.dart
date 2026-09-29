import '../models/recommendation.dart';

class AdaptiveMotivationEngine {
  Recommendation generateRecommendation({
    required String childId,
    required double speechScore,
    required double engagementScore,
    required List<String> interests,
    required String currentDifficulty,
  }) {
    final normalizedInterests = interests
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();

    final theme = _selectTheme(normalizedInterests);

    String difficulty = currentDifficulty.toUpperCase();
    int sessionItems = 5;
    String nextActivity = 'WORD_REPEAT';
    final reasons = <String>[];

    /*
     * VocalNova adaptation logic
     *
     * Speech score controls the learning challenge.
     * Engagement controls mission length and variety.
     * Child interests control the theme/presentation.
     *
     * These are prototype heuristics, not clinically validated thresholds.
     */

    if (speechScore < 50) {
      difficulty = 'EASY';
      sessionItems = 3;
      nextActivity = 'MODELED_WORD';
      reasons.add('Speech performance was low, so the next task is simplified with modeling.');
    } else if (speechScore < 80) {
      difficulty = difficulty == 'HARD' ? 'MEDIUM' : difficulty;
      sessionItems = 4;
      nextActivity = 'WORD_REPEAT';
      reasons.add('Speech performance is developing, so the child gets focused word practice.');
    } else if (speechScore >= 90) {
      if (currentDifficulty.toUpperCase() == 'HARD') {
        difficulty = 'HARD';
        sessionItems = 5;
        nextActivity = 'PHRASE_PRACTICE';
        reasons.add('Repeated strong performance supports moving from words toward phrases.');
      } else {
        difficulty = 'MEDIUM';
        sessionItems = 5;
        nextActivity = 'PHRASE_PRACTICE';
        reasons.add('Strong speech performance allows a gradual increase from words to phrases.');
      }
    } else {
      difficulty = 'MEDIUM';
      sessionItems = 4;
      nextActivity = 'WORD_REPEAT';
      reasons.add('Good speech performance is maintained with varied word practice.');
    }

    if (engagementScore < 40) {
  // Low engagement makes the mission shorter,
  // but it should NOT stop speech-based progression.
  sessionItems = sessionItems > 3 ? 3 : sessionItems;

  if (speechScore < 50) {
    nextActivity = 'MODELED_WORD';
  } else if (speechScore >= 90) {
    nextActivity = 'PHRASE_PRACTICE';
  } else {
    nextActivity = 'WORD_REPEAT';
  }

  reasons.add(
    theme == 'GENERAL'
        ? 'Engagement was low, so the mission was shortened.'
        : 'Engagement was low, so the mission was shortened and personalized around the child\'s interest.',
  );
} else if (engagementScore >= 70) {
      if (speechScore >= 80) {
        sessionItems = sessionItems < 5 ? 5 : sessionItems;
        reasons.add('Strong engagement supports a longer challenge.');
      } else {
        reasons.add('Good engagement allows continued practice without reducing the mission.');
      }
    } else {
      reasons.add('The mission length is kept moderate to support consistency.');
    }

    if (theme != 'GENERAL') {
      reasons.add('The next activity is presented using the child\'s "$theme" interest.');
    }

    return Recommendation(
      recommendationId: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: childId,
      theme: theme,
      difficulty: difficulty,
      sessionItems: sessionItems,
      nextActivity: nextActivity,
      reason: reasons.join(' '),
    );
  }

  String _selectTheme(List<String> interests) {
    if (interests.isEmpty) return 'GENERAL';

    // Rotate through the child's own interests instead of always taking
    // interests.first. This prevents the same theme from being used forever.
    final index = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return interests[index % interests.length].toUpperCase();
  }
}
