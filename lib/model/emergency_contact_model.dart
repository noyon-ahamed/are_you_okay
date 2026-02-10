class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship; // Renamed from relation to match usage
  final int priority;
  final bool isActive;
  final bool notifyViaSMS;
  final bool notifyViaCall;
  final bool notifyViaApp;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    required this.priority,
    this.isActive = true,
    this.notifyViaSMS = true,
    this.notifyViaCall = true,
    this.notifyViaApp = true,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      relationship: json['relationship'] ?? json['relation'] ?? 'Other',
      priority: json['priority'],
      isActive: json['isActive'] ?? true,
      notifyViaSMS: json['notifyViaSMS'] ?? true,
      notifyViaCall: json['notifyViaCall'] ?? true,
      notifyViaApp: json['notifyViaApp'] ?? true,
    );
  }

  EmergencyContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    int? priority,
    bool? isActive,
    bool? notifyViaSMS,
    bool? notifyViaCall,
    bool? notifyViaApp,
    DateTime? updatedAt, // Ignored but kept for compatibility if needed elsewhere
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      notifyViaSMS: notifyViaSMS ?? this.notifyViaSMS,
      notifyViaCall: notifyViaCall ?? this.notifyViaCall,
      notifyViaApp: notifyViaApp ?? this.notifyViaApp,
    );
  }

  // Getter for backward compatibility if needed, though strictly we changed the field
  String get relation => relationship;
}
