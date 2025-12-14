import 'api_service.dart';
import '../data/models/ritual_log.dart';

class RitualLogsService {
  /// Logs a ritual step completion
  static Future<RitualLog?> logCompletion({
    required String ritualId,
    required int stepIndex,
    required String source,
  }) async {
    try {
      final logData = {
        'ritual_id': ritualId,
        'step_index': stepIndex,
        'source': source,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.post('/ritual-logs', logData);
      return RitualLog.fromJson(response);
    } catch (e) {
      throw Exception('Failed to log completion: $e');
    }
  }

  /// Gets all completion logs for a specific ritual
  static Future<List<RitualLog>> getLogs(String ritualId) async {
    try {
      final response = await ApiService.get('/ritual-logs/$ritualId');
      
      return (response as List)
          .map((json) => RitualLog.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get logs: $e');
    }
  }

  /// Bugün bu ritüel tamamlandı mı kontrol et
  static Future<Map<String, dynamic>> getCompletionStatus(String ritualId) async {
    try {
      // Bugünün loglarını al
      final logs = await getLogs(ritualId);
      final today = DateTime.now();
      
      // Bugün tamamlanmış log var mı kontrol et (step_index = -1)
      final completedToday = logs.any((log) {
        final logDate = log.completedAt;
        return logDate.year == today.year &&
               logDate.month == today.month &&
               logDate.day == today.day &&
               log.stepIndex == -1;
      });
      
      return {'completedToday': completedToday};
    } catch (e) {
      return {'completedToday': false};
    }
  }
}
