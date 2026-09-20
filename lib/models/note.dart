class Note {
  final int? id;
  final int? userId;
  final String title;
  final String? content;
  final bool isDone;
  final DateTime createdAt;

  const Note({
    this.id,
    this.userId,
    required this.title,
    this.content,
    required this.isDone,
    required this.createdAt,
  });

  const Note.sansId({
    this.userId,
    required this.title,
    this.content,
    required this.isDone,
    required this.createdAt,
  }) : id = null;

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      userId: map['user_id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String?,
      isDone: map['is_done'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Note copyWith({
    int? id,
    int? userId,
    String? title,
    String? content,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
