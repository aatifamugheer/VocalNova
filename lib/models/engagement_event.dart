class EngagementEvent {
  final String eventId;
  final String childId;
  final String type;
  final DateTime timestamp;
  final int value;

  const EngagementEvent({
    required this.eventId,
    required this.childId,
    required this.type,
    required this.timestamp,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'childId': childId,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'value': value,
    };
  }

  factory EngagementEvent.fromMap(Map<String, dynamic> map) {
    return EngagementEvent(
      eventId: map['eventId'] as String,
      childId: map['childId'] as String,
      type: map['type'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      value: (map['value'] as num).toInt(),
    );
  }
}