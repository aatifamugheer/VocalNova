import 'dart:io';

import '../models/child_profile.dart';
import '../models/engagement_event.dart';
import '../models/learner_state.dart';
import '../models/recommendation.dart';
import '../models/speech_result.dart';
import 'speech_api_service.dart';
import 'vocalnova_backend.dart';

class SpeechAnalysisOutcome {
  final SpeechResult speechResult;
  final Recommendation recommendation;

  const SpeechAnalysisOutcome({
    required this.speechResult,
    required this.recommendation,
  });
}

class VocalNovaAppService {
  final VocalNovaBackend _backend;
  final SpeechApiService _speechApi;

  VocalNovaAppService({
    VocalNovaBackend? backend,
    SpeechApiService? speechApi,
  })  : _backend = backend ?? VocalNovaBackend(),
        _speechApi = speechApi ?? SpeechApiService();

  /// Creates or updates the child's profile.
  Future<void> setupChild(ChildProfile child) async {
    await _backend.createChildProfile(child);
  }

  /// Starts a new practice session.
  Future<void> startSession({
    required String childId,
    required String sessionId,
  }) async {
    await _backend.startPracticeSession(
      childId: childId,
      sessionId: sessionId,
    );
  }

  /// Sends recorded audio to Member 2's Speech AI service.
  Future<SpeechResult> analyzeSpeech({
    required String targetWord,
    required String attemptId,
    required File audioFile,
    String language = 'en-US',
  }) async {
    return _speechApi.analyzeSpeech(
      targetWord: targetWord,
      attemptId: attemptId,
      audioFile: audioFile,
      language: language,
    );
  }

  /// Sends a speech result to the adaptive backend.
  Future<Recommendation> submitSpeechAttempt({
    required ChildProfile child,
    required String sessionId,
    required SpeechResult speechResult,
    required String currentDifficulty,
    required LearnerState learnerState,
  }) async {
    return _backend.processSpeechAttempt(
      child: child,
      sessionId: sessionId,
      speechResult: speechResult,
      currentDifficulty: currentDifficulty,
      learnerState: learnerState,
    );
  }

  /// Complete pipeline:
  /// audio -> Speech AI -> SpeechResult -> Adaptive backend -> Recommendation.
  Future<SpeechAnalysisOutcome> analyzeAndAdapt({
    required ChildProfile child,
    required String sessionId,
    required String targetWord,
    required String attemptId,
    required File audioFile,
    required String currentDifficulty,
    required LearnerState learnerState,
    String language = 'en-US',
  }) async {
    final speechResult = await analyzeSpeech(
      targetWord: targetWord,
      attemptId: attemptId,
      audioFile: audioFile,
      language: language,
    );

    final recommendation = await submitSpeechAttempt(
      child: child,
      sessionId: sessionId,
      speechResult: speechResult,
      currentDifficulty: currentDifficulty,
      learnerState: learnerState,
    );

    return SpeechAnalysisOutcome(
      speechResult: speechResult,
      recommendation: recommendation,
    );
  }

  /// Records that the child voluntarily retried.
  Future<void> recordRetry({
    required String childId,
    required String sessionId,
  }) async {
    await _backend.recordVoluntaryRetry(
      childId: childId,
      sessionId: sessionId,
    );
  }

  /// Records a skipped activity.
  Future<void> recordSkip({
    required String childId,
    required String sessionId,
  }) async {
    await _backend.recordSkipped(
      childId: childId,
      sessionId: sessionId,
    );
  }

  /// Records time spent practicing.
  Future<void> recordPracticeTime({
    required String childId,
    required String sessionId,
    required int seconds,
  }) async {
    await _backend.recordTimeOnTask(
      childId: childId,
      sessionId: sessionId,
      seconds: seconds,
    );
  }

  /// Records mission completion.
  Future<void> completeMission({
    required String childId,
    required String sessionId,
    required int durationSec,
  }) async {
    await _backend.recordMissionCompleted(
      childId: childId,
      sessionId: sessionId,
      durationSec: durationSec,
    );
  }

  /// Gets engagement events for the current practice session.
  Future<List<EngagementEvent>> getEngagementEvents({
    required String childId,
    required String sessionId,
  }) async {
    return _backend.getEngagementEvents(
      childId: childId,
      sessionId: sessionId,
    );
  }

  /// Calculates the current engagement score from recorded events.
  double calculateEngagementScore(
    List<EngagementEvent> events,
  ) {
    return _backend.calculateEngagementScore(events);
  }

  /// Loads the child's persistent adaptive learner state.
  Future<LearnerState?> getLearnerState(
    String childId,
  ) async {
    return _backend.getLearnerState(childId);
  }

  /// Saves the child's persistent adaptive learner state.
  Future<void> saveLearnerState(
    LearnerState learnerState,
  ) async {
    await _backend.saveLearnerState(learnerState);
  }

  /// Checks whether Member 2's Speech AI server is reachable.
  Future<bool> isSpeechAiAvailable() {
    return _speechApi.checkHealth();
  }
}
