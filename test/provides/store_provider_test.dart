// test/providers/store_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/providers/store_provider.dart';
import 'package:applamdep/models/store_model.dart';
import 'package:applamdep/services/store_service.dart';

class MockStoreService extends Mock implements StoreService {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late StoreProvider provider;
  late MockStoreService mockService;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockService = MockStoreService();
    mockFirestore = MockFirebaseFirestore();

    // Inject cả 2 mock qua constructor – an toàn, sạch sẽ
    provider = StoreProvider(
      firestore: mockFirestore,
      storeService: mockService,
    );
  });

  group('StoreProvider', () {
    test('fetchUserLocation sets fixed position correctly and no error', () async {
      await provider.fetchUserLocation();

      expect(provider.isLoading, false);
      expect(provider.userPosition, isNotNull);
      expect(provider.userPosition!.latitude, closeTo(21.0091, 0.0001));
      expect(provider.userPosition!.longitude, closeTo(105.8289, 0.0001));
      expect(provider.error, null);
    });

    test('fetchAllStores calculates distance and sorts stores by distance ascending', () async {
      await provider.fetchUserLocation();

      final nearStore = Store(
        id: 'near',
        name: 'Near Store',
        address: '',
        imgUrl: '',
        location: GeoPoint(21.0095, 105.8290),
      );

      final farStore = Store(
        id: 'far',
        name: 'Far Store',
        address: '',
        imgUrl: '',
        location: GeoPoint(21.1000, 105.9000),
      );

      when(() => mockService.getAllStores(userPosition: any(named: 'userPosition')))
          .thenAnswer((_) async => [farStore, nearStore]);

      await provider.fetchAllStores();

      expect(provider.stores.length, 2);
      expect(provider.stores.first.id, 'near');
      expect(provider.stores.first.distance, lessThan(provider.stores.last.distance));
    });

    test('storesWithFlashSales returns only stores having flashsales', () async {
      await provider.fetchUserLocation();

      final storeWithFlash = Store(
        id: 'f1',
        name: 'Flash Store',
        address: '',
        imgUrl: '',
        location: GeoPoint(21.0091, 105.8289),
        flashsales: [
          Flashsale(title: '50% Off', imageUrl: '', discount: 50, description: '', conditions: ''),
        ],
      );

      final storeNoFlash = Store(
        id: 'f2',
        name: 'Normal Store',
        address: '',
        imgUrl: '',
        location: GeoPoint(21.0091, 105.8289),
        flashsales: [],
      );

      when(() => mockService.getAllStores(userPosition: any(named: 'userPosition')))
          .thenAnswer((_) async => [storeNoFlash, storeWithFlash]);

      await provider.fetchAllStores();

      expect(provider.storesWithFlashSales.length, 1);
      expect(provider.storesWithFlashSales.first.id, 'f1');
    });
  });
}