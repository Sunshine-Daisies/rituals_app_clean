import 'dart:io';

/// Base exception sınıfı
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic originalError;

  AppException(
    this.message, {
    this.statusCode,
    this.errorCode,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Kullanıcıya gösterilebilir mesaj
  String get userMessage => message;
}

/// Ağ bağlantısı hatası
class NetworkException extends AppException {
  NetworkException([String? message])
      : super(
          message ?? 'No internet connection. Please check your connection.',
          errorCode: 'NETWORK_ERROR',
        );
}

/// Sunucu hatası (5xx)
class ServerException extends AppException {
  ServerException([String? message, int? statusCode])
      : super(
          message ?? 'Sunucu hatası oluştu. Lütfen daha sonra tekrar deneyin.',
          statusCode: statusCode,
          errorCode: 'SERVER_ERROR',
        );
}

/// Yetkilendirme hatası (401)
class UnauthorizedException extends AppException {
  UnauthorizedException([String? message])
      : super(
          message ?? 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.',
          statusCode: 401,
          errorCode: 'UNAUTHORIZED',
        );
}

/// Erişim reddedildi (403)
class ForbiddenException extends AppException {
  ForbiddenException([String? message])
      : super(
          message ?? 'Bu işlem için yetkiniz yok.',
          statusCode: 403,
          errorCode: 'FORBIDDEN',
        );
}

/// Kaynak bulunamadı (404)
class NotFoundException extends AppException {
  NotFoundException([String? message])
      : super(
          message ?? 'İstenen kaynak bulunamadı.',
          statusCode: 404,
          errorCode: 'NOT_FOUND',
        );
}

/// Validasyon hatası (400)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException([String? message, this.fieldErrors])
      : super(
          message ?? 'Girdiğiniz bilgileri kontrol edin.',
          statusCode: 400,
          errorCode: 'VALIDATION_ERROR',
        );
}

/// Çakışma hatası (409) - Örn: kullanıcı adı zaten alınmış
class ConflictException extends AppException {
  ConflictException([String? message])
      : super(
          message ?? 'Bu işlem zaten gerçekleştirilmiş.',
          statusCode: 409,
          errorCode: 'CONFLICT',
        );
}

/// Rate limit hatası (429)
class RateLimitException extends AppException {
  RateLimitException([String? message])
      : super(
          message ?? 'Çok fazla istek gönderdiniz. Lütfen biraz bekleyin.',
          statusCode: 429,
          errorCode: 'RATE_LIMIT',
        );
}

/// Zaman aşımı hatası
class TimeoutException extends AppException {
  TimeoutException([String? message])
      : super(
          message ?? 'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
          errorCode: 'TIMEOUT',
        );
}

/// Bilinmeyen hata
class UnknownException extends AppException {
  UnknownException([String? message, dynamic originalError])
      : super(
          message ?? 'Beklenmeyen bir hata oluştu.',
          errorCode: 'UNKNOWN_ERROR',
          originalError: originalError,
        );
}

/// Exception handler - HTTP response'dan uygun exception oluşturur
class ExceptionHandler {
  /// HTTP status code'a göre exception oluştur
  static AppException fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ValidationException(message);
      case 401:
        return UnauthorizedException(message);
      case 403:
        return ForbiddenException(message);
      case 404:
        return NotFoundException(message);
      case 409:
        return ConflictException(message);
      case 429:
        return RateLimitException(message);
      case >= 500:
        return ServerException(message, statusCode);
      default:
        return AppException(message ?? 'Bir hata oluştu', statusCode: statusCode);
    }
  }

  /// Herhangi bir error'dan AppException oluştur
  static AppException fromError(dynamic error) {
    if (error is AppException) {
      return error;
    }
    
    if (error is SocketException) {
      return NetworkException();
    }
    
    if (error is HttpException) {
      return NetworkException('HTTP bağlantı hatası');
    }
    
    if (error.toString().contains('TimeoutException') || 
        error.toString().contains('timeout')) {
      return TimeoutException();
    }
    
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Network is unreachable')) {
      return NetworkException();
    }
    
    return UnknownException(error.toString(), error);
  }

  /// API response body'den error mesajı çıkar
  static String? extractErrorMessage(Map<String, dynamic>? body) {
    if (body == null) return null;
    
    // Farklı API formatlarını destekle
    return body['message'] as String? ??
           body['error'] as String? ??
           body['msg'] as String? ??
           body['detail'] as String?;
  }
}
