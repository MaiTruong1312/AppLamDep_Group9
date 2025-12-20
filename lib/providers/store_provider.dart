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
      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions denied forever';
        notifyListeners();
        return;
      }
    }
    _userPosition = await Geolocator.getCurrentPosition();
    notifyListeners();
  }

  Future<void> fetchAllStores() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stores = await _storeService.getAllStores(userPosition: _userPosition);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchStore(String storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentStore = await _storeService.getStoreById(storeId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}