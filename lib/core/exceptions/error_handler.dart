import 'package:flutter/material.dart';
import 'app_exceptions.dart';

/// Hata gösterme yardımcı sınıfı
class ErrorHandler {
  /// SnackBar ile hata göster
  static void showError(BuildContext context, dynamic error) {
    final appException = error is AppException 
        ? error 
        : ExceptionHandler.fromError(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getIcon(appException), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appException.userMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _getColor(appException),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Kapat',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Dialog ile hata göster (kritik hatalar için)
  static Future<void> showErrorDialog(
    BuildContext context, 
    dynamic error, {
    String? title,
    VoidCallback? onRetry,
  }) async {
    final appException = error is AppException 
        ? error 
        : ExceptionHandler.fromError(error);
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          _getIcon(appException),
          color: _getColor(appException),
          size: 48,
        ),
        title: Text(title ?? _getTitle(appException)),
        content: Text(
          appException.userMessage,
          textAlign: TextAlign.center,
        ),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Tekrar Dene'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  /// Başarı mesajı göster
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Bilgi mesajı göster
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Uyarı mesajı göster
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ============================================
  // PRIVATE HELPERS
  // ============================================

  static IconData _getIcon(AppException exception) {
    if (exception is NetworkException) return Icons.wifi_off;
    if (exception is ServerException) return Icons.cloud_off;
    if (exception is UnauthorizedException) return Icons.lock_outline;
    if (exception is ForbiddenException) return Icons.block;
    if (exception is NotFoundException) return Icons.search_off;
    if (exception is ValidationException) return Icons.warning_amber;
    if (exception is TimeoutException) return Icons.timer_off;
    if (exception is RateLimitException) return Icons.speed;
    return Icons.error_outline;
  }

  static Color _getColor(AppException exception) {
    if (exception is NetworkException) return Colors.grey.shade700;
    if (exception is ServerException) return Colors.red.shade700;
    if (exception is UnauthorizedException) return Colors.orange.shade700;
    if (exception is ForbiddenException) return Colors.red.shade600;
    if (exception is ValidationException) return Colors.amber.shade700;
    if (exception is TimeoutException) return Colors.grey.shade600;
    if (exception is RateLimitException) return Colors.purple.shade600;
    return Colors.red.shade600;
  }

  static String _getTitle(AppException exception) {
    if (exception is NetworkException) return 'Bağlantı Hatası';
    if (exception is ServerException) return 'Sunucu Hatası';
    if (exception is UnauthorizedException) return 'Oturum Hatası';
    if (exception is ForbiddenException) return 'Erişim Engellendi';
    if (exception is NotFoundException) return 'Bulunamadı';
    if (exception is ValidationException) return 'Geçersiz Bilgi';
    if (exception is TimeoutException) return 'Zaman Aşımı';
    if (exception is RateLimitException) return 'Çok Fazla İstek';
    return 'Hata';
  }
}
