/// LLM Güvenlik Servisi
/// 
/// Bu servis, LLM isteklerinin güvenliğini sağlamak için
/// validation, rate limiting ve audit logging işlemlerini yönetir.
class LlmSecurityService {
  // Rate Limiting
  static DateTime? _lastRequestTime;
  static int _requestCount = 0;
  static const int _maxRequestsPerMinute = 10;
  static const Duration _cooldownPeriod = Duration(seconds: 3);

  // Güvenlik: İzin verilen anahtar kelimeler (ritüel yönetimiyle ilgili)
  static const List<String> _allowedKeywords = [
    'ritual', 'ritüel', 'rituel',
    'habit', 'alışkanlık', 'aliskanlik',
    'routine', 'rutin',
    'reminder', 'hatırlatma', 'hatirlatma',
    'task', 'görev', 'gorev',
    'step', 'adım', 'adim',
    'complete', 'tamamla', 'done',
    'stat', 'istatistik', 'statistics',
    'create', 'oluştur', 'olustur',
    'edit', 'düzenle', 'duzenle',
    'delete', 'sil',
    'show', 'göster', 'goster',
    'list', 'listele',
    'morning', 'sabah',
    'evening', 'akşam', 'aksam',
    'daily', 'günlük', 'gunluk',
    'meditation', 'meditasyon',
    'exercise', 'egzersiz',
    'prayer', 'dua',
    'yoga',
    'sleep', 'uyku',
  ];

  // Güvenlik: Yasaklı konular
  static const List<String> _forbiddenTopics = [
    'hack', 'crack', 'exploit',
    'illegal', 'yasa dışı', 'yasadisi',
    'drug', 'uyuşturucu', 'uyusturucu',
    'weapon', 'silah',
    'violence', 'şiddet', 'siddet',
    'harm', 'zarar',
    'suicide', 'intihar',
  ];

  /// Kullanıcı girdisini doğrula
  /// 
  /// Returns: true ise geçerli, false ise geçersiz
  static bool validateUserInput(String userPrompt) {
    final lowerPrompt = userPrompt.toLowerCase();
    
    // Yasaklı konuları kontrol et
    for (final forbidden in _forbiddenTopics) {
      if (lowerPrompt.contains(forbidden.toLowerCase())) {
        return false;
      }
    }
    
    // Ritüel yönetimiyle ilgili olup olmadığını kontrol et
    // En az bir izin verilen kelime içermeli
    bool hasAllowedKeyword = false;
    for (final keyword in _allowedKeywords) {
      if (lowerPrompt.contains(keyword.toLowerCase())) {
        hasAllowedKeyword = true;
        break;
      }
    }
    
    // Eğer izin verilen kelime yoksa, genel sohbet olabilir mi kontrol et
    // Kısa ve genel ifadeler için (merhaba, nasılsın vb.) izin ver
    if (!hasAllowedKeyword && lowerPrompt.length < 50) {
      final greetings = ['hello', 'hi', 'hey', 'merhaba', 'selam', 'nasıl', 'nasilsin'];
      for (final greeting in greetings) {
        if (lowerPrompt.contains(greeting)) {
          hasAllowedKeyword = true;
          break;
        }
      }
    }
    
    return hasAllowedKeyword;
  }

  /// Audit log - İstekleri kaydet
  /// 
  /// TODO: İleride Supabase'e log kaydetmek için genişletilebilir
  static void logRequest(String userPrompt, String requestType) {
    // Şimdilik sadece debug print
    print('[LLM_AUDIT] Type: $requestType, Length: ${userPrompt.length}');
    
    // TODO: Supabase'e log kaydet
    // await supabase.from('llm_logs').insert({
    //   'user_id': userId,
    //   'request_type': requestType,
    //   'prompt_length': userPrompt.length,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }

  /// Rate limiting kontrolü
  /// 
  /// Throws: Exception eğer limit aşılırsa
  static void checkRateLimit() {
    final now = DateTime.now();
    
    // İlk istek
    if (_lastRequestTime == null) {
      _lastRequestTime = now;
      _requestCount = 1;
      return;
    }
    
    // Dakika sıfırla
    final diff = now.difference(_lastRequestTime!);
    if (diff.inMinutes >= 1) {
      _requestCount = 1;
      _lastRequestTime = now;
      return;
    }
    
    // Çok fazla istek
    if (_requestCount >= _maxRequestsPerMinute) {
      throw Exception('Çok fazla istek gönderildi. Lütfen ${60 - diff.inSeconds} saniye bekleyin.');
    }
    
    // Cooldown kontrolü
    if (diff < _cooldownPeriod) {
      final waitSeconds = _cooldownPeriod.inSeconds - diff.inSeconds;
      throw Exception('Çok hızlı istek gönderiyorsunuz. Lütfen $waitSeconds saniye bekleyin.');
    }
    
    _requestCount++;
    _lastRequestTime = now;
  }

  /// Rate limit ayarlarını sıfırla (test için kullanışlı)
  static void resetRateLimit() {
    _lastRequestTime = null;
    _requestCount = 0;
  }

  /// Güvenlik kontrollerini tek bir fonksiyonda topla
  /// 
  /// Throws: Exception eğer herhangi bir kontrol başarısız olursa
  static void performSecurityChecks(String userPrompt, String requestType) {
    // Rate limiting kontrolü
    checkRateLimit();
    
    // Input validation
    if (!validateUserInput(userPrompt)) {
      throw Exception(
        'Bu istek ritüel yönetimi kapsamında değil. '
        'Lütfen ritüel, alışkanlık veya rutin yönetimiyle ilgili sorular sorun.'
      );
    }
    
    // Audit log
    logRequest(userPrompt, requestType);
  }

  /// System prompt'u döndür (chat için)
  static String getChatSystemPrompt() {
    return '''
Sen bir ritüel ve alışkanlık yönetimi asistanısın. 
SADECE şu konularda yardımcı olabilirsin:
- Ritüel oluşturma, düzenleme, silme
- Alışkanlık takibi
- Hatırlatıcı ayarlama
- İstatistik gösterimi
- Motivasyon ve rutinle ilgili tavsiyeler

Bu kapsamın DIŞINDA herhangi bir soruya cevap VERME.
Eğer kullanıcı kapsam dışı bir şey sorarsa, kibarca reddet ve ne konularda yardımcı olabileceğini hatırlat.
''';
  }

  /// System prompt'u döndür (ritual intent için)
  static String getRitualIntentSystemPrompt() {
    return '''
Sen bir ritüel ve alışkanlık yönetimi asistanısın.
Kullanıcının ritüel yönetimi isteğini YALNIZCA JSON olarak döndür.

ÖNEMLİ GÜVENLİK KURALLARI:
- SADECE ritüel, alışkanlık, rutin yönetimiyle ilgili istekleri işle
- Kapsam dışı istekleri "small_talk" olarak işaretle
- Zararlı, yasadışı veya uygunsuz içerik ASLA oluşturma

Şema:
- intent: create_ritual | edit_ritual | delete_ritual | reorder_steps | log_completion | set_reminder | show_stats | small_talk
- ritual_name: string|null
- steps: string[]|null (max 20)
- reminder: { time: "HH:mm" | ISO saat, days: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] }|null

Kural:
- Serbest metin yok.
- Emin değilsen makul tahmin yap; eksikleri null bırakma, gerekirse reminder.days = tüm günler.
- Kapsam dışı istekler için intent="small_talk" ve diğer alanlar null.
''';
  }
}
