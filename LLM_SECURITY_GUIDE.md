# LLM Güvenlik Rehberi

## Genel Bakış
Bu proje, OpenAI LLM'lerini **sadece ritüel ve alışkanlık yönetimi** için kullanmaktadır. Amacı dışında kullanımı önlemek için çeşitli güvenlik katmanları uygulanmıştır.

## Uygulanan Güvenlik Önlemleri

### 1. **Prompt Validation (İstek Doğrulama)**
LLM'e gönderilen her istek, ritüel yönetimiyle ilgili olup olmadığı kontrol edilir.

#### İzin Verilen Anahtar Kelimeler:
- Ritüel, alışkanlık, rutin terminolojisi
- Görev, adım, hatırlatma kelimeleri
- Meditasyon, egzersiz, yoga gibi ortak ritüel tipleri
- CRUD operasyonları (oluştur, düzenle, sil, göster)

#### Yasaklı Konular:
- Hack, crack, exploit
- Yasadışı aktiviteler
- Uyuşturucu, silah
- Şiddet, zarar
- İntihar

#### Kod Örneği:
```dart
if (!_validateUserInput(userPrompt)) {
  throw Exception('Bu istek ritüel yönetimi kapsamında değil.');
}
```

### 2. **System Prompt Güçlendirme**
LLM'e her istekte, sadece ritüel yönetimi asistanı olduğu hatırlatılır.

#### Örnek System Prompt:
```
Sen bir ritüel ve alışkanlık yönetimi asistanısın. 
SADECE şu konularda yardımcı olabilirsin:
- Ritüel oluşturma, düzenleme, silme
- Alışkanlık takibi
- Hatırlatıcı ayarlama
- İstatistik gösterimi
- Motivasyon ve rutinle ilgili tavsiyeler

Bu kapsamın DIŞINDA herhangi bir soruya cevap VERME.
```

### 3. **Rate Limiting (Hız Sınırlama)**
Aşırı kullanımı ve spam'i önlemek için hız sınırları uygulanır.

#### Sınırlar:
- **Maksimum İstek:** Dakikada 10 istek
- **Cooldown Süresi:** İstekler arası minimum 3 saniye
- **Dakikalık Reset:** Her dakika sayaç sıfırlanır

#### Kod Örneği:
```dart
_checkRateLimit(); // Her istek öncesi kontrol edilir
```

#### Hata Mesajları:
- Çok fazla istek: `"Çok fazla istek gönderildi. Lütfen X saniye bekleyin."`
- Çok hızlı istek: `"Çok hızlı istek gönderiyorsunuz. Lütfen X saniye bekleyin."`

