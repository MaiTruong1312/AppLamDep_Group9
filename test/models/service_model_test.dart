// test/models/service_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/service_model.dart';

// Cách mock DocumentSnapshot đúng chuẩn (không extends trực tiếp)
class MockDocumentSnapshot extends Mock implements DocumentSnapshot {}

void main() {
  group('Service Model', () {
    late MockDocumentSnapshot mockDoc;

    setUp(() {
      mockDoc = MockDocumentSnapshot();
      // Register fallback values cho các type phức tạp nếu cần
      registerFallbackValue(GeoPoint(0, 0));
      registerFallbackValue(Timestamp.now());
    });

    test('fromFirestore handles both storeIds and legacy storeId', () {
      when(() => mockDoc.id).thenReturn('svc1');
      when(() => mockDoc.data()).thenReturn({
        'storeIds': ['store1', 'store2'],
        'name': 'Gel Polish',
        'description': 'Dịch vụ sơn gel cao cấp',
        'price': 250000,
        'duration': 60,
        'category': 'nail_service',
        'isActive': true,
      });

      final service = Service.fromFirestore(mockDoc);

      expect(service.id, 'svc1');
      expect(service.storeIds, ['store1', 'store2']);
      expect(service.name, 'Gel Polish');
      expect(service.description, 'Dịch vụ sơn gel cao cấp');
      expect(service.category, 'nail_service');
      expect(service.isActive, true);
      expect(service.isAvailableAt('store1'), true);
      expect(service.isAvailableAt('store3'), false);
      expect(service.durationText, '60 mins');
    });

    test('fromFirestore fallback to single storeId if storeIds missing', () {
      when(() => mockDoc.id).thenReturn('svc2');
      when(() => mockDoc.data()).thenReturn({
        'storeId': 'store999', // trường cũ
        'name': 'Acrylic Nails',
        'description': 'Móng acrylic bền đẹp',
        'price': 350000,
        'duration': 90,
        'category': 'nail_extension',
        'isActive': true,
      });

      final service = Service.fromFirestore(mockDoc);

      expect(service.storeIds, ['store999']);
      expect(service.name, 'Acrylic Nails');
      expect(service.durationText, '90 mins');
    });

    test('durationText returns correct format and other getters work', () {
      // Đầy đủ các required parameters
      final service = Service(
        id: 'svc3',
        storeIds: ['store1'],
        name: 'Manicure',
        description: 'Chăm sóc móng tay cơ bản',
        price: 150000,
        duration: 45,
        category: 'basic_care',
        isActive: true,
      );

      expect(service.durationText, '45 mins');
      expect(service.isAvailableAt('store1'), true);
      expect(service.isAvailableAt('store2'), false);
    });

    test('fromFirestore handles missing optional fields gracefully', () {
      when(() => mockDoc.id).thenReturn('svc4');
      when(() => mockDoc.data()).thenReturn({
        'storeIds': ['store10'],
        'name': 'Pedicure',
        'description': 'Chăm sóc móng chân',
        'price': 200000,
        'duration': 50,
        'category': 'foot_care',
        'isActive': false,
        'imageUrl': null,
      });

      final service = Service.fromFirestore(mockDoc);

      expect(service.imageUrl, isNull);
      expect(service.isActive, false);
      expect(service.rating, 5.0); // default value
      expect(service.quantity, 0); // default
    });
  });
}