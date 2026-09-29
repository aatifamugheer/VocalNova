import 'package:flutter_test/flutter_test.dart';
import 'package:vocalnova/services/engagement_service.dart';

void main() {
  group('EngagementService', () {
    late EngagementService service;

    setUp(() {
      service = EngagementService();
    });

    test('calculates weighted engagement score correctly', () {
      final score = service.calculateEngagementScore(
        completionRate: 80,
        voluntaryRetryRate: 60,
        timeOnTaskRate: 70,
        returnFrequencyRate: 50,
      );

      expect(score, 69);
    });

    test('does not exceed 100', () {
      final score = service.calculateEngagementScore(
        completionRate: 100,
        voluntaryRetryRate: 100,
        timeOnTaskRate: 100,
        returnFrequencyRate: 100,
      );

      expect(score, 100);
    });

    test('does not go below 0', () {
      final score = service.calculateEngagementScore(
        completionRate: 0,
        voluntaryRetryRate: 0,
        timeOnTaskRate: 0,
        returnFrequencyRate: 0,
      );

      expect(score, 0);
    });
  });
}