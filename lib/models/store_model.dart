import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String imgUrl;
  final double rating;
  final int reviewCount;
  final double distance;
  final String phone;
  final String description;
  final List<String> services;
  final bool isOpen;
  final GeoPoint location;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.imgUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.distance = 0.0,
    this.phone = '',
    this.description = '',
    this.services = const [],
    this.isOpen = true,
    required this.location,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      imgUrl: data['img_url'] ?? '',
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      services: List<String>.from(data['services'] ?? []),
      isOpen: data['is_open'] ?? true,
      location: data['location'] ?? const GeoPoint(0, 0),
    );
  }

  // Helper method to create store data for search
  Map<String, dynamic> toSearchData() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'img_url': imgUrl,
      'rating': rating,
      'review_count': reviewCount,
      'distance': distance,
      'phone': phone,
      'description': description,
      'services': services,
      'is_open': isOpen,
    };
  }
}