// test/models/booking_cart_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:applamdep/models/booking_cart_model.dart';
import 'package:applamdep/models/nail_model.dart';

void main() {
  group('BookingCartItem', () {
    final nail = Nail(
      id: 'nail123',
      name: 'Summer Vibes',
      imgUrl: 'https://example.com/summer.jpg',
      price: 300000,
      description: '',
      storeId: 'store456',
      likes: 100,
      tags: [],
      storeIds: ['store456'],
    );

    test('fromNail creates BookingCartItem correctly', () {
      final cartItem = BookingCartItem.fromNail(nail, storeName: 'Nail Spa Luxury');

      expect(cartItem.nailId, 'nail123');
      expect(cartItem.nailName, 'Summer Vibes');
      expect(cartItem.price, 300000);
      expect(cartItem.storeName, 'Nail Spa Luxury');
      expect(cartItem.id, startsWith('nail123_'));
      expect(cartItem.createdAt, isNotNull);
    });

    test('toMap and fromMap round-trip works', () {
      final original = BookingCartItem(
        id: 'item789',
        nailId: 'nail123',
        nailName: 'Classic Red',
        nailImage: 'url.jpg',
        price: 200000,
        storeId: 'store1',
        storeName: 'Salon A',
        notes: 'Làm nhẹ tay',
      );

      final map = original.toMap();
      final restored = BookingCartItem.fromMap('item789', map);

      expect(restored.id, 'item789');
      expect(restored.notes, 'Làm nhẹ tay');
      expect(restored.price, 200000);
    });
  });
}