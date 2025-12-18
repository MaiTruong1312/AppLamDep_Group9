import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? photoUrl;

  UserModel({required this.id, required this.name, this.photoUrl});

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'Anonymous',
      photoUrl: data['photoUrl'],
    );
  }
}
