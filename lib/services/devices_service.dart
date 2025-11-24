import 'api_service.dart';
import '../data/models/device.dart';

class DevicesService {
  /// Registers or updates a device
  static Future<Device?> registerDevice({
    required String profileId,
    required String deviceToken,
    required String platform,
    required String appVersion,
    required String locale,
  }) async {
    try {
      final deviceData = {
        'device_token': deviceToken,
        'platform': platform,
        'app_version': appVersion,
        'locale': locale,
      };

      final response = await ApiService.post('/devices', deviceData);
      return Device.fromJson(response);
    } catch (e) {
      print('Failed to register device: $e');
      return null;
    }
  }

  /// Updates the last seen timestamp for a device
  static Future<void> updateLastSeen(String deviceId) async {
    try {
      await ApiService.put('/devices/$deviceId/last-seen', {});
    } catch (e) {
      print('Failed to update last seen: $e');
    }
  }
}