class Mission {
  final String id;
  final String title;
  final String description;
  final String sdg;
  final int xp;
  final bool isCompleted;

  Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.sdg,
    required this.xp,
    this.isCompleted = false,
  });

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
    );
  }
}
