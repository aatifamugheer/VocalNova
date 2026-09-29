import '../models/learner_state.dart';
import '../models/recommendation.dart';

class AdaptiveLearningEngine {
  const AdaptiveLearningEngine();

  Recommendation recommend({
    required LearnerState learner,
    required double latestScore,
    required int engagementScore,
  }) {
    final average = learner.averageScore;
    final trend = learner.improvementTrend;

    String difficulty;
    String activity;
    int sessionItems;
    String teachingMode;
    String reason;

    // Low performance:
    // provide strong modeling and a short mission.
    if (latestScore < 40 || average < 45) {
      difficulty = 'EASY';
      activity = 'MODELED_WORD';
      sessionItems = 3;
      teachingMode = 'FULL_MODEL';

      reason =
          'The child needs more guided practice, '
          'so the next mission uses a short modeled '
          'activity.';
    }

    // Improving child:
    // gradually reduce support while keeping practice focused.
    else if (latestScore < 70 || trend < 5) {
      difficulty = 'MEDIUM';
      activity = 'FOCUSED_WORD';
      sessionItems = 4;
      teachingMode = 'GUIDED';

      reason =
          'The child is developing the skill, '
          'so guided word practice will reinforce '
          'the target.';
    }

    // Strong performance:
    // introduce more independent speech.
    else if (latestScore < 90) {
      difficulty = 'MEDIUM';
      activity = 'WORD_REPEAT';
      sessionItems = 5;
      teachingMode = 'INDEPENDENT';

      reason =
          'The child is progressing well, '
          'so independent word practice is introduced.';
    }

    // Very strong performance:
    // progress toward phrases.
    else {
      difficulty = 'HARD';
      activity = 'PHRASE_PRACTICE';
      sessionItems = 5;
      teachingMode = 'INDEPENDENT';

      reason =
          'The child is demonstrating strong performance, '
          'so phrase-level practice can begin.';
    }

    // Engagement modifies the mission length.
    if (engagementScore < 40) {
      sessionItems = sessionItems.clamp(2, 3);

      reason +=
          ' The mission is shortened because '
          'engagement is currently low.';
    }

    // A strong improvement trend can allow
    // slightly more challenging practice.
    if (trend >= 15 && latestScore >= 60) {
      if (difficulty == 'MEDIUM') {
        difficulty = 'HARD';
        activity = 'PHRASE_PRACTICE';
        teachingMode = 'INDEPENDENT';

        reason +=
            ' Recent performance shows strong improvement, '
            'so the difficulty is increased gradually.';
      }
    }

    return Recommendation(
      recommendationId:
          'adaptive_${DateTime.now().millisecondsSinceEpoch}',
      childId: learner.childId,
      theme: learner.preferredTheme,
      difficulty: difficulty,
      sessionItems: sessionItems,
      nextActivity: activity,
      reason:
          '$teachingMode • $reason',
    );
  }
}