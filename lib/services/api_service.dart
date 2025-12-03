import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../core/exceptions/app_exceptions.dart';

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

  /// API base URL - AppConfig'den alınır
  static String get baseUrl => appConfig.apiBaseUrl;

  /// Timeout süresi
  static const Duration _timeout = Duration(seconds: 15);

  static Future<dynamic> get(String endpoint, {String? authToken}) async {
    try {
      if (kDebugMode) print('📡 GET: $baseUrl$endpoint');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
      ).timeout(_timeout);
      
      if (kDebugMode) print('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (kDebugMode) print('❌ GET Error: $e');
      throw ExceptionHandler.fromError(e);
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data, {String? authToken}) async {
    try {
      if (kDebugMode) print('📡 POST: $baseUrl$endpoint');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
        body: jsonEncode(data),
      ).timeout(_timeout);
      
      if (kDebugMode) print('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (kDebugMode) print('❌ POST Error: $e');
      throw ExceptionHandler.fromError(e);
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data, {String? authToken}) async {
    try {
      if (kDebugMode) print('📡 PUT: $baseUrl$endpoint');
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
        body: jsonEncode(data),
      ).timeout(_timeout);
      
      if (kDebugMode) print('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (kDebugMode) print('❌ PUT Error: $e');
      throw ExceptionHandler.fromError(e);
    }
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data, {String? authToken}) async {
    try {
      if (kDebugMode) print('📡 PATCH: $baseUrl$endpoint');
      
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(customToken: authToken),
        body: jsonEncode(data),
      ).timeout(_timeout);
      
      if (kDebugMode) print('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (kDebugMode) print('❌ PATCH Error: $e');
      throw ExceptionHandler.fromError(e);
    }
  }

  static Future<dynamic> delete(String endpoint, {Map<String, dynamic>? body, String? authToken}) async {
    try {
      if (kDebugMode) print('📡 DELETE: $baseUrl$endpoint');
      
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(customToken: authToken));
      if (body != null) {
        request.body = jsonEncode(body);
      }
      
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      if (kDebugMode) print('📥 Response: ${response.statusCode}');
      return _handleResponse(response);
    } on TimeoutException {
      throw TimeoutException();
    } catch (e) {
      if (kDebugMode) print('❌ DELETE Error: $e');
      throw ExceptionHandler.fromError(e);
    }
  }

  /// HTTP response'u işle ve uygun exception fırlat
  static dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    // Başarılı response
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    
    // Hata mesajını çıkar
    String? errorMessage;
    try {
      final body = jsonDecode(response.body);
      errorMessage = ExceptionHandler.extractErrorMessage(body);
    } catch (_) {
      errorMessage = response.body.isNotEmpty ? response.body : null;
    }
    
    // Uygun exception fırlat
    throw ExceptionHandler.fromStatusCode(statusCode, errorMessage);
  }
}

