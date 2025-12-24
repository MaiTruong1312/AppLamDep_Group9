import 'package:flutter_test/flutter_test.dart';
import 'package:applamdep/models/coupon_model.dart';

void main() {
  group('Coupon Model', () {
    late Coupon percentageCoupon;
    late Coupon fixedCoupon;

    setUp(() {
      percentageCoupon = Coupon(
        id: 'c1',
        code: 'SAVE20',
        discountType: 'PERCENTAGE',
        discountValue: 20.0,
        minimumOrderAmount: 300000,
        maxDiscountAmount: 100000,
        expiryDate: DateTime.now().add(Duration(days: 7)),
        usageLimit: 100,
        usedCount: 10,
        isActive: true,
      );

      fixedCoupon = Coupon(
        id: 'c2',
        code: 'FIXED50',
        discountType: 'FIXED',
        discountValue: 50000,
        expiryDate: DateTime.now().add(Duration(days: 1)),
        usageLimit: 50,
        usedCount: 49,
        isActive: true,
      );
    });

    test('applyDiscount - percentage with max cap', () {
      final discounted = percentageCoupon.applyDiscount(600000);
      expect(discounted, 500000); // 20% = 120k nhưng cap 100k → giảm 100k
    });

    test('applyDiscount - percentage below minimum', () {
      final discounted = percentageCoupon.applyDiscount(200000);
      expect(discounted, 200000); // không đủ min → không giảm
    });

    test('applyDiscount - fixed amount', () {
      final discounted = fixedCoupon.applyDiscount(200000);
      expect(discounted, 150000);
    });

    test('isValid returns false when expired', () {
      final expired = Coupon(
        id: 'exp',
        code: 'OLD',
        discountType: 'PERCENTAGE',
        discountValue: 10,
        expiryDate: DateTime.now().subtract(Duration(days: 1)),
        usageLimit: 10,
        usedCount: 0,
        isActive: true,
      );
      expect(expired.isValid, false);
    });

    test('isValid returns false when usage limit reached', () {
      final usedUp = Coupon(
        id: 'used',
        code: 'FULL',
        discountType: 'FIXED',
        discountValue: 50000,
        expiryDate: DateTime.now().add(Duration(days: 10)),
        usageLimit: 5,
        usedCount: 5,
        isActive: true,
      );
      expect(usedUp.isValid, false);
    });
  });
}