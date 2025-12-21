// lib/models/technician_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class Technician {
  final String id;
  final String storeId;
  final String name;
  final String? avatarUrl;
  final List<String> specialty;
  final int experience; // years
  final double rating;
  final bool isAvailable;
  final List<String> workingHours;

  Technician({
    required this.id,
    required this.storeId,
    required this.name,
    this.avatarUrl,
    this.specialty = const [],
    this.experience = 0,
    this.rating = 0.0,
    this.isAvailable = true,
    this.workingHours = const [],
  });

  factory Technician.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Technician(
      id: doc.id,
      storeId: data['storeId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      avatarUrl: data['avatarUrl']?.toString(),
      specialty: List<String>.from(data['specialty'] ?? []),
      experience: (data['experience'] as int?) ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: data['isAvailable'] ?? true,
      workingHours: List<String>.from(data['workingHours'] ?? []),
    );
  }
}