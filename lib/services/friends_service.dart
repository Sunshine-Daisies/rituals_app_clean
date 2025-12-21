import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../data/models/user_profile.dart';

class FriendsService {
  /// API base URL - AppConfig'den alınır
  static String get _baseUrl => appConfig.apiBaseUrl;
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ============================================
  // FRIENDS LIST
  // ============================================

  /// Arkadaş listesini getir
  Future<List<Friendship>> getFriends() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/friends'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((f) => Friendship.fromJson(f)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting friends: $e');
      return [];
    }
  }

  // ============================================
  // FRIEND REQUESTS
  // ============================================

  /// Bekleyen arkadaşlık isteklerini getir
  Future<FriendRequestsResult?> getFriendRequests() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/friends/requests'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return FriendRequestsResult.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting friend requests: $e');
      return null;
    }
  }

  /// Arkadaşlık isteği gönder
  Future<FriendRequestResult> sendFriendRequest(String addresseeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/friends/request'),
        headers: await _getHeaders(),
        body: json.encode({'addresseeId': addresseeId}),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return FriendRequestResult(
          success: true,
          message: data['message'] ?? 'Request sent',
        );
      }
      
      return FriendRequestResult(
        success: false,
        message: data['error'] ?? 'An error occurred',
      );
    } catch (e) {
      print('Error sending friend request: $e');
      return FriendRequestResult(
        success: false,
        message: 'Connection error',
      );
    }
  }

  /// Arkadaşlık isteğini kabul et
  Future<FriendRequestResult> acceptFriendRequest(int friendshipId) async {
    print('🔍 acceptFriendRequest called with friendshipId: $friendshipId');
    try {
      final url = '$_baseUrl/friends/accept/$friendshipId';
      print('🔍 Request URL: $url');
      final response = await http.put(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return FriendRequestResult(
          success: true,
          message: data['message'] ?? 'Accepted',
        );
      }
      
      return FriendRequestResult(
        success: false,
        message: data['error'] ?? 'An error occurred',
      );
    } catch (e) {
      print('Error accepting friend request: $e');
      return FriendRequestResult(
        success: false,
        message: 'Connection error',
      );
    }
  }

  /// Arkadaşlık isteğini reddet
  Future<FriendRequestResult> rejectFriendRequest(int friendshipId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/friends/reject/$friendshipId'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return FriendRequestResult(
          success: true,
          message: data['message'] ?? 'Rejected',
        );
      }
      
      return FriendRequestResult(
        success: false,
        message: data['error'] ?? 'An error occurred',
      );
    } catch (e) {
      print('Error rejecting friend request: $e');
      return FriendRequestResult(
        success: false,
        message: 'Connection error',
      );
    }
  }

  /// Arkadaşı sil
  Future<FriendRequestResult> removeFriend(int friendshipId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/friends/$friendshipId'),
        headers: await _getHeaders(),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return FriendRequestResult(
          success: true,
          message: data['message'] ?? 'Removed from friends',
        );
      }
      
      return FriendRequestResult(
        success: false,
        message: data['error'] ?? 'An error occurred',
      );
    } catch (e) {
      print('Error removing friend: $e');
      return FriendRequestResult(
        success: false,
        message: 'Connection error',
      );
    }
  }
}

// ============================================
// RESULT CLASSES
// ============================================

class FriendRequestsResult {
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  FriendRequestsResult({required this.incoming, required this.outgoing});

  factory FriendRequestsResult.fromJson(Map<String, dynamic> json) {
    return FriendRequestsResult(
      incoming: (json['incoming'] as List<dynamic>)
          .map((r) => FriendRequest.fromJson(r))
          .toList(),
      outgoing: (json['outgoing'] as List<dynamic>)
          .map((r) => FriendRequest.fromJson(r))
          .toList(),
    );
  }

  int get totalCount => incoming.length + outgoing.length;
  int get incomingCount => incoming.length;
}

class FriendRequestResult {
  final bool success;
  final String message;

  FriendRequestResult({required this.success, required this.message});
}
