class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<ToolCall>? toolCalls;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.toolCalls,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['is_user'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'tool_calls': toolCalls?.map((tc) => tc.toJson()).toList(),
    };
  }
}

class ToolCall {
  final String name;
  final Map<String, dynamic> args;

  const ToolCall({
    required this.name,
    required this.args,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      name: json['name'] as String,
      args: Map<String, dynamic>.from(json['args'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'args': args,
    };
  }
}

class AiResponse {
  final String reply;
  final List<ToolCall> toolCalls;

  const AiResponse({
    required this.reply,
    required this.toolCalls,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      reply: json['reply'] as String,
      toolCalls: (json['tool_calls'] as List?)
              ?.map((tc) => ToolCall.fromJson(tc as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reply': reply,
      'tool_calls': toolCalls.map((tc) => tc.toJson()).toList(),
    };
  }
}