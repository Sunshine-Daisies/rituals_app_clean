// Ritual Sharing & Partner Models for Gamification Sprint 3

/// Represents a shared ritual with partner information
class SharedRitual {
  final String ritualId;
  final String ritualTitle;
  final String? ritualDescription;
  final String ownerId;
  final String ownerUsername;
  final int? ownerLevel;
  final String? partnerId;
  final String? partnerUsername;
  final String? inviteCode;
  final String visibility; // 'private' | 'friends_only' | 'public'
  final int partnerStreak;
  final int longestStreak;
  final DateTime? partnerAcceptedAt;
  final DateTime? joinedAt;
  final String status; // 'pending' | 'accepted' | 'rejected' | 'left'
  final DateTime createdAt;
  final String? time;
  final List<String>? days;

  SharedRitual({
    required this.ritualId,
    required this.ritualTitle,
    this.ritualDescription,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerLevel,
    this.partnerId,
    this.partnerUsername,
    this.inviteCode,
    required this.visibility,
    required this.partnerStreak,
    this.longestStreak = 0,
    this.partnerAcceptedAt,
    this.joinedAt,
    required this.status,
    required this.createdAt,
    this.time,
    this.days,
  });

  factory SharedRitual.fromJson(Map<String, dynamic> json) {
    // Parse days - can be string array or JSON string
    List<String>? parsedDays;
    if (json['days'] != null) {
      if (json['days'] is List) {
        parsedDays = (json['days'] as List).map((e) => e.toString()).toList();
      } else if (json['days'] is String) {
        try {
          final decoded = json['days'];
          if (decoded.startsWith('[')) {
            parsedDays = (decoded as String).replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',').map((e) => e.trim()).toList();
          }
        } catch (_) {}
      }
    }

    return SharedRitual(
      ritualId: (json['ritual_id'] ?? json['ritualId'] ?? '').toString(),
      ritualTitle: json['ritual_name'] ?? json['ritual_title'] ?? json['ritualTitle'] ?? json['name'] ?? json['title'] ?? '',
      ritualDescription: json['ritual_description'] ?? json['ritualDescription'] ?? json['description'],
      ownerId: (json['owner_id'] ?? json['ownerId'] ?? '').toString(),
      ownerUsername: json['owner_username'] ?? json['ownerUsername'] ?? '',
      ownerLevel: json['owner_level'] ?? json['ownerLevel'],
      partnerId: json['partner_id']?.toString() ?? json['partnerId']?.toString(),
      partnerUsername: json['partner_username'] ?? json['partnerUsername'],
      inviteCode: json['invite_code'] ?? json['inviteCode'],
      visibility: json['visibility'] ?? 'private',
      partnerStreak: json['current_streak'] ?? json['partner_streak'] ?? json['partnerStreak'] ?? 0,
      longestStreak: json['longest_streak'] ?? json['longestStreak'] ?? 0,
      partnerAcceptedAt: json['partner_accepted_at'] != null 
          ? DateTime.parse(json['partner_accepted_at']) 
          : json['partnerAcceptedAt'] != null 
              ? DateTime.parse(json['partnerAcceptedAt'])
              : null,
      joinedAt: json['joined_at'] != null 
          ? DateTime.parse(json['joined_at']) 
          : null,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      time: json['time'],
      days: parsedDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ritual_id': ritualId,
      'ritual_title': ritualTitle,
      'ritual_description': ritualDescription,
      'owner_id': ownerId,
      'owner_username': ownerUsername,
      'owner_level': ownerLevel,
      'partner_id': partnerId,
      'partner_username': partnerUsername,
      'invite_code': inviteCode,
      'visibility': visibility,
      'current_streak': partnerStreak,
      'longest_streak': longestStreak,
      'partner_accepted_at': partnerAcceptedAt?.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'time': time,
      'days': days,
    };
  }

  bool get hasPartner => partnerId != null;
  bool get isActive => status == 'accepted';
  bool get isPending => status == 'pending';
}

/// Represents partner information for a ritual
class RitualPartner {
  final String partnerId;
  final String partnerUsername;
  final String? partnerAvatarUrl;
  final int partnerStreak;
  final DateTime? acceptedAt;
  final String status;
  final bool isOwner;

  RitualPartner({
    required this.partnerId,
    required this.partnerUsername,
    this.partnerAvatarUrl,
    required this.partnerStreak,
    this.acceptedAt,
    required this.status,
    required this.isOwner,
  });

