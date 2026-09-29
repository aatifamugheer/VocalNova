import 'package:flutter_test/flutter_test.dart';
import 'package:vocalnova/services/adaptive_motivation_engine.dart';

void main() {
  group('AdaptiveMotivationEngine', () {
    late AdaptiveMotivationEngine engine;

    setUp(() {
      engine = AdaptiveMotivationEngine();
    });

    test('low speech score makes activity easier', () {
      final recommendation = engine.generateRecommendation(
        childId: 'child001',
        speechScore: 35,
        engagementScore: 70,
        interests: ['dinosaurs'],
        currentDifficulty: 'MEDIUM',
      );

      expect(recommendation.difficulty, 'EASY');
      expect(recommendation.sessionItems, 3);
      expect(recommendation.nextActivity, 'MODELED_WORD');
      expect(recommendation.theme, 'DINOSAURS');
    });

    test('low engagement shortens the mission', () {
      final recommendation = engine.generateRecommendation(
        childId: 'child001',
        speechScore: 75,
        engagementScore: 30,
        interests: ['animals'],
        currentDifficulty: 'MEDIUM',
      );

      expect(recommendation.sessionItems, 3);
      expect(recommendation.theme, 'ANIMALS');
    });

    test('high speech and engagement increase challenge', () {
      final recommendation = engine.generateRecommendation(
        childId: 'child001',
        speechScore: 92,
        engagementScore: 90,
        interests: ['space'],
        currentDifficulty: 'MEDIUM',
      );

      expect(recommendation.difficulty, 'HARD');
      expect(recommendation.sessionItems, 6);
      expect(recommendation.nextActivity, 'PHRASE_PRACTICE');
      expect(recommendation.theme, 'SPACE');
    });
  });
}