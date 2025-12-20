import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/store_model.dart';

class StoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Store>> getAllStores({Position? userPosition}) async {
    try {
      QuerySnapshot query = await _firestore.collection('stores').get();
      List<Store> stores = query.docs.map((doc) => Store.fromFirestore(doc)).toList();
      if (userPosition != null) {
        stores.sort((a, b) {
          double distA = _calculateDistance(userPosition, a.location);
          double distB = _calculateDistance(userPosition, b.location);
          return distA.compareTo(distB);
        });
      }
      return stores;
    } catch (e) {
      throw Exception('Error fetching stores: $e');
    }
  }

  Future<Store> getStoreById(String storeId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        return Store.fromFirestore(doc);
      } else {
        throw Exception('Store not found');
      }
    } catch (e) {
      throw Exception('Error fetching store: $e');
    }
  }

  double _calculateDistance(Position userPos, GeoPoint? storeLoc) {
    if (storeLoc == null) return double.infinity;
    const double earthRadius = 6371; // km
    double lat1 = userPos.latitude * pi / 180;
    double lat2 = storeLoc.latitude * pi / 180;
    double deltaLat = (storeLoc.latitude - userPos.latitude) * pi / 180;
    double deltaLon = (storeLoc.longitude - userPos.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }
}