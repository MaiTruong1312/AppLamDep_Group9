// lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/booking_cart_model.dart';

class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? photoUrl;
  final String? gender;
  final String? dob;
  final List<BookingCartItem>? bookingCartItems; // Thêm field mới
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.photoUrl,
    this.gender,
    this.dob,
    this.bookingCartItems,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse booking cart items
    final cartItemsData = data['booking_cart_items'] as List<dynamic>? ?? [];
    final bookingCartItems = cartItemsData.map((item) {
      if (item is Map<String, dynamic>) {
        return BookingCartItem(
          id: item['id']?.toString() ?? '',
          nailId: item['nailId']?.toString() ?? '',
          nailName: item['nailName']?.toString() ?? '',
          nailImage: item['nailImage']?.toString() ?? '',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          storeId: item['storeId']?.toString() ?? '',
          storeName: item['storeName']?.toString() ?? '',
          notes: item['notes']?.toString() ?? '',
        );
      }
      return null;
    }).where((item) => item != null).cast<BookingCartItem>().toList();

    return UserModel(
      id: doc.id,
      name: data['name']?.toString() ?? 'Anonymous',
      phone: data['phone']?.toString(),
      email: data['email']?.toString(),
      photoUrl: data['photoUrl']?.toString(),
      gender: data['gender']?.toString(),
      dob: data['dob']?.toString(),
      bookingCartItems: bookingCartItems,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'gender': gender,
      'dob': dob,
      if (bookingCartItems != null)
        'booking_cart_items': bookingCartItems!.map((item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}