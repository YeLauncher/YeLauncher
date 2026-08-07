import 'package:flutter/foundation.dart';
import 'package:yelauncher/domain/models/download/cancellation_token.dart';

enum NotificationStatus {
  running,
  completed,
  failed,
  cancelled,
}

class NotificationModel {
  final String id;
  final String title;
  final String description;
  final double? progress;
  final NotificationStatus status;
  final CancellationToken? cancellationToken;
  final VoidCallback? onCancel;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    this.progress,
    this.status = NotificationStatus.running,
    this.cancellationToken,
    this.onCancel,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? description,
    double? progress,
    NotificationStatus? status,
    CancellationToken? cancellationToken,
    VoidCallback? onCancel,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      cancellationToken: cancellationToken ?? this.cancellationToken,
      onCancel: onCancel ?? this.onCancel,
    );
  }
}
