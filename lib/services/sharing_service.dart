import '../data/models/sharing_models.dart';
import 'api_service.dart';

/// Service for ritual sharing and partner management
class SharingService {

  // =====================
  // Ritual Sharing
  // =====================

  /// Share a ritual and get invite code
  Future<ShareResult> shareRitual(String ritualId) async {
    final response = await ApiService.post('/sharing/ritual/$ritualId/share', {});
    return ShareResult.fromJson(response);
  }

  /// Update ritual visibility
  Future<Map<String, dynamic>> updateRitualVisibility(
      String ritualId, RitualVisibility visibility) async {
    final response = await ApiService.put(
      '/sharing/ritual/$ritualId/visibility',
      {'visibility': visibility.value},
    );
    return response as Map<String, dynamic>;
  }

  /// Get partner info for a ritual
  Future<RitualPartner?> getPartnerInfo(String ritualId) async {
    try {
      final response = await ApiService.get('/sharing/ritual/$ritualId/partner');
      if (response != null && response['partner'] != null) {
        return RitualPartner.fromJson(response['partner']);
      }
      return null;
    } catch (e) {
      // 404 durumunda null dön
      if (e.toString().contains('404')) {
        return null;
      }
      rethrow;
    }
  }

  /// Leave a partnership
  Future<Map<String, dynamic>> leavePartnership(String ritualId) async {
    final response = await ApiService.delete('/sharing/ritual/$ritualId/leave');
    return response as Map<String, dynamic>;
  }

  // =====================
  // Join & Partner Actions
  // =====================

  /// Join a ritual using invite code
  Future<JoinResult> joinRitual(String inviteCode) async {
    final response = await ApiService.post('/sharing/join/$inviteCode', {});
    return JoinResult.fromJson(response);
  }

  /// Accept a partner request
  Future<Map<String, dynamic>> acceptPartner(String partnerId) async {
    final response = await ApiService.put('/sharing/partner/$partnerId/accept', {});
    return response as Map<String, dynamic>;
  }

  /// Reject a partner request
  Future<Map<String, dynamic>> rejectPartner(String partnerId) async {
    final response = await ApiService.put('/sharing/partner/$partnerId/reject', {});
    return response as Map<String, dynamic>;
  }

  // =====================
  // Partner Rituals List
  // =====================

  /// Get all rituals where user is a partner (not owner)
  Future<List<SharedRitual>> getMyPartnerRituals() async {
    final response = await ApiService.get('/sharing/my-partner-rituals');
    final List<dynamic> ritualsList = response['rituals'] ?? [];
    return ritualsList.map((r) => SharedRitual.fromJson(r)).toList();
  }

  // =====================
  // Helper methods
  // =====================

  /// Get pending partner requests (rituals waiting for approval)
  Future<List<PartnerRequest>> getPendingPartnerRequests() async {
    final rituals = await getMyPartnerRituals();
    return rituals
        .where((r) => r.isPending)
        .map((r) => PartnerRequest(
              id: r.ritualId,
              ritualId: r.ritualId,
              ritualTitle: r.ritualTitle,
              ownerId: r.ownerId,
              ownerUsername: r.ownerUsername,
              requestedAt: r.createdAt,
            ))
        .toList();
  }

  /// Get active partner rituals
  Future<List<SharedRitual>> getActivePartnerRituals() async {
    final rituals = await getMyPartnerRituals();
    return rituals.where((r) => r.isActive).toList();
  }

  /// Generate shareable link from invite code
  String generateShareLink(String inviteCode) {
    return 'ritualsapp://join/$inviteCode';
  }

  /// Parse invite code from share link or direct code
  String? parseInviteCode(String input) {
    // Handle direct 6-char code
    if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(input.toUpperCase())) {
      return input.toUpperCase();
    }
    
    // Handle deep link format
    final regex = RegExp(r'ritualsapp://join/([A-Z0-9]{6})', caseSensitive: false);
    final match = regex.firstMatch(input);
    return match?.group(1)?.toUpperCase();
  }
}
