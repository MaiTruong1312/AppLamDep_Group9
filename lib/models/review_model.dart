import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final double rating;
  final String comment;
  final String? mediaUrl;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.rating,
    required this.comment,
    this.mediaUrl,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['user_id'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      mediaUrl: data['media_url'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  // Thêm vào file review_model.dart
  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      id: '', // Có thể để trống nếu bình luận nằm trong mảng của Store
      userId: data['user_id'] ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      mediaUrl: data['media_url'],
      // Chuyển đổi Timestamp từ Firestore sang DateTime
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
