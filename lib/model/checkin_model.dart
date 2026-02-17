class CheckInModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String method;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.method,
    this.notes,
    this.isSynced = false,
    required this.createdAt,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      method: json['method'],
      notes: json['notes'],
      isSynced: json['isSynced'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  CheckInModel copyWith({
    String? id,
    String? userId,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    String? method,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return CheckInModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'method': method,
      'notes': notes,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
