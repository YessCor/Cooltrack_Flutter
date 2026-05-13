class TechnicianLocation {
  final String id;
  final String technicianId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final DateTime recordedAt;

  TechnicianLocation({
    required this.id,
    required this.technicianId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    required this.recordedAt,
  });

  factory TechnicianLocation.fromJson(Map<String, dynamic> json) {
    return TechnicianLocation(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'technician_id': technicianId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}