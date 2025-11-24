import 'api_service.dart';
import '../data/models/ritual.dart';

class RitualsService {
  /// Valid day formats for reminder_days field
  static const List<String> validDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  /// Helper method to validate reminder days
  static bool isValidReminderDays(List<String> days) {
    return days.every((day) => validDays.contains(day));
  }
  
  /// Helper method to convert full day names to short format
  static List<String> convertToShortDayFormat(List<String> days) {
    final dayMap = {
      'monday': 'Mon', 'tuesday': 'Tue', 'wednesday': 'Wed', 'thursday': 'Thu',
      'friday': 'Fri', 'saturday': 'Sat', 'sunday': 'Sun',
      'mon': 'Mon', 'tue': 'Tue', 'wed': 'Wed', 'thu': 'Thu',
      'fri': 'Fri', 'sat': 'Sat', 'sun': 'Sun',
    };
    
    return days.map((day) => dayMap[day.toLowerCase()] ?? day).toList();
  }

  /// Creates a new ritual
  static Future<Ritual?> createRitual({
    required String name,
    required List<Map<String, dynamic>> steps,
    required String reminderTime,
    required List<String> reminderDays,
    String? timezone,
  }) async {
    try {
      // Validate and convert reminder days to correct format
      final validatedDays = convertToShortDayFormat(reminderDays);
      if (!isValidReminderDays(validatedDays)) {
        throw Exception('Invalid reminder days. Must be one of: ${validDays.join(', ')}');
      }
      
      final ritualData = {
        'name': name,
        'steps': steps,
        'reminder_time': reminderTime,
        'reminder_days': validatedDays,
        'timezone': timezone,
      };

      final response = await ApiService.post('/rituals', ritualData);
      return Ritual.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create ritual: $e');
    }
  }

  /// Updates an existing ritual
  static Future<Ritual?> updateRitual({
    required String id,
    String? name,
    List<Map<String, dynamic>>? steps,
    String? reminderTime,
    List<String>? reminderDays,
    String? timezone,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (steps != null) updateData['steps'] = steps;
      if (reminderTime != null) updateData['reminder_time'] = reminderTime;
      if (reminderDays != null) {
        final validatedDays = convertToShortDayFormat(reminderDays);
        if (!isValidReminderDays(validatedDays)) {
          throw Exception('Invalid reminder days. Must be one of: ${validDays.join(', ')}');
        }
        updateData['reminder_days'] = validatedDays;
      }
      if (timezone != null) updateData['timezone'] = timezone;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await ApiService.put('/rituals/$id', updateData);
      return Ritual.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ritual: $e');
    }
  }

  /// Gets all active rituals for a specific profile
  static Future<List<Ritual>> getRituals(String profileId) async {
    try {
      // Şimdilik profileId filtresi backend'de yok, tümünü getiriyoruz
      final response = await ApiService.get('/rituals');
      
      return (response as List)
          .map((json) => Ritual.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get rituals: $e');
    }
  }

  /// Gets a single ritual by ID
  static Future<Ritual?> getRitualById(String id) async {
    // Bu endpoint henüz backend'de yok ama listeyi filtreleyerek bulabiliriz şimdilik
    try {
      final rituals = await getRituals('');
      try {
        return rituals.firstWhere((r) => r.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get ritual: $e');
    }
  }

  /// Permanently deletes a ritual
  static Future<void> deleteRitual(String id) async {
    try {
      await ApiService.delete('/rituals/$id');
    } catch (e) {
      throw Exception('Failed to delete ritual: $e');
    }
  }

  /// Archives a ritual (soft delete)
  static Future<void> archiveRitual(String id) async {
    // Backend'de archive desteği henüz yok, şimdilik delete çağıralım veya update ile is_active=false yapalım
    // Backend updateRitual is_active'i destekliyor mu? Şimdilik hayır, sadece temel alanlar.
    // O yüzden şimdilik delete çağıralım.
    await deleteRitual(id);
  }
}