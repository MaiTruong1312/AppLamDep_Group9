// lib/models/appointment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/nail_model.dart';
import 'package:applamdep/models/service_model.dart';

class AppointmentService {
  final String serviceId;
  final String serviceName;
  final double price;
  final int quantity;

  AppointmentService({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'quantity': quantity,
    };
  }

  factory AppointmentService.fromMap(Map<String, dynamic> map) {
    return AppointmentService(
      serviceId: map['serviceId']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as int?) ?? 1,
    );
  }
}

class Appointment {
  final String id;
  final String userId;
  final String storeId;
  final String? technicianId;
  final DateTime bookingDate;
  final String timeSlot;
  final int duration;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'

  // Nail designs
  final List<Map<String, dynamic>> nailDesigns;

  // Additional services
  final List<AppointmentService> additionalServices;

  // Payment
  final double totalPrice;
  final double discountAmount;
  final double finalPrice;
  final String? couponCode;

  // Customer info
  final String customerName;
  final String customerPhone;
  final String? customerNotes;

  // Payment info
  final String paymentStatus; // 'pending', 'paid', 'refunded'
  final String? paymentMethod;
  final String? paymentId;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  Appointment({
    required this.id,
    required this.userId,
    required this.storeId,
    this.technicianId,
    required this.bookingDate,
    required this.timeSlot,
    required this.duration,
    required this.status,
    this.nailDesigns = const [],
    this.additionalServices = const [],
    required this.totalPrice,
    this.discountAmount = 0.0,
    required this.finalPrice,
    this.couponCode,
    required this.customerName,
    required this.customerPhone,
    this.customerNotes,
    required this.paymentStatus,
    this.paymentMethod,
    this.paymentId,
    this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse nail designs
    final nailDesigns = List<Map<String, dynamic>>.from(data['nailDesigns'] ?? []);

    // Parse additional services
    final servicesData = List<Map<String, dynamic>>.from(data['additionalServices'] ?? []);
    final additionalServices = servicesData.map((service) =>
        AppointmentService.fromMap(service)).toList();

    return Appointment(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      storeId: data['storeId']?.toString() ?? '',
      technicianId: data['technicianId']?.toString(),
      bookingDate: (data['bookingDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timeSlot: data['timeSlot']?.toString() ?? '',
      duration: (data['duration'] as int?) ?? 60,
      status: data['status']?.toString() ?? 'pending',
      nailDesigns: nailDesigns,
      additionalServices: additionalServices,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (data['finalPrice'] as num?)?.toDouble() ?? 0.0,
      couponCode: data['couponCode']?.toString(),
      customerName: data['customerName']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      customerNotes: data['customerNotes']?.toString(),
      paymentStatus: data['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: data['paymentMethod']?.toString(),
      paymentId: data['paymentId']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      cancellationReason: data['cancellationReason']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'storeId': storeId,
      if (technicianId != null) 'technicianId': technicianId,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'timeSlot': timeSlot,
      'duration': duration,
      'status': status,
      'nailDesigns': nailDesigns,
      'additionalServices': additionalServices.map((s) => s.toMap()).toList(),
      'totalPrice': totalPrice,
      'discountAmount': discountAmount,
      'finalPrice': finalPrice,
      if (couponCode != null) 'couponCode': couponCode,
      'customerName': customerName,
      'customerPhone': customerPhone,
      if (customerNotes != null) 'customerNotes': customerNotes,
      'paymentStatus': paymentStatus,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentId != null) 'paymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get formattedDate {
    return '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}';
  }

  String get formattedTime {
    return timeSlot.split('-')[0];
  }
}