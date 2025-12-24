// test/models/appointment_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:applamdep/models/appointment_model.dart';

class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  group('Appointment Model', () {
    late MockDocumentSnapshot mockDoc;

    setUp(() {
      mockDoc = MockDocumentSnapshot();
    });

    test('fromFirestore parses data correctly including nailDesigns and additionalServices', () {
      when(() => mockDoc.id).thenReturn('appt123');
      when(() => mockDoc.data()).thenReturn({
        'userId': 'user456',
        'storeId': 'store789',
        'bookingDate': Timestamp.fromDate(DateTime(2025, 12, 30)),
        'timeSlot': '10:00-11:00',
        'duration': 60,
        'status': 'confirmed',
        'nailDesigns': [
          {'nailId': 'nail1', 'name': 'Milky White'}
        ],
        'additionalServices': [
          {'serviceId': 'svc1', 'serviceName': 'Gel Top', 'price': 100000, 'quantity': 2}
        ],
        'totalPrice': 500000,
        'finalPrice': 450000,
        'customerName': 'Nguyễn Văn A',
        'customerPhone': '0901234567',
        'paymentStatus': 'paid',
      });

      final appointment = Appointment.fromFirestore(mockDoc);

      expect(appointment.id, 'appt123');
      expect(appointment.status, 'confirmed');
      expect(appointment.nailDesigns.length, 1);
      expect(appointment.additionalServices.length, 1);
      expect(appointment.additionalServices.first.serviceName, 'Gel Top');
      expect(appointment.additionalServices.first.quantity, 2);
      expect(appointment.formattedDate, '30/12/2025');
      expect(appointment.formattedTime, '10:00');
      expect(appointment.isConfirmed, true);
    });

    test('fromFirestore handles null/missing fields with defaults', () {
      when(() => mockDoc.id).thenReturn('appt456');
      when(() => mockDoc.data()).thenReturn({});

      final appointment = Appointment.fromFirestore(mockDoc);

      expect(appointment.status, 'pending');
      expect(appointment.paymentStatus, 'pending');
      expect(appointment.duration, 60);
      expect(appointment.nailDesigns, isEmpty);
      expect(appointment.additionalServices, isEmpty);
    });
  });
}