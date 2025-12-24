// test/models/nail_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/nail_model.dart'; // sửa đường dẫn nếu cần

// Tạo class mock kế thừa từ DocumentSnapshot
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Nail Model', () {
    late MockDocumentSnapshot mockDoc;

    setUp(() {
      mockDoc = MockDocumentSnapshot();
    });

    test('fromFirestore should create Nail correctly', () {
      // Setup mock data
      when(() => mockDoc.id).thenReturn('nail123');
      when(() => mockDoc.data()).thenReturn({
        'name': 'Milky White',
        'img_url': 'https://example.com/nail.jpg',
        'likes': 150,
        'price': 250000,
        'descriptions': 'Mẫu móng trắng sữa hot trend',
        'store_id': 'store456',
        'tags': ['Best Choice', 'Summer'],
        'store_Ids': ['store456', 'store789'],
      });

      final nail = Nail.fromFirestore(mockDoc);

      expect(nail.id, 'nail123');
      expect(nail.name, 'Milky White');
      expect(nail.price, 250000);
      expect(nail.isBestChoice, true);
      expect(nail.storeIds.length, 2);
    });

    test('fromFirestore handles missing fields gracefully', () {
      when(() => mockDoc.id).thenReturn('nail456');
      when(() => mockDoc.data()).thenReturn({}); // Không có dữ liệu

      final nail = Nail.fromFirestore(mockDoc);

      expect(nail.name, 'No Name');
      expect(nail.imgUrl, 'assets/images/nail1.png');
      expect(nail.price, 0);
      expect(nail.description, 'No description available.');
      expect(nail.isBestChoice, false);
    });
  });
}