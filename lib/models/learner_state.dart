class LearnerState {
  final String childId;
  final String target;
  final List<double> recentScores;
  final int totalAttempts;
  final int successfulAttempts;
  final int currentDifficulty;
  final int engagementScore;
  final String preferredTheme;

  const LearnerState({
    required this.childId,
    required this.target,
    this.recentScores = const [],
    this.totalAttempts = 0,
    this.successfulAttempts = 0,
    this.currentDifficulty = 2,
    this.engagementScore = 50,
    this.preferredTheme = 'GENERAL',
  });

  double get averageScore {
    if (recentScores.isEmpty) return 0;

    final total =
        recentScores.reduce((a, b) => a + b);

    return total / recentScores.length;
  }

  double get improvementTrend {
    if (recentScores.length < 2) return 0;

    final first = recentScores.first;
    final last = recentScores.last;

    return last - first;
  }

  double get successRate {
    if (totalAttempts == 0) return 0;

    return (successfulAttempts / totalAttempts) * 100;
  }

  LearnerState addAttempt({
    required double score,
    required bool successful,
    int? engagement,
  }) {
    final updatedScores =
        [...recentScores, score];

    // Keep only the most recent 5 attempts.
    if (updatedScores.length > 5) {
      updatedScores.removeAt(0);
    }

    return LearnerState(
      childId: childId,
      target: target,
      recentScores: updatedScores,
      totalAttempts: totalAttempts + 1,
      successfulAttempts:
          successfulAttempts + (successful ? 1 : 0),
      currentDifficulty: currentDifficulty,
      engagementScore:
          engagement ?? engagementScore,
      preferredTheme: preferredTheme,
    );
  }

  LearnerState copyWith({
    String? target,
    List<double>? recentScores,
    int? totalAttempts,
    int? successfulAttempts,
    int? currentDifficulty,
    int? engagementScore,
    String? preferredTheme,
  }) {
    return LearnerState(
      childId: childId,
      target: target ?? this.target,
      recentScores:
          recentScores ?? this.recentScores,
      totalAttempts:
          totalAttempts ?? this.totalAttempts,
      successfulAttempts:
          successfulAttempts ??
          this.successfulAttempts,
      currentDifficulty:
          currentDifficulty ??
          this.currentDifficulty,
      engagementScore:
          engagementScore ??
          this.engagementScore,
      preferredTheme:
          preferredTheme ??
          this.preferredTheme,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'target': target,
      'recentScores': recentScores,
      'totalAttempts': totalAttempts,
      'successfulAttempts':
          successfulAttempts,
      'currentDifficulty':
          currentDifficulty,
      'engagementScore':
          engagementScore,
      'preferredTheme':
          preferredTheme,
    };
  }

  factory LearnerState.fromMap(
    Map<String, dynamic> map,
  ) {
    return LearnerState(
      childId:
          map['childId'] as String? ?? '',
      target:
          map['target'] as String? ?? '',
      recentScores:
          (map['recentScores'] as List?)
                  ?.map(
                    (value) =>
                        (value as num).toDouble(),
                  )
                  .toList() ??
              const [],
      totalAttempts:
          (map['totalAttempts'] as num?)
                  ?.toInt() ??
              0,
      successfulAttempts:
          (map['successfulAttempts']
                      as num?)
                  ?.toInt() ??
              0,
      currentDifficulty:
          (map['currentDifficulty'] as num?)
                  ?.toInt() ??
              2,
      engagementScore:
          (map['engagementScore'] as num?)
                  ?.toInt() ??
              50,
      preferredTheme:
          map['preferredTheme'] as String? ??
              'GENERAL',
    );
  }
}