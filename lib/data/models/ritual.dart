import 'package:equatable/equatable.dart';

class Ritual extends Equatable {
  final String id;
  final String profileId; // Changed from userId to match DB
  final String name;
  final List<Map<String, dynamic>> steps; // Added steps as jsonb
  final String reminderTime; // Changed from time to match DB
  final List<String> reminderDays; // Changed from days to match DB
  final String? timezone; // Added timezone field
  final bool isActive;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ritual({
    required this.id,
    required this.profileId,
    required this.name,
    required this.steps,
    required this.reminderTime,
    required this.reminderDays,
    this.timezone,
    this.isActive = true,
    this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ritual.fromJson(Map<String, dynamic> json) {
    return Ritual(
      id: json['id'].toString(), // Safe conversion for UUID
      profileId: json['profile_id'].toString(), // Safe conversion for UUID
      name: json['name'] as String,
      steps: List<Map<String, dynamic>>.from(json['steps'] as List? ?? []),
      reminderTime: json['reminder_time'] as String,
      reminderDays: List<String>.from(json['reminder_days'] as List? ?? []),
      timezone: json['timezone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'steps': steps,
      'reminder_time': reminderTime,
      'reminder_days': reminderDays,
      'timezone': timezone,
      'is_active': isActive,
      'archived_at': archivedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Ritual copyWith({
    String? id,
    String? profileId,
    String? name,
    List<Map<String, dynamic>>? steps,
    String? reminderTime,
    List<String>? reminderDays,
    String? timezone,
    bool? isActive,
    DateTime? archivedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ritual(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      steps: steps ?? this.steps,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      timezone: timezone ?? this.timezone,
      isActive: isActive ?? this.isActive,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, profileId, name, steps, reminderTime, reminderDays, timezone, isActive, archivedAt, createdAt, updatedAt];
}