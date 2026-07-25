class MaintenanceItem {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String propertyName;
  final String unitNumber;
  final String tenantName;
  final String? tenantPhone;
  final String? tenantEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.propertyName,
    required this.unitNumber,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmergency => priority.toLowerCase() == 'emergency';
  bool get isResolved => status.toLowerCase() == 'completed';

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    final first = (json['tenant_first_name'] ?? '').toString();
    final last = (json['tenant_last_name'] ?? '').toString();
    final fullName = '$first $last'.trim();
    return MaintenanceItem(
      id: _toInt(json['id']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      category: (json['category'] ?? 'other').toString(),
      propertyName: (json['property_name'] ?? '').toString(),
      unitNumber: (json['unit_number'] ?? '').toString(),
      tenantName: fullName,
      tenantPhone: json['tenant_phone']?.toString(),
      tenantEmail: json['tenant_email']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
