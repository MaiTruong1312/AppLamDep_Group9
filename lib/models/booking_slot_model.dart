// lib/models/booking_slot_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingSlot {
  final String id;
  final String storeId;
  final String? technicianId;
  final DateTime date;
  final String timeSlot; // "09:00-10:00"
  final int duration;
  final String status; // 'available', 'booked', 'blocked'
  final int maxCustomers;
  final int currentBookings;
  final double priceModifier;

  BookingSlot({
    required this.id,
    required this.storeId,
    this.technicianId,
    required this.date,
    required this.timeSlot,
    required this.duration,
    required this.status,
    required this.maxCustomers,
    required this.currentBookings,
    this.priceModifier = 1.0,
  });

  factory BookingSlot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingSlot(
      id: doc.id,
      storeId: data['storeId']?.toString() ?? '',
      technicianId: data['technicianId']?.toString(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot']?.toString() ?? '',
      duration: (data['duration'] as int?) ?? 60,
      status: data['status']?.toString() ?? 'available',
      maxCustomers: (data['maxCustomers'] as int?) ?? 3,
      currentBookings: (data['currentBookings'] as int?) ?? 0,
      priceModifier: (data['priceModifier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  // Check if slot is available
  bool get isAvailable => status == 'available' && currentBookings < maxCustomers;

  // Get start time from timeslot
  String get startTime => timeSlot.split('-')[0];

  // Get end time from timeslot
  String get endTime => timeSlot.split('-')[1];
}