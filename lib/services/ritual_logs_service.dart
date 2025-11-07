import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/ritual_log.dart';

class RitualLogsService {
  static final _client = Supabase.instance.client;

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

  /// Logs a ritual step completion
  static Future<RitualLog?> logCompletion({
    required String ritualId,
    required int stepIndex,
    required String source,
  }) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final logData = {
        'ritual_id': ritualId, // UUID format
        'completed_at': DateTime.now().toIso8601String(), // timestamptz
        'source': source, // text
        'step_index': stepIndex, // int4
      };

      final response = await _client
          .from('ritual_logs')
          .insert(logData)
          .select()
          .single();

      return RitualLog.fromJson(response);
    });
  }

  /// Gets all completion logs for a specific ritual
  static Future<List<RitualLog>> getLogs(String ritualId) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final response = await _client
          .from('ritual_logs')
          .select()
          .eq('ritual_id', ritualId)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => RitualLog.fromJson(json))
          .toList();
    });
  }
}