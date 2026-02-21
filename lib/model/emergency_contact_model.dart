class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final String relationship;
  final String userId;
  final int priority;
  final bool isActive;
  final bool notifyViaSMS;
  final bool notifyViaCall;
  final bool notifyViaEmail;
  final bool notifyViaApp;
  final DateTime? createdAt;
  final DateTime? updatedAt; // ← this was missing in your file

  EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    this.email,
    required this.relationship,
    required this.priority,
    this.isActive = true,
    this.notifyViaSMS = true,
    this.notifyViaCall = true,
    this.notifyViaEmail = true,
    this.notifyViaApp = true,
    this.createdAt,
    this.updatedAt, // ← this was missing in your file
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'],
      userId: json['userId'] ?? '',
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      relationship: json['relationship'] ?? json['relation'] ?? 'Other',
      priority: json['priority'],
      isActive: json['isActive'] ?? true,
      notifyViaSMS: json['notifyViaSMS'] ?? true,
      notifyViaCall: json['notifyViaCall'] ?? true,
      notifyViaEmail: json['notifyViaEmail'] ?? true,
      notifyViaApp: json['notifyViaApp'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null, // ← this was missing
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'relationship': relationship,
      'priority': priority,
      'isActive': isActive,
      'notifyViaSMS': notifyViaSMS,
      'notifyViaCall': notifyViaCall,
      'notifyViaEmail': notifyViaEmail,
      'notifyViaApp': notifyViaApp,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(), // ← this was missing
    };
  }

  EmergencyContactModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? email,
    String? relationship,
    int? priority,
    bool? isActive,
    bool? notifyViaSMS,
    bool? notifyViaCall,
    bool? notifyViaEmail,
    bool? notifyViaApp,
    DateTime? createdAt,
    DateTime? updatedAt, // ← this was missing
  }) {
    return EmergencyContactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      notifyViaSMS: notifyViaSMS ?? this.notifyViaSMS,
      notifyViaCall: notifyViaCall ?? this.notifyViaCall,
      notifyViaEmail: notifyViaEmail ?? this.notifyViaEmail,
      notifyViaApp: notifyViaApp ?? this.notifyViaApp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // ← this was missing
    );
  }

  String get relation => relationship;
}