  factory RitualPartner.fromJson(Map<String, dynamic> json) {
    return RitualPartner(
      partnerId: json['partner_id'] ?? json['partnerId'] ?? '',
      partnerUsername: json['partner_username'] ?? json['partnerUsername'] ?? json['username'] ?? '',
      partnerAvatarUrl: json['partner_avatar_url'] ?? json['partnerAvatarUrl'] ?? json['avatar_url'],
      partnerStreak: json['partner_streak'] ?? json['partnerStreak'] ?? 0,
      acceptedAt: json['accepted_at'] != null 
          ? DateTime.parse(json['accepted_at']) 
          : json['acceptedAt'] != null
              ? DateTime.parse(json['acceptedAt'])
              : null,
      status: json['status'] ?? 'pending',
      isOwner: json['is_owner'] ?? json['isOwner'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_id': partnerId,
      'partner_username': partnerUsername,
      'partner_avatar_url': partnerAvatarUrl,
      'partner_streak': partnerStreak,
      'accepted_at': acceptedAt?.toIso8601String(),
      'status': status,
      'is_owner': isOwner,
    };
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
}

/// Partner request - pending partnership invitations
class PartnerRequest {
  final String id;
  final String ritualId;
  final String ritualTitle;
  final String ownerId;
  final String ownerUsername;
  final String? ownerAvatarUrl;
  final DateTime requestedAt;

  PartnerRequest({
    required this.id,
    required this.ritualId,
    required this.ritualTitle,
    required this.ownerId,
    required this.ownerUsername,
    this.ownerAvatarUrl,
    required this.requestedAt,
  });

  factory PartnerRequest.fromJson(Map<String, dynamic> json) {
    return PartnerRequest(
      id: json['id'] ?? '',
      ritualId: json['ritual_id'] ?? json['ritualId'] ?? '',
      ritualTitle: json['ritual_title'] ?? json['ritualTitle'] ?? '',
      ownerId: json['owner_id'] ?? json['ownerId'] ?? '',
      ownerUsername: json['owner_username'] ?? json['ownerUsername'] ?? '',
      ownerAvatarUrl: json['owner_avatar_url'] ?? json['ownerAvatarUrl'],
      requestedAt: json['requested_at'] != null 
          ? DateTime.parse(json['requested_at'])
          : json['requestedAt'] != null
              ? DateTime.parse(json['requestedAt'])
              : DateTime.now(),
    );
  }
}

/// Share result after sharing a ritual
class ShareResult {
  final String inviteCode;
  final String message;
  final String ritualId;

  ShareResult({
    required this.inviteCode,
    required this.message,
    required this.ritualId,
  });

  factory ShareResult.fromJson(Map<String, dynamic> json) {
    return ShareResult(
      inviteCode: json['inviteCode'] ?? json['invite_code'] ?? '',
      message: json['message'] ?? '',
      ritualId: json['ritual_id'] ?? json['ritualId'] ?? '',
    );
  }
}

/// Join result after joining a ritual with invite code
class JoinResult {
  final String message;
  final String ritualId;
  final String ritualTitle;
  final String ownerUsername;
  final String status;

  JoinResult({
    required this.message,
    required this.ritualId,
    required this.ritualTitle,
    required this.ownerUsername,
    required this.status,
  });

  factory JoinResult.fromJson(Map<String, dynamic> json) {
    return JoinResult(
      message: json['message'] ?? '',
      ritualId: json['ritual_id'] ?? json['ritualId'] ?? '',
      ritualTitle: json['ritual_title'] ?? json['ritualTitle'] ?? '',
      ownerUsername: json['owner_username'] ?? json['ownerUsername'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

/// Visibility options for rituals
enum RitualVisibility {
  private_,
  friendsOnly,
  public_;

  String get value {
    switch (this) {
      case RitualVisibility.private_:
        return 'private';
      case RitualVisibility.friendsOnly:
        return 'friends_only';
      case RitualVisibility.public_:
        return 'public';
    }
  }

  String get displayName {
    switch (this) {
      case RitualVisibility.private_:
        return 'Özel';
      case RitualVisibility.friendsOnly:
        return 'Sadece Arkadaşlar';
      case RitualVisibility.public_:
        return 'Herkese Açık';
    }
  }

  String get description {
    switch (this) {
      case RitualVisibility.private_:
        return 'Sadece sen görebilirsin';
      case RitualVisibility.friendsOnly:
        return 'Arkadaşların görebilir';
      case RitualVisibility.public_:
        return 'Herkes görebilir ve katılabilir';
    }
  }

  static RitualVisibility fromString(String value) {
    switch (value) {
      case 'private':
        return RitualVisibility.private_;
      case 'friends_only':
        return RitualVisibility.friendsOnly;
      case 'public':
        return RitualVisibility.public_;
      default:
        return RitualVisibility.private_;
    }
  }
}
