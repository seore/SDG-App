class Mission {
  final String id;
  final String title;
  final String description;
  final String sdg;
  final int xp;
  final bool isCompleted;

  /// Rough real-world impact of one completion (see impact_metrics.dart).
  final String? impactMetric;
  final double impactAmount;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.sdg,
    required this.xp,
    this.isCompleted = false,
    this.impactMetric,
    this.impactAmount = 0,
  });

  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        sdg: json['sdg'] as String,
        xp: json['xp'] as int,
        impactMetric: (json['impact'] as Map?)?['metric'] as String?,
        impactAmount:
            (((json['impact'] as Map?)?['amount']) as num?)?.toDouble() ?? 0,
      );

  Mission copyWith({
    String? id,
    String? title,
    String? description,
    String? sdg,
    int? xp,
    bool? isCompleted,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sdg: sdg ?? this.sdg,
      xp: xp ?? this.xp,
      isCompleted: isCompleted ?? this.isCompleted,
      impactMetric: impactMetric,
      impactAmount: impactAmount,
    );
  }
}
