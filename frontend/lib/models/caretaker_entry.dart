class CaretakerEntry {
  final int assignmentId;
  final int caretakerId;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final int propertyId;
  final String propertyName;
  final String propertyAddress;

  const CaretakerEntry({
    required this.assignmentId,
    required this.caretakerId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.propertyId,
    required this.propertyName,
    required this.propertyAddress,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory CaretakerEntry.fromJson(Map<String, dynamic> json) {
    return CaretakerEntry(
      assignmentId: _toInt(json['assignment_id']),
      caretakerId: _toInt(json['caretaker_id']),
      email: (json['email'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      propertyId: _toInt(json['property_id']),
      propertyName: (json['property_name'] ?? '').toString(),
      propertyAddress: (json['property_address'] ?? '').toString(),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