### 4. **Audit Logging (Denetim Kaydı)**
Tüm LLM istekleri loglanır (şu an konsola, ileride Supabase'e kaydedilebilir).

#### Log Formatı:
```
[LLM_AUDIT] Type: chat, Length: 45
[LLM_AUDIT] Type: ritual_intent, Length: 62
```

#### İleride Geliştirme:
```dart
// TODO: Supabase'e log kaydet
await supabase.from('llm_logs').insert({
  'user_id': userId,
  'request_type': requestType,
  'prompt_length': userPrompt.length,
  'timestamp': DateTime.now().toIso8601String(),
});
```

### 5. **Intent Validation (Niyet Doğrulama)**
JSON formatında dönen niyetler, sadece izin verilen intent türlerini içerebilir.

#### İzin Verilen Intent Türleri:
- `create_ritual` - Yeni ritüel oluştur
- `edit_ritual` - Mevcut ritüeli düzenle
- `delete_ritual` - Ritüel sil
- `reorder_steps` - Adımları yeniden sırala
- `log_completion` - Tamamlanmayı kaydet
- `set_reminder` - Hatırlatıcı ayarla
- `show_stats` - İstatistikleri göster
- `small_talk` - Genel sohbet (kapsam dışı)

## Kullanım Örnekleri

### ✅ İzin Verilen İstekler:
```
"Sabah meditasyon ritüeli oluştur"
"Egzersiz alışkanlığımı düzenle"
"Günlük rutinlerimi göster"
"Saat 07:00'da hatırlatıcı ayarla"
"Bu hafta kaç kere meditasyon yaptım?"
```

### ❌ Reddedilecek İstekler:
```
"Bir web sitesi nasıl hacklenir?"
"Python ile oyun yaz"
"Hava durumu nedir?"
"En iyi aksiyon filmleri"
"Yemek tarifi öner"
```

## Test Senaryoları

### Test 1: Normal Ritüel İsteği
```dart
final response = await LlmService.inferRitualIntent(
  "Sabah yoga ritüeli oluştur, 10 dakika meditasyon ve 20 dakika asana içersin"
);
// Beklenen: Başarılı intent dönüşü
```

### Test 2: Kapsam Dışı İstek
```dart
try {
  await LlmService.getChatResponse("Python ile hesap makinesi yaz");
} catch (e) {
  // Beklenen: "Bu istek ritüel yönetimi kapsamında değil" hatası
}
```

### Test 3: Rate Limiting
```dart
// 11 ardışık istek gönder
for (int i = 0; i < 11; i++) {
  await LlmService.getChatResponse("Ritüellerimi göster");
}
// Beklenen: 11. istekte "Çok fazla istek" hatası
```

### Test 4: Yasaklı Kelime
```dart
try {
  await LlmService.getChatResponse("Hack tools for rituals");
} catch (e) {
  // Beklenen: Güvenlik kontrolünden geçememe
}
```

## Performans Metrikleri

### Token Kullanımı:
- **Chat İsteği:** ~800 max token
- **Intent İsteği:** ~400 max token
- **Ortalama Maliyet:** $0.001 - $0.005 per istek (GPT-4o/mini)

### Yanıt Süreleri:
- **getChatResponse:** ~2-5 saniye
- **inferRitualIntent:** ~1-3 saniye

## Güvenlik Güncellemeleri

### Versiyon 1.0 (Mevcut)
- ✅ Prompt validation
- ✅ System prompt güçlendirme
- ✅ Rate limiting
- ✅ Audit logging (console)
- ✅ Intent validation

### Versiyon 1.1 (Planlanan)
- ⏳ Supabase'e audit log kaydetme
- ⏳ Kullanıcı başına rate limiting
- ⏳ Prompt injection testi
- ⏳ Content moderation API entegrasyonu
- ⏳ Dil bazlı filtreleme (TR/EN)

## Ek Öneriler

### 1. API Key Güvenliği
```bash
# .env dosyasını asla commit etmeyin
OPENAI_API_KEY=your-key-here

# .gitignore'a ekleyin
.env
.env.local
```

### 2. Backend Taşıma (Önerilen)
Daha yüksek güvenlik için LLM isteklerini backend'e taşıyın:
```
Flutter App → Backend API → OpenAI
```

### 3. Token Limitleri
Kullanıcı başına günlük/aylık token limitleri belirleyin:
```dart
// Örnek: Günde 50 istek/kullanıcı
const maxDailyRequests = 50;
```

### 4. Monitoring (İzleme)
Supabase veya Firebase Analytics ile LLM kullanımını izleyin.

## Sorun Giderme

### Sorun: "Çok fazla istek" hatası
**Çözüm:** Rate limit parametrelerini ayarlayın:
```dart
static const int _maxRequestsPerMinute = 20; // 10'dan 20'ye çıkar
static const Duration _cooldownPeriod = Duration(seconds: 2); // 3'ten 2'ye düşür
```

### Sorun: Geçerli istek reddediliyor
**Çözüm:** Anahtar kelime listesine yeni terimler ekleyin:
```dart
static const List<String> _allowedKeywords = [
  'ritual', 'habit', 'routine',
  'yeni-terim', // Ekle
];
```

### Sorun: Audit loglar kayboluyyor
**Çözüm:** Supabase entegrasyonu ekleyin (TODO kısmı).

## İletişim & Destek

Güvenlik açığı bulursanız veya öneri için:
- GitHub Issues
- Email: [proje-email]

## Lisans
Bu güvenlik implementasyonu projenin bir parçasıdır ve aynı lisans altındadır.
