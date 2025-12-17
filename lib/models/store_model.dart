import 'package:cloud_firestore/cloud_firestore.dart';

class Store {
  final String id;
  final String name;
  final String address;
  final String imgUrl;

  Store({
    required this.id,
    required this.name,
    required this.address,
    required this.imgUrl,
  });

  factory Store.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Store(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      imgUrl: data['img_url'] ?? '',
    );
  }
}
