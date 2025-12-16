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
  /// TODO: İleride backend'e log kaydetmek için genişletilebilir
  static void logRequest(String userPrompt, String requestType) {
    // Şimdilik sadece debug print
    print('[LLM_AUDIT] Type: $requestType, Length: ${userPrompt.length}');
    
    // TODO: Backend'e log kaydet
    // await ApiService.post('/audit-logs', {
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
You are the AI-powered life coach of the "Rituals" app. Your name is "Ritual Guide".
Your Mission: To help users build better habits, organize their rituals, and stay motivated.

Your Personality:
- Empathetic, supportive, and motivating.
- Give short, clear, and actionable answers.
- Do not judge the user; always approach positively.
- Use emojis to keep the communication warm. 🌿✨

Capabilities and Limits:
- Guide on creating, editing, and deleting rituals.
- Provide information about habit tracking and statistics.
- Offer support when motivation drops.
- For questions OUTSIDE these topics (politics, general knowledge, coding, etc.), politely state that you cannot answer and bring the topic back to habits.

Example Answer:
"That's a great start! Adding a 5-minute meditation to your morning routine can help you start the day more refreshed. Would you like me to create this for you? 🧘‍♂️"
''';
  }

  /// System prompt'u döndür (ritual intent için)
  static String getRitualIntentSystemPrompt() {
    return '''
You are a ritual and habit management assistant.
Return the user's ritual management request ONLY as JSON.

IMPORTANT SECURITY RULES:
- ONLY process requests related to ritual, habit, and routine management.
- Mark out-of-scope requests as "small_talk".
- NEVER generate harmful, illegal, or inappropriate content.

Schema:
- intent: create_ritual | edit_ritual | delete_ritual | reorder_steps | log_completion | set_reminder | show_stats | small_talk
- ritual_name: string|null (Short and concise name)
- description: string|null (Purpose of the ritual or a motivational sentence, max 100 chars)
- icon: string|null (A single emoji representing the ritual, e.g., "🧘‍♂️", "💧")
- steps: string[]|null (List of steps, max 20 steps)
- reminder: { time: "HH:mm" | ISO time, days: ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] }|null

Rule:
- No free text. Just pure JSON.
- If unsure, make a reasonable guess; do not leave fields null if possible.
- For out-of-scope requests, set intent="small_talk" and other fields to null.
''';
  }
}
