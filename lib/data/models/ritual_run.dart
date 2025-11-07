import 'package:equatable/equatable.dart';

class RitualRun extends Equatable {
  final String id;
  final String ritualId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final Map<String, dynamic> progress; // {"step_id": "done"|"skip"|"pending"}

  const RitualRun({
    required this.id,
    required this.ritualId,
    required this.startedAt,
    this.completedAt,
    required this.progress,
  });

  factory RitualRun.fromJson(Map<String, dynamic> json) {
    return RitualRun(
      id: json['id'] as String,
      ritualId: json['ritual_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      progress: Map<String, dynamic>.from(json['progress'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ritual_id': ritualId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  RitualRun copyWith({
    String? id,
    String? ritualId,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? progress,
  }) {
    return RitualRun(
      id: id ?? this.id,
      ritualId: ritualId ?? this.ritualId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      progress: progress ?? this.progress,
    );
  }

  bool get isCompleted => completedAt != null;
  
  double get completionPercentage {
    if (progress.isEmpty) return 0.0;
    final completed = progress.values.where((v) => v == 'done').length;
    return completed / progress.length;
  }

  @override
  List<Object?> get props => [id, ritualId, startedAt, completedAt, progress];
}