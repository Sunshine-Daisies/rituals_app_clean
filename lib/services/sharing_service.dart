import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models/sharing_models.dart';

/// Service for ritual sharing and partner management
class SharingService {
  final String baseUrl;
  String? _token;

  SharingService({this.baseUrl = 'http://10.0.2.2:3000/api'});

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // =====================
  // Ritual Sharing
  // =====================

  /// Share a ritual and get invite code
  Future<ShareResult> shareRitual(String ritualId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sharing/ritual/$ritualId/share'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ShareResult.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Ritual paylaşılamadı');
    }
  }

  /// Update ritual visibility
  Future<Map<String, dynamic>> updateRitualVisibility(
      String ritualId, RitualVisibility visibility) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sharing/ritual/$ritualId/visibility'),
      headers: _headers,
      body: jsonEncode({'visibility': visibility.value}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Görünürlük güncellenemedi');
    }
  }

  /// Get partner info for a ritual
  Future<RitualPartner?> getPartnerInfo(String ritualId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sharing/ritual/$ritualId/partner'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['partner'] != null) {
        return RitualPartner.fromJson(data['partner']);
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Partner bilgisi alınamadı');
    }
  }

  /// Leave a partnership
  Future<Map<String, dynamic>> leavePartnership(String ritualId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/sharing/ritual/$ritualId/leave'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Partnerlik bırakılamadı');
    }
  }

  // =====================
  // Join & Partner Actions
  // =====================

  /// Join a ritual using invite code
  Future<JoinResult> joinRitual(String inviteCode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sharing/join/$inviteCode'),
      headers: _headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return JoinResult.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Rituale katılınamadı');
    }
  }

  /// Accept a partner request
  Future<Map<String, dynamic>> acceptPartner(String partnerId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sharing/partner/$partnerId/accept'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Partner kabul edilemedi');
    }
  }

  /// Reject a partner request
  Future<Map<String, dynamic>> rejectPartner(String partnerId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/sharing/partner/$partnerId/reject'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Partner reddedilemedi');
    }
  }

  // =====================
  // Partner Rituals List
  // =====================

  /// Get all rituals where user is a partner (not owner)
  Future<List<SharedRitual>> getMyPartnerRituals() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sharing/my-partner-rituals'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> ritualsList = data['rituals'] ?? [];
      return ritualsList.map((r) => SharedRitual.fromJson(r)).toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Partner ritualleri alınamadı');
    }
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
