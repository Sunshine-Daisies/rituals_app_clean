import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String? _token;

  static bool get hasToken => _token != null;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> _getHeaders({String? customToken}) {
    final headers = {'Content-Type': 'application/json'};
    if (customToken != null) {
      headers['Authorization'] = 'Bearer $customToken';
    } else if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Map<String, String> get _headers => _getHeaders();

  /// API base URL - AppConfig'den alınır
  static String get baseUrl => appConfig.apiBaseUrl;

  static Future<dynamic> get(String endpoint, {String? authToken}) async {
    try {
      print('GET Request to: $baseUrl$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? authToken}) async {
    try {
      print('POST Request to: $baseUrl$endpoint');
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? authToken}) async {
    try {
      print('PUT Request to: $baseUrl$endpoint');
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, String? authToken}) async {
    try {
      print('DELETE Request to: $baseUrl$endpoint');
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(customToken: authToken));
      if (body != null) {
        request.body = jsonEncode(body);
      }
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('DELETE Error: $e');
      rethrow;
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Silme işlemi bazen boş dönebilir veya sadece mesaj dönebilir
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }
}
