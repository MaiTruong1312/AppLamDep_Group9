// lib/models/coupon_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code;
  final String discountType; // 'PERCENTAGE' or 'FIXED'
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maxDiscountAmount;
  final DateTime expiryDate;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final List<String> applicableCategories;
  final List<String> targetUsers;
  final bool isFirstBookingOnly;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
    this.maxDiscountAmount,
    required this.expiryDate,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    this.applicableCategories = const [],
    this.targetUsers = const [],
    this.isFirstBookingOnly = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Coupon(
      id: doc.id,
      code: data['code']?.toString() ?? '',
      discountType: data['discountType']?.toString() ?? 'PERCENTAGE',
      discountValue: (data['discountValue'] as num?)?.toDouble() ?? 0.0,
      minimumOrderAmount: (data['minimumOrderAmount'] as num?)?.toDouble(),
      maxDiscountAmount: (data['maxDiscountAmount'] as num?)?.toDouble(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usageLimit: (data['usageLimit'] as int?) ?? 0,
      usedCount: (data['usedCount'] as int?) ?? 0,
      isActive: data['isActive'] ?? false,
      applicableCategories: List<String>.from(data['applicableServiceCategories'] ?? []),
      targetUsers: List<String>.from(data['targetUsers'] ?? []),
      isFirstBookingOnly: data['isFirstBookingOnly'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountType': discountType,
      'discountValue': discountValue,
      if (minimumOrderAmount != null) 'minimumOrderAmount': minimumOrderAmount,
      if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'applicableCategories': applicableCategories,
      'targetUsers': targetUsers,
      'isFirstBookingOnly': isFirstBookingOnly,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Áp dụng discount
  double applyDiscount(double originalPrice) {
    if (!isValid) return originalPrice;

    if (minimumOrderAmount != null && originalPrice < minimumOrderAmount!) {
      return originalPrice;
    }

    double discount = 0;

    if (discountType == 'PERCENTAGE') {
      discount = originalPrice * (discountValue / 100);
      if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
        discount = maxDiscountAmount!;
      }
    } else {
      discount = discountValue;
    }

    return originalPrice - discount;
  }

  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isBefore(expiryDate) &&
        usedCount < usageLimit;
  }

  double calculateDiscountAmount(double originalPrice) {
    return originalPrice - applyDiscount(originalPrice);
  }
}