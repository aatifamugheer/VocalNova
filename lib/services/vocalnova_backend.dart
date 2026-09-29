import '../models/child_profile.dart';
import '../models/learner_state.dart';
import '../models/recommendation.dart';
import '../models/speech_result.dart';
import 'adaptive_learning_engine.dart';
import 'engagement_service.dart';
import 'firestore_service.dart';
import '../models/engagement_event.dart';


class VocalNovaBackend {
  final FirestoreService _firestoreService;
  final EngagementService _engagementService;
  final AdaptiveLearningEngine _learningEngine;

  VocalNovaBackend({
    FirestoreService? firestoreService,
    EngagementService? engagementService,
    AdaptiveLearningEngine? learningEngine,
  })  : _firestoreService =
            firestoreService ?? FirestoreService(),
        _engagementService =
            engagementService ?? EngagementService(),
        _learningEngine =
            learningEngine ?? const AdaptiveLearningEngine();

  /// Creates or updates a child's profile.
  Future<void> createChildProfile(ChildProfile child) async {
    await _firestoreService.saveChild(
      childId: child.childId,
      displayName: child.displayName,
      ageBand: child.ageBand,
      interests: child.interests,
      targetSounds: child.targetSounds,
    );
  }

  /// Starts a practice session and records the start event.
  Future<void> startPracticeSession({
    required String sessionId,
    required String childId,
  }) async {
    await _firestoreService.startSession(
      sessionId: sessionId,
      childId: childId,
    );

    await recordEngagementEvent(
      eventId: '${sessionId}_started',
      childId: childId,
      sessionId: sessionId,
      type: 'SESSION_STARTED',
      value: 1,
    );
  }

  /// Records when the child voluntarily retries an exercise.
  Future<void> recordVoluntaryRetry({
    required String childId,
    required String sessionId,
  }) async {
    await recordEngagementEvent(
      eventId:
          '${sessionId}_retry_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      type: 'VOLUNTARY_RETRY',
      value: 1,
    );
  }

  /// Records when the child skips an exercise.
  Future<void> recordSkipped({
    required String childId,
    required String sessionId,
  }) async {
    await recordEngagementEvent(
      eventId:
          '${sessionId}_skipped_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      type: 'SKIPPED',
      value: 1,
    );
  }

  /// Records time spent practicing, in seconds.
  Future<void> recordTimeOnTask({
    required String childId,
    required String sessionId,
    required int seconds,
  }) async {
    await recordEngagementEvent(
      eventId:
          '${sessionId}_time_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      type: 'TIME_ON_TASK',
      value: seconds,
    );
  }

  /// Records that the child returned for practice.
  Future<void> recordReturned({
    required String childId,
    required String sessionId,
  }) async {
    await recordEngagementEvent(
      eventId:
          '${sessionId}_returned_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      type: 'RETURNED',
      value: 1,
    );
  }

  /// Records mission completion and completes the session.
  Future<void> recordMissionCompleted({
    required String childId,
    required String sessionId,
    required int durationSec,
  }) async {
    await recordEngagementEvent(
      eventId:
          '${sessionId}_completed_${DateTime.now().millisecondsSinceEpoch}',
      childId: childId,
      sessionId: sessionId,
      type: 'MISSION_COMPLETED',
      value: 1,
    );

    await completePracticeSession(
      sessionId: sessionId,
      durationSec: durationSec,
    );
  }

  /// Saves a generic engagement event.
  Future<void> recordEngagementEvent({
    required String eventId,
    required String childId,
    required String sessionId,
    required String type,
    required int value,
  }) async {
    await _firestoreService.saveEngagementEvent(
      eventId: eventId,
      childId: childId,
      sessionId: sessionId,
      type: type,
      value: value,
    );
  }

  /// Processes a speech attempt and adapts the next activity
  /// using the learner's performance and engagement.
  Future<Recommendation> processSpeechAttempt({
  required ChildProfile child,
  required String sessionId,
  required SpeechResult speechResult,
  required String currentDifficulty,
  required LearnerState learnerState,
}) async {
  await _firestoreService.saveAttempt(
    speechResult: speechResult,
    childId: child.childId,
    sessionId: sessionId,
  );

  final events = await _firestoreService.getEngagementEvents(
    childId: child.childId,
    sessionId: sessionId,
  );

  final engagementScore =
      _engagementService.calculateFromEvents(events);

  final wasSuccessful =
      speechResult.feedbackType == 'SUCCESS' ||
      speechResult.speechScore >= 70;

  final updatedLearnerState = learnerState.addAttempt(
    score: speechResult.speechScore,
    successful: wasSuccessful,
    engagement: engagementScore.round(),
  );

  final recommendation = _learningEngine.recommend(
    learner: updatedLearnerState,
    latestScore: speechResult.speechScore,
    engagementScore: engagementScore.round(),
  );

  await _firestoreService.saveRecommendation(
    recommendationId: recommendation.recommendationId,
    childId: recommendation.childId,
    sessionId: sessionId,
    theme: recommendation.theme,
    difficulty: recommendation.difficulty,
    sessionItems: recommendation.sessionItems,
    nextActivity: recommendation.nextActivity,
    reason: recommendation.reason,
  );

  return recommendation;
}

  /// Completes a practice session.
  Future<void> completePracticeSession({
    required String sessionId,
    required int durationSec,
  }) async {
    await _firestoreService.completeSession(
      sessionId: sessionId,
      durationSec: durationSec,
    );
  }
  Future<LearnerState?> getLearnerState(
  String childId,
) async {
  return _firestoreService.getLearnerState(childId);
}
Future<void> saveLearnerState(
  LearnerState learnerState,
) async {
  await _firestoreService.saveLearnerState(
    learnerState,
  );
}
Future<List<EngagementEvent>> getEngagementEvents({
  required String childId,
  required String sessionId,
}) async {
  return _firestoreService.getEngagementEvents(
    childId: childId,
    sessionId: sessionId,
  );
}

double calculateEngagementScore(
  List<EngagementEvent> events,
) {
  return _engagementService.calculateFromEvents(events);
}
}