
class AttendanceEventModel {
  final String eventId;
  final String eventType;
  final String timestamp;
  final double latitude;
  final double longitude;

  AttendanceEventModel({
    required this.eventId,
    required this.eventType,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'eventType': eventType,
      'timestamp': timestamp,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
