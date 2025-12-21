// lib/models/service_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String storeId;
  final String name;
  final String description;
  final double price;
  final int duration; // phút
  final String category; // 'nail_service', 'additional_service', 'nails_care'
  final bool isActive;
  final String? imageUrl;
  final bool requiresNailDesign;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int? quantity;

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
  });

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
      imageUrl: data['imageUrl']?.toString(),
      requiresNailDesign: data['requiresNailDesign'] ?? false,
      position: (data['position'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      quantity: 0,
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
    };
  }
}