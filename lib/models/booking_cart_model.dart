// models/booking_cart_model.dart
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

  Map<String, dynamic> toMap() {
    return {
      'nailId': nailId,
      'nailName': nailName,
      'nailImage': nailImage,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}