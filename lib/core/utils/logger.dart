import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Log seviyeleri
enum LogLevel {
  debug,   // 🔵 Geliştirme detayları
  info,    // 🟢 Önemli olaylar
  warning, // 🟡 Dikkat edilmesi gerekenler
  error,   // 🔴 Hatalar
  fatal,   // ⚫ Kritik hatalar
}

/// Merkezi logging sistemi
class AppLogger {
  // Singleton
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Minimum log seviyesi (bu seviye ve üstü loglanır)
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Log geçmişi (son N log)
  final List<LogEntry> _history = [];
  static const int _maxHistory = 100;

  /// Log callback (Firebase Crashlytics, Sentry vs. için)
  void Function(LogEntry entry)? onLog;

  // ============================================
  // CONFIGURATION
  // ============================================

  /// Minimum log seviyesini ayarla
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Production modda sadece error ve üstünü logla
  void setProductionMode() {
    _minLevel = LogLevel.error;
  }

  /// Debug modda tüm logları göster
  void setDebugMode() {
    _minLevel = LogLevel.debug;
  }

  // ============================================
  // LOG METHODS
  // ============================================

  /// 🔵 Debug log - Geliştirme detayları
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// 🟢 Info log - Önemli olaylar
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// 🟡 Warning log - Dikkat edilmesi gerekenler
  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// 🔴 Error log - Hatalar
  void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  /// ⚫ Fatal log - Kritik hatalar
  void fatal(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // ============================================
  // SPECIALIZED LOGS
  // ============================================

  /// API request log
  void apiRequest(String method, String endpoint, {Map<String, dynamic>? body}) {
    debug(
      '📡 $method $endpoint',
      tag: 'API',
      data: body != null ? {'body': body} : null,
    );
  }

  /// API response log
  void apiResponse(String endpoint, int statusCode, {int? durationMs, dynamic body}) {
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    final level = statusCode >= 200 && statusCode < 300 ? LogLevel.debug : LogLevel.error;
    
    _log(
      level,
      '$emoji $endpoint → $statusCode${durationMs != null ? ' (${durationMs}ms)' : ''}',
      tag: 'API',
      data: body != null ? {'response': _truncate(body.toString(), 500)} : null,
    );
  }

  /// Navigation log
  void navigation(String route, {String? from}) {
    debug(
      '🧭 ${from != null ? '$from → ' : ''}$route',
      tag: 'NAV',
    );
  }

  /// User action log
  void userAction(String action, {Map<String, dynamic>? params}) {
    info(
      '👆 $action',
      tag: 'USER',
      data: params,
    );
  }

  /// Performance log
  void performance(String operation, int durationMs, {String? tag}) {
    final level = durationMs > 1000 ? LogLevel.warning : LogLevel.debug;
    final emoji = durationMs > 1000 ? '🐢' : '⚡';
    
    _log(
      level,
      '$emoji $operation: ${durationMs}ms',
      tag: tag ?? 'PERF',
    );
  }

  // ============================================
  // INTERNAL
  // ============================================

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    // Seviye kontrolü
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
      timestamp: DateTime.now(),
    );

    // History'e ekle
    _history.add(entry);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    // Console'a yaz
    if (kDebugMode) {
      _printToConsole(entry);
    }

    // Callback çağır (Crashlytics vs.)
    onLog?.call(entry);
  }

  void _printToConsole(LogEntry entry) {
    final buffer = StringBuffer();
    
    // Timestamp
    final time = entry.timestamp;
    buffer.write('[${_padZero(time.hour)}:${_padZero(time.minute)}:${_padZero(time.second)}] ');
    
    // Level emoji
    buffer.write('${_levelEmoji(entry.level)} ');
    
    // Tag
    if (entry.tag != null) {
      buffer.write('[${entry.tag}] ');
    }
    
    // Message
    buffer.write(entry.message);
    
    // Data
    if (entry.data != null) {
      buffer.write('\n    📎 ${_prettyJson(entry.data!)}');
    }
    
    // Error
    if (entry.error != null) {
      buffer.write('\n    💥 ${entry.error}');
    }
    
    // StackTrace (sadece error/fatal için)
    if (entry.stackTrace != null && entry.level.index >= LogLevel.error.index) {
      final trace = entry.stackTrace.toString().split('\n').take(5).join('\n    ');
      buffer.write('\n    📍 $trace');
    }

    // Renklendirme (terminal desteği varsa)
    debugPrint(buffer.toString());
  }

  String _levelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔵';
      case LogLevel.info:
        return '🟢';
      case LogLevel.warning:
        return '🟡';
      case LogLevel.error:
        return '🔴';
      case LogLevel.fatal:
        return '⚫';
    }
  }

  String _padZero(int n) => n.toString().padLeft(2, '0');

  String _truncate(String s, int max) {
    return s.length > max ? '${s.substring(0, max)}...' : s;
  }

  String _prettyJson(Map<String, dynamic> json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(json);
    } catch (_) {
      return json.toString();
    }
  }

  // ============================================
  // GETTERS
  // ============================================

  /// Log geçmişi
  List<LogEntry> get history => List.unmodifiable(_history);

  /// Son N log
  List<LogEntry> getLastLogs(int count) {
    return _history.reversed.take(count).toList();
  }

  /// Seviyeye göre filtrele
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return _history.where((e) => e.level == level).toList();
  }

  /// Hataları getir
  List<LogEntry> get errors {
    return _history.where((e) => e.level.index >= LogLevel.error.index).toList();
  }

  /// Geçmişi temizle
  void clearHistory() {
    _history.clear();
  }
}

/// Log entry model
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'message': message,
    'tag': tag,
    'error': error?.toString(),
    'timestamp': timestamp.toIso8601String(),
    'data': data,
  };

  @override
  String toString() => '[$level] ${tag != null ? '[$tag] ' : ''}$message';
}

/// Global logger instance
final logger = AppLogger();
