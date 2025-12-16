import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Uygulama ortam türleri
enum Environment {
  /// Geliştirme ortamı - Yerel ağ IP
  development,

  /// Staging ortamı - Test server
  staging,

  /// Production ortamı - Canlı server
  production,
}

/// Uygulama yapılandırma sınıfı
/// Tüm environment değişkenleri burada merkezi olarak yönetilir
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  // Mevcut ortam
  Environment _environment = Environment.production;

  // ============================================
  // NETWORK IPs - Buraya IP adreslerini yaz
  // ============================================

  /// Yerel ağ IP adresi (ipconfig ile bulunur)
  static const String localNetworkIp = '192.168.1.5';
  /// Staging server URL (varsa)
  static const String stagingUrl = 'https://staging-api.yourdomain.com';

  /// Production server URL (domain)
  // .env dosyasından okumaya çalış, yoksa hardcoded değeri kullan
  static String get productionUrl => dotenv.env['API_URL'] ?? 'https://ritualsappclean-production.up.railway.app';

  // ============================================
  // GETTERS
  // ============================================

  /// Mevcut ortamı döndürür
  Environment get environment => _environment;

  /// Debug modda mı?
  bool get isDebug => _environment == Environment.development;

  /// Production modda mı?
  bool get isProduction => _environment == Environment.production;

  /// API base URL - Ortama göre otomatik seçilir
  String get apiBaseUrl {
    switch (_environment) {
      case Environment.development:
        // Web için localhost, mobil için network IP
        if (kIsWeb) return 'http://localhost:3000/api';
        // Android emulator uses special host `10.0.2.2` to reach host machine.
        if (!kIsWeb && Platform.isAndroid) {
          return 'http://10.0.2.2:3000/api';
        }
        // iOS simulator and physical devices should use the LAN IP
        if (!kIsWeb && Platform.isIOS) {
          return 'http://$localNetworkIp:3000/api';
        }
        return 'http://localhost:3000/api';
      case Environment.staging:
        return '$stagingUrl/api';

      case Environment.production:
        return '$productionUrl/api';
    }
  }

  /// WebSocket URL (chat için)
  String get wsUrl {
    switch (_environment) {
      case Environment.development:
        if (kIsWeb) return 'ws://localhost:3000';
        if (!kIsWeb && Platform.isAndroid) return 'ws://10.0.2.2:3000';
        if (!kIsWeb && Platform.isIOS) return 'ws://$localNetworkIp:3000';
        return 'ws://localhost:3000';
      case Environment.staging:
        return stagingUrl.replaceFirst('https', 'wss');

      case Environment.production:
        return productionUrl.replaceFirst('https', 'wss');
    }
  }

  /// Backend URL (email linkleri için)
  String get backendUrl {
    switch (_environment) {
      case Environment.development:
        return 'http://$localNetworkIp:3000';
      case Environment.staging:
        return stagingUrl;
      case Environment.production:
        return productionUrl;
    }
  }

  // ============================================
  // SETTERS
  // ============================================

  /// Ortamı ayarla
  void setEnvironment(Environment env) {
    _environment = env;
    if (kDebugMode) {
      print('🌍 Environment set to: ${env.name}');
      print('📡 API URL: $apiBaseUrl');
    }
  }

  /// Development ortamına geç
  void setDevelopment() => setEnvironment(Environment.development);

  /// Staging ortamına geç
  void setStaging() => setEnvironment(Environment.staging);

  /// Production ortamına geç
  void setProduction() => setEnvironment(Environment.production);

  // ============================================
  // AUTO DETECT
  // ============================================

  /// Ortamı otomatik algıla (kDebugMode'a göre)
  void autoDetect() {
    if (kDebugMode) {
      setEnvironment(Environment.development);
    } else if (kReleaseMode) {
      setEnvironment(Environment.production);
    } else {
      setEnvironment(Environment.staging);
    }
  }

  // ============================================
  // DEBUG INFO
  // ============================================

  /// Debug bilgilerini yazdır
  void printConfig() {
    if (kDebugMode) {
      print('╔════════════════════════════════════════╗');
      print('║         APP CONFIGURATION              ║');
      print('╠════════════════════════════════════════╣');
      print('║ Environment: ${_environment.name.padRight(24)}║');
      print('║ API URL: ${apiBaseUrl.padRight(28)}║');
      print('║ Debug Mode: ${isDebug.toString().padRight(25)}║');
      print('╚════════════════════════════════════════╝');
    }
  }
}

/// Global erişim için kısayol
final appConfig = AppConfig();
