import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String? id;
  final String author;
  final String content;
  final DateTime createdAt;

  PostModel({
    this.id,
    required this.author,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PostModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final ts = map['createdAt'];
    DateTime created;
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is String) {
      created = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return PostModel(
      id: id,
      author: map['author'] ?? '',
      content: map['content'] ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
    'author': author,
    'content': content,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
