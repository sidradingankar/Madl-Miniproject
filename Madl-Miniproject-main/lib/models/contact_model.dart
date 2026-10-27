// ============================================================
// contact_model.dart — Data model for an emergency contact
// ============================================================

class ContactModel {
  final int? id;       // Auto-increment ID
  final String name;
  final String phone;
  final String relationship;
  final bool isEmergency; // true = contact used for SOS

  ContactModel({
    this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isEmergency = true,
  });

  // Convert to Map for JSON storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'isEmergency': isEmergency ? 1 : 0,
    };
  }

  // Create ContactModel from a stored JSON map
  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      relationship: map['relationship'] as String,
      isEmergency: (map['isEmergency'] as int) == 1,
    );
  }

  // Create a copy with modified fields
  ContactModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? relationship,
    bool? isEmergency,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isEmergency: isEmergency ?? this.isEmergency,
    );
  }

  @override
  String toString() =>
      'ContactModel(id: $id, name: $name, phone: $phone, relationship: $relationship)';
}
