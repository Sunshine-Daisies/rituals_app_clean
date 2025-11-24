import 'api_service.dart';
import '../data/models/llm_usage.dart';

class LlmUsageService {
  /// Logs LLM usage for analytics and billing
  static Future<LlmUsage?> logUsage({
    required String userId,
    required String model,
    required int tokensIn,
    required int tokensOut,
    required String sessionId,
    required String intent,
    required String promptType,
  }) async {
    try {
      final usageData = {
        'model': model,
        'tokens_in': tokensIn,
        'tokens_out': tokensOut,
        'session_id': sessionId,
        'intent': (intent is Enum) ? (intent as Enum).name : intent.toString(),
        'prompt_type': (promptType is Enum) ? (promptType as Enum).name : promptType.toString(),
      };

      final response = await ApiService.post('/llm-usage', usageData);
      return LlmUsage.fromJson(response);
    } catch (e) {
      print('Failed to log LLM usage: $e');
      return null; // Fail silently for analytics
    }
  }

  /// Gets usage statistics for a specific user (optional, for testing)
  static Future<List<LlmUsage>> getUsage(String userId) async {
    try {
      final response = await ApiService.get('/llm-usage');
      
      return (response as List)
          .map((json) => LlmUsage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get usage: $e');
    }
  }
}