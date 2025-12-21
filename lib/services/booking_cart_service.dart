// services/booking_cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/models/booking_cart_model.dart';

class BookingCartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tham chiếu đến booking cart collection của user hiện tại
  CollectionReference get _userBookingCartRef {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users').doc(userId).collection('booking_cart');
  }

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

      await _userBookingCartRef.doc(nailId).set({
        'nailId': nailId,
        'nailName': nailName,
        'nailImage': nailImage,
        'price': price,
        'storeId': storeId,
        'storeName': storeName,
        'notes': notes ?? '',
        'createdAt': FieldValue.serverTimestamp(), // Sử dụng server timestamp
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Dùng merge để tránh ghi đè dữ liệu cũ
    } catch (e) {
      print('Error adding to booking cart: $e');
      throw Exception('Failed to add to booking cart: $e');
    }
  }

  // Lấy số lượng mẫu nail trong giỏ đặt lịch
  Stream<int> getBookingCartItemCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _userBookingCartRef.snapshots().map((snapshot) => snapshot.docs.length);
  }

  // Lấy danh sách mẫu nail đã chọn
  Stream<List<BookingCartItem>> getBookingCartItems() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _userBookingCartRef
        .orderBy('createdAt', descending: true) // Sắp xếp theo thời gian thêm
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookingCartItem(
          id: doc.id,
          nailId: data['nailId']?.toString() ?? '',
          nailName: data['nailName']?.toString() ?? '',
          nailImage: data['nailImage']?.toString() ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          storeId: data['storeId']?.toString() ?? '',
          storeName: data['storeName']?.toString() ?? '',
          notes: data['notes']?.toString() ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  // Lấy danh sách items một lần (không dùng stream)
  Future<List<BookingCartItem>> getBookingCartItemsOnce() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _userBookingCartRef
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return BookingCartItem(
          id: doc.id,
          nailId: data['nailId']?.toString() ?? '',
          nailName: data['nailName']?.toString() ?? '',
          nailImage: data['nailImage']?.toString() ?? '',
          price: (data['price'] as num?)?.toDouble() ?? 0.0,
          storeId: data['storeId']?.toString() ?? '',
          storeName: data['storeName']?.toString() ?? '',
          notes: data['notes']?.toString() ?? '',
          createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      print('Error getting booking cart items: $e');
      return [];
    }
  }

  // Xóa mẫu nail khỏi giỏ
  Future<void> removeFromBookingCart(String nailId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _userBookingCartRef.doc(nailId).delete();
    } catch (e) {
      print('Error removing from booking cart: $e');
      throw Exception('Failed to remove from booking cart: $e');
    }
  }

  // Cập nhật ghi chú cho nail
  Future<void> updateNotes(String nailId, String notes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _userBookingCartRef.doc(nailId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating notes: $e');
      throw Exception('Failed to update notes: $e');
    }
  }

  // Xóa toàn bộ giỏ sau khi đặt lịch thành công
  Future<void> clearBookingCart() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _userBookingCartRef.get();

      // Sử dụng batch delete để xóa hàng loạt
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error clearing booking cart: $e');
      throw Exception('Failed to clear booking cart: $e');
    }
  }

  // Kiểm tra xem nail đã có trong giỏ chưa
  Future<bool> isInBookingCart(String nailId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _userBookingCartRef.doc(nailId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking if in booking cart: $e');
      return false;
    }
  }

  // Lấy thông tin cửa hàng từ booking cart items
  Future<Map<String, dynamic>?> getStoreInfoFromCart() async {
    try {
      final items = await getBookingCartItemsOnce();
      if (items.isEmpty) return null;

      // Nhóm items theo store
      final firstStoreId = items.first.storeId;
      final allSameStore = items.every((item) => item.storeId == firstStoreId);

      if (!allSameStore) {
        // Có nhiều cửa hàng khác nhau
        return {
          'hasMultipleStores': true,
          'stores': _groupItemsByStore(items),
        };
      }

      // Tất cả items cùng 1 store
      final firstItem = items.first;
      return {
        'hasMultipleStores': false,
        'storeId': firstItem.storeId,
        'storeName': firstItem.storeName,
        'itemCount': items.length,
        'totalPrice': items.fold(0.0, (sum, item) => sum + item.price),
      };
    } catch (e) {
      print('Error getting store info from cart: $e');
      return null;
    }
  }

  // Phương thức helper để nhóm items theo store
  Map<String, List<BookingCartItem>> _groupItemsByStore(List<BookingCartItem> items) {
    final Map<String, List<BookingCartItem>> grouped = {};

    for (var item in items) {
      if (!grouped.containsKey(item.storeId)) {
        grouped[item.storeId] = [];
      }
      grouped[item.storeId]!.add(item);
    }

    return grouped;
  }

  // Xóa tất cả items của một cửa hàng cụ thể
  Future<void> removeStoreItems(String storeId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final snapshot = await _userBookingCartRef
          .where('storeId', isEqualTo: storeId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      if (snapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      print('Error removing store items: $e');
      throw Exception('Failed to remove store items: $e');
    }
  }
}