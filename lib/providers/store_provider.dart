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
  Future<void> fetchUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services disabled';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permissions denied';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permissions denied forever';
      notifyListeners();
      return;
    }

    _userPosition = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  // 2. Lấy danh sách tiệm và TÍNH TOÁN KHOẢNG CÁCH THỰC TẾ
  Future<void> fetchAllStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Lấy dữ liệu thô từ Service
      List<Store> fetchedStores = await _storeService.getAllStores(userPosition: _userPosition);

      // Nếu có vị trí người dùng, tiến hành tính toán
      if (_userPosition != null) {
        _stores = fetchedStores.map((store) {
          if (store.location != null) {
            // Tính khoảng cách (mét) giữa 2 tọa độ GPS
            double distanceInMeters = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              store.location!.latitude,
              store.location!.longitude,
            );
            // Gán giá trị km mới cho store (Dùng copyWith)
            return store.copyWith(distance: distanceInMeters / 1000);
          }
          return store;
        }).toList();

        // NGHIỆP VỤ: Sắp xếp các tiệm gần người dùng nhất lên đầu
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