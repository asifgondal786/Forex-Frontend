class TaskStep {
  final String id;
  final String name;
  final String description;
  final StepStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int order;

  TaskStep({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    this.startTime,
    this.endTime,
    required this.order,
  });

  bool get isCompleted => status == StepStatus.completed;
  bool get isRunning => status == StepStatus.running;
  bool get isPending => status == StepStatus.pending;

  factory TaskStep.fromJson(Map<String, dynamic> json) {
    return TaskStep(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      status: StepStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StepStatus.pending,
      ),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'status': status.name,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'order': order,
    };
  }

  TaskStep copyWith({
    String? id,
    String? name,
    String? description,
    StepStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    int? order,
  }) {
    return TaskStep(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      order: order ?? this.order,
    );
  }
}

enum StepStatus {
  pending,
  running,
  completed,
  failed,
}