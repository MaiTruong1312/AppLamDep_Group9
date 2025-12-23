import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final List<String> storeIds;
  final String name;
  final String description;
  final double price;
  final int duration;
  final String category;
  final bool isActive;
  final String? imageUrl;
  final bool requiresNailDesign;
  final int position;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  int? quantity;
  final double rating;

  Service({
    required this.id,
    required this.storeIds,
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
    this.rating = 5.0,
  });
  String get durationText => "$duration mins";
  bool isAvailableAt(String specificStoreId) {
    return storeIds.contains(specificStoreId);
  }

  factory Service.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<String> parsedStoreIds = [];
    if (data['storeIds'] != null) {
      parsedStoreIds = List<String>.from(data['storeIds']);
    } else if (data['storeId'] != null) {
      parsedStoreIds = [data['storeId'].toString()];
    }

    return Service(
      id: doc.id,
      storeIds: parsedStoreIds,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      duration: (data['duration'] as int?) ?? 30,
      category: data['category']?.toString() ?? 'additional_service',
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
      requiresNailDesign: data['requiresNailDesign'] ?? false,
      position: (data['position'] as int?) ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      quantity: 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 5.0,
    );
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    List<String> parsedStoreIds = [];
    if (map['storeIds'] != null) {
      parsedStoreIds = List<String>.from(map['storeIds']);
    } else if (map['storeId'] != null) {
      parsedStoreIds = [map['storeId'].toString()];
    }

    return Service(
      id: map['id'] ?? '',
      storeIds: parsedStoreIds,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      duration: (map['duration'] is int)
          ? map['duration']
          : int.tryParse(map['duration'].toString()) ?? 30,
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
      'storeIds': storeIds,
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