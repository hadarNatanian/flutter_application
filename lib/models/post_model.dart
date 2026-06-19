import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String content;
  final String imageUrl;
  final String location;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.location,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'location': location,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  Map<String, dynamic> toSqliteMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Post.fromSqlite(Map<String, dynamic> map) => Post(
        id: map['id'],
        userId: map['userId'],
        userName: map['userName'],
        title: map['title'],
        content: map['content'],
        imageUrl: map['imageUrl'],
        location: map['location'],
        createdAt: DateTime.parse(map['createdAt']),
      );
}
