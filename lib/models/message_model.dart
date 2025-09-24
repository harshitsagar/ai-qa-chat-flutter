class Message {
  final String role;
  final String content;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      role: json['role'],
      content: json['content'],
    );
  }

  Message copyWith({String? role, String? content}) {
    return Message(
      role: role ?? this.role,
      content: content ?? this.content,
    );
  }
}