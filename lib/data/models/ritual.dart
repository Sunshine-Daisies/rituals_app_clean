import 'package:equatable/equatable.dart';

/// Partner bilgisi - ritüele katılan partner
class RitualPartnerInfo extends Equatable {
  final String id;
  final String oderId;
  final String username;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final DateTime? joinedAt;

  const RitualPartnerInfo({
    required this.id,
    required this.oderId,
    required this.username,
    required this.level,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.joinedAt,
  });

  factory RitualPartnerInfo.fromJson(Map<String, dynamic> json) {
    return RitualPartnerInfo(
      id: (json['id'] ?? '').toString(),
      oderId: (json['user_id'] ?? '').toString(),
      username: json['username'] ?? '',
      level: json['level'] ?? 1,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at']) : null,
    );
  }

  @override
  List<Object?> get props => [id, oderId, username];
}

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
  final int? partnershipId;
  final String? partnerRitualId;
  final bool isMine;
  // Streak bilgileri
  final int currentStreak;
  final int longestStreak;
  // Partner bilgileri
  final bool hasPartner;
  final String? inviteCode;
  final String? sharedRitualId;
  final RitualPartnerInfo? partner;

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
    this.partnershipId,
    this.partnerRitualId,
    this.isMine = true,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.hasPartner = false,
    this.inviteCode,
    this.sharedRitualId,
    this.partner,
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
      partnershipId: json['partnership_id'],
      partnerRitualId: json['partner_ritual_id']?.toString(),
      isMine: json['is_mine'] ?? true,
      // Streak bilgileri
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      // Partner bilgileri
      hasPartner: json['has_partner'] == true || json['partnership_id'] != null,
      inviteCode: json['invite_code'],
      sharedRitualId: json['shared_ritual_id']?.toString(),
      partner: json['partner'] != null 
          ? RitualPartnerInfo.fromJson(json['partner'] as Map<String, dynamic>)
          : null,
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
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'has_partner': hasPartner,
      'invite_code': inviteCode,
      'shared_ritual_id': sharedRitualId,
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
    int? partnershipId,
    String? partnerRitualId,
    bool? isMine,
    int? currentStreak,
    int? longestStreak,
    bool? hasPartner,
    String? inviteCode,
    String? sharedRitualId,
    RitualPartnerInfo? partner,
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
      partnershipId: partnershipId ?? this.partnershipId,
      partnerRitualId: partnerRitualId ?? this.partnerRitualId,
      isMine: isMine ?? this.isMine,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      hasPartner: hasPartner ?? this.hasPartner,
      inviteCode: inviteCode ?? this.inviteCode,
      sharedRitualId: sharedRitualId ?? this.sharedRitualId,
      partner: partner ?? this.partner,
    );
  }

  @override
  List<Object?> get props => [id, profileId, name, steps, reminderTime, reminderDays, timezone, isActive, archivedAt, createdAt, updatedAt, partnershipId, partnerRitualId, isMine, currentStreak, longestStreak, hasPartner, partner];
}