import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _premiumKey = 'auth_is_premium';

  // Uygulama açıldığında token var mı diye kontrol et
  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      ApiService.setToken(token);
      // We don't verify token here, just load it. 
      // Premium status will be loaded from local storage for faster UI initial load.
      return true;
    }
    return false;
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<void> login(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final token = response['token'];
      final user = response['user'];
      
      if (token != null) {
        ApiService.setToken(token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        if (user != null) {
          if (user['email'] != null) await prefs.setString(_emailKey, user['email']);
          await prefs.setBool(_premiumKey, user['isPremium'] ?? false);
        }
        
        // Update FCM token after login
        await NotificationService().updateTokenToServer();
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<void> register(String email, String password, {String? name}) async {
    try {
      await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
        'name': name,
      });
      
      // Token dönmüyor, sadece başarılı olduğunu biliyoruz.
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  static Future<void> forgotPassword(String email) async {
    try {
      // Backend returns success message even if email not found (security)
      await ApiService.post('/auth/forgot-password', {
        'email': email,
      });
    } catch (e) {
      throw Exception('Operation failed: $e');
    }
  }

  static Future<void> logout() async {
    ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_premiumKey);
  }

  static Future<bool> togglePremium() async {
    try {
      final response = await ApiService.patch('/auth/premium-toggle', {});
      final isPremium = response['isPremium'] as bool;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, isPremium);
      
      return isPremium;
    } catch (e) {
      throw Exception('Toggle failed: $e');
    }
  }
}
