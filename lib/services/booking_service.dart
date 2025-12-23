// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/models/booking_slot_model.dart';
import 'package:applamdep/models/appointment_model.dart';
import 'package:applamdep/models/service_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- 1. SỬA HÀM LẤY SLOT (QUAN TRỌNG NHẤT) ---
  Future<List<BookingSlot>> getAvailableSlots({
    required String storeId,
    required DateTime date,
  }) async {
    try {
      // Reset về đầu ngày và cuối ngày
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      print('🔍 Đang tìm slot Store: $storeId');
      print('   📅 Ngày: $startOfDay -> $endOfDay');

      final snapshot = await _firestore
          .collection('booking_slots')
          .where('storeId', isEqualTo: storeId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'available')
      // .orderBy('timeSlot') // <--- BỎ DÒNG NÀY ĐỂ TRÁNH LỖI INDEX
          .get();

      print('✅ Tìm thấy ${snapshot.docs.length} slots.');

      final slots = snapshot.docs
          .map((doc) => BookingSlot.fromFirestore(doc))
          .toList();

      // Sắp xếp thủ công bằng code Dart (An toàn hơn)
      slots.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));

      return slots;
    } catch (e) {
      print('❌ Lỗi lấy slot: $e');
      return [];
    }
  }

  // --- 2. CẬP NHẬT HÀM LẤY SERVICE (THEO LOGIC MỚI storeIds) ---
  Future<List<Service>> getStoreServices(String storeId) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('storeIds', arrayContains: storeId) // Sửa thành arrayContains
          .where('isActive', isEqualTo: true)
      // .orderBy('position') // Tạm bỏ nếu chưa có index
          .get();

      return snapshot.docs
          .map((doc) => Service.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting store services: $e');
      return [];
    }
  }

  // Lấy appointments của user
  Stream<List<Appointment>> getUserAppointments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('userId', isEqualTo: user.uid)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromFirestore(doc))
          .toList();
    });
  }

  // Tạo appointment mới
  Future<String> createAppointment(Map<String, dynamic> appointmentData) async {
    try {
      final docRef = await _firestore
          .collection('appointments')
          .add(appointmentData);

      return docRef.id;
    } catch (e) {
      print('Error creating appointment: $e');
      rethrow;
    }
  }

  // Hủy appointment
  Future<void> cancelAppointment(String appointmentId, String reason) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'cancellationReason': reason,
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error cancelling appointment: $e');
      rethrow;
    }
  }

  // Check slot availability
  Future<bool> checkSlotAvailability(String slotId) async {
    try {
      final doc = await _firestore
          .collection('booking_slots')
          .doc(slotId)
          .get();

      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      final maxCustomers = data['maxCustomers'] as int? ?? 3;
      final currentBookings = data['currentBookings'] as int? ?? 0;

      return status == 'available' && currentBookings < maxCustomers;
    } catch (e) {
      print('Error checking slot availability: $e');
      return false;
    }
  }
}