import '../models/practice_session.dart';

class PracticeStore {
  static final List<PracticeSession> sessions = [];

  static void addSession(PracticeSession session) {
    sessions.add(session);
  }

  static int get totalSessions => sessions.length;

  static int get totalAttempts {
    return sessions.fold(
      0,
      (total, session) => total + session.attempts,
    );
  }

  static int get totalSuccesses {
    return sessions.fold(
      0,
      (total, session) => total + session.successes,
    );
  }

  static int get totalPracticeSeconds {
    return sessions.fold(
      0,
      (total, session) => total + session.durationSeconds,
    );
  }

  static double get overallSuccessRate {
    if (totalAttempts == 0) return 0;
    return totalSuccesses / totalAttempts;
  }
  
  static PracticeSession? get latestSession {
    if (sessions.isEmpty) return null;
    return sessions.last;
  }
  static int get practiceDaysLast7 {
    final now = DateTime.now();

    final days = sessions.where((session) {
        final difference = now.difference(session.date).inDays;

        return difference >= 0 && difference < 7;
    }).map((session) {
        return DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
        );
    }).toSet();

    return days.length;
    }
}