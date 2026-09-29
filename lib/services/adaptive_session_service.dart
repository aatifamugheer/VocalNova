import '../models/recommendation.dart';
import 'adaptive_motivation_engine.dart';
import 'engagement_service.dart';

class AdaptiveSessionService {
  final EngagementService _engagementService;
  final AdaptiveMotivationEngine _motivationEngine;

  AdaptiveSessionService({
    EngagementService? engagementService,
    AdaptiveMotivationEngine? motivationEngine,
  })  : _engagementService = engagementService ?? EngagementService(),
        _motivationEngine =
            motivationEngine ?? AdaptiveMotivationEngine();

  Recommendation generateRecommendation({
    required String childId,
    required double speechScore,
    required List<String> interests,
    required String currentDifficulty,
    required double completionRate,
    required double voluntaryRetryRate,
    required double timeOnTaskRate,
    required double returnFrequencyRate,
  }) {
    final engagementScore =
        _engagementService.calculateEngagementScore(
      completionRate: completionRate,
      voluntaryRetryRate: voluntaryRetryRate,
      timeOnTaskRate: timeOnTaskRate,
      returnFrequencyRate: returnFrequencyRate,
    );

    return _motivationEngine.generateRecommendation(
      childId: childId,
      speechScore: speechScore,
      engagementScore: engagementScore,
      interests: interests,
      currentDifficulty: currentDifficulty,
    );
  }
}