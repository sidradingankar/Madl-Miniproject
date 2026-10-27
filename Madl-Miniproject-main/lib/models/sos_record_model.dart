// ============================================================
// sos_record_model.dart — Data model for an SOS history record
// ============================================================

class SosRecordModel {
  final int? id;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String status;           // e.g. "Alert Sent", "Cancelled", "No Contacts"
  final int contactsNotified;    // number of contacts alerted
  final bool isDemoMode;

  SosRecordModel({
    this.id,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.status,
    this.contactsNotified = 0,
    this.isDemoMode = false,
  });

  // Convert to Map for JSON storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'contactsNotified': contactsNotified,
      'isDemoMode': isDemoMode ? 1 : 0,
    };
  }

  // Create from stored JSON map
  factory SosRecordModel.fromMap(Map<String, dynamic> map) {
    return SosRecordModel(
      id: map['id'] as int?,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      status: map['status'] as String,
      contactsNotified: map['contactsNotified'] as int? ?? 0,
      isDemoMode: (map['isDemoMode'] as int? ?? 0) == 1,
    );
  }

  /// Returns a formatted Google Maps URL for this record's location
  String? get mapsUrl {
    if (latitude != null && longitude != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }
    return null;
  }

  @override
  String toString() =>
      'SosRecord(id: $id, status: $status, time: $timestamp)';
}
