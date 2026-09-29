class ChildProfile {
  final String childId;
  final String displayName;
  final String ageBand;
  final List<String> interests;
  final List<String> targetSounds;
  final List<String> targetWords;

  const ChildProfile({
    required this.childId,
    required this.displayName,
    required this.ageBand,
    required this.interests,
    required this.targetSounds,
    required this.targetWords,
  });

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'displayName': displayName,
      'ageBand': ageBand,
      'interests': interests,
      'targetSounds': targetSounds,
      'targetWords': targetWords,
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      childId: map['childId'] as String,
      displayName: map['displayName'] as String,
      ageBand: map['ageBand'] as String,
      interests: List<String>.from(
        map['interests'] ?? const [],
      ),
      targetSounds: List<String>.from(
        map['targetSounds'] ?? const [],
      ),
      targetWords: List<String>.from(
        map['targetWords'] ?? const [],
      ),
    );
  }
}