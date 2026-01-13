class LiveUpdate {
  final String id;
  final String taskId;
  final String message;
  final UpdateType type;
  final DateTime timestamp;
  final double? progress;

  LiveUpdate({
    required this.id,
    required this.taskId,
    required this.message,
    required this.type,
    required this.timestamp,
    this.progress,
  });

  factory LiveUpdate.fromJson(Map<String, dynamic> json) {
    return LiveUpdate(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      message: json['message'] as String,
      type: UpdateType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => UpdateType.info,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      progress: json['progress'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'progress': progress,
    };
  }
}

enum UpdateType {
  info,
  success,
  warning,
  error,
  progress,
}