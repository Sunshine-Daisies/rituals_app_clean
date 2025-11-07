import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/ritual.dart';

class RitualsService {
  static final _client = Supabase.instance.client;

  /// Valid day formats for reminder_days field
  /// Database constraint only accepts: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun']
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

  /// Verifies that the user is authenticated
  static String _getCurrentUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.id;
  }

  /// Wraps database operations with error handling
  static Future<T> _performOperation<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      throw Exception('Database operation failed: ${e.toString()}');
    }
  }

  /// Creates a new ritual
  static Future<Ritual?> createRitual({
    required String name,
    required List<Map<String, dynamic>> steps,
    required String reminderTime,
    required List<String> reminderDays,
    String? timezone,
  }) async {
    return _performOperation(() async {
      final userId = _getCurrentUserId();
      
      // Validate and convert reminder days to correct format
      final validatedDays = convertToShortDayFormat(reminderDays);
      if (!isValidReminderDays(validatedDays)) {
        throw Exception('Invalid reminder days. Must be one of: ${validDays.join(', ')}');
      }
      
      final ritualData = {
        'profile_id': userId,
        'name': name,
        'steps': steps,
        'reminder_time': reminderTime, // time format: "07:00"
        'reminder_days': validatedDays, // text[] array - validated format
        'timezone': timezone,
        'is_active': true,
        // created_at ve updated_at otomatik olarak Supabase tarafından set edilir
      };

      final response = await _client
          .from('rituals')
          .insert(ritualData)
          .select()
          .single();

      return Ritual.fromJson(response);
    });
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
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final updateData = <String, dynamic>{
        // updated_at otomatik olarak Supabase tarafından set edilir
      };

      // Only add fields that are provided
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

      final response = await _client
          .from('rituals')
          .update(updateData)
          .eq('id', id)
          .select()
          .single();

      return Ritual.fromJson(response);
    });
  }

  /// Gets all active rituals for a specific profile
  static Future<List<Ritual>> getRituals(String profileId) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final response = await _client
          .from('rituals')
          .select()
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Ritual.fromJson(json))
          .toList();
    });
  }

  /// Gets a single ritual by ID
  static Future<Ritual?> getRitualById(String id) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final response = await _client
          .from('rituals')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? Ritual.fromJson(response) : null;
    });
  }

  /// Permanently deletes a ritual
  static Future<void> deleteRitual(String id) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      await _client
          .from('rituals')
          .delete()
          .eq('id', id);
    });
  }

  /// Archives a ritual (soft delete)
  static Future<void> archiveRitual(String id) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      await _client
          .from('rituals')
          .update({
            'is_active': false,
            'archived_at': DateTime.now().toIso8601String(),
            // updated_at otomatik olarak set edilir
          })
          .eq('id', id);
    });
  }
}