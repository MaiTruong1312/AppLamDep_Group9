// models/cart_model.dart
class CartItem {
  final String id; // Document ID
  final String nailId;
  final String nailName;
  final String nailImage;
  final double price;
  final String storeId;
  final String storeName;
  final int quantity;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    required this.id,
    required this.nailId,
    required this.nailName,
    required this.nailImage,
    required this.price,
    required this.storeId,
    required this.storeName,
    required this.quantity,
    this.createdAt,
    this.updatedAt,
  });

  double get totalPrice => price * quantity.toDouble(); // Sửa lỗi type

  Map<String, dynamic> toMap() {
    return {
      'nailId': nailId,
      'nailName': nailName,
      'nailImage': nailImage,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'quantity': quantity,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      nailId: map['nailId'] ?? '',
      nailName: map['nailName'] ?? '',
      nailImage: map['nailImage'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      quantity: map['quantity'] ?? 1,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }
}