import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_profile.dart';

class GamificationService {
  static const String _baseUrl = 'http://10.0.2.2:3000/api';
  
  // Token'ı al
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Header'lar
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // PROFILE
  // ============================================

  /// Kendi profilini getir
  Future<UserProfile?> getMyProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  /// Başka kullanıcının profilini getir
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/profile/$userId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Kullanıcı adını güncelle
  Future<bool> updateUsername(String newUsername) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/profile/username'),
        headers: await _getHeaders(),
        body: json.encode({'username': newUsername}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating username: $e');
      return false;
    }
  }

  // ============================================
  // LEADERBOARD
  // ============================================

  /// Leaderboard getir
  Future<LeaderboardResult?> getLeaderboard({
    String type = 'global', // global, friends, weekly
    int limit = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/leaderboard?type=$type&limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return LeaderboardResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting leaderboard: $e');
      return null;
    }
  }

  // ============================================
  // BADGES
  // ============================================

  /// Tüm badge'leri getir (earned durumu ile)
  Future<List<Badge>> getAllBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/badges'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((b) => Badge.fromJson(b)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }

  /// Kazanılan badge'leri getir
  Future<List<Badge>> getMyBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/badges/my'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((b) => Badge.fromJson(b)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting my badges: $e');
      return [];
    }
  }

  /// Badge ilerleme durumunu getir
  Future<BadgeProgressResult?> getBadgeProgress() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/badges/progress'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BadgeProgressResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting badge progress: $e');
      return null;
    }
  }

  /// Badge kontrolü yap (yeni badge kazanma)
  Future<BadgeCheckResult?> checkBadges() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/badges/check'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BadgeCheckResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error checking badges: $e');
      return null;
    }
  }

  // ============================================
  // FREEZE
  // ============================================

  /// Freeze kullan
  Future<FreezeResult?> useFreeze({int? ritualPartnerId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/freeze/use'),
        headers: await _getHeaders(),
        body: json.encode({
          if (ritualPartnerId != null) 'ritualPartnerId': ritualPartnerId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FreezeResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error using freeze: $e');
      return null;
    }
  }

  /// Freeze satın al
  Future<FreezeBuyResult?> buyFreeze() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/freeze/buy'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FreezeBuyResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error buying freeze: $e');
      return null;
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Bildirimleri getir
  Future<NotificationResult?> getNotifications({
    int limit = 50,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/notifications?limit=$limit&unreadOnly=$unreadOnly'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting notifications: $e');
      return null;
    }
  }

  /// Bildirimi okundu işaretle
  Future<bool> markNotificationRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/$notificationId/read'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification read: $e');
      return false;
    }
  }

  /// Tüm bildirimleri okundu işaretle
  Future<bool> markAllNotificationsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/notifications/read-all'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking all notifications read: $e');
      return false;
    }
  }

  /// Bildirimi sil
  Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/notifications/$notificationId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting notification: $e');
      return false;
    }
  }

  // ============================================
  // USER SEARCH
  // ============================================

  /// Kullanıcı ara
  Future<List<Friendship>> searchUsers(String query, {int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/search?q=$query&limit=$limit'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((u) => Friendship.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}

// ============================================
// RESULT CLASSES
// ============================================

class LeaderboardResult {
  final List<LeaderboardEntry> leaderboard;
  final int? myRank;

  LeaderboardResult({required this.leaderboard, this.myRank});

  factory LeaderboardResult.fromJson(Map<String, dynamic> json) {
    return LeaderboardResult(
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList(),
      myRank: json['myRank'],
    );
  }
}

class FreezeResult {
  final bool success;
  final String message;
  final int streakSaved;

  FreezeResult({
    required this.success,
    required this.message,
    required this.streakSaved,
  });

  factory FreezeResult.fromJson(Map<String, dynamic> json) {
    return FreezeResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      streakSaved: json['streakSaved'] ?? 0,
    );
  }
}

class FreezeBuyResult {
  final bool success;
  final String message;
  final int newFreezeCount;
  final int newCoinBalance;

  FreezeBuyResult({
    required this.success,
    required this.message,
    required this.newFreezeCount,
    required this.newCoinBalance,
  });

  factory FreezeBuyResult.fromJson(Map<String, dynamic> json) {
    return FreezeBuyResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      newFreezeCount: json['newFreezeCount'] ?? 0,
      newCoinBalance: json['newCoinBalance'] ?? 0,
    );
  }
}

class NotificationResult {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationResult({required this.notifications, required this.unreadCount});

  factory NotificationResult.fromJson(Map<String, dynamic> json) {
    return NotificationResult(
      notifications: (json['notifications'] as List<dynamic>)
          .map((n) => AppNotification.fromJson(n))
          .toList(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

// ============================================
// BADGE PROGRESS CLASSES
// ============================================

class BadgeProgressResult {
  final List<BadgeProgress> badges;

  BadgeProgressResult({required this.badges});

  factory BadgeProgressResult.fromJson(Map<String, dynamic> json) {
    final progressData = json['progress'] as Map<String, dynamic>?;
    final badgesList = progressData?['badges'] as List<dynamic>? ?? [];
    
    return BadgeProgressResult(
      badges: badgesList.map((b) => BadgeProgress.fromJson(b)).toList(),
    );
  }
}

class BadgeProgress {
  final String badgeKey;
  final String name;
  final String description;
  final String icon;
  final bool earned;
  final DateTime? earnedAt;
  final int progress;
  final int target;
  final int percentage;

  BadgeProgress({
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.icon,
    required this.earned,
    this.earnedAt,
    required this.progress,
    required this.target,
    required this.percentage,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    return BadgeProgress(
      badgeKey: json['badge_key'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      earned: json['earned'] ?? false,
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at']) 
          : null,
      progress: json['progress'] ?? 0,
      target: json['target'] ?? 1,
      percentage: json['percentage'] ?? 0,
    );
  }
}

class BadgeCheckResult {
  final bool success;
  final List<NewBadge> newBadges;
  final String message;

  BadgeCheckResult({
    required this.success,
    required this.newBadges,
    required this.message,
  });

  factory BadgeCheckResult.fromJson(Map<String, dynamic> json) {
    return BadgeCheckResult(
      success: json['success'] ?? false,
      newBadges: (json['newBadges'] as List<dynamic>? ?? [])
          .map((b) => NewBadge.fromJson(b))
          .toList(),
      message: json['message'] ?? '',
    );
  }
}

class NewBadge {
  final String code;
  final String name;
  final int xp;
  final int coins;

  NewBadge({
    required this.code,
    required this.name,
    required this.xp,
    required this.coins,
  });

  factory NewBadge.fromJson(Map<String, dynamic> json) {
    return NewBadge(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 0,
    );
  }
}
