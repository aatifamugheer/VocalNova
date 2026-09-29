import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/engagement_event.dart';
import '../models/speech_result.dart';
import '../models/child_profile.dart';
import '../models/learner_state.dart';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Saves or updates a child's profile.
  Future<void> saveChild({
    required String childId,
    required String displayName,
    required String ageBand,
    required List<String> interests,
    required List<String> targetSounds,
  }) async {
    await _db.collection('children').doc(childId).set({
      'childId': childId,
      'displayName': displayName,
      'ageBand': ageBand,
      'interests': interests,
      'targetSounds': targetSounds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Starts a practice session.
  Future<void> startSession({
    required String sessionId,
    required String childId,
  }) async {
    await _db.collection('sessions').doc(sessionId).set({
      'sessionId': sessionId,
      'childId': childId,
      'startedAt': FieldValue.serverTimestamp(),
      'completed': false,
      'durationSec': 0,
    });
  }

  /// Completes a practice session.
  Future<void> completeSession({
    required String sessionId,
    required int durationSec,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'completed': true,
      'durationSec': durationSec,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves a speech-practice attempt.
  Future<void> saveAttempt({
    required SpeechResult speechResult,
    required String childId,
    required String sessionId,
  }) async {
    await _db.collection('attempts').doc(speechResult.attemptId).set({
      'attemptId': speechResult.attemptId,
      'childId': childId,
      'sessionId': sessionId,
      'targetWord': speechResult.targetWord,
      'recognizedText': speechResult.recognizedText,
      'speechScore': speechResult.speechScore,
      'confidence': speechResult.confidence,
      'feedbackType': speechResult.feedbackType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Saves a child engagement event.
  Future<void> saveEngagementEvent({
    required String eventId,
    required String childId,
    required String sessionId,
    required String type,
    required int value,
  }) async {
    await _db.collection('engagementEvents').doc(eventId).set({
      'eventId': eventId,
      'childId': childId,
      'sessionId': sessionId,
      'type': type,
      'value': value,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Gets engagement events for a specific practice session.
  Future<List<EngagementEvent>> getEngagementEvents({
    required String childId,
    required String sessionId,
  }) async {
    final snapshot = await _db
        .collection('engagementEvents')
        .where('childId', isEqualTo: childId)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return EngagementEvent(
        eventId: data['eventId'] as String,
        childId: data['childId'] as String,
        type: data['type'] as String,
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        value: (data['value'] as num).toInt(),
      );
    }).toList();
  }

  /// Saves an adaptive recommendation.
/// Saves an adaptive recommendation for a specific practice session.
Future<void> saveRecommendation({
  required String recommendationId,
  required String childId,
  required String sessionId,
  required String theme,
  required String difficulty,
  required int sessionItems,
  required String nextActivity,
  required String reason,
}) async {
  await _db.collection('recommendations').doc(recommendationId).set({
    'recommendationId': recommendationId,
    'childId': childId,
    'sessionId': sessionId,
    'theme': theme,
    'difficulty': difficulty,
    'sessionItems': sessionItems,
    'nextActivity': nextActivity,
    'reason': reason,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
  /// Gets all practice sessions for the dashboard.
  Future<List<Map<String, dynamic>>> getSessions() async {
    final snapshot = await _db
        .collection('sessions')
        .orderBy('startedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'sessionId': data['sessionId'] as String? ?? doc.id,
        'childId': data['childId'] as String? ?? '',
        'startedAt': data['startedAt'],
        'completed': data['completed'] as bool? ?? false,
        'durationSec': (data['durationSec'] as num?)?.toInt() ?? 0,
        'completedAt': data['completedAt'],
      };
    }).toList();
  }

  /// Gets all speech attempts for the dashboard.
  Future<List<Map<String, dynamic>>> getAttempts() async {
    final snapshot = await _db
        .collection('attempts')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'attemptId': data['attemptId'] as String? ?? doc.id,
        'childId': data['childId'] as String? ?? '',
        'sessionId': data['sessionId'] as String? ?? '',
        'targetWord': data['targetWord'] as String? ?? '',
        'recognizedText': data['recognizedText'] as String? ?? '',
        'speechScore': (data['speechScore'] as num?)?.toDouble() ?? 0,
        'confidence': (data['confidence'] as num?)?.toDouble() ?? 0,
        'feedbackType': data['feedbackType'] as String? ?? '',
        'createdAt': data['createdAt'],
      };
    }).toList();
  }
  Future<List<ChildProfile>> getChildrenForParent(
      String parentId,
) async {
  final snapshot = await _db
      .collection('children')
      .where('parentId', isEqualTo: parentId)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();

   return ChildProfile(
  childId: doc.id,
  displayName:
      data['displayName'] as String? ??
      data['name'] as String? ??
      'Child',
  ageBand:
      data['age']?.toString() ??
      data['ageBand'] as String? ??
      '',
  interests:
      List<String>.from(data['interests'] ?? const []),
  targetSounds: _getTargetSounds(data),
  targetWords: _getTargetWords(data),
);
  }).toList();
}
List<String> _getTargetSounds(Map<String, dynamic> data) {
  final storedSounds = data['targetSounds'];

  if (storedSounds is List && storedSounds.isNotEmpty) {
    return List<String>.from(storedSounds);
  }

  final targetWords = data['targetWords'];

  if (targetWords is List) {
    return targetWords
        .whereType<String>()
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .map((word) => word[0])
        .toSet()
        .toList();
  }

  return const [];
}
List<String> _getTargetWords(Map<String, dynamic> data) {
  final targetWords = data['targetWords'];

  if (targetWords is List) {
    return targetWords
        .whereType<String>()
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toList();
  }

  return const [];
}
Future<void> saveLearnerState(
  LearnerState learnerState,
) async {
  await _db
      .collection('learnerStates')
      .doc(learnerState.childId)
      .set(
    {
      ...learnerState.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    },
    SetOptions(merge: true),
  );
}

Future<LearnerState?> getLearnerState(
  String childId,
) async {
  final doc = await _db
      .collection('learnerStates')
      .doc(childId)
      .get();

  if (!doc.exists || doc.data() == null) {
    return null;
  }

  return LearnerState.fromMap(doc.data()!);
}
}