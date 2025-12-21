import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_model.dart';
import 'service_model.dart'; // Import model Service chuẩn

class Store {
  final String id;
  final String name;
  final String address;
  final String imgUrl;
  final GeoPoint? location;
  final Map<String, dynamic> openingHours;
  final double rating;
  final int reviewsCount;
  final List<Service> services; // Dùng Service chuẩn
  final List<Flashsale> flashsales;
  final List<String> portfolio;
  final List<Review> reviews;
  final int totalNails;
  final int followerCount;
  final int viewCount;
  final String hotline;
  final String email;
  final String website;
  final String description;
  final double distance;
  final bool isOpen;

  Store({
    required this.id, required this.name, required this.address, required this.imgUrl,
    this.location, this.openingHours = const {}, this.rating = 0.0, this.reviewsCount = 0,
    this.services = const [], this.flashsales = const [], this.portfolio = const [],
    this.reviews = const [], this.totalNails = 0, this.followerCount = 0,
    this.viewCount = 0, this.hotline = '', this.email = '', this.website = '',
    this.description = '', this.distance = 0.0, this.isOpen = true,
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
      reviewsCount: data['review_count'] ?? 0,
      totalNails: data['total_nails'] ?? 0,
      followerCount: data['follower_count'] ?? 0,
      viewCount: data['view_count'] ?? 0,
      portfolio: List<String>.from(data['portfolio'] ?? []),
      hotline: data['hotline'] ?? data['phone'] ?? '',
      email: data['email'] ?? '',
      website: data['website'] ?? '',
      description: data['description'] ?? '',
      // Map danh sách services
      services: (data['services'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((s) => Service.fromMap(s)).toList(),
      flashsales: (data['flashsales'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((f) => Flashsale.fromMap(f)).toList(),
      reviews: (data['reviews'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((r) => Review.fromMap(r)).toList(),
      isOpen: data['is_open'] ?? true,
    );
  }

  Store copyWith({double? distance}) {
    return Store(
      id: id, name: name, address: address, imgUrl: imgUrl, location: location,
      openingHours: openingHours, rating: rating, reviewsCount: reviewsCount,
      services: services, flashsales: flashsales, portfolio: portfolio,
      reviews: reviews, totalNails: totalNails, followerCount: followerCount,
      viewCount: viewCount, hotline: hotline, email: email, website: website,
      description: description, distance: distance ?? this.distance, isOpen: isOpen,
    );
  }
}

class Flashsale {
  final String title;
  final String imageUrl;
  final double discount;

  Flashsale({required this.title, required this.imageUrl, required this.discount});

  factory Flashsale.fromMap(Map<String, dynamic> map) => Flashsale(
    title: map['title'] ?? '',
    imageUrl: map['imageUrl'] ?? map['image_url'] ?? '',
    discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
  );
}