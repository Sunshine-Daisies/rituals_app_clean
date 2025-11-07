import 'package:equatable/equatable.dart';

class RitualLog extends Equatable {
  final String id;
  final String ritualId;
  final DateTime completedAt;
  final String source; // "manual", "reminder", "auto", etc.
  final int stepIndex;

  const RitualLog({
    required this.id,
    required this.ritualId,
    required this.completedAt,
    required this.source,
    required this.stepIndex,
  });

  factory RitualLog.fromJson(Map<String, dynamic> json) {
    return RitualLog(
      id: json['id'].toString(), // Safe conversion for UUID
      ritualId: json['ritual_id'].toString(), // Safe conversion for UUID
      completedAt: DateTime.parse(json['completed_at'] as String),
      source: json['source'] as String,
      stepIndex: json['step_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ritual_id': ritualId,
      'completed_at': completedAt.toIso8601String(),
      'source': source,
      'step_index': stepIndex,
    };
  }

  RitualLog copyWith({
    String? id,
    String? ritualId,
    DateTime? completedAt,
    String? source,
    int? stepIndex,
  }) {
    return RitualLog(
      id: id ?? this.id,
      ritualId: ritualId ?? this.ritualId,
      completedAt: completedAt ?? this.completedAt,
      source: source ?? this.source,
      stepIndex: stepIndex ?? this.stepIndex,
    );
  }

  @override
  List<Object?> get props => [id, ritualId, completedAt, source, stepIndex];
}