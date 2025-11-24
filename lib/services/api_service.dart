import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String? _token;

  static bool get hasToken => _token != null;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://localhost:3000/api';
  }

  static Future<dynamic> get(String endpoint) async {
    try {
      print('GET Request to: $baseUrl$endpoint');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    try {
      print('POST Request to: $baseUrl$endpoint');
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    try {
      print('PUT Request to: $baseUrl$endpoint');
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));
      print('Response Status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      print('PUT Error: $e');
      rethrow;
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    try {
      print('DELETE Request to: $baseUrl$endpoint');
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
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
