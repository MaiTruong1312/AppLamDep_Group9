import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  // --- THUỘC TÍNH GỐC (Giữ nguyên vẹn từ service_model.dart) ---
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final int duration; // Giữ nguyên kiểu int (phút)
  final String category; // 'nail_service', 'additional_service', 'nails_care'
  final bool isActive;
  final String? imageUrl;
  final bool requiresNailDesign;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int? quantity;

  // --- THUỘC TÍNH BỔ SUNG CHO UI CLIENT (Lấy từ store_model.dart cũ) ---
  final double rating;

  Service({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.category,
    required this.isActive,
    this.imageUrl,
    this.requiresNailDesign = false,
    this.position = 0,
    this.createdAt,
    this.updatedAt,
    this.quantity = 0,
    // Giá trị mặc định cho UI
    this.rating = 5.0,
  });

  // Getter tiện ích để hiển thị UI
  String get durationText => "$duration mins";

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Service(
      id: doc.id,
      storeId: data['storeId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      duration: (data['duration'] as int?) ?? 30,
      category: data['category']?.toString() ?? 'additional_service',
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(), // Support cả 2 key
      requiresNailDesign: data['requiresNailDesign'] ?? false,
      position: (data['position'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      quantity: 0,
      // Map thêm fields UI nếu có
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  // Factory để parse từ mảng services bên trong Store Document
  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] ?? '',
      storeId: map['storeId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      duration: (map['duration'] is int)
          ? map['duration']
          : int.tryParse(map['duration'].toString()) ?? 30, // Xử lý an toàn
      category: map['category'] ?? 'additional_service',
      isActive: map['isActive'] ?? true,
      imageUrl: map['imageUrl'] ?? map['image_url'],
      requiresNailDesign: map['requiresNailDesign'] ?? false,
      position: (map['position'] as int?) ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'category': category,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'requiresNailDesign': requiresNailDesign,
      'position': position,
      'updatedAt': FieldValue.serverTimestamp(),
      'rating': rating,
    };
  }
}