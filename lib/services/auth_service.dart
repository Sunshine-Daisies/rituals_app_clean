import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';

  // Uygulama açıldığında token var mı diye kontrol et
  static Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      ApiService.setToken(token);
      return true;
    }
    return false;
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
        if (user != null && user['email'] != null) {
          await prefs.setString(_emailKey, user['email']);
        }
      }
    } catch (e) {
      throw Exception('Giriş başarısız: $e');
    }
  }

  static Future<void> register(String email, String password) async {
    try {
      await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
      });
      
      // Token dönmüyor, sadece başarılı olduğunu biliyoruz.
    } catch (e) {
      throw Exception('Kayıt başarısız: $e');
    }
  }

  static Future<void> logout() async {
    ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }
}
