import 'dart:convert';
import 'api_service.dart';

class LlmService {
  /// Chat response from Backend directly
  static Future<String> getChatResponse(String userPrompt) async {
    try {
      final response = await ApiService.post('/llm/chat', {
        'prompt': userPrompt,
      });

      // Response format: { "response": "AI answer..." }
      if (response != null && response['response'] != null) {
        return response['response'].toString();
      }
      return 'Empty response';
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  /// Infer Intent from Backend directly
  static Future<RitualIntent> inferRitualIntent(String userPrompt) async {
    try {
      final response = await ApiService.post('/llm/intent', {
        'prompt': userPrompt,
      });

      if (response == null) {
        throw Exception('Model returned empty response');
      }

      // Backend returns the JSON object directly
      return RitualIntent.fromModelJson(response);
    } catch (e) {
      print('Intent error: $e');
      throw Exception('Intent inference failed: $e');
    }
  }
}

/// Uygulama içi temsil + DB eşleme
class RitualIntent {
  final String intent; // create_ritual, ...
  final String? ritualName;
  final String? description;
  final String? icon;
  final List<String>? steps;
  final String? reminderTime; // HH:mm
  final List<String>? reminderDays; // Mon..Sun

  RitualIntent({
    required this.intent,
    this.ritualName,
    this.description,
    this.icon,
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
      description: _safeString(j['description']),
      icon: _safeString(j['icon']),
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
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (steps != null) 'steps': steps, // jsonb
      if (reminderTime != null) 'reminder_time': reminderTime, // time 'HH:mm'
      if (reminderDays != null) 'reminder_days': reminderDays, // text[]
    };
  }
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
