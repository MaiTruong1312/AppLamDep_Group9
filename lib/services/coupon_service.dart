// lib/services/coupon_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:applamdep/models/coupon_model.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Validate coupon
  Future<Coupon?> validateCoupon(String code, double orderAmount) async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final coupon = Coupon.fromFirestore(doc);

      // Check basic validity
      if (!coupon.isValid) return null;

      // Check minimum order amount
      if (coupon.minimumOrderAmount != null &&
          orderAmount < coupon.minimumOrderAmount!) {
        return null;
      }

      // Check if coupon is for first booking only
      if (coupon.isFirstBookingOnly) {
        final user = _auth.currentUser;
        if (user != null) {
          final userBookings = await _firestore
              .collection('bookings')
              .where('user_id', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (userBookings.docs.isNotEmpty) {
            return null; // User has previous bookings
          }
        }
      }

      // Check if coupon is targeted to specific users
      if (coupon.targetUsers.isNotEmpty) {
        final user = _auth.currentUser;
        if (user == null || !coupon.targetUsers.contains(user.uid)) {
          return null;
        }
      }

      return coupon;
    } catch (e) {
      print('Error validating coupon: $e');
      return null;
    }
  }

  // Apply coupon and increment usage
  Future<void> applyCoupon(String couponId) async {
    try {
      await _firestore
          .collection('coupons')
          .doc(couponId)
          .update({
        'usedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error applying coupon: $e');
      rethrow;
    }
  }

  // Get all available coupons for current user
  Future<List<Coupon>> getAvailableCoupons() async {
    try {
      final snapshot = await _firestore
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .where('expiryDate', isGreaterThan: Timestamp.now())
          .orderBy('expiryDate')
          .get();

      final coupons = snapshot.docs
          .map((doc) => Coupon.fromFirestore(doc))
          .where((coupon) => coupon.isValid)
          .toList();

      // Filter by user eligibility if needed
      final user = _auth.currentUser;
      if (user != null) {
        return coupons.where((coupon) {
          // Check if coupon has target users
          if (coupon.targetUsers.isNotEmpty) {
            return coupon.targetUsers.contains(user.uid);
          }
          return true;
        }).toList();
      }

      return coupons;
    } catch (e) {
      print('Error getting available coupons: $e');
      return [];
    }
  }

  // Check if user has used this coupon before
  Future<bool> hasUserUsedCoupon(String couponCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: user.uid)
          .where('coupon_code', isEqualTo: couponCode)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking coupon usage: $e');
      return false;
    }
  }

  // Get coupon by ID
  Future<Coupon?> getCouponById(String couponId) async {
    try {
      final doc = await _firestore
          .collection('coupons')
          .doc(couponId)
          .get();

      if (doc.exists) {
        return Coupon.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting coupon by ID: $e');
      return null;
    }
  }

  // Calculate discount amount without applying
  Future<double> calculateDiscount(String couponCode, double orderAmount) async {
    final coupon = await validateCoupon(couponCode, orderAmount);
    if (coupon == null) return 0.0;

    return coupon.calculateDiscountAmount(orderAmount);
  }

  // Get coupon usage analytics
  Future<Map<String, dynamic>> getCouponAnalytics(String couponId) async {
    try {
      final doc = await _firestore
          .collection('coupons')
          .doc(couponId)
          .get();

      if (!doc.exists) {
        return {
          'totalUsed': 0,
          'remainingUses': 0,
          'isExpired': true,
          'isActive': false,
        };
      }

      final coupon = Coupon.fromFirestore(doc);
      final now = DateTime.now();

      return {
        'totalUsed': coupon.usedCount,
        'remainingUses': coupon.usageLimit - coupon.usedCount,
        'isExpired': now.isAfter(coupon.expiryDate),
        'isActive': coupon.isActive,
        'expiryDate': coupon.expiryDate,
      };
    } catch (e) {
      print('Error getting coupon analytics: $e');
      return {
        'totalUsed': 0,
        'remainingUses': 0,
        'isExpired': true,
        'isActive': false,
      };
    }
  }
}