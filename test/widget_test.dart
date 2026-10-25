import 'package:flutter_test/flutter_test.dart';
import 'package:emergency_assistance/models/contact_model.dart';
import 'package:emergency_assistance/models/sos_record_model.dart';

void main() {
  group('Model Tests', () {
    test('ContactModel toMap and fromMap serialization', () {
      final contact = ContactModel(
        id: 1,
        name: 'Jane Doe',
        phone: '9876543210',
        relationship: 'Sister',
        isEmergency: true,
      );

      final map = contact.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Jane Doe');
      expect(map['phone'], '9876543210');
      expect(map['relationship'], 'Sister');
      expect(map['isEmergency'], 1);

      final deserialized = ContactModel.fromMap(map);
      expect(deserialized.id, 1);
      expect(deserialized.name, 'Jane Doe');
      expect(deserialized.phone, '9876543210');
      expect(deserialized.relationship, 'Sister');
      expect(deserialized.isEmergency, true);
    });

    test('SosRecordModel mapsUrl generation', () {
      final record = SosRecordModel(
        latitude: 12.9716,
        longitude: 77.5946,
        timestamp: DateTime(2026, 10, 5, 10, 0),
        contactsNotified: 2,
        status: 'Sent (Demo)',
        isDemoMode: true,
      );

      expect(record.mapsUrl, contains('12.9716,77.5946'));
    });
  });
}
