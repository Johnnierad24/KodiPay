class PaymentRecord {
  final int? tenancyId;
  final String tenantName;
  final String tenantPhone;
  final String tenantEmail;
  final String unit;
  final String property;
  final int amount;
  final String status;
  final String method;
  final String transactionRef;
  final String dueDate;
  final String? paidAt;
  final String createdAt;
  final String updatedAt;
  final int daysLate;

  const PaymentRecord({
    this.tenancyId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantEmail,
    required this.unit,
    required this.property,
    required this.amount,
    required this.status,
    required this.method,
    required this.transactionRef,
    required this.dueDate,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    required this.daysLate,
  });

  bool get isPaid => status == 'Paid';
  bool get isPending => status == 'Pending';

  factory PaymentRecord.fromTenancyAndPayment(dynamic tenancy, Map<String, dynamic> payment) {
    final t = tenancy as TenancyRecord;
    final amount = _toNum(payment['amount']).toInt();
    final rawStatus = (payment['status'] ?? 'pending').toString().toLowerCase();
    final paymentDate = _parseDate(payment['payment_date']);
    final createdAt = _parseDate(payment['created_at']);
    final updatedAt = _parseDate(payment['updated_at']);
    final dueDate = _assumedDueDate(t.startDate, paymentDate);
    final daysLate = rawStatus == 'completed' ? 0 : _daysBetween(dueDate, DateTime.now()).clamp(0, 9999);
    return PaymentRecord(
      tenancyId: t.id,
      tenantName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
      tenantPhone: t.tenantPhone ?? '—',
      tenantEmail: t.tenantEmail ?? '—',
      unit: t.unitNumber,
      property: t.propertyName,
      amount: amount,
      status: rawStatus == 'completed' ? 'Paid' : 'Pending',
      method: _displayMethod((payment['payment_method'] ?? '').toString()),
      transactionRef: (payment['transaction_ref']?.toString().trim().isNotEmpty ?? false) ? payment['transaction_ref'].toString() : 'Pending',
      dueDate: _formatDateStatic(dueDate),
      paidAt: rawStatus == 'completed' && paymentDate != null ? _formatDateTimeStatic(paymentDate) : null,
      createdAt: createdAt != null ? _formatDateTimeStatic(createdAt) : '—',
      updatedAt: updatedAt != null ? _formatDateTimeStatic(updatedAt) : '—',
      daysLate: daysLate,
    );
  }

  factory PaymentRecord.pendingFor(dynamic tenancy) {
    final t = tenancy as TenancyRecord;
    final dueDate = _assumedDueDate(t.startDate, null);
    final daysLate = _daysBetween(dueDate, DateTime.now()).clamp(0, 9999);
    return PaymentRecord(
      tenancyId: t.id,
      tenantName: t.tenantName.isEmpty ? 'Tenant' : t.tenantName,
      tenantPhone: t.tenantPhone ?? '—',
      tenantEmail: t.tenantEmail ?? '—',
      unit: t.unitNumber,
      property: t.propertyName,
      amount: t.rentAmount.toInt(),
      status: 'Pending',
      method: 'M-Pesa',
      transactionRef: 'Pending',
      dueDate: _formatDateStatic(dueDate),
      paidAt: null,
      createdAt: '—',
      updatedAt: '—',
      daysLate: daysLate,
    );
  }
}

// ── Import and re-export TenancyRecord for convenience
class TenancyRecord {
  final int id;
  final int tenantId;
  final String tenantName;
  final String? tenantPhone;
  final String? tenantEmail;
  final String unitNumber;
  final int unitId;
  final String propertyName;
  final int propertyId;
  final num rentAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;

  const TenancyRecord({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    this.tenantPhone,
    this.tenantEmail,
    required this.unitNumber,
    required this.unitId,
    required this.propertyName,
    required this.propertyId,
    required this.rentAmount,
    this.startDate,
    this.endDate,
    required this.status,
  });

  factory TenancyRecord.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final tenantName = fullName.isNotEmpty ? fullName : (json['tenant_name']?.toString() ?? '');
    return TenancyRecord(
      id: _toInt(json['id']),
      tenantId: _toInt(json['tenant_id']),
      tenantName: tenantName,
      tenantPhone: json['tenant_phone'] as String?,
      tenantEmail: json['tenant_email'] as String?,
      unitNumber: (json['unit_number'] ?? '').toString(),
      unitId: _toInt(json['unit_id']),
      propertyName: (json['property_name'] ?? '').toString(),
      propertyId: _toInt(json['property_id']),
      rentAmount: _toNum(json['rent_amount']),
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      status: (json['status'] ?? 'active').toString(),
    );
  }
}

// ── Helpers ────────────────────────────────────────────
int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

num _toNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  return num.tryParse(value.toString()) ?? 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  try { return DateTime.parse(value.toString()); } catch (_) { return null; }
}

String _displayMethod(String raw) {
  switch (raw.toLowerCase()) {
    case 'mpesa': return 'M-Pesa';
    case 'bank_transfer': return 'Bank Transfer';
    case 'cash': return 'Cash';
    default: return raw.isEmpty ? '—' : raw;
  }
}

DateTime _assumedDueDate(DateTime? tenancyStart, DateTime? paymentDate) {
  final reference = paymentDate ?? DateTime.now();
  final dueDay = tenancyStart?.day ?? 25;
  final day = dueDay.clamp(1, 28);
  return DateTime(reference.year, reference.month, day);
}

int _daysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

String _formatDateStatic(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
}

String _formatDateTimeStatic(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${_formatDateStatic(d)}, ${hour12.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
}


