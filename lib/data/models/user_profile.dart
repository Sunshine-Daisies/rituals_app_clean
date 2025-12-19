import 'package:equatable/equatable.dart';

class Badge extends Equatable {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final int xpReward;
  final int coinReward;
  final String? requirementType;
  final int? requirementValue;
  final bool earned;
  final DateTime? earnedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.xpReward,
    required this.coinReward,
    this.requirementType,
    this.requirementValue,
    this.earned = false,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: json['category'] ?? 'milestone',
      xpReward: json['xp_reward'] ?? 0,
      coinReward: json['coin_reward'] ?? 0,
      requirementType: json['requirement_type'],
      requirementValue: json['requirement_value'],
      earned: json['earned'] ?? false,
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'xp_reward': xpReward,
      'coin_reward': coinReward,
      'requirement_type': requirementType,
      'requirement_value': requirementValue,
      'earned': earned,
      'earned_at': earnedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, category, earned];
}

class UserProfile extends Equatable {
  final int id;
  final String userId;
  final String username;
  final int xp;
  final int level;
  final String levelTitle;
  final int coins;
  final int freezeCount;
  final int totalFreezesUsed;
  final int longestStreak;
  final int xpForNextLevel;
  final int xpProgressPercent;
  final int friendsCount;
  final int ritualsCount;
  final int completionsCount;
  final String? email;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPremium;
  final List<Badge> badges;

  const UserProfile({
    required this.id,
    required this.userId,
    required this.username,
    required this.xp,
    required this.level,
    required this.levelTitle,
    required this.coins,
    required this.freezeCount,
    required this.totalFreezesUsed,
    required this.longestStreak,
    required this.xpForNextLevel,
    required this.xpProgressPercent,
    required this.friendsCount,
    required this.ritualsCount,
    required this.completionsCount,
    this.email,
    this.name,
    required this.createdAt,
    required this.updatedAt,
    this.isPremium = false,
    this.badges = const [],
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      levelTitle: json['level_title'] ?? '🌱 Tohum',
      coins: json['coins'] ?? 0,
      freezeCount: json['freeze_count'] ?? 0,
      totalFreezesUsed: json['total_freezes_used'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      xpForNextLevel: json['xp_for_next_level'] ?? 100,
      xpProgressPercent: json['xp_progress_percent'] ?? 0,
      friendsCount: int.tryParse(json['friends_count']?.toString() ?? '0') ?? 0,
      ritualsCount: int.tryParse(json['rituals_count']?.toString() ?? '0') ?? 0,
      completionsCount: int.tryParse(json['completions_count']?.toString() ?? '0') ?? 0,
      email: json['email'],
      name: json['name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isPremium: json['is_premium'] ?? false,
      badges: (json['badges'] as List<dynamic>?)
          ?.map((b) => Badge.fromJson(b))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'xp': xp,
      'level': level,
      'level_title': levelTitle,
      'coins': coins,
      'freeze_count': freezeCount,
      'total_freezes_used': totalFreezesUsed,
      'longest_streak': longestStreak,
      'xp_for_next_level': xpForNextLevel,
      'xp_progress_percent': xpProgressPercent,
      'friends_count': friendsCount,
      'rituals_count': ritualsCount,
      'completions_count': completionsCount,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_premium': isPremium,
      'badges': badges.map((b) => b.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
    id, userId, username, xp, level, coins, freezeCount,
    longestStreak, friendsCount, ritualsCount,
  ];
}

class Friendship extends Equatable {
  final int friendshipId;
  final String userId;
  final String username;
  final int level;
  final int xp;
  final int longestStreak;
  final DateTime? friendsSince;
  final String? friendshipStatus;

  const Friendship({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.level,
    this.xp = 0,
    this.longestStreak = 0,
    this.friendsSince,
    this.friendshipStatus,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendshipId: json['friendship_id'] ?? json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      friendsSince: json['friends_since'] != null 
          ? DateTime.parse(json['friends_since']) 
          : null,
      friendshipStatus: json['friendship_status'],
    );
  }

  @override
  List<Object?> get props => [friendshipId, userId, username];
}

class FriendRequest extends Equatable {
  final int friendshipId;
  final String userId;
  final String username;
  final int level;
  final DateTime requestedAt;

  const FriendRequest({
    required this.friendshipId,
    required this.userId,
    required this.username,
    required this.level,
    required this.requestedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    print('🔍 FriendRequest.fromJson: $json');
    print('🔍 friendship_id value: ${json['friendship_id']}');
    return FriendRequest(
      friendshipId: json['friendship_id'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      level: json['level'] ?? 1,
      requestedAt: json['requested_at'] != null 
          ? DateTime.parse(json['requested_at']) 
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [friendshipId, userId];
}

class AppNotification extends Equatable {
  final int id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: json['data'],
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, type, isRead];
}

class LeaderboardEntry extends Equatable {
  final String userId;
  final String username;
  final int xp;
  final int level;
  final int longestStreak;
  final int rank;
  final int? weeklyXp;

  const LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.xp,
    required this.level,
    this.longestStreak = 0,
    required this.rank,
    this.weeklyXp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      xp: int.tryParse(json['xp']?.toString() ?? '') ?? int.tryParse(json['weekly_xp']?.toString() ?? '') ?? 0,
      level: int.tryParse(json['level']?.toString() ?? '') ?? 1,
      longestStreak: int.tryParse(json['longest_streak']?.toString() ?? '') ?? 0,
      rank: int.tryParse(json['rank']?.toString() ?? '0') ?? 0,
      weeklyXp: int.tryParse(json['weekly_xp']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [userId, username, rank];
}
