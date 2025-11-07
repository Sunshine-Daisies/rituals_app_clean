import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'llm_security_service.dart';

class LlmService {
  // Modeller
  static const String _chatModel = 'gpt-4o';
  static const String _intentModel = 'gpt-4o-mini';

  static void initialize() {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY .env içinde yok');
    }
    OpenAI.apiKey = apiKey;
  }

  /// Serbest sohbet (sadece ritüel yönetimi için)
  static Future<String> getChatResponse(String userPrompt) async {
    initialize();
    
    // Tüm güvenlik kontrolleri (rate limit, validation, audit log)
    LlmSecurityService.performSecurityChecks(userPrompt, 'chat');
    
    try {
      final r = await OpenAI.instance.chat.create(
        model: _chatModel,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(
              LlmSecurityService.getChatSystemPrompt(),
            )],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
          ),
        ],
        maxTokens: 800,
        temperature: 0.7,
      );
      final content = r.choices.first.message.content;
      return (content == null || content.isEmpty) ? 'Boş yanıt' : (content.first.text ?? 'Boş yanıt');
    } catch (e) {
      rethrow;
    }
  }

  /// Niyet çıkarımı → JSON → normalize → RitualIntent
  static Future<RitualIntent> inferRitualIntent(String userPrompt) async {
    initialize();

    // Tüm güvenlik kontrolleri (rate limit, validation, audit log)
    LlmSecurityService.performSecurityChecks(userPrompt, 'ritual_intent');

    print('🔵 [LLM] User prompt: $userPrompt');

    final r = await OpenAI.instance.chat.create(
      model: _intentModel,
      responseFormat: {"type": "json_object"},
      temperature: 0, // deterministik
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(
            LlmSecurityService.getRitualIntentSystemPrompt(),
          )],
        ),
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userPrompt)],
        ),
      ],
      maxTokens: 400,
    );

    final content = r.choices.first.message.content?.first.text;
    if (content == null || content.isEmpty) {
      throw Exception('Model boş döndü');
    }

    // 📋 Raw JSON response
    print('📋 [LLM RAW JSON]:\n$content\n');

    // JSON parse
    final Map<String, dynamic> j = jsonDecode(content);

    // 🟢 Parsed JSON (pretty print)
    print('🟢 [LLM PARSED JSON]:\n${jsonEncode(j)}\n');

    // Normalize → RitualIntent
    final intent = RitualIntent.fromModelJson(j);
    
    // 🔸 Final RitualIntent object
    print('🔸 [RITUAL INTENT OBJECT]:');
    print('  Intent: ${intent.intent}');
    print('  Name: ${intent.ritualName}');
    print('  Steps: ${intent.steps}');
    print('  Reminder Time: ${intent.reminderTime}');
    print('  Reminder Days: ${intent.reminderDays}');
    print('---\n');

    return intent;
  }
}

/// Uygulama içi temsil + DB eşleme
class RitualIntent {
  final String intent; // create_ritual, ...
  final String? ritualName;
  final List<String>? steps;
  final String? reminderTime; // HH:mm
  final List<String>? reminderDays; // Mon..Sun

  RitualIntent({
    required this.intent,
    this.ritualName,
    this.steps,
    this.reminderTime,
    this.reminderDays,
  });

  factory RitualIntent.fromModelJson(Map<String, dynamic> j) {
    final intent = (j['intent'] ?? '').toString();
    // steps
    List<String>? steps;
    if (j['steps'] is List) {
      steps = (j['steps'] as List).map((e) => e.toString()).take(20).toList();
    }
    // reminder
    String? time;
    List<String>? days;
    final rem = j['reminder'];
    if (rem is String) {
      time = _normalizeTime(rem);
      days = _allDays;
    } else if (rem is Map) {
      time = _normalizeTime(rem['time']?.toString());
      if (rem['days'] is List) {
        days = (rem['days'] as List).map((e) => e.toString()).toList();
      }
    }
    days ??= _allDays;

    return RitualIntent(
      intent: intent,
      ritualName: _safeString(j['ritual_name']),
      steps: steps,
      reminderTime: time,
      reminderDays: days,
    );
  }

  /// DB insert/update payload (rituals)
  Map<String, dynamic> toRitualRow(String profileId) {
    return {
      'profile_id': profileId,
      if (ritualName != null) 'name': ritualName,
      if (steps != null) 'steps': steps, // jsonb
      if (reminderTime != null) 'reminder_time': reminderTime, // time 'HH:mm'
      if (reminderDays != null) 'reminder_days': reminderDays, // text[]
    };
  }

  /// Örnek: Supabase insert kullanım notu
  /// await supabase.from('rituals').insert(intent.toRitualRow(user.id));
}

String? _safeString(dynamic v) => (v == null) ? null : v.toString().trim().isEmpty ? null : v.toString().trim();

String? _normalizeTime(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  // 07:00 veya 7:00 → HH:mm
  final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
  if (m != null) {
    final hh = m.group(1)!.padLeft(2, '0');
    final mm = m.group(2)!;
    return '$hh:$mm';
  }
  // ISO datetime ise saat kısmını al
  final iso = RegExp(r'T(\d{2}):(\d{2})').firstMatch(s);
  if (iso != null) return '${iso.group(1)}:${iso.group(2)}';
  return null;
}

const List<String> _allDays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
