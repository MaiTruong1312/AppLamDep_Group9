// lib/models/store_working_hours_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreWorkingHours {
  final String id;
  final String storeId;
  final int dayOfWeek; // 0 = Sunday, 1 = Monday, ...
  final bool isOpen;
  final String openTime;
  final String closeTime;
  final String? breakStart;
  final String? breakEnd;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StoreWorkingHours({
    required this.id,
    required this.storeId,
    required this.dayOfWeek,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
    this.breakStart,
    this.breakEnd,
    this.createdAt,
    this.updatedAt,
  });

  factory StoreWorkingHours.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreWorkingHours(
      id: doc.id,
      storeId: data['storeId']?.toString() ?? '',
      dayOfWeek: (data['dayOfWeek'] as int?) ?? 1,
      isOpen: data['isOpen'] ?? true,
      openTime: data['openTime']?.toString() ?? '09:00',
      closeTime: data['closeTime']?.toString() ?? '18:00',
      breakStart: data['breakStart']?.toString(),
      breakEnd: data['breakEnd']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}