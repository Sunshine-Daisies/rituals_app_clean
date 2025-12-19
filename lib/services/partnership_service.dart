import 'api_service.dart';

/// Eşit Partner Sistemi Service
/// Her iki taraf da eşit yetkilere sahip
class PartnershipService {
  // ============================================
  // INVITE MANAGEMENT
  // ============================================

  /// Ritüel için davet kodu oluştur
  static Future<InviteResult> createInvite(String ritualId) async {
    try {
      final data = await ApiService.post('/partnerships/invite/$ritualId', {});
      return InviteResult(
        success: true,
        inviteCode: data['inviteCode'],
        inviteId: data['inviteId'],
        expiresAt: data['expiresAt'] != null ? DateTime.parse(data['expiresAt']) : null,
        message: data['message'],
      );
    } catch (e) {
      return InviteResult(success: false, error: e.toString());
    }
  }

  /// Davet kodunu iptal et
  static Future<bool> cancelInvite(int inviteId) async {
    try {
      await ApiService.delete('/partnerships/invite/$inviteId');
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // JOIN PARTNERSHIP
  // ============================================

  /// Davet koduyla partner ol
  static Future<JoinResult> joinWithCode(String code, {String? ritualId}) async {
    try {
      final data = await ApiService.post('/partnerships/join/$code', {
        if (ritualId != null) 'ritualId': ritualId,
      });
      return JoinResult(
        success: true,
        requestId: data['requestId'],
        ritualName: data['ritualName'],
        ownerUsername: data['ownerUsername'],
        yourRitualId: data['yourRitualId'],
        message: data['message'],
      );
    } catch (e) {
      return JoinResult(success: false, error: e.toString());
    }
  }

  // ============================================
  // REQUEST MANAGEMENT
  // ============================================

  /// Bekleyen partner istekleri
  static Future<List<PartnerRequest>> getPendingRequests() async {
    try {
      final data = await ApiService.get('/partnerships/pending');
      if (data is List) {
        return data.map((r) => PartnerRequest.fromJson(r)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Partner isteğini kabul et
  static Future<AcceptResult> acceptRequest(int requestId, {String? partnerRitualId}) async {
    try {
      final data = await ApiService.put('/partnerships/request/$requestId/accept', {
        if (partnerRitualId != null) 'partnerRitualId': partnerRitualId,
      });
      return AcceptResult(
        success: true,
        partnershipId: data['partnershipId'],
        message: data['message'],
      );
    } catch (e) {
      return AcceptResult(success: false, error: e.toString());
    }
  }

  /// Partner isteğini reddet
  static Future<bool> rejectRequest(int requestId) async {
    try {
      await ApiService.put('/partnerships/request/$requestId/reject', {});
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================
  // PARTNERSHIP MANAGEMENT
  // ============================================

  /// Benim partnerlıklarım
  static Future<List<Partnership>> getMyPartnerships() async {
    try {
      final data = await ApiService.get('/partnerships/my');
      if (data is List) {
        return data.map((p) => Partnership.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Belirli ritüelin partnership bilgisi
  static Future<PartnershipInfo?> getPartnershipByRitual(String ritualId) async {
    try {
      final data = await ApiService.get('/partnerships/ritual/$ritualId');
      if (data['hasPartner'] == true) {
        return PartnershipInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Partnerlıktan ayrıl (her iki taraf kendi ritüeline devam eder)
  static Future<LeaveResult> leavePartnership(int partnershipId) async {
    try {
      final data = await ApiService.delete('/partnerships/$partnershipId/leave');
      return LeaveResult(success: true, message: data['message']);
    } catch (e) {
      return LeaveResult(success: false, error: e.toString());
    }
  }

  /// Bugün bu partnership tamamlandı mı kontrol et
  static Future<bool> isCompletedToday(int partnershipId) async {
    try {
      final partnerships = await getMyPartnerships();
      final partnership = partnerships.firstWhere(
        (p) => p.id == partnershipId,
        orElse: () => throw Exception('Partnership not found'),
      );
      
      // lastBothCompletedAt bugün mü kontrol et
      if (partnership.lastBothCompletedAt == null) return false;
      
      final today = DateTime.now();
      final lastCompleted = partnership.lastBothCompletedAt!;
      
      return lastCompleted.year == today.year &&
             lastCompleted.month == today.month &&
             lastCompleted.day == today.day;
    } catch (e) {
      return false;
    }
  }
}

// ============================================
// MODELS
// ============================================

class InviteResult {
  final bool success;
  final String? inviteCode;
  final int? inviteId;
  final DateTime? expiresAt;
  final String? message;
  final String? error;

  InviteResult({
    required this.success,
    this.inviteCode,
    this.inviteId,
    this.expiresAt,
    this.message,
    this.error,
  });
}

class JoinResult {
  final bool success;
  final int? requestId;
  final String? ritualName;
  final String? ownerUsername;
  final String? yourRitualId;
  final String? message;
  final String? error;

  JoinResult({
    required this.success,
    this.requestId,
    this.ritualName,
    this.ownerUsername,
    this.yourRitualId,
    this.message,
    this.error,
  });
}

class PartnerRequest {
  final int id;
  final String ritualName;
  final String requesterUsername;
  final String requesterId;
  final DateTime createdAt;

  PartnerRequest({
    required this.id,
    required this.ritualName,
    required this.requesterUsername,
    required this.requesterId,
    required this.createdAt,
  });

  factory PartnerRequest.fromJson(Map<String, dynamic> json) {
    return PartnerRequest(
      id: json['id'],
      ritualName: json['ritualName'] ?? '',
      requesterUsername: json['requesterUsername'] ?? '',
      requesterId: json['requesterId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AcceptResult {
  final bool success;
  final int? partnershipId;
  final String? message;
  final String? error;

  AcceptResult({
    required this.success,
    this.partnershipId,
    this.message,
    this.error,
  });
}

class Partnership {
  final int id;
  final String myRitualId;
  final String myRitualName;
  final String? myRitualTime;
  final List<String>? myRitualDays;
  final String partnerRitualId;
  final String partnerRitualName;
  final String partnerUserId;
  final String partnerUsername;
  final String? partnerAvatarUrl;
  final int? partnerLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastBothCompletedAt;
  final bool myCompletedToday;
  final bool partnerCompletedToday;
  final DateTime createdAt;

  Partnership({
    required this.id,
    required this.myRitualId,
    required this.myRitualName,
    this.myRitualTime,
    this.myRitualDays,
    required this.partnerRitualId,
    required this.partnerRitualName,
    required this.partnerUserId,
    required this.partnerUsername,
    this.partnerAvatarUrl,
    this.partnerLevel,
    required this.currentStreak,
    required this.longestStreak,
    this.lastBothCompletedAt,
    this.myCompletedToday = false,
    this.partnerCompletedToday = false,
    required this.createdAt,
  });

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      id: json['id'],
      myRitualId: json['myRitualId'] ?? '',
      myRitualName: json['myRitualName'] ?? '',
      myRitualTime: json['myRitualTime'],
      myRitualDays: json['myRitualDays'] != null 
          ? List<String>.from(json['myRitualDays']) 
          : null,
      partnerRitualId: json['partnerRitualId'] ?? '',
      partnerRitualName: json['partnerRitualName'] ?? '',
      partnerUserId: json['partnerUserId'] ?? '',
      partnerUsername: json['partnerUsername'] ?? '',
      partnerAvatarUrl: json['partnerAvatarUrl'] ?? json['partner_avatar_url'],
      partnerLevel: json['partnerLevel'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastBothCompletedAt: json['lastBothCompletedAt'] != null 
          ? DateTime.parse(json['lastBothCompletedAt']) 
          : null,
      myCompletedToday: json['myCompletedToday'] ?? false,
      partnerCompletedToday: json['partnerCompletedToday'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class PartnershipInfo {
  final bool hasPartner;
  final int? partnershipId;
  final String? partnerUserId;
  final String? partnerUsername;
  final int? partnerLevel;
  final String? partnerRitualId;
  final int currentStreak;
  final int longestStreak;

  PartnershipInfo({
    required this.hasPartner,
    this.partnershipId,
    this.partnerUserId,
    this.partnerUsername,
    this.partnerLevel,
    this.partnerRitualId,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory PartnershipInfo.fromJson(Map<String, dynamic> json) {
    return PartnershipInfo(
      hasPartner: json['hasPartner'] ?? false,
      partnershipId: json['partnershipId'],
      partnerUserId: json['partnerUserId'],
      partnerUsername: json['partnerUsername'],
      partnerLevel: json['partnerLevel'],
      partnerRitualId: json['partnerRitualId'],
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
    );
  }
}

class LeaveResult {
  final bool success;
  final String? message;
  final String? error;

  LeaveResult({
    required this.success,
    this.message,
    this.error,
  });
}
