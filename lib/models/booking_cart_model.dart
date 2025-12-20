// models/booking_cart_model.dart
import 'nail_model.dart'; // Thêm import này

class BookingCartItem {
  final String id;
  final String nailId;
  final String nailName;
  final String nailImage;
  final double price;
  final String storeId;
  final String storeName;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BookingCartItem({
    required this.id,
    required this.nailId,
    required this.nailName,
    required this.nailImage,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor từ Nail
  factory BookingCartItem.fromNail(Nail nail, {String storeName = ''}) {
    return BookingCartItem(
      id: '${nail.id}_${DateTime.now().millisecondsSinceEpoch}', // Tạo id duy nhất
      nailId: nail.id,
      nailName: nail.name,
      nailImage: nail.imgUrl,
      price: nail.price.toDouble(),
      storeId: nail.storeId,
      storeName: storeName,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nailId': nailId,
      'nailName': nailName,
      'nailImage': nailImage,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'notes': notes,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  // Factory constructor từ Map (Firestore)
  factory BookingCartItem.fromMap(String id, Map<String, dynamic> map) {
    return BookingCartItem(
      id: id,
      nailId: map['nailId'] ?? '',
      nailName: map['nailName'] ?? '',
      nailImage: map['nailImage'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int)
          : null,
    );
  }
}