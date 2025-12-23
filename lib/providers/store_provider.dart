import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_model.dart';
import '../models/service_model.dart';
import '../services/store_service.dart';

class StoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StoreService _storeService = StoreService();

  List<Store> _stores = [];
  Store? _currentStore;
  bool _isLoading = false;
  String? _error;
  Position? _userPosition;

  // Getters
  List<Store> get stores => _stores;
  Store? get currentStore => _currentStore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get userPosition => _userPosition;
  List<Store> get storesWithFlashSales {
    return _stores.where((store) => store.flashsales.isNotEmpty).toList();
  }

  // 1. LẤY VỊ TRÍ NGƯỜI DÙNG (Giả lập tại Học viện Ngân hàng)
  Future<void> fetchUserLocation() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Thiết lập vị trí cố định theo yêu cầu
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
      debugPrint("Đã xác định vị trí tại: Học viện Ngân hàng");
    } catch (e) {
      _error = 'Lỗi giả lập vị trí: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. LẤY CHI TIẾT TIỆM VÀ ĐỒNG BỘ DỊCH VỤ TỪ KHO TỔNG
  Future<void> fetchStore(String storeId) async {
    _isLoading = true;
    _error = null;
    _currentStore = null; // Xóa dữ liệu cũ để tránh nhầm lẫn UI
    notifyListeners();

    try {
      // BƯỚC A: Lấy dữ liệu Store từ collection 'stores'
      DocumentSnapshot storeDoc = await _firestore.collection('stores').doc(storeId).get();
      if (!storeDoc.exists) throw "Cửa hàng không tồn tại";

      Map<String, dynamic> storeData = storeDoc.data() as Map<String, dynamic>;

      // BƯỚC B: Lấy mảng String tên dịch vụ từ trường 'services'
      List<String> serviceNames = List<String>.from(storeData['services'] ?? []);
      // BƯỚC C: Truy vấn "Kho tổng" để lấy chi tiết (ảnh, giá, mô tả...)
      List<Service> detailedServices = [];
      if (serviceNames.isNotEmpty) {
        // Dùng 'whereIn' để lấy tất cả dịch vụ chỉ với 1 lần gọi (tối ưu hiệu năng)
        QuerySnapshot serviceSnap = await _firestore
            .collection('services')
            .where('name', whereIn: serviceNames)
            .get();

        detailedServices = serviceSnap.docs.map((doc) => Service.fromFirestore(doc)).toList();
      }

      // BƯỚC D: Tạo đối tượng Store và tính khoảng cách thực tế
      Store store = Store.fromFirestore(storeDoc);

      double? dist;
      if (_userPosition != null && store.location != null) {
        dist = Geolocator.distanceBetween(
            _userPosition!.latitude, _userPosition!.longitude,
            store.location!.latitude, store.location!.longitude
        ) / 1000; // Đổi sang km
      }

      // Cập nhật currentStore với đầy đủ thông tin dịch vụ
      // LƯU Ý: Phải đảm bảo Model Store đã có hàm copyWith nhận tham số 'services'
      _currentStore = store.copyWith(
        distance: dist,
        services: detailedServices,
      );

    } catch (e) {
      _error = e.toString();
      debugPrint("Lỗi fetchStore: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. LẤY DANH SÁCH TIỆM (Dành cho trang chủ)
  Future<void> fetchAllStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      List<Store> fetchedStores = await _storeService.getAllStores(userPosition: _userPosition);

      if (_userPosition != null) {
        _stores = fetchedStores.map((store) {
          if (store.location != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              _userPosition!.latitude,
              _userPosition!.longitude,
              store.location!.latitude,
              store.location!.longitude,
            );
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
}