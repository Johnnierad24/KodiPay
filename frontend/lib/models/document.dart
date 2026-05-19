class DocumentItem {
  final int id;
  final String type;
  final String title;
  final String? description;
  final String fileUrl;
  final String? mimeType;
  final int? sizeBytes;
  final bool generated;
  final String status;
  final int? propertyId;
  final String? propertyName;
  final int? unitId;
  final String? unitNumber;
  final int? tenantId;
  final String? tenantName;
  final int? tenancyId;
  final int? paymentId;
  final DateTime? startsOn;
  final DateTime? expiresOn;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  DocumentItem({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.fileUrl,
    this.mimeType,
    this.sizeBytes,
    required this.generated,
    required this.status,
    this.propertyId,
    this.propertyName,
    this.unitId,
    this.unitNumber,
    this.tenantId,
    this.tenantName,
    this.tenancyId,
    this.paymentId,
    this.startsOn,
    this.expiresOn,
    required this.createdAt,
    required this.metadata,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return DocumentItem(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      mimeType: json['mime_type'] as String?,
      sizeBytes: json['size_bytes'] is int ? json['size_bytes'] as int : null,
      generated: json['generated'] == true,
      status: (json['status'] as String?) ?? 'active',
      propertyId: json['property_id'] is int ? json['property_id'] as int : null,
      propertyName: json['property_name'] as String?,
      unitId: json['unit_id'] is int ? json['unit_id'] as int : null,
      unitNumber: json['unit_number'] as String?,
      tenantId: json['tenant_id'] is int ? json['tenant_id'] as int : null,
      tenantName: json['tenant_name'] as String?,
      tenancyId: json['tenancy_id'] is int ? json['tenancy_id'] as int : null,
      paymentId: json['payment_id'] is int ? json['payment_id'] as int : null,
      startsOn: parseDate(json['starts_on']),
      expiresOn: parseDate(json['expires_on']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : <String, dynamic>{},
    );
  }
}
