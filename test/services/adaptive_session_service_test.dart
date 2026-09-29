import 'package:flutter_test/flutter_test.dart';
import 'package:vocalnova/services/adaptive_session_service.dart';

void main() {
  group('AdaptiveSessionService', () {
    late AdaptiveSessionService service;

    setUp(() {
      service = AdaptiveSessionService();
    });

    test('combines speech and engagement to create an adaptive recommendation', () {
      final recommendation = service.generateRecommendation(
        childId: 'child001',
        speechScore: 35,
        interests: ['dinosaurs'],
        currentDifficulty: 'MEDIUM',
        completionRate: 80,
        voluntaryRetryRate: 60,
        timeOnTaskRate: 70,
        returnFrequencyRate: 50,
      );

      expect(recommendation.childId, 'child001');
      expect(recommendation.theme, 'DINOSAURS');
      expect(recommendation.difficulty, 'EASY');
      expect(recommendation.sessionItems, 3);
      expect(recommendation.nextActivity, 'MODELED_WORD');
    });

    test('high performance and engagement increase the challenge', () {
      final recommendation = service.generateRecommendation(
        childId: 'child002',
        speechScore: 92,
        interests: ['animals'],
        currentDifficulty: 'MEDIUM',
        completionRate: 100,
        voluntaryRetryRate: 100,
        timeOnTaskRate: 100,
        returnFrequencyRate: 100,
      );

      expect(recommendation.childId, 'child002');
      expect(recommendation.theme, 'ANIMALS');
      expect(recommendation.difficulty, 'HARD');
      expect(recommendation.sessionItems, 6);
      expect(recommendation.nextActivity, 'PHRASE_PRACTICE');
    });
  });
}