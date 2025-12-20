// services/booking_cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/models/booking_cart_model.dart';

class BookingCartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Thêm mẫu nail vào giỏ đặt lịch
  Future<void> addToBookingCart({
    required String nailId,
    required String nailName,
    required String nailImage,
    required double price,
    required String storeId,
    required String storeName,
    String? notes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final cartRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('booking_cart') // Đổi tên collection
          .doc(nailId);

      await cartRef.set({
        'nailId': nailId,
        'nailName': nailName,
        'nailImage': nailImage,
        'price': price,
        'storeId': storeId,
        'storeName': storeName,
        'notes': notes ?? '', // Ghi chú cho nail (kiểu nail mong muốn)
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to add to booking cart: $e');
    }
  }

  // Lấy số lượng mẫu nail trong giỏ đặt lịch
  Stream<int> getBookingCartItemCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('booking_cart')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Lấy danh sách mẫu nail đã chọn
  Stream<List<BookingCartItem>> getBookingCartItems() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('booking_cart')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return BookingCartItem(
          id: doc.id,
          nailId: data['nailId'] ?? '',
          nailName: data['nailName'] ?? '',
          nailImage: data['nailImage'] ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          storeId: data['storeId'] ?? '',
          storeName: data['storeName'] ?? '',
          notes: data['notes'] ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  // Xóa mẫu nail khỏi giỏ
  Future<void> removeFromBookingCart(String nailId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('booking_cart')
          .doc(nailId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from booking cart: $e');
    }
  }

  // Cập nhật ghi chú
  Future<void> updateNotes(String nailId, String notes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('booking_cart')
          .doc(nailId)
          .update({
        'notes': notes,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to update notes: $e');
    }
  }

  // Xóa toàn bộ giỏ sau khi đặt lịch thành công
  Future<void> clearBookingCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('booking_cart')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to clear booking cart: $e');
    }
  }
}