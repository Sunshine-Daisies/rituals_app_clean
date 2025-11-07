import 'package:equatable/equatable.dart';

class Device extends Equatable {
  final String id;
  final String profileId;
  final String deviceToken;
  final String platform; // "android", "ios", "web"
  final String appVersion;
  final String locale; // "tr", "en", etc.
  final DateTime lastSeen;

  const Device({
    required this.id,
    required this.profileId,
    required this.deviceToken,
    required this.platform,
    required this.appVersion,
    required this.locale,
    required this.lastSeen,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'].toString(), // Safe conversion for UUID
      profileId: json['profile_id'].toString(), // Safe conversion for UUID
      deviceToken: json['device_token'] as String,
      platform: json['platform'] as String,
      appVersion: json['app_version'] as String,
      locale: json['locale'] as String,
      lastSeen: DateTime.parse(json['last_seen'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'device_token': deviceToken,
      'platform': platform,
      'app_version': appVersion,
      'locale': locale,
      'last_seen': lastSeen.toIso8601String(),
    };
  }

  Device copyWith({
    String? id,
    String? profileId,
    String? deviceToken,
    String? platform,
    String? appVersion,
    String? locale,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      deviceToken: deviceToken ?? this.deviceToken,
      platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion,
      locale: locale ?? this.locale,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        deviceToken,
        platform,
        appVersion,
        locale,
        lastSeen,
      ];
}