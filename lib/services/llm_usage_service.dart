import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/llm_usage.dart';

class LlmUsageService {
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
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final usageData = {
  'user_id': userId.toString(),
  'model': model.toString(),
  'tokens_in': tokensIn,      // int
  'tokens_out': tokensOut,    // int
  'session_id': sessionId.toString(),
  'intent': (intent is Enum) ? (intent as Enum).name : intent.toString(),
  'prompt_type': (promptType is Enum) ? (promptType as Enum).name : promptType.toString(),
};

usageData.forEach((k, v) => print('$k => ${v.runtimeType} : $v')); // hangi alan int çıkıyor gör



      final response = await _client
          .from('llm_usage')
          .insert(usageData)
          .select()
          .single();

      return LlmUsage.fromJson(response);
    });
  }

  /// Gets usage statistics for a specific user (optional, for testing)
  static Future<List<LlmUsage>> getUsage(String userId) async {
    return _performOperation(() async {
      _getCurrentUserId(); // Verify authentication
      
      final response = await _client
          .from('llm_usage')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => LlmUsage.fromJson(json))
          .toList();
    });
  }
}