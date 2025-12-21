import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_model.dart';
import '../services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final StoreService _storeService = StoreService();
  List<Store> _stores = [];
  Store? _currentStore;
  bool _isLoading = false;
  String? _error;
  Position? _userPosition;

  List<Store> get stores => _stores;
  Store? get currentStore => _currentStore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get userPosition => _userPosition;

  // 1. Lấy tọa độ GPS của người dùng
  // store_provider.dart
  Future<void> fetchUserLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      // THIẾT LẬP VỊ TRÍ CỐ ĐỊNH TẠI HỌC VIỆN NGÂN HÀNG
      _userPosition = Position(
        latitude: 21.0091,
        longitude: 105.8289,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      print("Đã xác định vị trí tại: Học viện Ngân hàng");
    } catch (e) {
      _error = 'Lỗi giả lập vị trí: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Lấy danh sách tiệm và TÍNH TOÁN KHOẢNG CÁCH THỰC TẾ
  Future<void> fetchAllStores() async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Lấy danh sách tiệm từ Firebase
      List<Store> fetchedStores = await _storeService.getAllStores(userPosition: _userPosition);

      // 2. Nếu đã lấy được vị trí người dùng (_userPosition không null)
      if (_userPosition != null) {
        _stores = fetchedStores.map((store) {
          if (store.location != null) {
            // Tính khoảng cách từ bạn đến tiệm (trả về mét)
            double distanceInMeters = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              store.location!.latitude,
              store.location!.longitude,
            );
            // Chuyển sang km và tạo bản sao mới của store bằng copyWith
            return store.copyWith(distance: distanceInMeters / 1000);
          }
          return store;
        }).toList();

        // Sắp xếp tiệm gần nhất lên đầu
        _stores.sort((a, b) => a.distance.compareTo(b.distance));
      } else {
        _stores = fetchedStores;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. Lấy chi tiết 1 tiệm và cập nhật khoảng cách cho màn hình Detail
  Future<void> fetchStore(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Store store = await _storeService.getStoreById(storeId);

      if (_userPosition != null && store.location != null) {
        double dist = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude,
            store.location!.latitude, store.location!.longitude
        );
        _currentStore = store.copyWith(distance: dist / 1000);
      } else {
        _currentStore = store;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}