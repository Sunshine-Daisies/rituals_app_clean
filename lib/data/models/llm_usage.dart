import 'package:equatable/equatable.dart';

class LlmUsage extends Equatable {
  final int id; // Changed to int to match database int8 type
  final String userId;
  final String model; // "gpt-3.5-turbo", "gpt-4", etc.
  final int tokensIn;
  final int tokensOut;
  final String sessionId;
  final String intent; // "chat", "ritual_creation", "ritual_modification", etc.
  final String promptType; // "system", "user", "assistant"
  final DateTime createdAt;

  const LlmUsage({
    required this.id,
    required this.userId,
    required this.model,
    required this.tokensIn,
    required this.tokensOut,
    required this.sessionId,
    required this.intent,
    required this.promptType,
    required this.createdAt,
  });

  factory LlmUsage.fromJson(Map<String, dynamic> json) {
    return LlmUsage(
      id: (json['id'] as num).toInt(), // Convert to int from int8
      userId: json['user_id'].toString(), // Safe conversion for UUID
      model: json['model'] as String,
      tokensIn: (json['tokens_in'] as num).toInt(),
      tokensOut: (json['tokens_out'] as num).toInt(),
      sessionId: json['session_id'] as String,
      intent: json['intent'] as String,
      promptType: json['prompt_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'model': model,
      'tokens_in': tokensIn,
      'tokens_out': tokensOut,
      'session_id': sessionId,
      'intent': intent,
      'prompt_type': promptType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LlmUsage copyWith({
    int? id,
    String? userId,
    String? model,
    int? tokensIn,
    int? tokensOut,
    String? sessionId,
    String? intent,
    String? promptType,
    DateTime? createdAt,
  }) {
    return LlmUsage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      model: model ?? this.model,
      tokensIn: tokensIn ?? this.tokensIn,
      tokensOut: tokensOut ?? this.tokensOut,
      sessionId: sessionId ?? this.sessionId,
      intent: intent ?? this.intent,
      promptType: promptType ?? this.promptType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Total tokens used in this request
  int get totalTokens => tokensIn + tokensOut;

  /// Cost estimation (approximate, based on GPT-3.5-turbo pricing)
  double get estimatedCost {
    // Rough estimation: $0.002 per 1K tokens
    return (totalTokens / 1000) * 0.002;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        model,
        tokensIn,
        tokensOut,
        sessionId,
        intent,
        promptType,
        createdAt,
      ];
}