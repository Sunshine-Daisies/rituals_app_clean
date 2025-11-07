import 'package:equatable/equatable.dart';

class RitualStep extends Equatable {
  final String id;
  final String ritualId;
  final String title;
  final int orderNo;
  final DateTime createdAt;

  const RitualStep({
    required this.id,
    required this.ritualId,
    required this.title,
    required this.orderNo,
    required this.createdAt,
  });

  factory RitualStep.fromJson(Map<String, dynamic> json) {
    return RitualStep(
      id: json['id'] as String,
      ritualId: json['ritual_id'] as String,
      title: json['title'] as String,
      orderNo: json['order_no'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ritual_id': ritualId,
      'title': title,
      'order_no': orderNo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RitualStep copyWith({
    String? id,
    String? ritualId,
    String? title,
    int? orderNo,
    DateTime? createdAt,
  }) {
    return RitualStep(
      id: id ?? this.id,
      ritualId: ritualId ?? this.ritualId,
      title: title ?? this.title,
      orderNo: orderNo ?? this.orderNo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, ritualId, title, orderNo, createdAt];
}