import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/device.dart';

class DevicesService {
  static final _client = Supabase.instance.client;

  /// Verifies that the user is authenticated
  static String _getCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  /// Wraps database operations with error handling
  static Future<T> _performOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw Exception('Database operation failed: ${e.toString()}');
    }
  }

  /// Registers or updates a device
  static Future<Device?> registerDevice({
    required String profileId,
    required String deviceToken,
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final now = DateTime.now();
      
      // First, try to find existing device with same token
      final existingDevices = await _client
          .from('devices')
          .select()
          .eq('device_token', deviceToken)
          .eq('profile_id', profileId);

      if (existingDevices.isNotEmpty) {
        // Update existing device
        final deviceData = {
          'platform': platform,
          'app_version': appVersion,
          'locale': locale,
          'last_seen': now.toIso8601String(),
          // updated_at otomatik olarak set edilir
        };

        final response = await _client
            .from('devices')
            .update(deviceData)
            .eq('id', existingDevices.first['id'])
            .select()
            .single();

        return Device.fromJson(response);
      } else {
        // Create new device
        final deviceData = {
          'profile_id': profileId,
          'device_token': deviceToken,
          'platform': platform,
          'app_version': appVersion,
          'locale': locale,
          'last_seen': now.toIso8601String(),
          // created_at ve updated_at otomatik olarak set edilir
        };

        final response = await _client
            .from('devices')
            .insert(deviceData)
            .select()
            .single();

        return Device.fromJson(response);
      }
    });
  }

  /// Updates the last seen timestamp for a device
  static Future<void> updateLastSeen(String deviceId) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      await _client
          .from('devices')
          .update({
            'last_seen': DateTime.now().toIso8601String(),
            // updated_at otomatik olarak set edilir
          })
          .eq('id', deviceId);
    });
  }
}