
import 'package:cloud_firestore/cloud_firestore.dart';

class Nail {
  final String id;
  final String name;
  final String imgUrl;
  final int likes;
  final int price;
  final String description;
  final String storeId;
  final List<String> tags;
  final bool isBestChoice;

  Nail({
    required this.id,
    required this.name,
    required this.imgUrl,
    required this.likes,
    required this.price,
    required this.description,
    required this.storeId,
    required this.tags,
    this.isBestChoice = false,
  });

  factory Nail.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Nail(
      id: doc.id,
      name: data['name'] ?? 'No Name',
      imgUrl: data['img_url'] ?? 'assets/images/nail_placeholder.png',
      likes: data['likes'] ?? 0,
      price: data['price'] ?? 0,
      description: data['descriptions'] ?? 'No description available.',
      storeId: data['store_id'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      isBestChoice: (List<String>.from(data['tags'] ?? [])).contains('Best Choice'),
    );
  }
}
