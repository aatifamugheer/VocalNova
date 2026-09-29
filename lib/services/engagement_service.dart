import '../models/engagement_event.dart';

class EngagementService {
  /// Calculates a prototype engagement score from 0 to 100.
  ///
  /// This is a product heuristic, not a clinically validated measure.
  double calculateEngagementScore({
    required double completionRate,
    required double voluntaryRetryRate,
    required double timeOnTaskRate,
    required double returnFrequencyRate,
    double skipRate = 0,
    double consistencyRate = 0,
  }) {
    final score =
        (completionRate * 0.30) +
        (voluntaryRetryRate * 0.20) +
        (timeOnTaskRate * 0.15) +
        (returnFrequencyRate * 0.15) +
        (consistencyRate * 0.10) -
        (skipRate * 0.10);

    return score.clamp(0.0, 100.0);
  }

  /// Calculates engagement from recorded child events.
  ///
  /// This is a prototype product heuristic, not a clinically
  /// validated engagement measure.
  double calculateFromEvents(List<EngagementEvent> events) {
    if (events.isEmpty) {
      return 0;
    }

    double completionRate = 0;
    double voluntaryRetryRate = 0;
    double timeOnTaskRate = 0;
    double returnFrequencyRate = 0;
    double skipRate = 0;
    double consistencyRate = 0;

    final completed = events.where(
      (event) => event.type == 'MISSION_COMPLETED',
    );

    final retries = events.where(
      (event) => event.type == 'VOLUNTARY_RETRY',
    );

    final returns = events.where(
      (event) => event.type == 'RETURNED',
    );

    final sessionStarts = events.where(
      (event) => event.type == 'SESSION_STARTED',
    );

    final skips = events.where(
      (event) => event.type == 'SKIP',
    );

    if (sessionStarts.isNotEmpty) {
      final completedCount = completed.length;
      completionRate =
          (completedCount / sessionStarts.length * 100).clamp(0, 100);
    }

    if (events.isNotEmpty) {
      voluntaryRetryRate =
          (retries.length / events.length * 100).clamp(0, 100);

      skipRate =
          (skips.length / events.length * 100).clamp(0, 100);
    }

    final timeEvents = events.where(
      (event) => event.type == 'TIME_ON_TASK',
    );

    if (timeEvents.isNotEmpty) {
      final totalTime = timeEvents.fold<int>(
        0,
        (sum, event) => sum + event.value,
      );

      // Prototype normalization:
      // 300 seconds is treated as 100% time-on-task.
      timeOnTaskRate = (totalTime / 300 * 100).clamp(0, 100);
    }

    if (sessionStarts.isNotEmpty) {
      returnFrequencyRate =
          (returns.length / sessionStarts.length * 100).clamp(0, 100);
    }

    // Consistency is estimated from repeated practice sessions.
    // More sessions indicate more consistent participation.
    final sessionCount = sessionStarts.length;

    if (sessionCount > 0) {
      consistencyRate =
          (sessionCount / 5 * 100).clamp(0, 100);
    }

    return calculateEngagementScore(
      completionRate: completionRate,
      voluntaryRetryRate: voluntaryRetryRate,
      timeOnTaskRate: timeOnTaskRate,
      returnFrequencyRate: returnFrequencyRate,
      skipRate: skipRate,
      consistencyRate: consistencyRate,
    );
  }
}
