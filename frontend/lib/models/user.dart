class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phone;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;
  final String? businessName;
  final String? businessRegistration;
  final String? businessKraPin;
  final String? businessContactPerson;
  final String? businessAddress;
  final String? businessCity;
  final String? businessCounty;
  final String? businessPostalCode;
  final String? businessPhone;
  final String? businessEmail;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phone,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.businessName,
    this.businessRegistration,
    this.businessKraPin,
    this.businessContactPerson,
    this.businessAddress,
    this.businessCity,
    this.businessCounty,
    this.businessPostalCode,
    this.businessPhone,
    this.businessEmail,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
      phone: json['phone'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactRelation: json['emergency_contact_relation'],
      emergencyContactPhone: json['emergency_contact_phone'],
      businessName: json['business_name'],
      businessRegistration: json['business_registration'],
      businessKraPin: json['business_kra_pin'],
      businessContactPerson: json['business_contact_person'],
      businessAddress: json['business_address'],
      businessCity: json['business_city'],
      businessCounty: json['business_county'],
      businessPostalCode: json['business_postal_code'],
      businessPhone: json['business_phone'],
      businessEmail: json['business_email'],
    );
  }
}
