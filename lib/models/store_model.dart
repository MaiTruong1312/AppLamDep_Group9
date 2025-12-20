import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_model.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String imgUrl;
  final GeoPoint? location;
  final Map<String, dynamic> openingHours;
  final double rating;
  final int reviewsCount;
  final List<Service> services;
  final List<Flashsale> flashsales;
  final List<String> portfolio;
  final List<Review> reviews;
  final int totalNails;
  final int followerCount;
  final int viewCount;
  final String hotline; // Khớp với lỗi dòng 353
  final String email;
  final String website;
  final String description;
  final double distance;

  Store({
    required this.id, required this.name, required this.address, required this.imgUrl,
    this.location, this.openingHours = const {}, this.rating = 0.0, this.reviewsCount = 0,
    this.services = const [], this.flashsales = const [], this.portfolio = const [],
    this.reviews = const [], this.totalNails = 0, this.followerCount = 0,
    this.viewCount = 0, this.hotline = '', this.email = '', this.website = '', this.description = '', this.distance = 0.0,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      imgUrl: data['img_url'] ?? '',
      location: data['location'] as GeoPoint?,
      openingHours: data['opening_hours'] is Map ? data['opening_hours'] : {},
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: data['review_count'] as int? ?? 0,
      totalNails: data['total_nails'] as int? ?? 0,
      followerCount: data['follower_count'] as int? ?? 0,
      viewCount: data['view_count'] as int? ?? 0,
      portfolio: List<String>.from(data['portfolio'] ?? []),
      hotline: data['hotline'] ?? data['phone'] ?? '', // Xử lý cả 2 key
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      services: (data['services'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => Service.fromMap(s)).toList(),
      flashsales: (data['flashsales'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((f) => Flashsale.fromMap(f)).toList(),
      reviews: (data['reviews'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((r) => Review.fromMap(r)).toList(),
    );
  }
}

class Flashsale {
  final String title;
  final String imageUrl; // Phải có trường này để sửa lỗi dòng 207
  final double discount;

  Flashsale({required this.title, required this.imageUrl, required this.discount});

  factory Flashsale.fromMap(Map<String, dynamic> map) => Flashsale(
    title: map['title'] ?? '',
    imageUrl: map['imageUrl'] ?? map['image_url'] ?? '',
    discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
  );
}

class Service {
  final String name;
  final String imageUrl;
  final String duration;
  final double rating;
  final int bookings;
  final double price;

  Service({
    required this.name, required this.imageUrl, required this.duration,
    required this.price, this.rating = 5.0, this.bookings = 0,
  });

  factory Service.fromMap(Map<String, dynamic> map) => Service(
    name: map['name'] ?? '',
    imageUrl: map['imageUrl'] ?? map['image_url'] ?? '',
    duration: map['duration'] ?? '',
    bookings: map['booking'] ?? map['bookings'] ?? 0,
    rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
  );
}