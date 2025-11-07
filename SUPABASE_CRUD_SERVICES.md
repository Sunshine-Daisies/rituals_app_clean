# Supabase CRUD Services Documentation

Bu dokümantasyon, Flutter uygulaması için oluşturulan Supabase CRUD servislerinin kullanımını açıklar.

## 📋 Servisler

### 1. RitualsService
Ritüel yönetimi için CRUD işlemleri.

#### ⚠️ Önemli: Reminder Days Format
`reminder_days` alanı sadece şu formatları kabul eder: `['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']`

#### Kullanım Örnekleri:

```dart
import 'package:rituals_app/services/rituals_service.dart';

// Yeni ritüel oluşturma
final ritual = await RitualsService.createRitual(
  name: 'Sabah Rutini',
  steps: [
    {'title': 'Uyan', 'duration': 1},
    {'title': 'Su iç', 'duration': 2},
    {'title': 'Egzersiz yap', 'duration': 30},
  ],
  reminderTime: '07:00',
  reminderDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], // Doğru format!
  timezone: 'Europe/Istanbul',
);

// Alternatif: Otomatik format dönüşümü
final ritual2 = await RitualsService.createRitual(
  name: 'Akşam Rutini',
  steps: [{'title': 'Meditasyon', 'duration': 10}],
  reminderTime: '21:00',
  reminderDays: ['monday', 'wednesday', 'friday'], // Otomatik olarak ['Mon', 'Wed', 'Fri'] olur
  timezone: 'Europe/Istanbul',
);

// Ritüel güncelleme
final updatedRitual = await RitualsService.updateRitual(
  id: ritual!.id,
  name: 'Güncellenmiş Sabah Rutini',
  reminderTime: '07:30',
);

// Aktif ritüelleri getirme
final rituals = await RitualsService.getRituals(profileId);

// Ritüel arşivleme (soft delete)
await RitualsService.archiveRitual(ritualId);

// Ritüel silme (hard delete)
await RitualsService.deleteRitual(ritualId);
```

### 2. RitualLogsService
Ritüel tamamlama kayıtları için işlemler.

#### Kullanım Örnekleri:

```dart
import 'package:rituals_app/services/ritual_logs_service.dart';

// Ritüel adımı tamamlama kaydı
final log = await RitualLogsService.logCompletion(
  ritualId: 'ritual-uuid',
  stepIndex: 0,
  source: 'manual', // 'manual', 'reminder', 'auto'
);

// Ritüel tamamlama geçmişini getirme
final logs = await RitualLogsService.getLogs('ritual-uuid');
```

### 3. DevicesService
Cihaz kaydı ve yönetimi için işlemler.

#### Kullanım Örnekleri:

```dart
import 'package:rituals_app/services/devices_service.dart';

// Cihaz kaydı (varsa günceller, yoksa oluşturur)
final device = await DevicesService.registerDevice(
  profileId: 'profile-uuid',
  deviceToken: 'fcm-device-token',
  platform: 'android', // 'android', 'ios', 'web'
  appVersion: '1.0.0',
  locale: 'tr',
);

// Son görülme zamanını güncelleme
await DevicesService.updateLastSeen(device!.id);
```

### 4. LlmUsageService
AI kullanım istatistikleri için işlemler.

#### Kullanım Örnekleri:

```dart
import 'package:rituals_app/services/llm_usage_service.dart';

// AI kullanım kaydı
final usage = await LlmUsageService.logUsage(
  userId: 'user-uuid',
  model: 'gpt-3.5-turbo',
  tokensIn: 100,
  tokensOut: 50,
  sessionId: 'session-uuid',
  intent: 'chat', // 'chat', 'ritual_creation', 'ritual_modification'
  promptType: 'user', // 'system', 'user', 'assistant'
);

// Kullanım istatistiklerini getirme
final usageList = await LlmUsageService.getUsage('user-uuid');
```

## 🔐 Kimlik Doğrulama

Tüm servisler otomatik olarak kullanıcı kimlik doğrulamasını kontrol eder:

```dart
// Kullanıcı giriş yapmamışsa Exception fırlatır
try {
  final rituals = await RitualsService.getRituals(profileId);
} catch (e) {
  if (e.toString().contains('User not authenticated')) {
    // Kullanıcıyı giriş sayfasına yönlendir
  }
}
```

## 🛡️ Hata Yönetimi

Tüm servisler tutarlı hata yönetimi kullanır:

```dart
try {
  final ritual = await RitualsService.createRitual(/* ... */);
} catch (e) {
  // Hata mesajları:
  // - "User not authenticated" - Kimlik doğrulama hatası
  // - "Database operation failed: ..." - Veritabanı hatası
  // - "Network error: ..." - Ağ bağlantı hatası
  print('Hata: $e');
}
```

## 📊 Veri Modelleri

### Ritual Model
```dart
class Ritual {
  final String id;
  final String profileId;
  final String name;
  final List<Map<String, dynamic>> steps;
  final String reminderTime;
  final List<String> reminderDays;
  final String? timezone;
  final bool isActive;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### RitualLog Model
```dart
class RitualLog {
  final String id;
  final String ritualId;
  final DateTime completedAt;
  final String source;
  final int stepIndex;
}
```

### Device Model
```dart
class Device {
  final String id;
  final String profileId;
  final String deviceToken;
  final String platform;
  final String appVersion;
  final String locale;
  final DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### LlmUsage Model
```dart
class LlmUsage {
  final String id;
  final String userId;
  final String model;
  final int tokensIn;
  final int tokensOut;
  final String sessionId;
  final String intent;
  final String promptType;
  final DateTime createdAt;
  
  // Yardımcı metodlar
  int get totalTokens => tokensIn + tokensOut;
  double get estimatedCost => (totalTokens / 1000) * 0.002;
}
```

## 🧪 Test Etme

Manuel test için `dev_test.dart` dosyasını çalıştırın:

```bash
flutter run dev_test.dart
```

Bu test uygulaması:
- ✅ Tüm servislerin temel işlevlerini test eder
- ✅ Kimlik doğrulama kontrollerini doğrular
- ✅ Hata yönetimini test eder
- ✅ Gerçek Supabase bağlantısını doğrular

## 🔧 Kurulum Gereksinimleri

1. **Supabase Yapılandırması**: `.env` dosyasında Supabase URL ve anahtar
2. **Kimlik Doğrulama**: Kullanıcı giriş yapmış olmalı
3. **RLS Politikaları**: Supabase'de Row Level Security aktif olmalı
4. **Tablo Yapısı**: Gerekli tablolar oluşturulmuş olmalı

## 📝 Notlar

- Tüm servisler `Supabase.instance.client` kullanır
- RLS (Row Level Security) politikaları veri güvenliğini sağlar
- Soft delete için `archiveRitual` kullanın
- Hard delete için `deleteRitual` kullanın
- Cihaz kaydı otomatik olarak mevcut kayıtları günceller
- AI kullanım kayıtları maliyet analizi için kullanılabilir